"""

    build_existing_ratings.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script filtra il dataset dei rating per includere solo quelli
    relativi ai film presenti nel dataset dei film esistenti.
    Il risultato viene salvato in un nuovo file CSV chiamato
    'existing_ratings.csv'.

"""

#   ########################################################################   #
#   LIBRERIE

import pandas as pd

from constants import ML_DATASET_PATH_MAPPING, \
    EXISTING_MOVIES_PATH, \
    EXISTING_RATINGS_PATH

#   ########################################################################   #
#   CARICAMENTO DEI DATASET

ratings = pd.read_csv(ML_DATASET_PATH_MAPPING['ratings'])
existing_movies = pd.read_csv(EXISTING_MOVIES_PATH)

#   ########################################################################   #
#   FILTRAGGIO DEI RATING
#   Si lasciano solo quelli relativi ai film presenti in 'existing_movies'.

filtered_ratings = ratings[ratings["movieId"].isin(existing_movies["movieID"])]

#   ########################################################################   #
#   SALVATAGGIO DELL'OUTPUT

filtered_ratings.to_csv(EXISTING_RATINGS_PATH, index=False)
print("existing_ratings.csv created successfully!")