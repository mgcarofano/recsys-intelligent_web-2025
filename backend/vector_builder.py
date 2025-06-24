import os
import pandas as pd
from collections import defaultdict
from tqdm import tqdm
from scipy.sparse import lil_matrix, save_npz

# === CONFIGURATION ===
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/data"

metadata_files = [
    os.path.join(BASE_FOLDER, "CSVs", "movie_actors.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_composers.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_directors.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_genres.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_producers.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_production_companies.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_subjects.csv"),
    os.path.join(BASE_FOLDER, "CSVs", "movie_writers.csv")
]

# === Step 1: Load all movie IDs ===
movies_csv = os.path.join(BASE_FOLDER, "ml-latest-small", "movies.csv")
movies_df = pd.read_csv(movies_csv)
movie_ids = movies_df['movieId'].astype(str).tolist()
movie_id_to_index = {mid: i for i, mid in enumerate(movie_ids)}
print(f"Loaded {len(movie_ids)} movies.")

# === Step 2: Collect all unique categories and movie→category mapping ===
global_category_set = set()
movie_to_categories = defaultdict(set)

print("Scanning all metadata files to build global category list and mapping...")
for file_path in metadata_files:
    print(f"Reading {file_path} ...")
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split(',', 1)
            if len(parts) < 2:
                continue
            movie_id, value = parts[0].strip(), parts[1].strip()
            if movie_id in movie_id_to_index:
                movie_to_categories[movie_id].add(value)
                global_category_set.add(value)

# === Step 3: Build global index for all categories ===
global_category_list = sorted(global_category_set)
category_to_index = {cat: i for i, cat in enumerate(global_category_list)}
print(f"Total unique categories: {len(global_category_list)}")

# === Step 4: Build sparse matrix (movies × global categories) ===
num_movies = len(movie_ids)
num_categories = len(global_category_list)

print("Building sparse matrix...")
sparse_matrix = lil_matrix((num_movies, num_categories), dtype=int)

for movie_id, categories in tqdm(movie_to_categories.items()):
    row_idx = movie_id_to_index[movie_id]
    for category in categories:
        col_idx = category_to_index[category]
        sparse_matrix[row_idx, col_idx] = 1

# === Step 5: Save sparse matrix and category index ===
output_matrix_path = os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz")
save_npz(output_matrix_path, sparse_matrix.tocsr())
print(f"Saved sparse matrix to {output_matrix_path}")

index_df = pd.DataFrame({
    "dimension": range(num_categories),
    "category": global_category_list
})
index_csv_path = os.path.join(BASE_FOLDER, "vector_index.csv")
index_df.to_csv(index_csv_path, index=False)
print(f"Saved category index to {index_csv_path}")
