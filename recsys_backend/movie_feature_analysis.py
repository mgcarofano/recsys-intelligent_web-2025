import numpy as np
import matplotlib.pyplot as plt
from scipy.sparse import load_npz
import sys
import matplotlib.ticker as ticker  # Importa il modulo ticker per la formattazione

# Tenta di importare il percorso della matrice dal tuo file constants.py
# ... (il codice di importazione rimane invariato)
try:
    from constants import MOVIE_FEATURE_MATRIX_PATH
except ImportError:
    print("Errore: Impossibile trovare 'constants.py'.")
    print("Assicurati di eseguire questo script dalla directory principale del progetto.")
    MOVIE_FEATURE_MATRIX_PATH = './data/movie_features_matrix.npz'
except AttributeError:
    print("Errore: 'MOVIE_FEATURE_MATRIX_PATH' non trovato in 'constants.py'.")
    sys.exit(1)

def analizza_distribuzione_feature(matrix_path):
    """
    Carica la matrice movie-feature, calcola il numero di film per feature
    e genera un grafico della distribuzione "long-tail" log-log.
    """
    print(f"Caricamento matrice da: {matrix_path}...")
    try:
        movie_features_matrix = load_npz(matrix_path)
    except FileNotFoundError:
        print(f"Errore: File non trovato a '{matrix_path}'.")
        print("Verifica il percorso in 'constants.py'.")
        return
    except Exception as e:
        print(f"Errore durante il caricamento della matrice: {e}")
        return

    print("Matrice caricata. Calcolo del numero di film per feature...")

    films_per_feature = np.asarray(movie_features_matrix.sum(axis=0)).ravel()
    sorted_counts = np.sort(films_per_feature)[::-1]
    sorted_counts = sorted_counts[sorted_counts > 0]

    num_features = len(sorted_counts)
    if num_features == 0:
        print("Nessuna feature trovata con film associati.")
        return

    print(f"Calcolo completato. Trovate {num_features} feature con almeno 1 film.")
    print(f"Feature più popolare ha: {sorted_counts[0]} film")
    print(f"Feature meno popolare ha: {sorted_counts[-1]} film")

    # Creazione dell'asse X come percentuale
    # Va da (1/num_features) * 100% a (num_features/num_features) * 100%
    x_axis_percentage = (np.arange(1, num_features + 1) / num_features) * 100

    # --- Creazione del Grafico ---
    print("Generazione del grafico...")

    plt.figure(figsize=(12, 7))
    plt.plot(x_axis_percentage, sorted_counts, linewidth=2, color='b') # 'b' per blu

    # --- MODIFICHE PRINCIPALI ---

    # 1. Usiamo una scala logaritmica per ENTRAMBI gli assi
    plt.yscale('log')
    plt.xscale('log')  # <-- QUESTA È LA MODIFICA CHIAVE

    # 2. Aggiorniamo titoli ed etichette
    plt.title('Distribuzione Log-Log della Popolarità delle Feature', fontsize=16)
    plt.xlabel('Percentuale di Feature (ordinate per popolarità, Scala Log)', fontsize=12)
    plt.ylabel('Numero di Film Associati (Scala Log)', fontsize=12)

    # 3. Impostiamo i tick sull'asse X per mostrare le percentuali su scala log
    #    Questo crea etichette leggibili come "1%", "10%" invece di 10^0, 10^1
    ticks = [0.01, 0.1, 1, 10, 100]
    plt.xticks(ticks)
    plt.gca().xaxis.set_major_formatter(ticker.StrMethodFormatter('{x:g}%'))

    # Imposta i limiti dell'asse X per mostrare l'intera gamma fino al 100%
    plt.xlim(None, 100)

    # --- Fine Modifiche ---

    plt.grid(True, which="both", linestyle='--', linewidth=0.5, alpha=0.7)

    # Salva il grafico su file
    output_filename = 'distribuzione_feature_log_log.png' # Nome file aggiornato
    plt.savefig(output_filename, dpi=150, bbox_inches='tight')

    print(f"\nGrafico salvato come '{output_filename}'")
    print("Il grafico ora usa una scala log-log per mostrare meglio la distribuzione")
    print("nella 'testa' (le feature più popolari) e nella 'coda' (quelle di nicchia).")

if __name__ == "__main__":
    analizza_distribuzione_feature(MOVIE_FEATURE_MATRIX_PATH)
