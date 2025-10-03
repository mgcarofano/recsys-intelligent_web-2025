"""

	http_server.py
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

"""

#	########################################################################	#
#	LIBRERIE

import json
import socket
import os
import shutil

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qsl
from pathlib import Path
from time import sleep

import random

import csv
import numpy as np
import pandas as pd
from scipy.sparse import load_npz

#	########################################################################	#
#	COSTANTI

ADDRESS = '0.0.0.0'
PORT = 8000
TIMEOUT = 30

SUBJECTS_SELECTION = 3
MOVIE_RECOMMENDATIONS = 5

POSTER_DIR = Path('./data/movie_posters')
CSV_PATH_MAPPING = {
	'title': Path('./data/CSVs/existing_movies.csv'),
	'description': Path('./data/CSVs/movie_abstracts.csv'),
	'actors': Path('./data/CSVs/movie_actors.csv'),
	'composers': Path('./data/CSVs/movie_composers.csv'),
	'directors': Path('./data/CSVs/movie_directors.csv'),
	'genres': Path('./data/CSVs/movie_genres.csv'),
	'producers': Path('./data/CSVs/movie_producers.csv'),
	'production_companies': Path('./data/CSVs/movie_production_companies.csv'),
	'subjects': Path('./data/CSVs/movie_subjects.csv'),
	'writers': Path('./data/CSVs/movie_writers.csv'),
}

CATEGORIES = [
	cat
	for cat in CSV_PATH_MAPPING.keys()
	if cat not in ['title', 'description']
]

#	########################################################################	#
#	VARIABILI GLOBALI

movies_features_map = {}
user_id = 3
all_ratings = {}
top_features_list = []

#	########################################################################	#
#	ALTRE FUNZIONI

def compute_movie_features_ratings():
    # 1) Matrice film-features (M x F) e mapping
    movie_features_matrix = load_npz('./data/movie_vectors_sparse.npz')  # CSR matrix (M x F)
    M, F = movie_features_matrix.shape

    mapping_df = pd.read_csv('./data/movie_index.csv')
    mapping_df['movie_id'] = mapping_df['movie_id'].astype(int)
    mapping_df['matrix_id'] = mapping_df['matrix_id'].astype(int)
    movie_id_to_index = dict(zip(mapping_df['movie_id'], mapping_df['matrix_id']))

    # 2a) Estrai i rating dello user
    ratings_df = pd.read_csv('./data/CSVs/existing_ratings.csv')
    user_real_ratings = ratings_df[ratings_df["userId"] == user_id][["movieId", "rating"]]

    # 2b) Estrai i rating predetti per lo user
    comp_path = f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv'
    user_predicted_ratings = pd.read_csv(comp_path)

    # 2c) Crea i dizionari {movieId: rating}
    real_ratings = dict(zip(
        user_real_ratings['movieId'].astype(int),
        user_real_ratings['rating'].astype(float)
    ))
    comp_ratings = dict(zip(
        user_predicted_ratings['movieId'].astype(int),
        user_predicted_ratings['rating'].astype(float)
    ))

    # 3) Unione dei rating reali con quelli predetti
    all_ratings = comp_ratings.copy()
    all_ratings.update(real_ratings)

    # 3b) Vettore dei rating (M x 1), riempito con 0 dove non ci sono rating
    movie_ratings = np.zeros(M, dtype=float)
    for movie_id, rating in all_ratings.items():
        idx = movie_id_to_index.get(movie_id)
        if idx is not None and 0 <= idx < M:
            movie_ratings[idx] = rating

    # 4) Calcolo feature_means in modo ottimizzato (O(NNZ), ovvero proporzionale al numero di elementi non-nulli nella matrice sparsa)
    sum_per_feature = movie_features_matrix.T.dot(movie_ratings)

    # Conteggio del numero di film per ogni feature (numero di 1 in colonna)
    count_per_feature = movie_features_matrix.T.dot(np.ones(M, dtype=float))

    # Media dei rating per feature (ignorando divisione per 0)
    feature_means = np.divide(
        sum_per_feature,
        count_per_feature,
        out=np.zeros_like(sum_per_feature, dtype=float),
        where=(count_per_feature != 0)
    )

    return feature_means, movie_ratings

	#	2. unire ratings calcolati e assegnati da U (dim. Mx1)
	#	3. calcolare hadamard prodotto di M (ratings) moltiplicato M*F (matrice movies-features)
	#	4a. calcolare la media sulla matrice M*F per ogni feature -> vettore 1xF
	#	4b. calcolare la media sulla matrice M*F per ogni feature -> vettore Mx1

	# end

