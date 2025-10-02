import os
import pandas as pd
import numpy as np
from scipy.sparse import load_npz
from sklearn.metrics.pairwise import cosine_similarity

# Configurazione dei percorsi
BASE_FOLDER = "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data"
ratings_path = os.path.join(BASE_FOLDER, "CSVs", "existing_ratings.csv")
similarity_matrix_path = os.path.join(BASE_FOLDER, "movie_cosine_similarity.npz")
movies_path = os.path.join(BASE_FOLDER, "CSVs", "existing_movies.csv")

output_path = os.path.join(BASE_FOLDER, "ratings_complemented.csv")

# Caricamento dei dati necessari
print("Loading ratings and similarity matrix...")
ratings_df = pd.read_csv(ratings_path)
movies_df = pd.read_csv(movies_path)

# Carichiamo la matrice film-feature e calcoliamo la similarità coseno tra tutti i film
X = load_npz(os.path.join(BASE_FOLDER, "movie_vectors_sparse.npz"))
movie_ids = movies_df['movieID'].astype(int).tolist()
sim_matrix = cosine_similarity(X, dense_output=True)

# Creiamo un DataFrame per accedere comodamente alla similarità tra film
sim_df = pd.DataFrame(sim_matrix, index=movie_ids, columns=movie_ids)

# Costruzione dei rating complementati utente per utente
for user_id, group in ratings_df.groupby("userId"):
    print(f"Predicting user {user_id}..")

    # Film già valutati dall'utente
    rated_movies = group["movieId"].astype(int).tolist()
    rated_ratings = group["rating"].tolist()
    rated_idx = rated_movies

    complemented_rows = []

    # Costruzione dizionario {movieId -> rating} per i film visti
    user_ratings = {mid: r for mid, r in zip(rated_movies, rated_ratings)}

    # Predizione rating per ogni film non ancora visto
    for mid in movie_ids:
        if mid not in user_ratings:
            sims = sim_df.loc[mid, rated_idx].values
            votes = np.array([user_ratings[m] for m in rated_movies])

            if sims.sum() > 0:
                # Predizione basata su similarità pesata con i voti reali
                pred = np.dot(sims, votes) / sims.sum()
            else:
                # Fallback: media dei voti reali (o 0.5 se non ci sono voti)
                pred = np.mean(rated_ratings) if len(rated_ratings) > 0 else 0.5

            # Clipping tra 1 e 5 per mantenere i valori nel range corretto
            pred = float(np.clip(pred, 1.0, 5.0))
            complemented_rows.append((user_id, mid, pred))

    # Salvataggio dei rating complementati in un file CSV specifico per l'utente
    output_path_user = os.path.join(
        BASE_FOLDER,
        "ratings_complemented",
        f"ratings_complemented_user_{user_id}.csv"
    )
    comp_df = pd.DataFrame(complemented_rows, columns=["userId", "movieId", "rating"])
    comp_df.to_csv(output_path_user, index=False)
    print(f"Saved complemented ratings to {output_path_user} !")
