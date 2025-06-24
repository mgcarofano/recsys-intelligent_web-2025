import os
import csv

# Paths
input_csv = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/ml-latest-small/movies.csv")
output_dir = os.path.expanduser("~/IW_Project/recsys-intelligent_web-2025/")
os.makedirs(output_dir, exist_ok=True)
output_csv = os.path.join(output_dir, "movie_genres.csv")

# Read movies.csv and write movie_genres.csv
with open(input_csv, newline='', encoding='utf-8') as f_in, \
        open(output_csv, 'w', newline='', encoding='utf-8') as f_out:

    reader = csv.DictReader(f_in)
    writer = csv.writer(f_out)
    writer.writerow(['movieId', 'genre'])  # header

    for row in reader:
        movie_id = row['movieId']
        genres = row['genres'].split('|') if row['genres'] else []
        for genre in genres:
            writer.writerow([movie_id, genre])

print(f"Created genre list CSV at: {output_csv}")
