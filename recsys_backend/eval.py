"""

    eval.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo file implementa un Sistema di Valutazione per la
    Predizione di Rating. Confronta l'accuratezza (MAE, RMSE) di diversi
    algoritmi nella predizione dei rating nascosti nel test set.
    L'algoritmo custom 'RatingPredictor' replica la logica di
    build_ratings_complemented.py con l'aggiunta di bias terms.

"""

#   ########################################################################    #
#   LIBRERIE

import pandas as pd
import numpy as np
from scipy.sparse import load_npz
from sklearn.metrics.pairwise import cosine_similarity
from lenskit import crossfold as xf
from lenskit import util
from lenskit.algorithms import Recommender, als, item_knn as knn, user_knn as uknn
from sklearn.metrics import mean_squared_error, mean_absolute_error

from pathlib import Path
from constants import EXISTING_RATINGS_PATH, \
    EXISTING_MOVIES_PATH, \
    MOVIE_FEATURE_MATRIX_PATH

#   ########################################################################    #
#   COMANDI e MACRO

import warnings
warnings.filterwarnings('ignore')

#   ########################################################################    #
#   LA CLASSE CosineSimilarityRecommender PER LA PREDIZIONE DEI RATING (con bias terms)

class CosineSimilarityRecommender:
    """
    Questo recommender replica la logica di build_ratings_complemented.py
    ma aggiunge bias terms per migliorare l'accuratezza.
    """
    def __init__(self, feature_matrix, movies_df, use_bias=True):
        """
        Inizializza il recommender con la matrice di feature (X).

        Args:
            feature_matrix: La matrice sparse delle feature dei film
            movies_df: DataFrame con le informazioni sui film
            use_bias: Se True, usa bias terms (user e item bias)
        """
        self.feature_matrix = feature_matrix
        self.movies_df = movies_df
        self.movie_ids = movies_df['movieID'].astype(int).tolist()
        self.use_bias = use_bias

        # Calcola la similarità coseno
        print(f"   Calculating cosine similarity matrix (bias={'ON' if use_bias else 'OFF'})...")
        self.sim_matrix = cosine_similarity(feature_matrix, dense_output=True)

        # Crea un DataFrame per accedere comodamente alla similarità tra film
        self.sim_df = pd.DataFrame(
            self.sim_matrix,
            index=self.movie_ids,
            columns=self.movie_ids
        )

        self.user_profiles = {}  # {user_id: {movie_id: rating}}
        self.global_mean = None  # Media globale di tutti i rating
        self.user_bias = {}      # {user_id: bias}
        self.item_bias = {}      # {movie_id: bias}

    def fit(self, train_data):
        """
        Costruisce i profili utente dal training set e calcola i bias.
        """
        # Costruisce i profili utente
        self.user_profiles = {}
        for user_id, group in train_data.groupby('user'):
            profile = dict(zip(group['item'].astype(int), group['rating']))
            if profile:
                self.user_profiles[user_id] = profile

        if self.use_bias:
            # Calcola la media globale
            self.global_mean = train_data['rating'].mean()

            # Calcola user bias: quanto l'utente vota sopra/sotto la media
            self.user_bias = {}
            for user_id, profile in self.user_profiles.items():
                user_mean = np.mean(list(profile.values()))
                self.user_bias[user_id] = user_mean - self.global_mean

            # Calcola item bias: quanto il film è votato sopra/sotto la media
            self.item_bias = {}
            item_ratings = train_data.groupby('item')['rating'].apply(list).to_dict()
            for item_id, ratings in item_ratings.items():
                item_mean = np.mean(ratings)
                self.item_bias[int(item_id)] = item_mean - self.global_mean

        return self

    def predict(self, user, item):
        """
        Predice il rating per una coppia (user, item).
        Usa la logica di build_ratings_complemented.py + bias terms.
        """
        if user not in self.user_profiles:
            return np.nan

        # Converti item a int per sicurezza
        mid = int(item)

        # Verifica che il film esista nella matrice di similarità
        if mid not in self.sim_df.index:
            return np.nan

        # Ottieni il profilo dell'utente (film già valutati)
        user_ratings = self.user_profiles[user]

        # Se l'utente ha già valutato questo film (non dovrebbe succedere nel test)
        if mid in user_ratings:
            return user_ratings[mid]

        # Film già valutati dall'utente
        rated_movies = list(user_ratings.keys())
        rated_ratings = list(user_ratings.values())

        # Filtra solo i film che esistono nella matrice di similarità
        rated_idx = [m for m in rated_movies if m in self.sim_df.columns]

        if len(rated_idx) == 0:
            # Fallback: media dei voti dell'utente
            return float(np.clip(np.mean(rated_ratings), 1.0, 5.0))

        # Logica di base
        sims = self.sim_df.loc[mid, rated_idx].values
        votes = np.array([user_ratings[m] for m in rated_idx])

        if sims.sum() > 0:
            # Predizione basata su similarità pesata con i voti reali
            pred_base = np.dot(sims, votes) / sims.sum()
        else:
            # Fallback: media dei voti reali
            pred_base = np.mean(rated_ratings) if len(rated_ratings) > 0 else 0.5

        # Aggiunta dei bias terms
        if self.use_bias and self.global_mean is not None:
            # Ottieni i bias
            i_bias = self.item_bias.get(mid, 0.0)

            # Se la similarità è alta, ci fidiamo di più del content-based
            max_sim = sims.max() if len(sims) > 0 else 0.0
            confidence = min(1.0, max_sim * 2.0)  # 0.5 + similarità -> confidenza

            # confidenza alta -> più peso al content-based
            # confidenza bassa -> più peso al bias
            bias_weight = 1.0 - confidence

            pred = pred_base + (i_bias * bias_weight)
        else:
            pred = pred_base

        # Clipping tra 1 e 5
        pred = float(np.clip(pred, 1.0, 5.0))

        return pred

