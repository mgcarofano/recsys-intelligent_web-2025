"""

	build_similarity_matrix.py \n
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	Questo script calcola la matrice di similarità coseno tra i film basandosi sulla matrice sparsa film x feature, che descrive un film in termini delle sue features presenti (1) o assenti (0). Il risultato viene salvato in un nuovo file NPZ chiamato 'movie_similarity_matrix.npz' e in una versione di anteprima in formato NPY chiamato 'movie_similarity_preview.npy'.

"""

#	########################################################################	#
#	LIBRERIE

from constants import *

import numpy as np
from scipy.sparse import load_npz, save_npz, csr_matrix
from sklearn.metrics.pairwise import cosine_similarity

#	########################################################################	#
#   CARICAMENTO DELLA MATRICE SPARSA (film x feature)

print("Loading sparse movie-category matrix...")
X = load_npz(MOVIE_FEATURE_MATRIX_PATH)
print(f"Matrix shape: {X.shape}")  # (num_movies, num_categories)

#	########################################################################	#
#   CALCOLO DELLA MATRICE DI SIMILARITÀ COSENO TRA I FILM

print("Computing cosine similarity...")
similarity_matrix = cosine_similarity(X, dense_output=False)  # mantiene output sparso
similarity_matrix = csr_matrix(similarity_matrix)  # conversione a formato CSR

#	########################################################################	#
#   SALVATAGGIO DEGLI OUTPUT

# Salvataggio della matrice di similarità in formato compresso
save_npz(MOVIE_SIMILARIITY_MATRIX_PATH, similarity_matrix)
print(f"Saved cosine similarity matrix to {MOVIE_SIMILARIITY_MATRIX_PATH}")

# Salvataggio opzionale di una versione densa in formato .npy (anteprima)
np.save(MOVIE_SIMILARIITY_PREVIEW_PATH, similarity_matrix.toarray())
print(f"Saved dense version preview to {MOVIE_SIMILARIITY_PREVIEW_PATH}")