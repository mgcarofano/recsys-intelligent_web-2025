"""

    extract_genres.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script estrae i generi dei film dal dataset originale
    e li salva in un nuovo file CSV.

"""

#   ########################################################################    #
#   LIBRERIE

import csv
from constants import ML_DATASET_PATH_MAPPING, \
    CATEGORIES_PATH_MAPPING

#   ########################################################################    #
#   LETTURA E TRASFORMAZIONE DATI

# Apriamo il CSV sorgente in lettura e quello di output in scrittura
with open(ML_DATASET_PATH_MAPPING['movies'], newline='', encoding='utf-8') as f_in, \
        open(CATEGORIES_PATH_MAPPING['genres'], 'w', newline='', encoding='utf-8') as f_out:

    # Legge riga per riga con i nomi delle colonne.
    reader = csv.DictReader(f_in)

    # Prepara il writer per il file di output.
    writer = csv.writer(f_out)

    # Aggiungiamo l'intestazione nel nuovo file.
    writer.writerow(['movieId', 'genre'])

    # Per ogni film nella tabella
    for row in reader:
        movie_id = row['movieId']
        # Ogni film può avere più generi separati da '|'
        genres = row['genres'].split('|') if row['genres'] else []

        # Creiamo una riga separata per ogni coppia (film, genere)
        for genre in genres:
            writer.writerow([movie_id, genre])

print(f"Creato file con lista dei generi: {CATEGORIES_PATH_MAPPING['genres']}!")