def extract_user_top_features(feature_means, top_n):

    # if cat == "genres" and row['value'] == "(no genres listed)":

    # # Filtra le features più importanti.
    # # filtered_features = {
    # #     feat: sorted(list(films))
    # #     for feat, films in features.items() if len(films) >= MOVIE_RECOMMENDATIONS
    # # }

    # 5. ordinare il vettore 1xF dei rating sulle features
    top_indices = np.argsort(-feature_means)[:top_n]  # ordina in desc, prende top_n

    # 6. accedere a feature_index.csv e ritornare un vettore di 3 features (id, category, name, rating)
    feature_index = pd.read_csv("./data/feature_index.csv")

    top_features_list = []
    # Non usiamo 'rating' qui, ma usiamo 'idx' per accedere sia al DataFrame che a feature_means
    for idx in top_indices:
        row = feature_index.iloc[idx]

        # Prende il valore di rating (media) per la feature all'indice 'idx'
        feature_rating_value = feature_means[idx]

        top_features_list.append({
            "id": int(row["feature_id"]),
            "category": row["category"],
            "name": row["feature"],
            # Inseriamo il valore del rating (float) nel campo 'rating', come richiesto
            "rating": float(feature_rating_value)
        })

    return top_features_list

    # end

def mab_softmax_predictions(top_features_list, temperature=0.5, k=3):
    """
    Esegue MAB softmax prediction per le top features.

    Args:
        top_features_list: lista di features con dentro "movies" come lista di triple (movieId, rating, seen_bool)
        temperature: parametro tau della softmax (default 0.5)
        k: numero di film da estrarre per feature

    Returns:
        predictions: dizionario feature_id -> lista di predizioni [(movieId, rating, seen_bool, prob)]
    """

    predictions = {}

    for f in top_features_list:
        movies = f.get("movies", [])
        if not movies:
            continue

        # estrai solo i rating
        ratings = np.array([m[1] for m in movies], dtype=float)

        # softmax con temperatura tau
        exp_r = np.exp(ratings / temperature)
        probs = exp_r / np.sum(exp_r)

        # campiona k film in base alle probabilità
        chosen_idx = np.random.choice(len(movies), size=min(k, len(movies)), replace=False, p=probs)

        chosen_movies = []
        for idx in chosen_idx:
            chosen_movies.append((
                movies[idx][0],   # movieId
                movies[idx][1],   # rating
                movies[idx][2],   # visto o meno
                probs[idx]        # probabilità softmax
            ))

        predictions[f["id"]] = {
            "feature_name": f["name"],
            "category": f["category"],
            "movies": chosen_movies
        }

    return predictions


def get_movie_recommendations():

	pass

	# end

# def get_movie_recommendations():

# 	recommendations = {}

# 	# # Test
# 	# selected_categories = ["actors", "directors"]
# 	# available_features = {"Sylvester Stallone"}

# 	# Seleziona casualmente le categorie da raccomandare.
# 	selected_categories = random.choices(CATEGORIES, k=SUBJECTS_SELECTION)

# 	for cat in selected_categories:

# 		# Verifica che la categoria non sia vuota.
# 		if movies_features_map[cat]:

# 			# Estrai solo le feature che non sono ancora state scelte per quella categoria.
# 			available_features = set(movies_features_map[cat].keys()) - set(recommendations.get(cat, {}).keys())

# 			if available_features:

# 				# Seleziona casualmente le features da raccomandare.
# 				feature = random.choice(list(available_features))

# 				# Aggiorna la raccomandazione con la lista di film relativa alla feature della categoria selezionata.
# 				recommendations.setdefault(cat, {})[feature] = movies_features_map[cat][feature]

# 	return recommendations

# 	# end

#	########################################################################	#
#	CLASSI

