"""
Sistema di Valutazione Algoritmi di Raccomandazione
===================================================
Confronta CosineSimilarity (content-based) con algoritmi LensKit (collaborative).
Calcola metriche Top-N (nDCG, Recall, Precision) e metriche di predizione (MAE, RMSE).

Autore: [Nome]
Data: [Data]
"""

import pandas as pd
import numpy as np
from pathlib import Path
from scipy.sparse import load_npz
from lenskit import batch, topn, util
from lenskit import crossfold as xf
from lenskit.algorithms import Recommender, als, item_knn as knn, user_knn as uknn, basic
from sklearn.metrics import mean_squared_error, mean_absolute_error
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

from constants import *

# ========================================
# CONFIGURAZIONE GLOBALE
# ========================================
TOPN_SIZE = 100      # Numero di raccomandazioni da generare
NFOLDS = 1           # Numero di fold per cross-validation
TEST_FRAC = 0.2      # Frazione di dati per test (20%)

# ========================================
# CLASSE COSINE SIMILARITY RECOMMENDER
# ========================================
class CosineSimilarityRecommender:
    """
    Recommender system content-based basato su cosine similarity.

    Ottimizzazioni:
    - Pre-calcolo dei k vicini più simili per ogni film
    - Uso di sparse matrix per efficienza
    - Normalizzazione con media utente per predizioni
    """

    def __init__(self, sim_matrix, movie_id_to_idx, k_neighbors=50):
        """
        Inizializza il recommender e pre-calcola top-k similarità.

        Args:
            sim_matrix: Matrice di similarità film-film (sparse)
            movie_id_to_idx: Dizionario {movie_id -> indice_matrice}
            k_neighbors: Numero di vicini da considerare
        """
        self.sim_matrix = sim_matrix.tocsr()
        self.movie_id_to_idx = movie_id_to_idx
        self.idx_to_movie_id = {v: k for k, v in movie_id_to_idx.items()}
        self.k_neighbors = k_neighbors
        self.user_profiles = {}      # {user_id: {movie_id: rating}}
        self.user_means = {}          # {user_id: rating_medio}

        # Pre-calcola i k film più simili per ogni film (una tantum)
        print("   Pre-calcolo top-k similarità...")
        n_movies = sim_matrix.shape[0]
        self.topk_indices = np.zeros((n_movies, k_neighbors), dtype=np.int32)
        self.topk_sims = np.zeros((n_movies, k_neighbors), dtype=np.float32)

        for idx in range(n_movies):
            # Estrae riga di similarità per il film corrente
            row = sim_matrix[idx, :].toarray().ravel()

            # Trova indici dei k film più simili
            topk_idx = np.argpartition(row, -k_neighbors)[-k_neighbors:]
            topk_idx = topk_idx[np.argsort(row[topk_idx])[::-1]]  # Ordina per similarità

            # Salva indici e valori di similarità
            self.topk_indices[idx] = topk_idx
            self.topk_sims[idx] = row[topk_idx]

    def fit(self, train_data):
        """
        Costruisce i profili utente dal training set. Non è un training come quello di una rete neurale

        Args:
            train_data: DataFrame con colonne [user, item, rating]
        """
        self.user_profiles = {}
        self.user_means = {}

        # Crea profilo per ogni utente: crea una lista dei film con i loro rating
        for user_id in train_data['user'].unique():
            user_data = train_data[train_data['user'] == user_id]
            profile = {}
            ratings = []

            for _, row in user_data.iterrows():
                mid = int(row['item'])
                rating = float(row['rating'])

                if mid in self.movie_id_to_idx:
                    profile[mid] = rating
                    ratings.append(rating)

            if profile:
                self.user_profiles[user_id] = profile
                self.user_means[user_id] = np.mean(ratings)

        return self

    def recommend(self, user, n=100):
        """
        Genera top-N raccomandazioni per un utente.

        Algoritmo:
        1. Per ogni film votato dall'utente
        2. Trova i k film più simili (pre-calcolati)
        3. Accumula punteggi: score[film_vicino] += similarità * rating_film_votato
        4. Restituisce i film non votati con punteggio più alto

        Args:
            user: ID utente
            n: Numero di raccomandazioni

        Returns:
            DataFrame con colonne [item, score]
        """
        if user not in self.user_profiles:
            return pd.DataFrame(columns=['item', 'score'])

        profile = self.user_profiles[user]
        rated_set = set(profile.keys())  # Film già votati (da escludere)
        scores = {}

        # Aggrega punteggi dai film votati
        for rated_mid, rating in profile.items():
            rated_idx = self.movie_id_to_idx.get(rated_mid)
            if rated_idx is None:
                continue

            # Recupera top-k vicini pre-calcolati
            neighbor_indices = self.topk_indices[rated_idx]
            neighbor_sims = self.topk_sims[rated_idx]

            # Accumula punteggi per i vicini non votati
            for nei_idx, sim in zip(neighbor_indices, neighbor_sims):
                neighbor_mid = self.idx_to_movie_id[nei_idx]

                if neighbor_mid not in rated_set:
                    scores[neighbor_mid] = scores.get(neighbor_mid, 0.0) + sim * rating

        if not scores:
            return pd.DataFrame(columns=['item', 'score'])

        # Restituisce top-N
        top_items = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:n]
        return pd.DataFrame({
            'item': [x[0] for x in top_items],
            'score': [x[1] for x in top_items]
        })

    def predict(self, user, item):
        """
        Predice il rating per una coppia user-item (per MAE/RMSE).

        Formula: rating_pred = media_utente + (weighted_avg_deviazioni)

        Args:
            user: ID utente
            item: ID film

        Returns:
            Rating predetto (0.5-5.0) o NaN se impossibile predire
        """
        if user not in self.user_profiles:
            return np.nan

        target_idx = self.movie_id_to_idx.get(item)
        if target_idx is None:
            return np.nan

        profile = self.user_profiles[user]
        user_mean = self.user_means[user]

        # Calcola weighted average delle deviazioni dai film votati
        weighted_sum = 0.0
        sim_sum = 0.0

        for rated_mid, rating in profile.items():
            if rated_mid == item:  # Salta se è il film da predire
                continue

            rated_idx = self.movie_id_to_idx.get(rated_mid)
            if rated_idx is None:
                continue

            # Similarità tra film target e film votato
            sim = self.sim_matrix[target_idx, rated_idx]

            # Accumula: sim * (rating - media)
            weighted_sum += sim * (rating - user_mean)
            sim_sum += abs(sim)

        # Se nessuna similarità disponibile, restituisce media utente
        if sim_sum == 0:
            return np.clip(user_mean, 0.5, 5.0)

        # Predizione finale: media + weighted_avg_deviazioni
        pred = user_mean + (weighted_sum / sim_sum)
        return np.clip(pred, 0.5, 5.0)

