"""

    vector_extractor.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo file fornisce un esempio di come caricare e utilizzare la matrice sparsa delle feature dei film, insieme ai metadati associati, per estrarre e visualizzare le feature di un film dato il suo indice.

"""

#   ########################################################################    #
#   LIBRERIE

from constants import *

import pandas as pd
from scipy.sparse import load_npz

#   ########################################################################    #
#   CARICAMENTO DELLA MATRICE SPARSA (film x feature)

print("Loading sparse matrix...")
sparse_matrix = load_npz(MOVIE_FEATURE_MATRIX_PATH)

#   ########################################################################    #
#   CARICAMENTO DELLA MAPPA TRA DIMENSIONI E CATEGORIE DI FEATURE

print("Loading category index...")
index_df = pd.read_csv(FEATURE_INDEX_PATH)
dim_to_category = dict(zip(
    index_df['feature_id'],
    index_df['feature']
))

#   ########################################################################    #
#   CARICAMENTO DEI METADATI DEI FILM

print("Loading movie metadata...")
movies_df = pd.read_csv(ML_DATASET_PATH_MAPPING['movies'])
movie_id_to_title = dict(zip(movies_df['movieId'].astype(str), movies_df['title']))
movie_ids = movies_df['movieId'].astype(str).tolist()
movie_index_to_id = {i: mid for i, mid in enumerate(movie_ids)}

#   ########################################################################    #
#   ESEMPIO DI UTILIZZO
#   Chiedi all’utente un indice e mostra le feature corrispondenti.

def show_movie_attributes_by_index(movie_index: int):
    """Mostra le feature associate a un film a partire dall'indice.

    Args:
        movie_index (int): indice del film nel dataset.
    """

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
    
    # end

if __name__ == "__main__":
    try:
        index = int(input("Enter movie index (0 to {}): ".format(sparse_matrix.shape[0] - 1)))
        show_movie_attributes_by_index(index)
    except ValueError:
        print("Please enter a valid integer index.")
    
    # end