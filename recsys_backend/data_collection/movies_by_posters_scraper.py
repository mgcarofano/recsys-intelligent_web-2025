import os
import csv

# Cartella contenente i poster dei film
folder_path = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/movie_posters"
)

# Percorso del CSV di output, salvato nella stessa cartella dello script
output_csv = os.path.join(os.path.dirname(__file__), "existing_movies.csv")

# Lista che conterrà le informazioni dei film (movieID + nome)
movie_data = []

# Scansione dei file nella cartella dei poster
for filename in sorted(os.listdir(folder_path)):
    # Considera solo immagini con estensioni comuni
    if filename.lower().endswith((".jpg", ".jpeg", ".png")):
        # Rimuove l'estensione dal nome del file
        name_without_ext = os.path.splitext(filename)[0]

        # Controlla che ci sia il separatore "_" tra ID e nome
        if "_" in name_without_ext:
            movieIDd, movie_name = name_without_ext.split("_", 1)
            movie_data.append([movieIDd, movie_name])

# Ordina i dati in base al movieID numerico
movie_data.sort(key=lambda x: int(x[0]))

# Scrive il CSV di output con header
with open(output_csv, "w", newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(["movieIDd", "movie_name"])
    writer.writerows(movie_data)

print(f"CSV salvato correttamente in: {output_csv}!")
