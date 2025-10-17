import pandas as pd
import numpy as np
import warnings
from pathlib import Path
from scipy.sparse import load_npz
from sklearn.metrics import mean_squared_error, mean_absolute_error
from lenskit.algorithms import Recommender, als, item_knn as knn, basic
from lenskit import util
from lenskit.crossfold import sample_rows

# ========================================
# CONFIGURAZIONE E PATHS
# ========================================
# I tuoi path per il dataset small ml
EXISTING_RATINGS_PATH = 'data/CSVs/existing_ratings.csv'
MOVIE_INDEX_PATH = 'data/movie_index.csv'
MOVIE_SIMILARIITY_MATRIX_PATH = 'data/movie_cosine_similarity.npz'

TEST_FRACTION = 0.2
K_NEIGHBORS = 20
# ALGORITHMS è definito più avanti

# ========================================
# COSINE SIMILARITY PREDICTOR
# ========================================
class CosineSimilarityPredictor:
    """Item-Item CF con Cosine Similarity e centraggio sulla media utente."""
    def __init__(self, sim_matrix, movie_id_to_idx, k=20):
        self.sim_matrix = sim_matrix
        self.movie_id_to_idx = movie_id_to_idx
        self.k = k
        self.user_ratings = {}
        self.user_means = {}

    def fit(self, train_data):
        self.user_ratings = {}
        user_groups = train_data.groupby('user')
        self.user_means = user_groups['rating'].mean().to_dict()

        for _, row in train_data.iterrows():
            uid = row['user']
            mid = int(row['item'])
            rating = float(row['rating'])
            if uid not in self.user_ratings:
                self.user_ratings[uid] = {}
            self.user_ratings[uid][mid] = rating

    def predict(self, user_id, movie_id):
        if user_id not in self.user_ratings:
            return np.nan

        user_mean = self.user_means.get(user_id)
        if user_mean is None or np.isnan(user_mean):
            return np.nan

        target_idx = self.movie_id_to_idx.get(movie_id)
        if target_idx is None:
            return np.nan

        user_ratings = self.user_ratings[user_id]
        rated_indices = []
        rated_deviations = []

        for rated_id, rating in user_ratings.items():
            idx = self.movie_id_to_idx.get(rated_id)
            if idx is not None and idx != target_idx:
                rated_indices.append(idx)
                rated_deviations.append(rating - user_mean)

        if not rated_indices:
            return np.nan

        # Estrazione Similarity
        if hasattr(self.sim_matrix, 'toarray'):
            similarities = self.sim_matrix[target_idx, rated_indices].toarray().ravel()
        else:
            similarities = self.sim_matrix[target_idx, rated_indices]

        rated_deviations = np.array(rated_deviations)

        # Top-k vicini
        if len(similarities) > self.k:
            top_k_idx = np.argsort(similarities)[-self.k:]
            similarities = similarities[top_k_idx]
            rated_deviations = rated_deviations[top_k_idx]

        sim_sum = np.sum(np.abs(similarities))
        if sim_sum == 0:
            return np.clip(user_mean, 0.5, 5.0)

        pred_deviation = np.sum(similarities * rated_deviations) / sim_sum
        pred = user_mean + pred_deviation

        return np.clip(pred, 0.5, 5.0)