# ========================================
# FUNZIONI DI VALUTAZIONE
# ========================================
def evaluate_recommendations(algo_name, algo, train, test, topn_size=100):
    """
    Genera raccomandazioni top-N per un algoritmo.

    Args:
        algo_name: Nome dell'algoritmo
        algo: Istanza dell'algoritmo
        train: DataFrame di training
        test: DataFrame di test
        topn_size: Numero di raccomandazioni

    Returns:
        DataFrame con colonne [user, item, score, Algorithm]
    """
    recs_list = []

    if isinstance(algo, CosineSimilarityRecommender):
        # Gestione algoritmo custom
        algo.fit(train)
        for user in test['user'].unique():
            recs = algo.recommend(user, n=topn_size)
            if len(recs) > 0:
                recs['user'] = user
                recs_list.append(recs)

        all_recs = pd.concat(recs_list, ignore_index=True) if recs_list else pd.DataFrame()
    else:
        # Gestione algoritmi LensKit
        fittable = Recommender.adapt(util.clone(algo))
        fittable.fit(train)
        users = test['user'].unique()
        all_recs = batch.recommend(fittable, users, topn_size)

    if len(all_recs) > 0:
        all_recs['Algorithm'] = algo_name

    return all_recs

def evaluate_predictions(algo_name, algo, train, test):
    """
    Genera predizioni di rating per calcolare MAE/RMSE.

    Args:
        algo_name: Nome dell'algoritmo
        algo: Istanza dell'algoritmo
        train: DataFrame di training
        test: DataFrame di test

    Returns:
        DataFrame con colonne [user, item, rating, prediction, Algorithm]
    """
    predictions = []

    if isinstance(algo, CosineSimilarityRecommender):
        # Gestione algoritmo custom
        algo.fit(train)
        for _, row in test.iterrows():
            pred = algo.predict(row['user'], row['item'])
            predictions.append({
                'user': row['user'],
                'item': row['item'],
                'rating': row['rating'],
                'prediction': pred,
                'Algorithm': algo_name
            })
    else:
        # Gestione algoritmi LensKit
        try:
            fittable = Recommender.adapt(util.clone(algo))
            fittable.fit(train)

            # Predici in batch
            test_pairs = test[['user', 'item']].copy()
            pred_results = fittable.predict(test_pairs)

            if pred_results is not None and len(pred_results) > 0:
                # Gestisci Series o DataFrame
                if isinstance(pred_results, pd.Series):
                    pred_values = pred_results.reindex(test.index).values
                elif isinstance(pred_results, pd.DataFrame):
                    if 'prediction' in pred_results.columns:
                        pred_values = pred_results['prediction'].reindex(test.index).values
                    else:
                        pred_values = pred_results.iloc[:, 0].reindex(test.index).values
                else:
                    pred_values = [np.nan] * len(test)

                # Crea DataFrame con predizioni
                for i, row in test.iterrows():
                    predictions.append({
                        'user': row['user'],
                        'item': row['item'],
                        'rating': row['rating'],
                        'prediction': pred_values[i] if i < len(pred_values) else np.nan,
                        'Algorithm': algo_name
                    })
        except Exception as e:
            print(f"      (Predizioni fallite: {type(e).__name__})")
            return pd.DataFrame()

    return pd.DataFrame(predictions)

