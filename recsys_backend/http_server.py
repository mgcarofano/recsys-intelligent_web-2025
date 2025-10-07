"""

	http_server.py \n
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	Implementa il server HTTP e il motore di raccomandazione dei film. Gestisce le richieste del client tramite API REST (GET/POST), calcola le raccomandazioni personalizzate in base alle feature dei film e i ratings dell'utente loggato e restituisce i risultati in formato JSON.

"""

#	########################################################################	#
#	LIBRERIE

from constants import *

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qsl
import json

import csv
import numpy as np
import pandas as pd
from scipy.sparse import load_npz

#	########################################################################	#
#	VARIABILI GLOBALI

# Identificativo dell'utente di cui si vogliono verificare le raccomandazioni.
user_id = ""

# Lista di features, caratterizzate da (id, category, name, average_rating), a cui sono collegati i movies, caratterizzati da (movieId, rating, seen_bool), che includono tale feature.
top_features_list = []

# Matrice sparsa contenente la rappresentazione vettoriale di un film secondo le sue features.
movie_features_matrix = load_npz(MOVIE_FEATURE_MATRIX_PATH)
M, F = movie_features_matrix.shape

# Dataframe che mette in relazione l'id di un film con l'indice all'interno della matrice movie/features.
movie_index_df = pd.read_csv(MOVIE_INDEX_PATH, dtype=int)
movie_id_to_index = dict(zip(
	movie_index_df['movie_id'],
	movie_index_df['matrix_id']
))

# Dataframe di features identificate da 3 elementi (id, category, name).
feature_index_df = pd.read_csv(FEATURE_INDEX_PATH)

# Dataframe contenente tutti i rating assegnati dagli utenti ai film della lista "existing_movies.csv"
real_ratings_df = pd.read_csv(EXISTING_RATINGS_PATH)

#	########################################################################	#
#	ALTRE FUNZIONI

