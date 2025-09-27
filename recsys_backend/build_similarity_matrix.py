import os
import numpy as np
from scipy.sparse import load_npz, save_npz, csr_matrix
from sklearn.metrics.pairwise import cosine_similarity

# === CONFIGURATION ===
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data"
input_matrix_path = os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz")
output_matrix_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npz")

print("Loading sparse movie-category matrix...")
X = load_npz(input_matrix_path)

print(f"Matrix shape: {X.shape}")  # (num_movies, num_categories)

# === Step 1: Compute cosine similarity ===
print("Computing cosine similarity...")
similarity_matrix = cosine_similarity(X, dense_output=False)  # returns sparse CSR

# Convert to sparse CSR matrix
similarity_matrix = csr_matrix(similarity_matrix)

# === Step 2: Save similarity matrix ===
save_npz(output_matrix_path, similarity_matrix)
print(f"Saved cosine similarity matrix to {output_matrix_path}")

# Optional: also save a preview as .npy for easy loading with numpy
preview_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npy")
np.save(preview_path, similarity_matrix.toarray())
print(f"Saved dense version preview to {preview_path}")
