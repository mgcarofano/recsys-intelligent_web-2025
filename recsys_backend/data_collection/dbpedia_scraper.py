"""

    dbpedia_scraper.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo script estrae metadati sui film dal dataset DBpedia utilizzando
    i titoli dei film presenti nel dataset MovieLens 'ml-latest-small'.
    I metadati estratti vengono salvati in file CSV separati per categoria
    (e.g. attori, registi, generi, ...).

"""

#   ########################################################################    #
#   LIBRERIE

import re

import csv
from pandas import DataFrame

from DBpediaLoader import DBpediaLoader
from MovieLensDataLoader import MovieLensDataLoader

from pathlib import Path
from constants import MOVIES_ABSTRACT_PATH, \
    CATEGORIES_PATH_MAPPING

#   ########################################################################    #
#   FUNZIONI

def normalize_title(title):
    """Normalizza il titolo di un film per l’uso con DBpedia.

    Args:
        title (str): Il titolo del film.

    Returns:
        str: Il titolo normalizzato.
    """

    title = title.strip()
    title_clean = re.sub(r'\s*\(\d{4}\)', '', title).strip()

    # Sposta articoli (The, A, An) all’inizio del titolo
    match = re.match(r"^(.*),\s*(The|A|An)$", title_clean)
    if match:
        main_title, article = match.groups()
        title_clean = f"{article} {main_title}"

    # Sostituiamo gli spazi con underscore per formare URI compatibili con DBpedia
    return title_clean.replace(' ', '_')

    # end

def append_to_csv(filepath, rows, header=["movieId", "value"]):
    """Aggiunge righe a un file CSV, creando il file con intestazione se non esiste.

    Args:
        filepath (str): Il percorso del file CSV.
        rows (list[tuple]): Le righe da aggiungere.
        header (list, optional): L'intestazione del CSV. Defaults to ["movieId", "value"].
    
    Returns:
        None
    """

    # file_exists = os.path.isfile(filepath)
    file_exists = Path(filepath).is_file()
    with open(filepath, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(header)
        writer.writerows(rows)

    # end

#   ########################################################################    #
#   CARICAMENTO DEL DATASET MOVIELENS

# loader = MovieLensDataLoader(ML_DATASET_DIR)
loader = MovieLensDataLoader()
loader.load_datasets()
combined_all: DataFrame = loader.merge_all()
movies_df = loader.movies

#   ########################################################################    #
#   ESTRAZIONE DEI METADATI DA DBPEDIA

# Indice iniziale da cui partire (utile per debug o resume)
start_index = 2699

# Elaborazione di ciascun film a partire dall’indice scelto
for i, (_, row) in enumerate(movies_df.iloc[start_index:].iterrows()):
    current_index = start_index + i
    movie_id = row['movieId']
    title = row['title']

    # Estrazione del titolo e dell’anno (se presente tra parentesi)
    match = re.match(r"^(.*)\s+\((\d{4})\)$", title.strip())
    if match:
        raw_title, year = match.group(1).strip(), match.group(2)
    else:
        raw_title, year = title.strip(), None

    normalized_title = normalize_title(title)
    print(
        f"\nProcessing index {current_index} | movieId: {movie_id} | {title} --> \"{normalized_title}\" ({year})"
    )

    explorer = DBpediaLoader(title=normalized_title, year=year)

    # Configurazione: in questo esempio si scarica solo l’abstract
    explorer.configure(
        actors=False,
        composers=False,
        directors=False,
        genres=False,
        producers=False,
        production_companies=False,
        subjects=False,
        writers=False,
        wikipedia=False,
        abstract=True
    )

    explorer.execute()
    explorer.print_results()
    data = explorer.get_results_dict()

    # Salvataggio dei risultati nelle rispettive categorie CSV
    # for category, results_list in data.items():
    #     if category in category_to_csv and results_list:
    #         rows = [(movie_id, val) for val in results_list]
    #         csv_path = os.path.join(csv_dir, category_to_csv[category])
    #         append_to_csv(csv_path, rows)
    for category, results_list in data.items():
        if category == 'abstract' and results_list:
            rows = [(movie_id, results_list[0])]
            csv_path = MOVIES_ABSTRACT_PATH
        elif category in CATEGORIES_PATH_MAPPING and results_list:
            rows = [(movie_id, val) for val in results_list]
            csv_path = CATEGORIES_PATH_MAPPING[category]
        append_to_csv(csv_path, rows)

    # Sezione opzionale per il download dei poster
    # safe_title = re.sub(r'[<>:"/\\|?*]', '', title)
    # poster_filename = f"{movie_id}_{safe_title}.jpg"
    # poster_path = os.path.join(poster_dir, poster_filename)
    # success = explorer.download_poster(output_filename=poster_path)
    # if success:
    #     print(f"Poster saved as: {poster_path}")