def load_user_ratings():

	global user_id

	# print("2a")
	real = real_ratings_df[real_ratings_df["userId"] == user_id][["movieId", "rating"]]
	real = dict(zip(real['movieId'].astype(int), real['rating'].astype(float)))

	# print("2b")
	comp = pd.read_csv(f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv')
	comp = dict(zip(comp['movieId'].astype(int), comp['rating'].astype(float)))

	return real, comp

	# end

def compute_feature_means(ratings):
    
	# print("4")
	sum_per_feature = movie_features_matrix.T.dot(ratings)
	count_per_feature = movie_features_matrix.T.dot(np.ones(M, dtype=float))

	means = np.divide(
		sum_per_feature,
		count_per_feature,
		out = np.zeros_like(sum_per_feature),
		where = (count_per_feature != 0)
	)

	# Filtra le feature che hanno un numero di occorrenze sufficiente rispetto alla soglia minima di supporto.
	mask = count_per_feature >= MIN_SUPPORT

	# print("5b")
	return means * mask

	# end

def extract_user_top_features(feature_means):

	global top_features_list

	# 5. ordinare il vettore 1xF dei rating sulle features
	top_indices = np.argsort(-feature_means)[:TOP_FEATURES] # ordina in desc, prende TOP_FEATURES

	# Non usiamo 'rating' qui, ma usiamo 'idx' per accedere sia al DataFrame che a feature_means
	for idx in top_indices:
		row = feature_index_df.iloc[idx]

		# Prende il valore di rating (media) per la feature all'indice 'idx'
		feature_rating_value = feature_means[idx]

		top_features_list.append({
			"id": int(row["feature_id"]),
			"category": row["category"],
			"name": row["feature"],
			"rating": float(feature_rating_value) # Inseriamo il valore del rating (float) nel campo 'rating', come richiesto
		})

	# end

def attach_movies_to_features(real_ratings, comp_ratings):

	global top_features_list

	# print("6")
	for f in top_features_list:
		feat_id = f["id"]
		col = movie_features_matrix[:, feat_id].toarray().ravel()
		indices = np.where(col == 1)[0]

		movies = []
		for idx in indices:
			movie_row = movie_index_df[movie_index_df["matrix_id"] == idx]
			if movie_row.empty:
				continue
			m_id = int(movie_row["movie_id"].iloc[0])
			if m_id in real_ratings:
				movies.append((m_id, real_ratings[m_id], True))
			elif m_id in comp_ratings:
				movies.append((m_id, comp_ratings[m_id], False))

		f["movies"] = movies
	
	# end

def extract_user_preferences():

	#	################################################################	#
	#	INIZIALIZZAZIONE DELLE VARIABILI

	global top_features_list, user_id
	top_features_list.clear()

	#	################################################################	#
	#	ESTRAZIONE DEI RATINGS PER L'UTENTE

	# Utilizzo "dict unpacking" per unire tutti i rating in un unico dizionario.
	real_ratings, comp_ratings = load_user_ratings()
	all_ratings = {**comp_ratings, **real_ratings}

	#	################################################################	#
	#	CREZIONE VETTORE DEI RATING
	#	Ordinato secondo la matrice delle features, e riempito con 0 dove non ci sono rating.

	# print("3b")
	movie_ratings = np.zeros(M, dtype=float)
	for movie_id, rating in all_ratings.items():
		idx = movie_id_to_index.get(movie_id)
		if idx is not None and 0 <= idx < M:
			movie_ratings[idx] = rating

	# # Debug output
	# non_zero_ratings = np.count_nonzero(movie_ratings)
	# print(f"DEBUG: Non-zero movie ratings: {non_zero_ratings}")

	#	################################################################	#
	#	CALCOLO RATING MEDIO DELLE FEATURES
	#	Il tempo di esecuzione è proporzionale al numero di elementi non-nulli nella matrice sparsa, cioè O(NNZ).

	feature_means = compute_feature_means(movie_ratings)

	# print("Feature means:", feature_means.shape)
	# print("Movie ratings:", movie_ratings.shape)
	# print("OK: feature and movie ratings extracted!")
	
	#	################################################################	#
	#	ESTRAZIONE DELLE TOP FEATURES DELL'UTENTE

	extract_user_top_features(feature_means)

	#	################################################################	#
	#	ASSOCIAZIONE DEI MOVIE ALLE FEATURES ESTRATTE

	attach_movies_to_features(real_ratings, comp_ratings)

	#	################################################################	#
	#	STAMPA FINALE

	# Usiamo un contatore 'i' solo per stampare la posizione di debug, sebbene il campo 'rating' sia ora il rating
	# print("\nTop Features:")
	# for i, f in enumerate(top_features_list, start=1):
	# 	print(f"Position {i}: [{f['category']}] {f['name']} (id={f['id']}, rating/rank={f['rating']:.2f})")

	# print("\nTop features extracted with movies:")
	# for f in top_features_list:
	# 	print(f"\nFeature: {f['name']} (id={f['id']}, cat={f['category']})")
	# 	for m in f["movies"][:10]:  # stampane max 10 per leggibilità
	# 		print(f"  MovieId={m[0]}, Rating={m[1]}, Seen={m[2]}")
	
	# end

def mab_softmax_predictions(
		temperature : float = 0.5,
		k : int = MOVIE_RECOMMENDATIONS
	):
	"""
	Esegue MAB softmax prediction per le top features.

	Args:
		temperature: parametro tau della softmax.
		k: numero di film da estrarre per feature.

	Returns:
		predictions: dizionario feature_id -> lista di predizioni [(movieId, rating, seen_bool, prob)]
	"""

	predictions = {}
	min_k = k

	for f in top_features_list:
		movies = f.get("movies", [])
		if not movies:
			continue

		if k <= 0:
			min_k = len(movies)

		# estrai solo i rating
		ratings = np.array([m[1] for m in movies], dtype=float)

		# softmax con temperatura tau
		probs = np.exp(ratings / temperature)
		probs /= np.sum(probs)

		# campiona k film in base alle probabilità
		sample_size = min(min_k, len(movies))
		chosen_idx = np.random.choice(len(movies), size=sample_size, replace=False, p=probs)

		predictions[f["id"]] = {
			"category": f["category"],
			"feature_name": f["name"],
			"feature_rating": f["rating"],
			"movies": [{
				"movie_id": movies[idx][0],
				"movie_rating": movies[idx][1],
				"seen": movies[idx][2],
				"softmax_prob": probs[idx]
			} for idx in chosen_idx]
		}

	return predictions

	# end

#	########################################################################	#
#	CLASSI

class RecSys_HTTPServer:

	def __init__(self):

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
				with open(EXISTING_RATINGS_PATH, newline='', encoding='utf-8') as f:
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
				recs = mab_softmax_predictions()
				output = json.dumps(recs)

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-recommendations'
			
			elif urlparse(self.path).path.endswith('/get-movies'):
				params = dict(parse_qsl(urlparse(self.path).query))
				selected_id = params['id']
				selected_type = ""

				if 'type' in params.keys():
					selected_type = params['type']
					if selected_type not in ['feature']:
						self.send_response(400, 'Query non disponibile.') # BAD REQUEST
						self._send_cors_headers()
						self.send_header('Content-type', 'text/plain')
						self.end_headers()
						return

				if not selected_id or not selected_id.isdigit():
					self.send_response(400, 'ID non valido.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return
				
				if not Path.exists(MOVIE_FEATURE_MATRIX_PATH):
					self.send_response(500, 'Matrice non trovata sul server.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				selected_id = int(selected_id)

				if selected_id < 0 or selected_id >= F:
					self.send_response(400, 'ID non valido.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return
				
				global movie_index_df, movie_features_matrix
				
				feature_column = movie_features_matrix[:, selected_id].toarray().ravel()
				related_matrix_ids = np.where(feature_column > 0)[0]
				related_movie_ids = movie_index_df.loc[
					movie_index_df['matrix_id'].isin(related_matrix_ids), 'movie_id'
				].astype(str).tolist()

				if not related_movie_ids:
					self.send_response(404, f'Nessun movie trovato per la feature "{selected_id}"') # NOT FOUND
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				output = json.dumps(related_movie_ids)

				self.send_response(200)
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-movies'

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
				selected_type = ""

				if 'type' in params.keys():
					selected_type = params['type']
					if selected_type not in CATEGORIES:
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

				for key in CATEGORIES:
					if selected_type != "" and selected_type != key:
						continue
						
					if key == 'title':
						path = EXISTING_MOVIES_PATH
					elif key == 'description':
						path = MOVIES_ABSTRACT_PATH
					else:
						path = CATEGORIES_PATH_MAPPING[key]

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

					if selected_type != "" and selected_type == key:
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

			if urlparse(self.path).path.endswith('/login-user'):
				ctype = self.headers.get('Content-Type')
				content_len = int(self.headers.get('Content-Length', 0))

				if not ctype == 'application/json':
					self.send_response(400, 'Il "content-type" non è application/json.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				body = self.rfile.read(content_len).decode('utf-8')
				data = json.loads(body)["userId"]
				# print(data)

				if not data or not isinstance(data, str):
					self.send_response(400, 'Il payload deve essere una stringa.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				global user_id
				user_id = data
				extract_user_preferences()

				self.send_response(201, f'Utente <{data}> loggato con successo!') # CREATED
				self._send_cors_headers()
				self.end_headers()
				# print(str(self.user_prefs))
				return

				# end if '/login-user'

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
