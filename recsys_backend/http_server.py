"""

	http_server.py \n
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	Implementa il server HTTP e il motore di raccomandazione dei film.
	Gestisce le richieste del client tramite API REST (GET/POST), calcola le
	raccomandazioni personalizzate in base alle feature dei film e i ratings
	dell'utente loggato e restituisce i risultati in formato JSON.

"""

#	########################################################################	#
#	LIBRERIE

from constants import *

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qsl
import json

import numpy as np
import pandas as pd
from scipy.sparse import load_npz

#	########################################################################	#
#	VARIABILI GLOBALI

user_id = ""
"""Identificativo dell'utente di cui si vogliono verificare le raccomandazioni."""

top_features_list = []
"""Lista di features, caratterizzate da (id, category, name, average_rating), a cui sono collegati i movies, caratterizzati da (movieId, rating, seen_bool), che includono tale feature."""

real_ratings = {}
"""Dizionario contenente i rating reali assegnati dall'utente loggato."""

comp_ratings = {}
"""Dizionario contenente i rating complementari predetti dal sistema per l'utente loggato."""

all_ratings = {}
"""Dizionario unificato contenente tutti i rating (reali e complementari) per l'utente loggato."""

#	########################################################################	#
#	DATAFRAMES

movie_index_df = pd.read_csv(MOVIE_INDEX_PATH, dtype=int)
"""Dataframe che mette in relazione l'id di un film con l'indice all'interno della matrice movie/features."""

movie_titles_df = pd.read_csv(EXISTING_MOVIES_PATH)
"""Dataframe contenente i titoli di tutti i film della lista "existing_movies.csv"."""

movie_abstracts_df = pd.read_csv(MOVIES_ABSTRACT_PATH)
"""Dataframe contenente le descrizioni (abstract) dei film della lista "existing_movies.csv"."""

real_ratings_df = pd.read_csv(EXISTING_RATINGS_PATH)
"""Dataframe contenente tutti i rating assegnati dagli utenti ai film della lista "existing_movies.csv"."""

feature_index_df = pd.read_csv(FEATURE_INDEX_PATH)
"""Dataframe di features identificate da 3 elementi (id, category, name)."""

U = real_ratings_df['userId'].unique().shape[0]

#	########################################################################	#
#	MATRIX

movie_features_matrix = load_npz(MOVIE_FEATURE_MATRIX_PATH)
"""Matrice sparsa contenente la rappresentazione vettoriale di un film secondo le sue features."""

M, F = movie_features_matrix.shape

#	########################################################################	#
#	ALTRE FUNZIONI

