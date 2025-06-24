import re
import os
import csv
from pandas import DataFrame
from DBpediaLoader import DBpediaLoader
from MovieLensDataLoader import MovieLensDataLoader

# --- Helper function to normalize titles ---


def normalize_title(title):
    title = title.strip()
    title_clean = re.sub(r'\s*\(\d{4}\)', '', title).strip()

    match = re.match(r"^(.*),\s*(The|A|An)$", title_clean)
    if match:
        main_title, article = match.groups()
        title_clean = f"{article} {main_title}"

    return title_clean.replace(' ', '_')  # use underscores for DBpedia URI


# --- Load MovieLens data ---
loader = MovieLensDataLoader(
    '~/IW_Project/recsys-intelligent_web-2025/ml-latest-small')
loader.load_datasets()
combined_all: DataFrame = loader.merge_all()

movies_df = loader.movies

# --- Define poster directory ---
poster_dir = os.path.expanduser(
    "~/IW_Project/recsys-intelligent_web-2025/movie_posters")
os.makedirs(poster_dir, exist_ok=True)

# --- Define output CSV files mapping ---
category_to_csv = {
    "actors": "movie_actors.csv",
    "composers": "movie_composers.csv",
    "directors": "movie_directors.csv",
    "genres": "movie_genres.csv",
    "producers": "movie_producers.csv",
    "production_companies": "movie_production_companies.csv",
    "subjects": "movie_subjects.csv",
    "writers": "movie_writers.csv",
}

# Ensure CSV directory exists (same as poster_dir for convenience)
# or specify another directory if you want
csv_dir = os.path.expanduser("~/IW_Project/recsys-intelligent_web-2025/")
os.makedirs(csv_dir, exist_ok=True)


# Helper function to append rows to CSV (creates file with header if not exists)


def append_to_csv(filepath, rows, header=["movieId", "value"]):
    file_exists = os.path.isfile(filepath)
    with open(filepath, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(header)
        writer.writerows(rows)


start_index = 7735  # for example, start from the 51st movie (0-based index)

# --- Process each title ---
for i, (_, row) in enumerate(movies_df.iloc[start_index:].iterrows()):
    current_index = start_index + i
    movie_id = row['movieId']
    title = row['title']

    match = re.match(r"^(.*)\s+\((\d{4})\)$", title.strip())
    if match:
        raw_title, year = match.group(1).strip(), match.group(2)
    else:
        raw_title, year = title.strip(), None

    normalized_title = normalize_title(title)
    print(
        f"\n=== Processing index {current_index} | movieId: {movie_id} | {title} --> \"{normalized_title}\" ({year}) ===")

    explorer = DBpediaLoader(title=normalized_title, year=year)

    explorer.configure(
        genres=False
    )

    explorer.execute()
    explorer.print_results()
    data = explorer.get_results_dict()

    # Save results by category to respective CSVs
    for category, results_list in data.items():
        if category in category_to_csv and results_list:
            rows = [(movie_id, val) for val in results_list]
            csv_path = os.path.join(csv_dir, category_to_csv[category])
            append_to_csv(csv_path, rows)

    # Sanitize original title for filename
    safe_title = re.sub(r'[<>:"/\\|?*]', '', title)
    poster_filename = f"{movie_id}_{safe_title}.jpg"
    poster_path = os.path.join(poster_dir, poster_filename)

    success = explorer.download_poster(output_filename=poster_path)
    if success:
        print(f"📸 Poster saved as: {poster_path}")
