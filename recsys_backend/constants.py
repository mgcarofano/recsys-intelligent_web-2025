"""

	constants.py \n
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.
	
	Questo file raccoglie tutti i valori costanti utilizzati nei file di progetto.

"""

from pathlib import Path

#	########################################################################	#
#	CONFIGURAZIONE SERVER

# Indirizzo su cui il server è in ascolto (0.0.0.0 = tutte le interfacce).
ADDRESS = '0.0.0.0'

# Porta di ascolto del server.
PORT = 8000

# Timeout massimo per le richieste HTTP (in secondi).
TIMEOUT = 30

#	########################################################################	#
#	PARAMETRI DEL SISTEMA DI RACCOMANDAZIONE

# Minimo numero di film in cui appare una certa feature per poter essere considerata raccomandabile.
MIN_SUPPORT = 20

# Numero di film raccomandati per ogni feature.
MOVIE_RECOMMENDATIONS = 5

# Numero di feature raccomandate all’utente.
TOP_FEATURES = 5

#	########################################################################	#
#	PERCORSI UTILI

# ...
MOVIE_SIMILARIITY_PREVIEW_PATH = Path('./data/movie_cosine_similarity.npy')

# ...
MOVIE_SIMILARIITY_MATRIX_PATH = Path('./data/movie_cosine_similarity.npz')

# ...
MOVIE_FEATURE_MATRIX_PATH = Path('./data/movie_vectors_sparse.npz')

# ...
FEATURE_INDEX_PATH = Path('./data/feature_index.csv')

# ...
MOVIE_INDEX_PATH = Path('./data/movie_index.csv')

# Percorso della directory contenente i poster dei film.
POSTER_DIR = Path('./data/movie_posters')

# Mappa che associa ad ogni file del dataset 'ml-latest-small' il relativo file CSV.
ML_DATASET_PATH_MAPPING = {
    'links': Path('./data/ml-latest-small/links.csv'),
    'movies': Path('./data/ml-latest-small/movies.csv'),
    'ratings': Path('./data/ml-latest-small/ratings.csv'),
    'tags': Path('./data/ml-latest-small/tags.csv')
}

# ...
EXISTING_MOVIES_PATH = Path('./data/CSVs/existing_movies.csv')

# ...
EXISTING_RATINGS_PATH = Path('./data/CSVs/existing_ratings.csv')

# ...
MOVIES_ABSTRACT_PATH = Path('./data/CSVs/movie_abstracts.csv')

# Mappa che associa ad ogni categoria di feature il relativo file CSV.
CATEGORIES_PATH_MAPPING = {
	'actors': Path('./data/CSVs/movie_actors.csv'),
	'composers': Path('./data/CSVs/movie_composers.csv'),
	'directors': Path('./data/CSVs/movie_directors.csv'),
	'genres': Path('./data/CSVs/movie_genres.csv'),
	'producers': Path('./data/CSVs/movie_producers.csv'),
	'production_companies': Path('./data/CSVs/movie_production_companies.csv'),
	'subjects': Path('./data/CSVs/movie_subjects.csv'),
	'writers': Path('./data/CSVs/movie_writers.csv'),
}