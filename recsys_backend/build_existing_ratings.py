import pandas as pd

# === Load data ===
ratings = pd.read_csv("/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/ml-latest-small/ratings.csv")
existing_movies = pd.read_csv("/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/CSVs/existing_movies.csv")

# === Filter ratings to keep only those movies in existing_movies ===
filtered_ratings = ratings[ratings["movieId"].isin(existing_movies["movieID"])]

# === Save to new CSV ===
filtered_ratings.to_csv("/home/olexandro/IW_Project/recsys-intelligent_web-2025/recsys_backend/data/CSVs/existing_ratings.csv", index=False)

print("✅ existing_ratings.csv created successfully!")