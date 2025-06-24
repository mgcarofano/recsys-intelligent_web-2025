import os
import csv

# Percorso alla cartella contenente i poster
folder_path = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/movie_posters")

# Output CSV da salvare nella stessa cartella dello script
output_csv = os.path.join(os.path.dirname(__file__), "existing_movies.csv")

movie_data = []

for filename in sorted(os.listdir(folder_path)):
    if filename.lower().endswith((".jpg", ".jpeg", ".png")):
        name_without_ext = os.path.splitext(filename)[0]
        if "_" in name_without_ext:
            movieIDd, movie_name = name_without_ext.split("_", 1)
            movie_data.append([movieIDd, movie_name])

# Ordina per movieIDd numerico
movie_data.sort(key=lambda x: int(x[0]))

with open(output_csv, "w", newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(["movieIDd", "movie_name"])
    writer.writerows(movie_data)


print(f"CSV salvato in: {output_csv}")
