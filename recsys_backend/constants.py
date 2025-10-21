"""

	constants.py \n
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.
	
	Questo file raccoglie tutti i valori costanti utilizzati nei file di progetto.

"""

from pathlib import Path

#	########################################################################	#
#	CONFIGURAZIONE SERVER

ADDRESS = '0.0.0.0'
"""Indirizzo su cui il server è in ascolto (0.0.0.0 = tutte le interfacce)."""

PORT = 8000
"""Porta di ascolto del server."""

TIMEOUT = 30
"""Timeout massimo per le richieste HTTP (in secondi)."""

#	########################################################################	#
#	PARAMETRI DEL SISTEMA DI RACCOMANDAZIONE

MIN_SUPPORT = 20
"""Minimo numero di film a supporto di una feature per poter essere raccomandata."""

MOVIE_RECOMMENDATIONS = 5
"""Numero di film raccomandati per ogni feature."""

TOP_FEATURES = 5
"""Numero di feature raccomandate all’utente."""

#	########################################################################	#
#	PERCORSI UTILI

POSTER_DIR = Path('./data/movie_posters')
"""Percorso della directory contenente i poster dei film."""
POSTER_DIR.mkdir(parents=True, exist_ok=True)

MOVIE_SIMILARIITY_PREVIEW_PATH = Path('./data/movie_cosine_similarity.npy')
"""Indica il percorso del file NPY contenente l'anteprima della matrice di similarità tra film."""

MOVIE_SIMILARIITY_MATRIX_PATH = Path('./data/movie_cosine_similarity.npz')
"""Indica il percorso del file NPZ contenente la matrice di similarità tra film."""

MOVIE_FEATURE_MATRIX_PATH = Path('./data/movie_vectors_sparse.npz')
"""Indica il percorso del file NPZ contenente la matrice sparsa film x feature."""

FEATURE_INDEX_PATH = Path('./data/feature_index.csv')
"""Indica il percorso del file CSV contenente l'indice di tutte le feature disponibili."""

MOVIE_INDEX_PATH = Path('./data/movie_index.csv')
"""Indica il percorso del file CSV che mappa gli ID dei film con i loro indici nella matrice di similarità."""

ML_DATASET_DIR = Path('./data/ml-latest-small')
"""Indica il percorso della directory del dataset 'ml-latest-small'."""

ML_DATASET_PATH_MAPPING = {
    'links': Path('./data/ml-latest-small/links.csv'),
    'movies': Path('./data/ml-latest-small/movies.csv'),
    'ratings': Path('./data/ml-latest-small/ratings.csv'),
    'tags': Path('./data/ml-latest-small/tags.csv')
}
"""Mappa che associa ad ogni file del dataset 'ml-latest-small' il relativo file CSV."""

#	########################################################################	#
#	PERCORSI DEI FILE CSV DEI METADATI

CSV_DIR = Path('./data/CSVs')
"""Indica il percorso della directory contenente i file CSV dei metadati."""
CSV_DIR.mkdir(parents=True, exist_ok=True)

EXISTING_MOVIES_PATH = Path('./data/CSVs/existing_movies.csv')
"""Indica il percorso del file CSV contenente i titoli dei film."""

EXISTING_RATINGS_PATH = Path('./data/CSVs/existing_ratings.csv')
"""Indica il percorso del file CSV contenente le valutazioni (ratings) dei film."""

MOVIES_ABSTRACT_PATH = Path('./data/CSVs/movie_abstracts.csv')
"""Indica il percorso del file CSV contenente le descrizioni (abstract) dei film."""

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
"""Mappa che associa ad ogni categoria di feature il relativo file CSV."""

CATEGORIES = ['title', 'description'] + [cat for cat in CATEGORIES_PATH_MAPPING.keys()]
"""Lista di categorie delle feature."""