import pandas as pd

# Caricamento dei dataset
ratings = pd.read_csv("/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/ml-latest-small/ratings.csv")
existing_movies = pd.read_csv("/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/CSVs/existing_movies.csv")

# Filtriamo i rating mantenendo solo quelli relativi ai film presenti in existing_movies
filtered_ratings = ratings[ratings["movieId"].isin(existing_movies["movieID"])]

# Salvataggio del nuovo file con i rating filtrati
filtered_ratings.to_csv(
    "/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/CSVs/existing_ratings.csv",
    index=False
)

print("existing_ratings.csv created successfully!")