# ========================================
# METRICHE PERSONALIZZATE
# ========================================
def calculate_hit_rate(recs, test):
    """
    Calcola Hit Rate: % utenti con almeno 1 raccomandazione corretta.

    Hit Rate = (# utenti con hit) / (# utenti totali)
    """
    test_items = test.groupby('user')['item'].apply(set).to_dict()
    hits = 0
    total = 0

    for user in recs['user'].unique():
        if user not in test_items:
            continue

        total += 1
        user_recs = set(recs[recs['user'] == user]['item'].values)

        # Verifica se c'è intersezione tra raccomandati e test
        if len(user_recs & test_items[user]) > 0:
            hits += 1

    return hits / total if total > 0 else 0.0

def calculate_coverage(recs, all_items):
    """
    Calcola Coverage: % di item unici raccomandati (diversità catalogo).

    Coverage = (# item raccomandati) / (# item totali)
    """
    rec_items = set(recs['item'].unique())
    return len(rec_items) / len(all_items) if len(all_items) > 0 else 0.0

def calculate_diversity(recs, sim_matrix, movie_id_to_idx):
    """
    Calcola Diversity: quanto sono diversi i film raccomandati tra loro.

    Diversity = 1 - (similarità media tra coppie di film raccomandati)
    Valori alti = film molto diversi tra loro
    """
    diversities = []

    for user in recs['user'].unique():
        user_recs = recs[recs['user'] == user]['item'].values
        if len(user_recs) < 2:
            continue

        # Calcola similarità tra coppie (limita a 20 per performance)
        sims = []
        max_items = min(len(user_recs), 20)

        for i in range(max_items):
            for j in range(i+1, max_items):
                mid_i, mid_j = user_recs[i], user_recs[j]
                idx_i = movie_id_to_idx.get(mid_i)
                idx_j = movie_id_to_idx.get(mid_j)

                if idx_i is not None and idx_j is not None:
                    sim = sim_matrix[idx_i, idx_j]
                    sims.append(sim)

        if sims:
            diversities.append(1.0 - np.mean(sims))

    return np.mean(diversities) if diversities else 0.0

