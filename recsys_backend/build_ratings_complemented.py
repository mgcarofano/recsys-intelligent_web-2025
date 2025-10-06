"""

    build_ratings_complemented.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script stima i ratings per i film che l'utente non ha ancora valutato. Siccome il motore di raccomandazione implementato è knowledge-based, il rating viene stimato utilizzando la similarità coseno tra i film basata sulle loro feature. I risultati sono salvati in file CSV separati per ogni utente.

"""

#	########################################################################	#
#	LIBRERIE

from constants import *

import pandas as pd
import numpy as np
from scipy.sparse import load_npz
from sklearn.metrics.pairwise import cosine_similarity

#	########################################################################	#
#   CARICAMENTO DEI DATI NECESSARI

print("Loading ratings and similarity matrix...")
ratings_df = pd.read_csv(EXISTING_RATINGS_PATH)
movies_df = pd.read_csv(EXISTING_MOVIES_PATH)
X = load_npz(MOVIE_FEATURE_MATRIX_PATH)

#	########################################################################	#
#   CALCOLO DELLA SIMILARITÀ COSENO TRA TUTTI I FILM

movie_ids = movies_df['movieID'].astype(int).tolist()
sim_matrix = cosine_similarity(X, dense_output=True)

#	########################################################################	#
#   COSTRUZIONE DEI RATING COMPLEMENTATI UTENTE PER UTENTE

# Creiamo un DataFrame per accedere comodamente alla similarità tra film
sim_df = pd.DataFrame(sim_matrix, index=movie_ids, columns=movie_ids)

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

            # end if

        # end for mid

    # Salvataggio dei rating complementati in un file CSV specifico per l'utente
    output_path_user = Path(f'./data/ratings_complemented/ratings_complemented_user_{user_id}.csv')
    comp_df = pd.DataFrame(complemented_rows, columns=["userId", "movieId", "rating"])
    comp_df.to_csv(output_path_user, index=False)

    print(f"Saved complemented ratings to {output_path_user} !")

    # end for user_id, group