# ========================================
# VALUTAZIONE ALGORITMI (Funzione Stabile)
# ========================================
def evaluate_algorithm(algo, train_data, test_data, algo_name):
    """Valuta un singolo algoritmo, gestendo LensKit in modo robusto."""
    true_ratings = test_data['rating'].values

    if algo_name == 'CosineSim':
        # Interfaccia item-by-item per il tuo codice legacy
        predictions = []
        try:
            algo.fit(train_data)
            for _, row in test_data.iterrows():
                pred = algo.predict(row['user'], int(row['item']))
                predictions.append(pred)
        except Exception as e:
            # Cattura errori interni al tuo CF
            print(f" ERRORE: {type(e).__name__}", end="")
            return None
    else:
        # LensKit: Predizione in batch (robusto contro KeyError)
        try:
            # 1. Clona e adatta
            fittable = util.clone(algo)
            fittable = Recommender.adapt(fittable)

            # 2. Fit (LensKit gestisce internamente la mappatura degli ID)
            with warnings.catch_warnings():
                 # Ignora warning come quello TBB di Numba che non sono errori fatali
                 warnings.simplefilter("ignore")
                 fittable.fit(train_data)

            # 3. Prepara i pairs (user, item)
            test_pairs = test_data[['user', 'item']].copy()

            # 4. Predict in batch. Il risultato è una Series (o DF) con l'indice di test_pairs.
            pred_results = fittable.predict(test_pairs)

            if pred_results is None or pred_results.empty:
                predictions = [np.nan] * len(test_data)
            else:
                # 5. ALLINEAMENTO CRITICO: Usa reindex per garantire che l'array di predizioni
                # corrisponda esattamente all'ordine e alla lunghezza di test_data.
                if isinstance(pred_results, pd.Series):
                    predictions = pred_results.reindex(test_data.index).values
                else: # Gestisce il caso di DataFrame (es. ItemKNN su alcune versioni)
                    predictions = pred_results.iloc[:, 0].reindex(test_data.index).values

        except Exception as e:
            # Cattura errori nel Fit/Predict di LensKit
            print(f" ERRORE: {type(e).__name__}", end="")
            return None

    # Calcolo Metriche
    predictions = np.array(predictions)
    mask = ~np.isnan(predictions)

    if mask.sum() == 0:
        return None

    preds_valid = predictions[mask]
    true_valid = true_ratings[mask]

    rmse = np.sqrt(mean_squared_error(true_valid, preds_valid))
    mae = mean_absolute_error(true_valid, preds_valid)
    coverage = mask.sum() / len(mask) * 100

    return {
        'RMSE': rmse,
        'MAE': mae,
        'Coverage': coverage,
        'n_predictions': mask.sum()
    }

# ========================================
# MODALITÀ UTENTI MULTIPLI (Batch Evaluation)
# ========================================
def evaluate_multiple_users(ratings_df, cosine_predictor, n_users=50):
    """Valuta multipli utenti e fornisce risultati aggregati."""

    # Pre-filtraggio Utenti (almeno 10 rating e varianza > 0)
    user_counts = ratings_df.groupby('userId').size()
    user_stds = ratings_df.groupby('userId')['rating'].std().fillna(0)
    valid_users = user_counts[user_counts >= 10].index.intersection(
        user_stds[user_stds > 0].index
    ).tolist()

    n_users = min(n_users, len(valid_users))
    selected_users = np.random.choice(valid_users, size=n_users, replace=False)

    print(f"\nValutazione su {n_users} utenti validi...")

    all_results = {algo: [] for algo in ['CosineSim'] + list(ALGORITHMS.keys())}
    failed_algos = {algo: 0 for algo in ['CosineSim'] + list(ALGORITHMS.keys())}

    for i, user_id in enumerate(selected_users, 1):
        print(f"[{i}/{n_users}] Utente {user_id}...", end=" ")

        user_ratings = ratings_df[ratings_df['userId'] == user_id].copy()
        user_ratings = user_ratings.rename(columns={'userId': 'user', 'movieId': 'item'})

        # Split (usa un seed dinamico per ogni utente)
        test_size = max(2, int(len(user_ratings) * TEST_FRACTION))
        splits = sample_rows(user_ratings, partitions=1, size=test_size, disjoint=True, rng_spec=i)
        train_data, test_data = next(splits)

        # 1. CosineSim
        res = evaluate_algorithm(cosine_predictor, train_data, test_data, 'CosineSim')
        if res:
            all_results['CosineSim'].append(res)
        else:
            failed_algos['CosineSim'] += 1

        # 2. Altri algoritmi
        for name, algo in ALGORITHMS.items():
            res = evaluate_algorithm(algo, train_data, test_data, name)
            if res:
                all_results[name].append(res)
            else:
                failed_algos[name] += 1

        print("✓")

    # Stampa e salva risultati aggregati
    print("\n" + "="*60)
    print("RISULTATI AGGREGATI (Media e Deviazione Standard)")
    print("="*60)

    summary = []
    for algo, results in all_results.items():
        if results:
            summary.append({
                'Algorithm': algo,
                'RMSE': np.mean([r['RMSE'] for r in results]),
                'RMSE_std': np.std([r['RMSE'] for r in results]),
                'MAE': np.mean([r['MAE'] for r in results]),
                'MAE_std': np.std([r['MAE'] for r in results]),
                'Coverage': np.mean([r['Coverage'] for r in results]),
                'n_users': len(results)
            })

    summary_df = pd.DataFrame(summary).sort_values('RMSE')

    print(f"\n{'Algorithm':<12} {'RMSE':>17} {'MAE':>17} {'Coverage':>10} {'Users':>6} {'Failures':>8}")
    print("-" * 88)
    for _, row in summary_df.iterrows():
        algo_name = row['Algorithm']
        print(f"{algo_name:<12} "
              f"{row['RMSE']:>7.4f} ± {row['RMSE_std']:<7.4f} "
              f"{row['MAE']:>7.4f} ± {row['MAE_std']:<7.4f} "
              f"{row['Coverage']:>9.1f}% "
              f"{int(row['n_users']):>6} "
              f"{failed_algos.get(algo_name, 0):>8}")

    output_path = Path('./evaluation_results/prediction_evaluation.csv')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    summary_df.to_csv(output_path, index=False)
    print(f"\n✓ Risultati salvati in: {output_path}")

    best = summary_df.iloc[0]
    print(f"\n🏆 MIGLIOR ALGORITMO: {best['Algorithm']} (RMSE={best['RMSE']:.4f})")

