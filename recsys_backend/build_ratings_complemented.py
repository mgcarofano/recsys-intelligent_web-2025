import os
import pandas as pd
import numpy as np
from scipy.sparse import load_npz
from sklearn.metrics.pairwise import cosine_similarity

# === CONFIGURATION ===
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data"
ratings_path = os.path.join(BASE_FOLDER, "ml-latest-small", "ratings.csv")
similarity_matrix_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npz")
movies_path = os.path.join(BASE_FOLDER, "ml-latest-small", "movies.csv")

output_path = os.path.join(BASE_FOLDER, "ratings_complemented.csv")

# === Step 1: Load data ===
print("Loading ratings and similarity matrix...")
ratings_df = pd.read_csv(ratings_path)
movies_df = pd.read_csv(movies_path)

# Usiamo direttamente i movieId come indici nella matrice di similarità
X = load_npz(os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz"))
movie_ids = movies_df['movieId'].astype(int).tolist()
sim_matrix = cosine_similarity(X, dense_output=True)
sim_df = pd.DataFrame(sim_matrix, index=movie_ids, columns=movie_ids)

# === Step 2: Build complemented ratings ===

for user_id, group in ratings_df.groupby("userId"):
    print(f"Predicting user {user_id}..")
    # Estrai la lista di movieId da ratings.csv
    rated_movies = group["movieId"].astype(int).tolist()
    # Estrai la lista di rating da ratings.csv
    rated_ratings = group["rating"].tolist()
    # Crea l'indice dei rating in base all'indice dei movie
    rated_idx = rated_movies

    complemented_rows = []

    # Costruiamo il dizionario movieId -> rating
    user_ratings = {mid: r for mid, r in zip(rated_movies, rated_ratings)}

    for mid in movie_ids:
        # if mid in user_ratings:
            # Già valutato → manteniamo il voto originale
            # complemented_rows.append((user_id, mid, user_ratings[mid]))
        if mid not in user_ratings:
            # Se non valutato → prediciamo la valutazione
            sims = sim_df.loc[mid, rated_idx].values
            votes = np.array([user_ratings[m] for m in rated_movies])

            if sims.sum() > 0:
                # se la similarità è positiva, allora avremo un valore coerente
                pred = np.dot(sims, votes) / sims.sum()
            else:
                # se la similarità è non positiva, allora scegliamo un valore medio e se non è positivo allora si pone il ranking minimo (pari a 1)
                pred = np.mean(rated_ratings) if len(rated_ratings) > 0 else 0.5  # fallback

            # Clipping tra 1 e 5
            pred = float(np.clip(pred, 1.0, 5.0))
            complemented_rows.append((user_id, mid, pred))
    # Salva l'output in "ratings_complemented/ratings_complemented_user_user_id"
    output_path_user = os.path.join(BASE_FOLDER, "ratings_complemented", f"ratings_complemented_user_{user_id}.csv")
    comp_df = pd.DataFrame(complemented_rows, columns=["userId", "movieId", "rating"])
    comp_df.to_csv(output_path_user, index=False)
    print(f"Saved complemented ratings to {output_path_user} !")
