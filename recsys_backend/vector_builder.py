"""

    vector_builder.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script costruisce la matrice sparsa film x feature a partire dai file CSV dei metadati dei film. Ogni feature è rappresentata come una coppia (categoria, valore), dove la categoria può essere ad esempio 'genres', 'directors', 'actors', ecc. La matrice sparsa risultante viene salvata in formato NPZ, insieme agli indici dei film e delle feature in file CSV.

"""

#   ########################################################################    #
#   LIBRERIE

import pandas as pd
from collections import defaultdict
from tqdm import tqdm
from scipy.sparse import lil_matrix, save_npz

from constants import EXISTING_MOVIES_PATH, \
    MOVIE_FEATURE_MATRIX_PATH, \
    FEATURE_INDEX_PATH, \
    MOVIE_INDEX_PATH, \
    CATEGORIES_PATH_MAPPING

#   ########################################################################    #
#   CARICA GLI ID DEI FILM

movies_df = pd.read_csv(EXISTING_MOVIES_PATH)
movie_ids = movies_df['movieID'].astype(str).tolist()
movie_id_to_index = {mid: i for i, mid in enumerate(movie_ids)}

print(f"Sono stati caricati {len(movie_ids)} film.")

#   ########################################################################    #
#   COLLEZIONA TUTTE LE FEATURE PER CIASCUN FILM E CATEGORIA

movie_to_features = defaultdict(list)
all_features = []

print("Scanning dei metadata files per costruire la lista delle feature e il mapping...")

for category, file_path in CATEGORIES_PATH_MAPPING.items():
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

#   ########################################################################    #
#   CREA UN INDICE GLOBALE PER TUTTE LE FEATURE (categoria, valore)

unique_features = sorted(set(all_features), key=lambda x: (x[0], x[1]))
feature_to_index = {feat: i for i, feat in enumerate(unique_features)}

print(f"Coppie (category, feature) uniche totali: {len(unique_features)}")

#   ########################################################################    #
#   COSTRUISCI LA MATRICE SPARSA (film x feature)

print("Building sparse matrix...")

num_movies = len(movie_ids)
num_features = len(unique_features)
sparse_matrix = lil_matrix((num_movies, num_features), dtype=int)

for movie_id, features in tqdm(movie_to_features.items()):
    row_idx = movie_id_to_index[movie_id]
    for feature_key in features:
        col_idx = feature_to_index[feature_key]
        sparse_matrix[row_idx, col_idx] = 1

#   ########################################################################    #
#   SALVATAGGIO DEGLI OUTPUT

# Salva la matrice sparsa e gli indici
save_npz(MOVIE_FEATURE_MATRIX_PATH, sparse_matrix.tocsr())
print(f"Saved sparse matrix to {MOVIE_FEATURE_MATRIX_PATH}")

# Crea il file CSV con l’indice delle feature
feature_df = pd.DataFrame({
    "feature_id": range(num_features),
    "category": [f[0] for f in unique_features],
    "feature": [f[1] for f in unique_features]
})
feature_df.to_csv(FEATURE_INDEX_PATH, index=False)
print(f"Saved feature index (with categories) to {FEATURE_INDEX_PATH}")

# Crea il file CSV con l’indice dei film
movie_df = pd.DataFrame(
    list(movie_id_to_index.items()),
    columns=["movie_id", "matrix_id"]
)
movie_df.to_csv(MOVIE_INDEX_PATH, index=False, quotechar="'")
print(f"Saved movie index to {MOVIE_INDEX_PATH}")