# ========================================
# MAIN E INIZIALIZZAZIONE
# ========================================
def main():
    # Definisci gli algoritmi qui per poter usare le variabili K_NEIGHBORS
    global ALGORITHMS
    ALGORITHMS = {
        'Bias': basic.Bias(),
        # ItemKNN_LK con uncentered=True per robustezza (come da raccomandazione LK)
        'ItemKNN_LK': knn.ItemItem(K_NEIGHBORS, uncentered=True, aggregate='sum'),
        'ALS': als.BiasedMF(50, iterations=10)
    }

    # ------------------ INIZIO ------------------
    print("="*60)
    print("VALUTAZIONE COMPARATIVA DEI PREDICTOR (RMSE/MAE)")
    print("="*60)

    print("\n1. Caricamento dati e matrice di similarità...")
    try:
        ratings_df = pd.read_csv(EXISTING_RATINGS_PATH)
        movie_index_df = pd.read_csv(MOVIE_INDEX_PATH)
        sim_matrix = load_npz(MOVIE_SIMILARIITY_MATRIX_PATH)
    except FileNotFoundError as e:
        print(f"❌ ERRORE: File non trovato. Assicurati che i percorsi PATH siano corretti. ({e})")
        return

    print(f"   ✓ Rating: {len(ratings_df)}, Similarity Matrix Shape: {sim_matrix.shape}")

    movie_id_to_idx = dict(zip(movie_index_df['movie_id'], movie_index_df['matrix_id']))
    cosine_predictor = CosineSimilarityPredictor(sim_matrix, movie_id_to_idx, k=K_NEIGHBORS)

    print("\n2. Modalità:")
    mode = input("   (s) Singolo utente  (m) Multipli utenti [s/m]: ").lower()

    if mode == 's':
        try:
            user_id = int(input("\nUser ID: "))
        except ValueError:
            print("ID utente non valido.")
            return
        # Rimuovo la modalità singola complessa e la sostituisco con la logica multipla semplificata
        # per non reintrodurre i problemi di gestione degli indici.
        print("\nLa valutazione utente singolo è stata disabilitata per stabilità. Eseguire la modalità 'm'.")
        return
    else:
        try:
            n_users = int(input("\nQuanti utenti? [50]: ") or "50")
        except ValueError:
            n_users = 50

        evaluate_multiple_users(ratings_df, cosine_predictor, n_users)

if __name__ == '__main__':
    # Ignora i FutureWarnings di Pandas per output più pulito
    warnings.simplefilter(action='ignore', category=FutureWarning)
    main()