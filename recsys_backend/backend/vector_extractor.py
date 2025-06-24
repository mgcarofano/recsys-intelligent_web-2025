import os
import pandas as pd
from scipy.sparse import load_npz

# === CONFIGURATION ===
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/data"
VECTOR_FILE = os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz")
INDEX_FILE = os.path.join(BASE_FOLDER, "vector_index.csv")
MOVIES_FILE = os.path.join(BASE_FOLDER, "ml-latest-small", "movies.csv")

# === LOAD DATA ===
print("Loading sparse matrix...")
sparse_matrix = load_npz(VECTOR_FILE)

print("Loading category index...")
index_df = pd.read_csv(INDEX_FILE)
dim_to_category = dict(zip(index_df['dimension'], index_df['category']))

print("Loading movie metadata...")
movies_df = pd.read_csv(MOVIES_FILE)
movie_id_to_title = dict(
    zip(movies_df['movieId'].astype(str), movies_df['title']))
movie_ids = movies_df['movieId'].astype(str).tolist()
movie_index_to_id = {i: mid for i, mid in enumerate(movie_ids)}

# === FUNCTION TO DISPLAY CATEGORIES FOR A MOVIE INDEX ===


def show_movie_attributes_by_index(movie_index):
    if movie_index < 0 or movie_index >= sparse_matrix.shape[0]:
        print("Invalid movie index.")
        return

    movie_id = movie_index_to_id[movie_index]
    movie_title = movie_id_to_title.get(movie_id, "Unknown Title")

    print(f"\nMovie [{movie_index}] ID: {movie_id} → {movie_title}")

    row = sparse_matrix.getrow(movie_index)
    nonzero_indices = row.indices

    if not nonzero_indices.size:
        print("No attributes present.")
        return

    print("Attributes present:")
    for dim in sorted(nonzero_indices):
        print(f" - {dim_to_category[dim]}")


# === USAGE EXAMPLE ===
if __name__ == "__main__":
    try:
        index = int(input("Enter movie index (0 to {}): ".format(
            sparse_matrix.shape[0] - 1)))
        show_movie_attributes_by_index(index)
    except ValueError:
        print("Please enter a valid integer index.")
