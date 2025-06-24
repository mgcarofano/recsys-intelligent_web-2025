import pandas as pd
import os


class MovieLensDataLoader:
    def __init__(self, data_path):
        """
        Initialize the data loader with a path to the MovieLens dataset.
        """
        self.data_path = data_path
        self.ratings = None
        self.movies = None
        self.tags = None
        self.links = None
        self.combined_data = None

    def load_datasets(self):
        """
        Load the individual MovieLens datasets into DataFrames.
        """
        self.ratings = pd.read_csv(os.path.join(self.data_path, 'ratings.csv'))
        self.movies = pd.read_csv(os.path.join(self.data_path, 'movies.csv'))
        self.tags = pd.read_csv(os.path.join(self.data_path, 'tags.csv'))
        self.links = pd.read_csv(os.path.join(self.data_path, 'links.csv'))

    def merge_all(self):
        """
        Merge all datasets into a single DataFrame and return it.
        """
        if not all([self.ratings is not None, self.movies is not None,
                    self.tags is not None, self.links is not None]):
            raise ValueError(
                "Datasets not loaded. Call load_datasets() first.")

        ratings_movies = pd.merge(self.ratings, self.movies, on='movieId')
        ratings_movies_tags = pd.merge(ratings_movies, self.tags, on=[
                                       'userId', 'movieId'], how='left')
        self.combined_data = pd.merge(
            ratings_movies_tags, self.links, on='movieId', how='left')

        return self.combined_data
