import os
import pandas as pd
from collections import defaultdict
from tqdm import tqdm
from scipy.sparse import lil_matrix, save_npz

# Configurazione cartelle e percorsi
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data"

# File di metadati per ciascuna categoria
metadata_files = {
    "actor": os.path.join(BASE_FOLDER, "CSVs", "movie_actors.csv"),
    "composer": os.path.join(BASE_FOLDER, "CSVs", "movie_composers.csv"),
    "director": os.path.join(BASE_FOLDER, "CSVs", "movie_directors.csv"),
    "genre": os.path.join(BASE_FOLDER, "CSVs", "movie_genres.csv"),
    "producer": os.path.join(BASE_FOLDER, "CSVs", "movie_producers.csv"),
    "company": os.path.join(BASE_FOLDER, "CSVs", "movie_production_companies.csv"),
    "subject": os.path.join(BASE_FOLDER, "CSVs", "movie_subjects.csv"),
    "writer": os.path.join(BASE_FOLDER, "CSVs", "movie_writers.csv")
}

# Carica gli ID dei film
movies_csv = os.path.join(BASE_FOLDER, "CSVs", "existing_movies.csv")
movies_df = pd.read_csv(movies_csv)
movie_ids = movies_df['movieID'].astype(str).tolist()
movie_id_to_index = {mid: i for i, mid in enumerate(movie_ids)}
print(f"Sono stati caricati {len(movie_ids)} film.")

# Colleziona tutte le feature per ciascun film e categoria
movie_to_features = defaultdict(list)
all_features = []

print("Scanning dei metadata files per costruire la lista delle feature e il mapping...")
for category, file_path in metadata_files.items():
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
                # Associa al film la coppia (categoria, feature)
                feature_key = (category, value)
                movie_to_features[movie_id].append(feature_key)
                all_features.append(feature_key)

# Crea un indice globale per tutte le feature (categoria, valore)
unique_features = sorted(set(all_features), key=lambda x: (x[0], x[1]))
feature_to_index = {feat: i for i, feat in enumerate(unique_features)}
print(f"Coppie (category, feature) uniche totali: {len(unique_features)}")

# Costruisci la matrice sparsa (film × feature)
num_movies = len(movie_ids)
num_features = len(unique_features)

print("Building sparse matrix...")
sparse_matrix = lil_matrix((num_movies, num_features), dtype=int)

for movie_id, features in tqdm(movie_to_features.items()):
    row_idx = movie_id_to_index[movie_id]
    for feature_key in features:
        col_idx = feature_to_index[feature_key]
        sparse_matrix[row_idx, col_idx] = 1

# Salva la matrice sparsa e gli indici
output_matrix_path = os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz")
save_npz(output_matrix_path, sparse_matrix.tocsr())
print(f"Saved sparse matrix to {output_matrix_path}")

# Crea il file CSV con l’indice delle feature
index_df = pd.DataFrame({
    "feature_id": range(num_features),
    "category": [f[0] for f in unique_features],
    "feature": [f[1] for f in unique_features]
})
index_csv_path = os.path.join(BASE_FOLDER, "feature_index.csv")
index_df.to_csv(index_csv_path, index=False)
print(f"Saved feature index (with categories) to {index_csv_path}")

# Crea il file CSV con l’indice dei film
index_csv_path = os.path.join(BASE_FOLDER, "movie_index.csv")
df = pd.DataFrame(list(movie_id_to_index.items()), columns=["movie_id", "matrix_id"])
df.to_csv(index_csv_path, index=False, quotechar="'")
print(f"Saved movie index to {index_csv_path}")
