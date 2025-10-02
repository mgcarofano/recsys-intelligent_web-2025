import os
import csv

# === Definizione dei percorsi ===
# File di input (movies.csv con lista completa dei film e generi)
input_csv = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/movies.csv"
)

# Directory di output
output_dir = os.path.expanduser("~/IW_Project/recsys-intelligent_web-2025/")
os.makedirs(output_dir, exist_ok=True)

# File CSV risultante che conterrà la tabella film-genere
output_csv = os.path.join(output_dir, "movie_genres.csv")

# === Lettura da movies.csv e scrittura in movie_genres.csv ===
# Apriamo contemporaneamente file di input e output
with open(input_csv, newline='', encoding='utf-8') as f_in, \
        open(output_csv, 'w', newline='', encoding='utf-8') as f_out:

    reader = csv.DictReader(f_in)   # Legge i film come dizionari {colonna: valore}
    writer = csv.writer(f_out)      # Scrittore CSV per l’output

    # Scriviamo intestazione del nuovo file
    writer.writerow(['movieId', 'genre'])

    # Per ogni film, estraiamo i generi
    for row in reader:
        movie_id = row['movieId']
        # Alcuni film hanno più generi separati da "|"
        genres = row['genres'].split('|') if row['genres'] else []

        # Creiamo una riga distinta per ogni (film, genere)
        for genre in genres:
            writer.writerow([movie_id, genre])

# === Output finale ===
print(f"File dei generi creato: {output_csv}!")
