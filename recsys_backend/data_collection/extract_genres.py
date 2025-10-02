import os
import csv

# === Definizione percorsi ===
# File sorgente (movies.csv di MovieLens)
input_csv = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/ml-latest-small/movies.csv"
)

# Directory di output
output_dir = os.path.expanduser("~/IW_Project/recsys-intelligent_web-2025/")
os.makedirs(output_dir, exist_ok=True)

# File di destinazione (tabella "film-genere")
output_csv = os.path.join(output_dir, "movie_genres.csv")

# === Lettura e trasformazione dati ===
# Apriamo il CSV sorgente in lettura e quello di output in scrittura
with open(input_csv, newline='', encoding='utf-8') as f_in, \
        open(output_csv, 'w', newline='', encoding='utf-8') as f_out:

    reader = csv.DictReader(f_in)   # Legge riga per riga con i nomi delle colonne
    writer = csv.writer(f_out)      # Scrittore CSV
    writer.writerow(['movieId', 'genre'])  # Header del nuovo file

    # Per ogni film nella tabella
    for row in reader:
        movie_id = row['movieId']
        # Ogni film può avere più generi separati da '|'
        genres = row['genres'].split('|') if row['genres'] else []

        # Creiamo una riga separata per ogni coppia (film, genere)
        for genre in genres:
            writer.writerow([movie_id, genre])

# === Output ===
print(f"Creato file con lista dei generi: {output_csv}!")
