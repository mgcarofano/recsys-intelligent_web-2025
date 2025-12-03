"""

    movies_by_posters_scraper.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script genera un file CSV che elenca tutti i film per cui
    sono disponibili i poster, detti "existing movies".

"""

#   ########################################################################    #
#   LIBRERIE

import csv
from constants import POSTER_DIR, \
    EXISTING_MOVIES_PATH

#   ########################################################################    #
#   GENERAZIONE DEL CSV DEI FILM ESISTENTI

# Lista che conterrà le informazioni dei film (movieID + nome)
movie_data = []

# Scansione dei file nella cartella dei poster
# for filename in sorted(os.listdir(folder_path)):
for filename in sorted(POSTER_DIR.iterdir()):
    # Considera solo immagini con estensioni comuni
    if filename.lower().endswith((".jpg", ".jpeg", ".png")):
        # Rimuove l'estensione dal nome del file
        # name_without_ext = os.path.splitext(filename)[0]
        name_without_ext = filename.stem

        # Controlla che ci sia il separatore "_" tra ID e nome
        if "_" in name_without_ext:
            movieIDd, movie_name = name_without_ext.split("_", 1)
            movie_data.append([movieIDd, movie_name])

# Ordina i dati in base al movieID numerico
movie_data.sort(key=lambda x: int(x[0]))

#   ########################################################################    #
#   SALVATAGGIO DEL CSV DEI FILM ESISTENTI

# Scrive il CSV di output con header
with open(EXISTING_MOVIES_PATH, "w", newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(["movieIDd", "movie_name"])
    writer.writerows(movie_data)

print(f"CSV salvato correttamente in: {EXISTING_MOVIES_PATH}!")