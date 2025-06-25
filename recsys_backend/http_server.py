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

#	########################################################################	#
#	COSTANTI e VARIABILI GLOBALI

ADDRESS = '0.0.0.0'
PORT = 8000
TIMEOUT = 30

EXISTING_MOVIES = 6725
MOVIE_RECOMMENDATIONS = 15

POSTER_DIR = Path('./data/movie_posters')

#	########################################################################	#
#	ALTRE FUNZIONI

def get_movie_recommendations():
	return [str(random.randint(1, EXISTING_MOVIES)) for _ in range(MOVIE_RECOMMENDATIONS)]

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

