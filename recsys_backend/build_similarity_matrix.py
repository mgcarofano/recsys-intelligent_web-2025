import os
import numpy as np
from scipy.sparse import load_npz, save_npz, csr_matrix
from sklearn.metrics.pairwise import cosine_similarity

# Configurazione dei percorsi ai file
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data"
input_matrix_path = os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz")
output_matrix_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npz")

# Caricamento della matrice sparsa (film × categorie/feature)
print("Loading sparse movie-category matrix...")
X = load_npz(input_matrix_path)
print(f"Matrix shape: {X.shape}")  # (num_movies, num_categories)

# Calcolo della matrice di similarità coseno tra i film
print("Computing cosine similarity...")
similarity_matrix = cosine_similarity(X, dense_output=False)  # mantiene output sparso
similarity_matrix = csr_matrix(similarity_matrix)  # conversione a formato CSR

# Salvataggio della matrice di similarità in formato compresso
save_npz(output_matrix_path, similarity_matrix)
print(f"Saved cosine similarity matrix to {output_matrix_path}")

# Salvataggio opzionale di una versione densa in formato .npy (anteprima)
preview_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npy")
np.save(preview_path, similarity_matrix.toarray())
print(f"Saved dense version preview to {preview_path}")