#   ########################################################################    #
#   FUNZIONE DI VALUTAZIONE (SOLO PREDIZIONI)

def evaluate_predictions(algo_name, algo, train, test):
    """
    Genera predizioni di rating per un algoritmo e le aggiunge al DataFrame di test.
    """
    if isinstance(algo, CosineSimilarityRecommender):
        # Logica per l'algoritmo custom
        fittable = algo.fit(train)
        predictions = []
        for _, row in test.iterrows():
            pred = fittable.predict(row['user'], row['item'])
            predictions.append(pred)

        test_with_preds = test.copy()
        test_with_preds['prediction'] = predictions
        test_with_preds['Algorithm'] = algo_name
        return test_with_preds

    else:
        # Logica per gli algoritmi standard di LensKit
        fittable = Recommender.adapt(util.clone(algo))
        fittable.fit(train)

        preds = fittable.predict(test[['user', 'item']])

        if preds is not None:
            test_with_preds = test.copy()
            test_with_preds['prediction'] = preds
            test_with_preds['Algorithm'] = algo_name
            return test_with_preds

    return pd.DataFrame()

#   ########################################################################    #
#   FUNZIONE PRINCIPALE

def main():
    """Pipeline di valutazione focalizzata su MAE e RMSE."""

    print("=" * 80)
    print("VALUTAZIONE ACCURATEZZA PREDIZIONE RATING (MAE, RMSE)")
    print("=" * 80)

    #   ####################################################################    #
    #   1. CARICAMENTO DATI

    print("\n1. Caricamento dati...")
    try:
        ratings_raw = pd.read_csv(EXISTING_RATINGS_PATH)
        movies_df = pd.read_csv(EXISTING_MOVIES_PATH)
        X = load_npz(MOVIE_FEATURE_MATRIX_PATH)
    except FileNotFoundError as e:
        print(f"❌ ERRORE: {e}")
        return

    ratings = ratings_raw.rename(columns={'userId': 'user', 'movieId': 'item'})[['user', 'item', 'rating']]
    print(f"   ✓ {len(ratings)} rating, {ratings['user'].nunique()} utenti, {len(movies_df)} film")

    #   ####################################################################    #
    #   2. DEFINIZIONE DEGLI ALGORITMI DA VALUTARE

    print("\n2. Inizializzazione algoritmi...")

    # Crea due versioni del cosine similarity predictor: con e senza bias
    cosine_predictor_no_bias = CosineSimilarityRecommender(X, movies_df, use_bias=False)
    cosine_predictor_with_bias = CosineSimilarityRecommender(X, movies_df, use_bias=True)

    algorithms = {
        'CosineSimilarityPredictor (no bias)': cosine_predictor_no_bias,
        'CosineSimilarityPredictor (with bias)': cosine_predictor_with_bias,
        'ItemKNN': knn.ItemItem(50),
        'ALS': als.BiasedMF(50, iterations=10),
        'UserKNN': uknn.UserUser(50),
    }
    print(f"   ✓ {len(algorithms)} algoritmi configurati per la predizione")

    #   ####################################################################    #
    #   3. CROSS VALIDATION

    print(f"\n3. Esecuzione valutazione...")
    all_preds = []

    # Suddivide i dati in training e test
    train, test = next(xf.partition_users(ratings, 1, xf.SampleFrac(0.2)))
    print(f"   - Training set: {len(train)} rating")
    print(f"   - Test set: {len(test)} rating (da predire)")

    for algo_name, algo in algorithms.items():
        print(f"    -> Eseguendo {algo_name:<30}...", end="", flush=True)
        try:
            preds = evaluate_predictions(algo_name, algo, train, test)
            if not preds.empty:
                all_preds.append(preds)
                print(" Fatto!")
        except Exception as e:
            print(f"ERRORE: {type(e).__name__}: {e}")

    if not all_preds:
        print("\nNessuna predizione generata!")
        return

    all_preds_df = pd.concat(all_preds, ignore_index=True)

    #   ####################################################################    #
    #   4. CALCOLO E VISUALIZZAZIONE DELLE METRICHE DI ERRORE

    print("\n" + "=" * 80)
    print("RISULTATI - METRICHE DI ERRORE")
    print("=" * 80 + "\n")

    # Rimuove le righe dove la predizione è fallita
    valid_preds = all_preds_df.dropna(subset=['prediction'])

    if valid_preds.empty:
        print("Nessuna predizione valida generata!")
        return

    # Calcola le metriche per ogni algoritmo
    results = valid_preds.groupby('Algorithm').apply(
        lambda df: pd.Series({
            'MAE': mean_absolute_error(df['rating'], df['prediction']),
            'RMSE': np.sqrt(mean_squared_error(df['rating'], df['prediction'])),
            'N_predictions': len(df)
        })
    )

    # Ordina i risultati per RMSE
    results = results.sort_values('RMSE')

    print(results)

    # Calcola il miglioramento
    if 'CosineSimilarityPredictor (no bias)' in results.index \
        and 'CosineSimilarityPredictor (with bias)' in results.index:
        mae_no_bias = results.loc['CosineSimilarityPredictor (no bias)', 'MAE']
        mae_with_bias = results.loc['CosineSimilarityPredictor (with bias)', 'MAE']
        improvement = ((mae_no_bias - mae_with_bias) / mae_no_bias) * 100
        print(f"\nMiglioramento con bias: {improvement:.2f}% riduzione del MAE")

    #   ####################################################################    #
    #   5. SALVATAGGIO DEI RISULTATI

    output_path = Path('./evaluation_results/prediction_error_evaluation.csv')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    results.to_csv(output_path)
    print(f"\nRisultati salvati in: {output_path}")

    # end

#   ########################################################################    #
#   ENTRY POINT

if __name__ == '__main__':
    main()