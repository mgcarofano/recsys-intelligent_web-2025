"""

    MovieLensDataLoader.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    La classe MovieLensDataLoader gestisce il caricamento e la
    fusione dei dataset MovieLens. Il metodo load_datasets() carica i
    singoli CSV in DataFrame pandas, mentre il metodo merge_all() unisce
    tutti i dataset in un unico DataFrame combinato.

"""

#   ########################################################################    #
#   LIBRERIE

import pandas as pd
from constants import ML_DATASET_PATH_MAPPING

#   ########################################################################    #
#   LA CLASSE MovieLensDataLoader

class MovieLensDataLoader:
    # def __init__(self, data_path) -> None:
    def __init__(self) -> None:
        # """Inizializza il loader per il dataset MovieLens.

        # Args:
        #     data_path (str): percorso della cartella contenente i CSV del dataset.
        
        # Returns:
        #     None
        # """
        """Inizializza il loader per il dataset MovieLens.

        Args:
            self: istanza della classe MovieLensDataLoader.
        
        Returns:
            None
        """

        # self.data_path = data_path
        self.links = None        # DataFrame dei link esterni ai film
        self.movies = None       # DataFrame dei film
        self.ratings = None      # DataFrame dei rating degli utenti
        self.tags = None         # DataFrame dei tag associati ai film
        self.combined_data = None  # DataFrame combinato di tutti i dati

        # end

    def load_datasets(self) -> None:
        """Carica i singoli CSV del dataset MovieLens in DataFrame pandas.

        Args:
            self: istanza della classe MovieLensDataLoader.
        
        Returns:
            None
        """

        # self.ratings = pd.read_csv(os.path.join(self.data_path, 'ratings.csv'))
        # self.movies = pd.read_csv(os.path.join(self.data_path, 'movies.csv'))
        # self.tags = pd.read_csv(os.path.join(self.data_path, 'tags.csv'))
        # self.links = pd.read_csv(os.path.join(self.data_path, 'links.csv'))

        self.links = pd.read_csv(ML_DATASET_PATH_MAPPING['links'])
        self.movies = pd.read_csv(ML_DATASET_PATH_MAPPING['movies'])
        self.ratings = pd.read_csv(ML_DATASET_PATH_MAPPING['ratings'])
        self.tags = pd.read_csv(ML_DATASET_PATH_MAPPING['tags'])

        # end

    def merge_all(self) -> pd.DataFrame:
        """Effettua il merge di tutti i dataset in un unico DataFrame.

        Args:
            self: istanza della classe MovieLensDataLoader.

        Returns:
            pd.DataFrame: DataFrame combinato contenente tutte le informazioni.
        """

        # Controllo se tutti i dataset sono stati caricati
        if not all([self.ratings is not None, self.movies is not None,
                    self.tags is not None, self.links is not None]):
            raise ValueError("Datasets non caricati. Esegui load_datasets() prima.")

        # Merge ratings + movies
        ratings_movies = pd.merge(self.ratings, self.movies, on='movieId')

        # Merge con tags (left join per mantenere tutti i rating)
        ratings_movies_tags = pd.merge(ratings_movies, self.tags,
                                       on=['userId', 'movieId'], how='left')

        # Merge con links (left join)
        self.combined_data = pd.merge(ratings_movies_tags, self.links,
                                      on='movieId', how='left')

        return self.combined_data

        # end

    # end class MovieLensDataLoader