def load_user_ratings():

	# print("2a")
	real = real_ratings_df[real_ratings_df["userId"] == int(user_id)][["movieId", "rating"]]
	real = dict(zip(real['movieId'].astype(int), real['rating'].astype(float)))

	# print("2b")
	comp = pd.read_csv(f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv')
	comp = dict(zip(comp['movieId'].astype(int), comp['rating'].astype(float)))

	return real, comp

	# end

def compute_feature_means(ratings, min_support: int):

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
	mask = count_per_feature >= min_support

	# print("5b")
	return means * mask

	# end

def extract_user_top_features(feature_means, top_features: int):

	# Controllo che esista almeno una feature di interesse.
	if (feature_means.sum() > 0.0):

		# 5. ordinare il vettore 1xF dei rating sulle features
		top_indices = np.argsort(-feature_means)[:top_features] # ordina in desc, prende TOP_FEATURES

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

def extract_user_preferences(min_support: int, top_features: int):

	#	################################################################	#
	#	INIZIALIZZAZIONE DELLE VARIABILI

	global real_ratings
	global comp_ratings
	global all_ratings
	top_features_list.clear()

	if isinstance(min_support, int) and min_support <= 0:
		min_support = MIN_SUPPORT

	if isinstance(top_features, int) and top_features <= 0:
		top_features = TOP_FEATURES

	if not isinstance(user_id, str) or not user_id.isdigit():
		raise ValueError('ID utente non valido')

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

		idx = movie_index_df.loc[movie_index_df['movie_id'] == movie_id, 'matrix_id']
		idx = int(idx.iloc[0]) if not idx.empty else None

		if idx and 0 <= idx < M:
			movie_ratings[idx] = rating

	# # Debug output
	# non_zero_ratings = np.count_nonzero(movie_ratings)
	# print(f"DEBUG: Non-zero movie ratings: {non_zero_ratings}")

	#	################################################################	#
	#	CALCOLO RATING MEDIO DELLE FEATURES
	#	Il tempo di esecuzione è proporzionale al numero di elementi non-nulli nella matrice sparsa, cioè O(NNZ).

	feature_means = compute_feature_means(movie_ratings, min_support)

	# print("Feature means:", feature_means.shape)
	# print("Movie ratings:", movie_ratings.shape)
	# print("OK: feature and movie ratings extracted!")

	#	################################################################	#
	#	ESTRAZIONE DELLE TOP FEATURES DELL'UTENTE

	extract_user_top_features(feature_means, top_features)

	#	################################################################	#
	#	ASSOCIAZIONE DEI MOVIE ALLE FEATURES ESTRATTE

	attach_movies_to_features(real_ratings, comp_ratings)

	#	################################################################	#
	#	STAMPA FINALE

	# # Usiamo un contatore 'i' solo per stampare la posizione di debug, sebbene il campo 'rating' sia ora il rating
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
		temperature : float,
		k : int
	):
	"""
	Esegue MAB softmax prediction solo su film non visti (seen == False).

	Args:
		temperature: parametro tau della softmax.
		k: numero di film da estrarre per feature.

	Returns:
		predictions: dizionario feature_id -> lista di predizioni [(movieId, rating, seen_bool, prob)]
	"""

	if isinstance(k, int) and k < 0:
		k = MOVIE_RECOMMENDATIONS

	predictions = []
	# predictions = {}
	min_k = k

	for f in top_features_list:
		movies = f.get("movies", [])

		if not movies:
			continue

		# Considera solo i film non visti
		movies = [m for m in movies if not m[2]]
		if not movies:
			continue

		if k == 0:
			min_k = len(movies)

		# Estrai solo i rating
		ratings = np.array([m[1] for m in movies], dtype=float)

		# Calcola softmax con temperatura tau
		probs = np.exp(ratings / temperature)
		probs /= np.sum(probs)

		# Campiona k film in base alle probabilità
		sample_size = min(min_k, len(movies))
		chosen_idx = np.random.choice(len(movies), size=sample_size, replace=False, p=probs)

		predictions.append({
		# predictions[f["id"]] = {
			"feature_id": f["id"],
			"category": f["category"],
			"feature_name": f["name"],
			"feature_rating": f["rating"],
			"movies": {
				movies[idx][0]: {
					"movie_rating": movies[idx][1],
					"seen": movies[idx][2],
					"softmax_prob": probs[idx]
				}
			for idx in chosen_idx}
		# }
		})

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

	# Parametri del sistema di raccomandazione
	min_support = MIN_SUPPORT
	movie_recommendations = MOVIE_RECOMMENDATIONS
	top_features = TOP_FEATURES

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

		# Dataframes
		global movie_index_df
		global movie_titles_df
		global movie_abstracts_df
		global real_ratings_df
		global feature_index_df

		# Matrix
		global movie_features_matrix
		global M
		global F

		# Dict
		global real_ratings
		global comp_ratings
		global all_ratings

		try:

			if urlparse(self.path).path.endswith('/get-users'):

				output = json.dumps(real_ratings_df['userId'].unique().astype(str).tolist())

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-users'

			if urlparse(self.path).path.endswith('/get-params'):

				output = json.dumps({
					"minSupport": RecSys_RequestHandler.min_support,
					"movieRecommendations": RecSys_RequestHandler.movie_recommendations,
					"topFeatures": RecSys_RequestHandler.top_features
				})

				self.send_response(200) # OK
				self._send_cors_headers()
				self.send_header('Content-type', 'application/json')
				self.end_headers()
				self.wfile.write(output.encode(encoding='utf_8'))
				return

				# end if '/get-users'

			if urlparse(self.path).path.endswith('/get-recommendations'):

				recs = mab_softmax_predictions(
					temperature=0.5,
					k=RecSys_RequestHandler.movie_recommendations
				)

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
				selected_type = params['type']
				selected_id = params['id']
				selected_order = ""

				if not selected_id or not selected_id.isdigit():
					self.send_response(400, 'ID non valido.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				selected_id = int(selected_id)

				if not selected_type or selected_type not in ['feature', 'ratings']:
					self.send_response(400, 'Query non disponibile.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return
				else:
					if selected_type == 'feature' and not 0 <= selected_id < F or \
					selected_type == 'ratings' and not 1 <= selected_id <= U:
						msg = f"ID non valido per la query '{selected_type}'."
						self.send_response(400, msg) # BAD REQUEST
						self._send_cors_headers()
						self.send_header('Content-type', 'text/plain')
						self.end_headers()
						return

				if 'order' in params.keys():
					selected_order = params['order']
					if selected_order not in ['title', 'rating']:
						self.send_response(400, 'Query non disponibile.') # BAD REQUEST
						self._send_cors_headers()
						self.send_header('Content-type', 'text/plain')
						self.end_headers()
						return

				if selected_type == 'feature':
					feature_column = movie_features_matrix[:, selected_id].toarray().ravel()
					related_matrix_ids = np.where(feature_column > 0)[0]
					related_movie_ids = movie_index_df.loc[
						movie_index_df['matrix_id'].isin(related_matrix_ids), 'movie_id'
					]
				elif selected_type == 'ratings':
					related_movie_ids = real_ratings_df.loc[
						real_ratings_df['userId'] == selected_id
					]['movieId']

				if selected_order == 'title':
					related_movie_ids = movie_titles_df.loc[
						movie_titles_df['movieID'].isin(related_movie_ids)
					].sort_values(by='movie_name')['movieID'].astype(str).tolist()
				elif selected_order == 'rating':
					related_movie_ids = sorted(
						related_movie_ids,
						key = lambda movie_id: all_ratings.get(int(movie_id), 0),
						reverse = True
					)
					related_movie_ids = [str(mid) for mid in related_movie_ids]

				if not related_movie_ids:
					self.send_response(404, f'Nessun movie trovato.') # NOT FOUND
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
					if selected_type not in CATEGORIES + ['rating']:
						self.send_response(400, 'Informazione non disponibile.') # BAD REQUEST
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

				matrix_id = movie_index_df.loc[movie_index_df['movie_id'] == int(selected_id), 'matrix_id']
				matrix_id = int(matrix_id.iloc[0]) if not matrix_id.empty else None

				if matrix_id is None:
					self.send_response(400, f'ID non valido.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				if not 0 <= matrix_id < M:
					self.send_response(400, f'ID non valido.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				results = {}

				# Recupero 'title' e 'description' direttamente dai file CSV.
				if selected_type == "" or selected_type == 'title':
					title_row = movie_titles_df.loc[movie_titles_df['movieID'] == int(selected_id)]
					results['title'] = title_row['movie_name'].dropna().astype(str).tolist()

				if selected_type == "" or selected_type == 'description':
					desc_row = movie_abstracts_df.loc[movie_abstracts_df['movieId'] == int(selected_id)]
					results['description'] = desc_row['value'].dropna().astype(str).tolist()

				# Recupero tutte le altre features dalla matrice 'movie_features_matrix'.
				if selected_type == "" or selected_type in CATEGORIES_PATH_MAPPING.keys():
					movie_column = movie_features_matrix[matrix_id, :].toarray().ravel()
					related_matrix_ids = np.where(movie_column > 0)[0]
					related_features_df = feature_index_df.loc[
						feature_index_df['feature_id'].isin(related_matrix_ids)
					]

					for category, group in related_features_df.groupby('category'):
						if selected_type == "" or selected_type == category:
							results[category] = sorted(group['feature'].dropna().astype(str).tolist())
						if selected_type == category:
							break

				# Recupero il rating dal dict 'all_ratings'.
				if selected_type == "" or selected_type == 'rating':
					if int(selected_id) in real_ratings:
						results['seen'] = True
					elif int(selected_id) in comp_ratings:
						results['seen'] = False
					results['rating'] = all_ratings[int(selected_id)]

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
			return

		# end

	def do_POST(self):

		# Variabili globali
		global user_id

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

				user_id = data
				extract_user_preferences(
					RecSys_RequestHandler.min_support,
					RecSys_RequestHandler.top_features
				)

				self.send_response(201, f'Utente <{data}> loggato con successo!') # CREATED
				self._send_cors_headers()
				self.end_headers()
				return

				# end if '/login-user'

			if urlparse(self.path).path.endswith('/update-params'):
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

				if not data:
					self.send_response(400, 'Payload non corretto') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return

				RecSys_RequestHandler.min_support = data['minSupport']
				RecSys_RequestHandler.movie_recommendations = data['movieRecommendations']
				RecSys_RequestHandler.top_features = data['topFeatures']

				extract_user_preferences(
					RecSys_RequestHandler.min_support,
					RecSys_RequestHandler.top_features
				)

				self.send_response(201, f'Parametri aggiornati con successo!') # CREATED
				self._send_cors_headers()
				self.end_headers()
				return

				# end if '/update-params'

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

#	########################################################################	#
#	RIFERIMENTI
