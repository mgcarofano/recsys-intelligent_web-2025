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
user_id = 1

#	########################################################################	#
#	ALTRE FUNZIONI

def compute_movie_features_ratings():
		# 1) Matrice film-features (M x F) e mapping
    movie_features = load_npz('./data/movie_vectors_sparse.npz').toarray()  # M x F
    mapping_df = pd.read_csv('./data/movie_index.csv')
    # Assicuriamoci che i tipi siano interi
    mapping_df['movie_id'] = mapping_df['movie_id'].astype(int)
    mapping_df['matrix_id'] = mapping_df['matrix_id'].astype(int)
    movie_id_to_index = dict(zip(mapping_df['movie_id'], mapping_df['matrix_id']))
    M, F = movie_features.shape

    # 2a) Rating reali (tutti gli utenti) -> prendiamo solo quelli dell'user
    ratings_df = pd.read_csv('./data/ml-latest-small/ratings.csv')
    user_existing = ratings_df[ratings_df["userId"] == user_id][["movieId", "rating"]]

    # 2b) Rating complementati (file per user). Se non esiste, consideriamo vuoto.
    comp_path = f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv'
    if os.path.exists(comp_path):
        ratings_complemented = pd.read_csv(comp_path)
    else:
        # file complementati non trovato: trattiamo come vuoto
        ratings_complemented = pd.DataFrame(columns=["movieId", "rating"])

    # 2c) Dizionari {movieId: rating}
    # Attenzione ai tipi
    real_ratings = dict(zip(user_existing['movieId'].astype(int), user_existing['rating'].astype(float)))
    comp_ratings = dict(zip(ratings_complemented['movieId'].astype(int), ratings_complemented['rating'].astype(float)))

    # 3) UNIONE (disgiunta). Se dovesse esserci overlap, il rating reale sovrascrive.
    overlap = set(real_ratings.keys()) & set(comp_ratings.keys())
    if overlap:
        # avviso utile in caso di dati non disgiunti
        print(f"[compute_movie_features_ratings] Warning: overlap found for user {user_id} on movieIds: {sorted(overlap)}. Real ratings will override complemented.")
    all_ratings = comp_ratings.copy()   # prima complementati
    all_ratings.update(real_ratings)    # poi i reali (sovrascrivono se necessario)

    # 3 (cont.) -> costruisco ratings_vector (lunghezza M) allineato alla matrix_id
    ratings_vector = np.zeros(M, dtype=float)  # vettore 1D: indices 0..M-1
    for movie_id, rating in all_ratings.items():
        idx = movie_id_to_index.get(movie_id)
        ratings_vector[idx] = rating

    # 4) Hadamard product: (M,) -> reshape (M,1) per broadcasting con (M,F)
    weighted_matrix = ratings_vector.reshape(M, 1) * movie_features  # risultato M x F

    # 5a) Media per feature (1 x F)
    feature_means = weighted_matrix.mean(axis=0)   # shape (F,)

    # 5b) Media per film (M x 1)
    movie_means = weighted_matrix.mean(axis=1)     # shape (M,)

    return feature_means, movie_means

	#	2. unire ratings calcolati e assegnati da U (dim. Mx1)
	#	3. calcolare hadamard prodotto di M (ratings) moltiplicato M*F (matrice movies-features)
	#	4a. calcolare la media sulla matrice M*F per ogni feature -> vettore 1xF
	#	4b. calcolare la media sulla matrice M*F per ogni feature -> vettore Mx1

	# end

def extract_user_top_features():

	print(compute_movie_features_ratings())
	print("OK: feature and movie ratings extracted!")

	# if cat == "genres" and row['value'] == "(no genres listed)":

	# # Filtra le features più importanti.
	# filtered_features = {
	# 	feat: sorted(list(films))
	# 	for feat, films in features.items() if len(films) >= MOVIE_RECOMMENDATIONS
	# }

	#	5. ordinare il vettore 1xF dei rating sulle features
	#	6. accedere a vector_index.csv e ritornare un vettore di 3 features (id, category, name, rank)

	# end

def extract_xxx():
	pass

	# end

def get_movie_recommendations():

	recommendations = {}

	# # Test
	# selected_categories = ["actors", "directors"]
	# available_features = {"Sylvester Stallone"}

	# Seleziona casualmente le categorie da raccomandare.
	selected_categories = random.choices(CATEGORIES, k=SUBJECTS_SELECTION)

	for cat in selected_categories:

		# Verifica che la categoria non sia vuota.
		if movies_features_map[cat]:

			# Estrai solo le feature che non sono ancora state scelte per quella categoria.
			available_features = set(movies_features_map[cat].keys()) - set(recommendations.get(cat, {}).keys())

			if available_features:

				# Seleziona casualmente le features da raccomandare.
				feature = random.choice(list(available_features))

				# Aggiorna la raccomandazione con la lista di film relativa alla feature della categoria selezionata.
				recommendations.setdefault(cat, {})[feature] = movies_features_map[cat][feature]

	return recommendations

	# end

#	########################################################################	#
#	CLASSI

class RecSys_HTTPServer:

	def __init__(self):

		#	################################################################	#
		#	ANALISI DEL DATASET

		# Recupera tutti le voci di tutte le categorie dei movie dal dataset (es. actors, composers, ...)
		# La struttura del dizionario è: categoria -> feature -> lista di id.
		for cat in CATEGORIES:
			features = {}
			with open(CSV_PATH_MAPPING[cat], newline='', encoding='utf-8') as f:
				next(f)
				reader = csv.DictReader(f, fieldnames=['movieId', 'value'])
				for row in reader:
					m_id, feat = row['movieId'], row['value']
					if m_id and m_id.isdigit() and feat:
						# Aggiunge il movieId se esiste ed è corretto.
						features.setdefault(feat, set()).add(m_id)

				# Aggiungi la categoria solo se non è vuota.
				if features:
					movies_features_map[cat] = features

		#	################################################################	#
		#	INIZIALIZZAZIONE ED ESECUZIONE DEL SERVER

		server = HTTPServer((ADDRESS, PORT), RecSys_RequestHandler)
		print("Server in esecuzione su " + str(ADDRESS) + ":" + str(PORT) + "...")
		extract_user_top_features()
		return

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

			if urlparse(self.path).path.endswith('/get-recommendations'):
				recs = get_movie_recommendations()
				output = json.dumps(recs)

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))

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

				# end if '/get-movie-info'

			else:
				self.send_response(404, 'Impossibile eseguire tale richiesta.') # NOT FOUND
				self._send_cors_headers()
				self.send_header('Content-type', 'text/plain')
				self.end_headers()

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