class RecSys_HTTPServer:

    def __init__(self):

        # ################################################################ #
        # ANALISI DEL DATASET
        top_n = 5
        # Estrae le feature e i ratings film per l'utente

        # 1) Matrice film-features (M x F) e mapping
        movie_features_matrix = load_npz('./data/movie_vectors_sparse.npz')  # CSR matrix (M x F)
        M, F = movie_features_matrix.shape

        mapping_df = pd.read_csv('./data/movie_index.csv')
        mapping_df['movie_id'] = mapping_df['movie_id'].astype(int)
        mapping_df['matrix_id'] = mapping_df['matrix_id'].astype(int)
        movie_id_to_index = dict(zip(mapping_df['movie_id'], mapping_df['matrix_id']))
        print("1")

        # 2a) Estrai i rating dello user
        ratings_df = pd.read_csv('./data/CSVs/existing_ratings.csv')
        user_real_ratings = ratings_df[ratings_df["userId"] == user_id][["movieId", "rating"]]
        print("2a")

        # 2b) Estrai i rating predetti per lo user
        comp_path = f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv'
        user_predicted_ratings = pd.read_csv(comp_path)
        print("2b")

        # 2c) Crea i dizionari {movieId: rating}
        real_ratings = dict(zip(
         user_real_ratings['movieId'].astype(int),
         user_real_ratings['rating'].astype(float)
        ))
        # print(f"real ratings {real_ratings}")
        comp_ratings = dict(zip(
         user_predicted_ratings['movieId'].astype(int),
         user_predicted_ratings['rating'].astype(float)
        ))
        # print(f"comp ratings {comp_ratings}")
        print("2c")

        # 3) Unione dei rating reali con quelli predetti
        all_ratings = comp_ratings.copy()
        all_ratings.update(real_ratings)
        print("3")
        # print(f"all_ratings {all_ratings}")
        # print(f"DEBUG: Comp Ratings Count: {len(comp_ratings)}")
        # print(f"DEBUG: Real Ratings Count: {len(real_ratings)}")
        # print(f"DEBUG: All Ratings Count: {len(all_ratings)}")

        # 3b) Vettore dei rating (M x 1), riempito con 0 dove non ci sono rating
        movie_ratings = np.zeros(M, dtype=float)
        for movie_id, rating in all_ratings.items():
          idx = movie_id_to_index.get(movie_id)
          if idx is not None and 0 <= idx < M:
            movie_ratings[idx] = rating
        non_zero_ratings = np.count_nonzero(movie_ratings)
        print(f"DEBUG: Non-zero movie ratings: {non_zero_ratings}")
        print("3b")

        # 4) Calcolo feature_means in modo ottimizzato (O(NNZ), ovvero proporzionale al numero di elementi non-nulli nella matrice sparsa)
        sum_per_feature = movie_features_matrix.T.dot(movie_ratings)

        # Conteggio del numero di film per ogni feature (numero di 1 in colonna)
        count_per_feature = movie_features_matrix.T.dot(np.ones(M, dtype=float))

        # Media dei rating per feature (ignorando divisione per 0)
        feature_means = np.divide(
         sum_per_feature,
         count_per_feature,
         out=np.zeros_like(sum_per_feature, dtype=float),
         where=(count_per_feature != 0)
        )
        print("4")

        # 5b) Filtro: consideriamo solo le feature con almeno top_n valori non nulli
        valid_mask = count_per_feature >= 4 * top_n
        feature_means = feature_means * valid_mask  # azzera le feature con meno supporto
        print("5b")

        print("Feature means:", feature_means.shape)
        print("Movie ratings:", movie_ratings.shape)
        print("OK: feature and movie ratings extracted!")


        # Estrae le top features dell'utente
        top_features_list = extract_user_top_features(feature_means, top_n)
        # stampa le top features
        print("\nTop Features:")
        # Usiamo un contatore 'i' solo per stampare la posizione di debug, sebbene il campo 'rating' sia ora il rating
        for i, f in enumerate(top_features_list, start=1):
            print(f"Position {i}: [{f['category']}] {f['name']} (id={f['id']}, rating/rank={f['rating']:.2f})")

        for f in top_features_list:
            feat_id = f["id"]

            # prendi la colonna corrispondente alla feature
            if 0 <= feat_id < F:
                col = movie_features_matrix[:, feat_id].toarray().flatten()  # colonna Mx1

                # trova gli indici con valore 1
                matrix_indices = np.where(col == 1)[0]

                movies_list = []
                for idx in matrix_indices:
                    # trova movieId dal matrix_id
                    movie_row = mapping_df[mapping_df["matrix_id"] == idx]
                    if movie_row.empty:
                        continue
                    movie_id = int(movie_row["movie_id"].iloc[0])

                    # cerca rating reale o complementare
                    if movie_id in real_ratings:
                        movies_list.append((movie_id, real_ratings[movie_id], True))
                    elif movie_id in comp_ratings:
                        movies_list.append((movie_id, comp_ratings[movie_id], False))

                # aggiungi la lista di triple alla feature
                f["movies"] = movies_list

        # stampa aggiornato
        print("\nTop features extracted with movies:")
        for f in top_features_list:
            print(f"\nFeature: {f['name']} (id={f['id']}, cat={f['category']})")
            for m in f["movies"][:10]:  # stampane max 10 per leggibilità
                print(f"  MovieId={m[0]}, Rating={m[1]}, Seen={m[2]}")

        # # Recupera tutti i movieId e le feature per ogni categoria
        # movies_features_map = {}
        # for cat in CATEGORIES:
        #     features = {}
        #     with open(CSV_PATH_MAPPING[cat], newline='', encoding='utf-8') as f:
        #         next(f)
        #         reader = csv.DictReader(f, fieldnames=['movieId', 'value'])
        #         for row in reader:
        #             m_id, feat = row['movieId'], row['value']
        #             if m_id and m_id.isdigit() and feat:
        #                 # Ottieni il rating da ratings_complemented (se esiste)
        #                 # rating = ratings_complemented.set_index("movieId")["rating"].get(m_id_int, None)

        #                 # Salva sia il movieId che il rating nella struttura
        #                 features.setdefault(feat, []).append({
        #                     "movieId": m_id,
        #                     # "rating": rating
        #                 })

        #         # Aggiungi la categoria solo se non è vuota.
        #         if features:
        #             movies_features_map[cat] = features

        # ################################################################ #
        # STAMPA TUTTI I MOVIE DELLE TOP FEATURES
        # print("\nMovies for top features:")
        # for f in top_features_list:
        #     cat = f["category"]
        #     feat_name = f["name"]
        #     if cat in movies_features_map and feat_name in movies_features_map[cat]:
        #         print(f"\nCategory: {cat}, Feature: {feat_name}")
        #         for movie_entry in movies_features_map[cat][feat_name]:
        #             print(f"MovieId: {movie_entry['movieId']}, Rating: {movie_entry['rating']}")

        # ################################################################ #mo
        # INIZIALIZZAZIONE ED ESECUZIONE DEL SERVER
        server = HTTPServer((ADDRESS, PORT), RecSys_RequestHandler)
        print("Server in esecuzione su " + str(ADDRESS) + ":" + str(PORT) + "...")

        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass

        print('Interruzione del server in corso...')
        server.server_close()
        print('Arrivederci!')
        exit(1)

        # end

    # end class

