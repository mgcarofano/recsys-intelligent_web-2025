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

#	########################################################################	#
#	COSTANTI e VARIABILI GLOBALI

ADDRESS = '0.0.0.0'
PORT = 8000
TIMEOUT = 30

MOVIE_RECOMMENDATIONS = 15

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

#	########################################################################	#
#	ALTRE FUNZIONI

def get_movie_recommendations():

	with open(CSV_PATH_MAPPING['title'], newline='', encoding='utf-8') as f:
		next(f) # Salta la prima riga (intestazione del file .csv).
		reader = csv.DictReader(f, fieldnames=['movieId', 'value'])
		existing_ids = [int(row['movieId']) for row in reader if row['movieId'].isdigit()]

	selected_ids = random.sample(existing_ids, MOVIE_RECOMMENDATIONS)
	ret = [str(i) for i in selected_ids]
	
	return ret

	# end

#	########################################################################	#
#	CLASSI

class UserPreferences:
	id_movies = []

	def __str__(self) -> str:
		return f'''
		
		--- USER PREFERENCES ---

			prefs: {self.id_movies}

		-----
		'''

		# end

	# end class

class RecSys_HTTPServer:

	def __init__(self):
		RecSys_RequestHandler.user_prefs = UserPreferences()

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

	user_prefs = None

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

			if urlparse(self.path).path.endswith('/update-preferences'):
				# Content-type, Parameter dictionary
				ctype = self.headers.get('Content-Type')
				content_len = int(self.headers.get('Content-Length', 0))

				if not ctype == 'application/json':
					self.send_response(400, 'Il "content-type" non è application/json.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return
					
				body = self.rfile.read(content_len).decode('utf-8')
				data = json.loads(body)['idMovies']
				print(data)

				if not isinstance(data, list) or not all(isinstance(i, str) for i in data):
					self.send_response(400, 'Il payload deve essere una lista di stringhe.') # BAD REQUEST
					self._send_cors_headers()
					self.send_header('Content-type', 'text/plain')
					self.end_headers()
					return
				
				self.user_prefs.id_movies = data

				self.send_response(201, 'Preferenze aggiornate con successo!') # CREATED
				self._send_cors_headers()
				self.end_headers()
				print(str(self.user_prefs))
				
				# end if '/update-preferences'
			
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

	# end class

#	########################################################################	#
#	MAIN

if __name__ == "__main__":
    RecSys_HTTPServer()
	# end

#	########################################################################	#
#	RIFERIMENTI