# ========================================
# FUNZIONE PRINCIPALE
# ========================================
def main():
    """Pipeline completa di valutazione algoritmi di raccomandazione."""

    print("=" * 80)
    print("VALUTAZIONE ALGORITMI DI RACCOMANDAZIONE")
    print("=" * 80)

    # --------------------------------------------------
    # 1. CARICAMENTO DATI
    # --------------------------------------------------
    print("\n1. Caricamento dati...")
    try:
        ratings_raw = pd.read_csv(EXISTING_RATINGS_PATH)
        sim_matrix = load_npz(MOVIE_SIMILARIITY_MATRIX_PATH)
        # --- CORREZIONE QUI ---
        # Aggiungi la costante con il percorso del file
        movie_index_df = pd.read_csv(MOVIE_INDEX_PATH)
        # ----------------------
    except FileNotFoundError as e:
        print(f"❌ ERRORE: {e}")
        return

    # Prepara i dati nel formato LensKit
    ratings = ratings_raw.rename(
        columns={'userId': 'user', 'movieId': 'item'}
    )[['user', 'item', 'rating']]

    movie_id_to_idx = dict(zip(
        movie_index_df['movie_id'],
        movie_index_df['matrix_id']
    ))
    all_items = set(ratings['item'].unique())

    print(f"   ✓ {len(ratings)} rating, {ratings['user'].nunique()} utenti, {len(all_items)} film")

    # --------------------------------------------------
    # 2. DEFINIZIONE ALGORITMI
    # --------------------------------------------------
    print("\n2. Inizializzazione algoritmi...")
    cosine_algo = CosineSimilarityRecommender(sim_matrix, movie_id_to_idx, k_neighbors=50)

    algorithms = {
        'CosineSim': cosine_algo,              # Content-based
        'ItemKNN-20': knn.ItemItem(20),        # Collaborative (20 vicini)
        'ItemKNN-50': knn.ItemItem(50),        # Collaborative (50 vicini)
        'ALS': als.BiasedMF(50, iterations=10), # Matrix factorization
        'UserKNN-30': uknn.UserUser(30),       # User-based CF
        'Popular': basic.Popular()             # Baseline (popolarità)
    }

    print(f"   ✓ {len(algorithms)} algoritmi configurati")

    # --------------------------------------------------
    # 3. CROSS-VALIDATION
    # --------------------------------------------------
    print(f"\n3. Cross-validation ({NFOLDS} fold, test={TEST_FRAC*100}%)...")

    all_recs = []    # Lista di tutte le raccomandazioni
    all_preds = []   # Lista di tutte le predizioni
    test_data = []   # Lista dei set di test

    # Esegui cross-validation
    for fold, (train, test) in enumerate(xf.partition_users(ratings, NFOLDS, xf.SampleFrac(TEST_FRAC))):
        print(f"\n  Fold {fold+1}/{NFOLDS}")
        print(f"    Train: {len(train)} rating, {train['user'].nunique()} utenti")
        print(f"    Test:  {len(test)} rating, {test['user'].nunique()} utenti")

        test_data.append(test)

        # Valuta ogni algoritmo
        for algo_name, algo in algorithms.items():
            print(f"    {algo_name:<15}...", end=" ", flush=True)

            try:
                # Genera raccomandazioni top-N
                recs = evaluate_recommendations(algo_name, algo, train, test, topn_size=TOPN_SIZE)
                if len(recs) > 0:
                    all_recs.append(recs)
                    print(f"✓ {len(recs)} recs", end="")

                # Genera predizioni per MAE/RMSE
                preds = evaluate_predictions(algo_name, algo, train, test)
                if len(preds) > 0:
                    all_preds.append(preds)
                    print(f", {len(preds)} pred")
                else:
                    print()

            except Exception as e:
                print(f"✗ ERRORE: {type(e).__name__}")

    # Consolida risultati
    all_recs = pd.concat(all_recs, ignore_index=True)
    all_preds = pd.concat(all_preds, ignore_index=True) if all_preds else pd.DataFrame()
    test_data = pd.concat(test_data, ignore_index=True)

    # --------------------------------------------------
    # 4. CALCOLO METRICHE TOP-N (LensKit)
    # --------------------------------------------------
    print("\n4. Calcolo metriche Top-N...")

    rla = topn.RecListAnalysis()
    rla.add_metric(topn.ndcg)         # Normalized Discounted Cumulative Gain
    rla.add_metric(topn.recip_rank)   # Reciprocal Rank
    rla.add_metric(topn.precision)    # Precision@K
    rla.add_metric(topn.recall)       # Recall@K

    results = rla.compute(all_recs, test_data)
    summary = results.groupby('Algorithm').mean(numeric_only=True).reset_index()

    # --------------------------------------------------
    # 5. CALCOLO METRICHE AGGIUNTIVE
    # --------------------------------------------------
    print("   Calcolo metriche aggiuntive...")

    additional_metrics = []
    for algo_name in algorithms.keys():
        algo_recs = all_recs[all_recs['Algorithm'] == algo_name]
        if len(algo_recs) > 0:
            hr = calculate_hit_rate(algo_recs, test_data)
            cov = calculate_coverage(algo_recs, all_items)
            div = calculate_diversity(algo_recs, sim_matrix, movie_id_to_idx)

            additional_metrics.append({
                'Algorithm': algo_name,
                'hit_rate': hr,
                'coverage': cov,
                'diversity': div
            })

    additional_df = pd.DataFrame(additional_metrics)
    summary = summary.merge(additional_df, on='Algorithm', how='left')

    # --------------------------------------------------
    # 6. CALCOLO MAE E RMSE
    # --------------------------------------------------
    print("   Calcolo MAE e RMSE...")

    if len(all_preds) > 0:
        mae_rmse_metrics = []

        for algo_name in algorithms.keys():
            algo_preds = all_preds[all_preds['Algorithm'] == algo_name]

            if len(algo_preds) > 0:
                # Filtra predizioni valide (non NaN)
                mask = ~algo_preds['prediction'].isna()

                if mask.sum() > 0:
                    true_vals = algo_preds[mask]['rating'].values
                    pred_vals = algo_preds[mask]['prediction'].values

                    mae = mean_absolute_error(true_vals, pred_vals)
                    rmse = np.sqrt(mean_squared_error(true_vals, pred_vals))
                    pred_coverage = mask.sum() / len(algo_preds) * 100
                else:
                    mae = rmse = pred_coverage = np.nan

                mae_rmse_metrics.append({
                    'Algorithm': algo_name,
                    'MAE': mae,
                    'RMSE': rmse,
                    'pred_coverage': pred_coverage
                })

        mae_rmse_df = pd.DataFrame(mae_rmse_metrics)
        summary = summary.merge(mae_rmse_df, on='Algorithm', how='left')

    # --------------------------------------------------
    # 7. VISUALIZZAZIONE RISULTATI
    # --------------------------------------------------
    print("\n" + "=" * 100)
    print("RISULTATI - METRICHE COMPLETE")
    print("=" * 100 + "\n")

    # Ordina per nDCG (migliore prima)
    summary = summary.sort_values('ndcg', ascending=False)

    # Stampa tabella formattata
    print(f"{'Algorithm':<15} {'nDCG':>8} {'Recall':>8} {'Prec':>8} "
          f"{'RecRank':>8} {'HitRate':>8} {'MAE':>8} {'RMSE':>8} "
          f"{'Cov%':>6} {'Div':>6}")
    print("-" * 105)

    for _, row in summary.iterrows():
        mae_str = f"{row['MAE']:.4f}" if pd.notna(row.get('MAE')) else "N/A"
        rmse_str = f"{row['RMSE']:.4f}" if pd.notna(row.get('RMSE')) else "N/A"

        print(f"{row['Algorithm']:<15} "
              f"{row['ndcg']:>8.4f} "
              f"{row['recall']:>8.4f} "
              f"{row['precision']:>8.4f} "
              f"{row['recip_rank']:>8.4f} "
              f"{row['hit_rate']:>8.4f} "
              f"{mae_str:>8} "
              f"{rmse_str:>8} "
              f"{row['coverage']*100:>6.1f} "
              f"{row['diversity']:>6.3f}")

    # Salva risultati
    output_path = Path('./evaluation_results/recommendation_evaluation_full.csv')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    summary.to_csv(output_path, index=False)
    print(f"\n✓ Risultati salvati in: {output_path}")

    # --------------------------------------------------
    # 8. GENERAZIONE GRAFICI
    # --------------------------------------------------
    print("\n5. Generazione grafici...")

    fig, axes = plt.subplots(2, 4, figsize=(20, 10))
    fig.suptitle('Confronto Algoritmi di Raccomandazione',
                 fontsize=16, fontweight='bold')

    metrics_to_plot = [
        ('ndcg', 'nDCG'),
        ('recall', 'Recall'),
        ('precision', 'Precision'),
        ('hit_rate', 'Hit Rate'),
        ('MAE', 'MAE (lower is better)'),
        ('RMSE', 'RMSE (lower is better)'),
        ('coverage', 'Catalog Coverage'),
        ('diversity', 'Diversity')
    ]

    for ax, (metric, title) in zip(axes.flat, metrics_to_plot):
        plot_data = summary[['Algorithm', metric]].dropna()

        if len(plot_data) == 0:
            ax.text(0.5, 0.5, 'N/A', ha='center', va='center')
            ax.set_title(title, fontweight='bold', fontsize=11)
            continue

        # Ordina (inverti per MAE/RMSE dove lower is better)
        ascending = metric in ['MAE', 'RMSE']
        plot_data = plot_data.sort_values(metric, ascending=ascending)

        # Evidenzia CosineSim in verde
        colors = ['green' if algo == 'CosineSim' else 'steelblue'
                  for algo in plot_data['Algorithm']]

        ax.bar(range(len(plot_data)), plot_data[metric],
               color=colors, alpha=0.7)
        ax.set_title(title, fontweight='bold', fontsize=11)
        ax.set_ylabel('Score')
        ax.set_xlabel('Algoritmo')
        ax.set_xticks(range(len(plot_data)))
        ax.set_xticklabels(plot_data['Algorithm'], rotation=45,
                          ha='right', fontsize=9)
        ax.grid(axis='y', alpha=0.3)

    plt.tight_layout()
    plot_path = Path('./evaluation_results/recommendation_comparison_full.png')
    plt.savefig(plot_path, dpi=300, bbox_inches='tight')
    print(f"✓ Grafico salvato in: {plot_path}")

    # --------------------------------------------------
    # 9. GRAFICI DISTRIBUZIONE PER UTENTE
    # --------------------------------------------------
    print("\n6. Analisi distribuzione per utente...")

    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    user_metrics = results.reset_index()

    # Box plot nDCG
    sns.boxplot(data=user_metrics, x='Algorithm', y='ndcg', ax=axes[0])
    axes[0].set_title('Distribuzione nDCG per Utente', fontweight='bold')
    axes[0].set_xticklabels(axes[0].get_xticklabels(), rotation=45, ha='right')
    axes[0].grid(axis='y', alpha=0.3)

    # Box plot Recall
    sns.boxplot(data=user_metrics, x='Algorithm', y='recall', ax=axes[1])
    axes[1].set_title('Distribuzione Recall per Utente', fontweight='bold')
    axes[1].set_xticklabels(axes[1].get_xticklabels(), rotation=45, ha='right')
    axes[1].grid(axis='y', alpha=0.3)

    plt.tight_layout()
    dist_plot_path = Path('./evaluation_results/metrics_distribution.png')
    plt.savefig(dist_plot_path, dpi=300, bbox_inches='tight')
    print(f"✓ Grafico distribuzione salvato in: {dist_plot_path}")

    plt.show()

    # --------------------------------------------------
    # 10. ANALISI FINALE E RIEPILOGO
    # --------------------------------------------------
    print("\n" + "=" * 100)
    print("ANALISI FINALE")
    print("=" * 100)

    # Miglior algoritmo per nDCG
    best_algo = summary.iloc[0]['Algorithm']
    best_ndcg = summary.iloc[0]['ndcg']
    print(f"\n🏆 MIGLIOR ALGORITMO (nDCG): {best_algo} ({best_ndcg:.4f})")

    # Miglior algoritmo per MAE
    if 'MAE' in summary.columns:
        best_mae = summary.dropna(subset=['MAE']).nsmallest(1, 'MAE')
        if len(best_mae) > 0:
            print(f"📉 MIGLIOR ALGORITMO (MAE): {best_mae.iloc[0]['Algorithm']} "
                  f"({best_mae.iloc[0]['MAE']:.4f})")

    # Analisi specifica CosineSim
    cosine_row = summary[summary['Algorithm'] == 'CosineSim']
    if not cosine_row.empty:
        cosine_rank = summary.reset_index(drop=True).index[
            summary['Algorithm'] == 'CosineSim'
        ].tolist()[0] + 1

        print(f"\n📊 TUO ALGORITMO (CosineSim):")
        print(f"   - Posizione nDCG: {cosine_rank}/{len(summary)}")
        print(f"   - nDCG: {cosine_row['ndcg'].values[0]:.4f}")
        print(f"   - Recall: {cosine_row['recall'].values[0]:.4f}")
        print(f"   - Precision: {cosine_row['precision'].values[0]:.4f}")
        print(f"   - Hit Rate: {cosine_row['hit_rate'].values[0]:.4f}")
        print(f"   - Coverage: {cosine_row['coverage'].values[0]*100:.1f}%")
        print(f"   - Diversity: {cosine_row['diversity'].values[0]:.4f}")

        # Mostra MAE/RMSE se disponibili
        if pd.notna(cosine_row['MAE'].values[0]):
            print(f"   - MAE: {cosine_row['MAE'].values[0]:.4f}")
            print(f"   - RMSE: {cosine_row['RMSE'].values[0]:.4f}")

        # Valutazione qualitativa
        print()
        if cosine_rank == 1:
            print("   🎉 Il tuo algoritmo è il MIGLIORE!")
            print("   Content-based supera collaborative filtering!")
        elif cosine_rank <= 3:
            print("   ✅ OTTIMO RISULTATO! Tra i top 3")
            print("   Content-based molto competitivo con collaborative filtering")
        elif cosine_rank <= len(summary) // 2:
            print("   ✔️  Buone performance nella metà superiore")
            print("   Content-based con margine di miglioramento")
        else:
            print("   ℹ️  Performance sotto la media")
            print("   Considera: più feature, tuning k_neighbors, o approcci ibridi")

        # Analisi punti di forza
        print("\n   💪 PUNTI DI FORZA:")
        if cosine_row['coverage'].values[0] > summary['coverage'].mean():
            print("      • Alta coverage: raccomanda film più diversificati")
        if cosine_row['diversity'].values[0] > summary['diversity'].mean():
            print("      • Alta diversity: evita filter bubble")
        if cosine_row['hit_rate'].values[0] > summary['hit_rate'].mean():
            print("      • Alto hit rate: almeno 1 film rilevante per la maggior parte degli utenti")

        # Analisi aree di miglioramento
        print("\n   🔧 AREE DI MIGLIORAMENTO:")
        if cosine_row['ndcg'].values[0] < summary['ndcg'].mean():
            print("      • nDCG: la rilevanza dei primi risultati può migliorare")
        if cosine_row['recall'].values[0] < summary['recall'].mean():
            print("      • Recall: aumentare k_neighbors o migliorare feature")
        if pd.notna(cosine_row['MAE'].values[0]) and cosine_row['MAE'].values[0] > summary['MAE'].mean():
            print("      • MAE: le predizioni di rating possono essere più accurate")

    # Confronto Content-Based vs Collaborative
    print("\n" + "=" * 100)
    print("CONFRONTO: CONTENT-BASED vs COLLABORATIVE FILTERING")
    print("=" * 100)

    # Identifica il miglior collaborative
    collaborative_algos = ['ItemKNN-20', 'ItemKNN-50', 'ALS', 'UserKNN-30']
    collab_rows = summary[summary['Algorithm'].isin(collaborative_algos)]

    if not collab_rows.empty and not cosine_row.empty:
        best_collab = collab_rows.nsmallest(1, 'ndcg', keep='first').iloc[0]

        print(f"\nContent-Based (CosineSim) vs Collaborative ({best_collab['Algorithm']}):")
        print(f"  nDCG:      {cosine_row['ndcg'].values[0]:.4f} vs {best_collab['ndcg']:.4f}")
        print(f"  Recall:    {cosine_row['recall'].values[0]:.4f} vs {best_collab['recall']:.4f}")
        print(f"  Precision: {cosine_row['precision'].values[0]:.4f} vs {best_collab['precision']:.4f}")
        print(f"  Coverage:  {cosine_row['coverage'].values[0]*100:.1f}% vs {best_collab['coverage']*100:.1f}%")
        print(f"  Diversity: {cosine_row['diversity'].values[0]:.4f} vs {best_collab['diversity']:.4f}")

        # Interpretazione
        print("\n  Interpretazione:")
        if cosine_row['ndcg'].values[0] > best_collab['ndcg']:
            print("  ✅ Content-based vince! Sfrutta bene le feature dei film")
        else:
            print("  ℹ️  Collaborative vince su accuracy, ma content-based ha altri vantaggi:")
            print("     • Funziona con utenti nuovi (no cold start)")
            print("     • Spiega le raccomandazioni ('simile a X')")
            print("     • Non serve storico di altri utenti")

    # Raccomandazioni finali
    print("\n" + "=" * 100)
    print("RACCOMANDAZIONI FINALI")
    print("=" * 100)
    print("\n💡 POSSIBILI MIGLIORAMENTI:")
    print("   1. Aumentare k_neighbors (50 → 100) per più candidati")
    print("   2. Aggiungere più feature (cast, director, keywords)")
    print("   3. Implementare approccio IBRIDO (content + collaborative)")
    print("   4. Aggiungere pesi diversi per tipo di feature")
    print("   5. Normalizzazione avanzata (TF-IDF per genres)")

    print("\n📚 METRICHE CHIAVE DA RICORDARE:")
    print("   • nDCG: Qualità ranking (più alto = primi risultati più rilevanti)")
    print("   • Recall: Capacità di trovare item rilevanti (più alto = trova di più)")
    print("   • Coverage: Diversità catalogo (più alto = raccomanda item vari)")
    print("   • Diversity: Varietà raccomandazioni (più alto = evita filter bubble)")
    print("   • MAE/RMSE: Accuratezza predizioni (più basso = migliore)")

    print("\n" + "=" * 100)
    print("✅ VALUTAZIONE COMPLETATA!")
    print("=" * 100)
    print(f"\nRisultati salvati in: ./evaluation_results/")
    print("  • recommendation_evaluation_full.csv (metriche)")
    print("  • recommendation_comparison_full.png (confronto algoritmi)")
    print("  • metrics_distribution.png (distribuzione per utente)")

# ========================================
# ENTRY POINT
# ========================================
if __name__ == '__main__':
    main()