class RecSys_RequestHandler(BaseHTTPRequestHandler):

	def _send_cors_headers(self):
		self.send_header('Access-Control-Allow-Origin', '*')
		self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
		self.send_header('Access-Control-Allow-Headers', '*')
		# end

	def do_OPTIONS(self):
		self.send_response(200) # OK
		self._send_cors_headers()
		self.end_headers()
		# end

	def do_HEAD(self):
		self.send_response(200) # OK
		self._send_cors_headers()
		self.end_headers()
		# end

	def do_GET(self):

		try:

			if urlparse(self.path).path.endswith('/get-users'):
				with open("./data/CSVs/existing_ratings.csv", newline='', encoding='utf-8') as f:
					next(f)
					reader = csv.DictReader(f, fieldnames=['userId'])
					user_ids = {row['userId'] for row in reader if row['userId'].isdigit()}

				output = json.dumps(sorted(list(user_ids)))

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-users'

			if urlparse(self.path).path.endswith('/get-recommendations'):
				recs = get_movie_recommendations()
				output = json.dumps(recs)

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-recommendations'

			elif urlparse(self.path).path.endswith('/download-movie-poster'):
				selected_id = dict(parse_qsl(urlparse(self.path).query))['id']

				if not selected_id:
					self.send_response(400, 'Impossibile eseguire tale richiesta.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				file_name_path = None

				for file in POSTER_DIR.glob("*.jpg"):
					if file.name.startswith(selected_id + '_') and file.is_file:
						file_name_path = POSTER_DIR.resolve().joinpath(file.name)

				if not file_name_path:
					self.send_response(404, 'Copertina non trovata') # NOT FOUND
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				with open(file_name_path, 'rb') as f:
					self.send_response(200)
					self._send_cors_headers()
					self.send_header('Content-type', 'image/jpeg')
					self.end_headers()
					self.wfile.write(f.read())
					return

				# end if '/download-movie-poster'

			elif urlparse(self.path).path.endswith('/get-movie-info'):
				params = dict(parse_qsl(urlparse(self.path).query))
				selected_id = params['id']

				if 'type' in params.keys():
					selected_type = params['type']
					if selected_type not in CSV_PATH_MAPPING:
						self.send_response(400, 'Informazione non disponibile.') # BAD REQUEST
						self._send_cors_headers()
						self.send_header('Content-type', 'text/plain')
						self.end_headers()
						return

				if not selected_id:
					self.send_response(400, 'Impossibile eseguire tale richiesta.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				results = {}

				for key, path in CSV_PATH_MAPPING.items():
					if 'selected_type' in locals() and selected_type != key:
						continue

					with open(path, newline='', encoding='utf-8') as f:
						collecting = False
						info_values = []
						reader = csv.DictReader(f, fieldnames=['movieId', 'value'])

						for row in reader:
							if row['movieId'] == selected_id:
								collecting = True
								info_values.append(row['value'])
							elif collecting:
								break

						if info_values:
							results[key] = info_values

					if 'selected_type' in locals() and selected_type == key:
						break

				if not results:
					self.send_response(404, f'Informazione "{selected_type}" non trovata per movie "{selected_id}"') # NOT FOUND
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				output = json.dumps(results)

				self.send_response(200)
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-movie-info'

			else:
				self.send_response(404, 'Impossibile eseguire tale richiesta.') # NOT FOUND
				self._send_cors_headers()
				self.send_header('Content-type', 'text/plain')
				self.end_headers()
				return

				# end

		except BaseException as exc:
			self.send_response(500, f'{type(exc).__name__}: {exc}') # INTERNAL SERVER ERROR
			self._send_cors_headers()
			self.send_header('Content-type', 'text/plain')
			self.end_headers()

		# end

	def do_POST(self):

		try:

			if urlparse(self.path).path.endswith('/update-user'):
				ctype = self.headers.get('Content-Type')
				content_len = int(self.headers.get('Content-Length', 0))

				if not ctype == 'application/json':
					self.send_response(400, 'Il "content-type" non è application/json.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				body = self.rfile.read(content_len).decode('utf-8')
				data = json.loads(body)
				# print(data)

				if not isinstance(data, int):
					self.send_response(400, 'Il payload deve essere un intero.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				user_id = data

				self.send_response(201, 'Utente loggato con successo!') # CREATED
				self._send_cors_headers()
				self.end_headers()
				# print(str(self.user_prefs))
				return

				# end if '/update-user'

			# if urlparse(self.path).path.endswith('/update-preferences'):
			# 	# Content-type, Parameter dictionary
			# 	ctype = self.headers.get('Content-Type')
			# 	content_len = int(self.headers.get('Content-Length', 0))

			# 	if not ctype == 'application/json':
			# 		self.send_response(400, 'Il "content-type" non è application/json.') # BAD REQUEST
			# 		self._send_cors_headers()
			# 		self.send_header('Content-type', 'text/plain')
			# 		self.end_headers()
			# 		return

			# 	body = self.rfile.read(content_len).decode('utf-8')
			# 	data = json.loads(body)
			# 	# print(data)

			# 	if not isinstance(data, list) or not all(isinstance(i, str) for i in data):
			# 		self.send_response(400, 'Il payload deve essere una lista di stringhe.') # BAD REQUEST
			# 		self._send_cors_headers()
			# 		self.send_header('Content-type', 'text/plain')
			# 		self.end_headers()
			# 		return

			# 	self.user_prefs.id_movies = data

			# 	self.send_response(201, 'Preferenze aggiornate con successo!') # CREATED
			# 	self._send_cors_headers()
			# 	self.end_headers()
			# 	# print(str(self.user_prefs))
			# 	return

			# 	# end if '/update-preferences'

			else:
				self.send_response(404, 'Impossibile eseguire tale richiesta.') # NOT FOUND
				self._send_cors_headers()
				self.send_header('Content-type', 'text/plain')
				self.end_headers()
				return

				# end

		except BaseException as exc:
			self.send_response(500, f'{type(exc).__name__}: {exc}') # INTERNAL SERVER ERROR
			self._send_cors_headers()
			self.send_header('Content-type', 'text/plain')
			self.end_headers()
			return

		# end

	# end class

#	########################################################################	#
#	MAIN

if __name__ == "__main__":
    RecSys_HTTPServer()
	# end

#	########################################################################	#
#	RIFERIMENTI

