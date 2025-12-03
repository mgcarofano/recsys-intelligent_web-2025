"""

    test_main.py \n
    by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

    Questo file permette di eseguire un semplice test per l'estrazione
    dell'URL del poster di un film dalla sua pagina Wikipedia, e di
    scaricare l'immagine localmente.

"""

#   ########################################################################    #
#   LIBRERIE

import requests
from lxml import html

#   ########################################################################    #
#   FUNZIONI

# Ottiene l'URL del poster da una pagina Wikipedia
def get_wikipedia_poster_url(wiki_url) -> str | None:
    """Estrae l'URL dell'immagine del poster da una pagina Wikipedia del film.

    Args:
        wiki_url (str): L'URL della pagina Wikipedia del film.
    
    Returns:
        (str | None): L'URL dell'immagine del poster, o None se non trovato.
    """

    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; example-bot/1.0; +https://example.com/bot)"
    }

    # Effettua la richiesta HTTP alla pagina Wikipedia
    response = requests.get(wiki_url, headers=headers)
    if response.status_code != 200:
        print(f"Attenzione: errore nel fetch dalla pagina Wikipedia: status code {response.status_code}")
        return None

    # Parsing del contenuto HTML della pagina
    tree = html.fromstring(response.content)

    # XPath per selezionare l'immagine del poster
    xpath = "/html/body/div[2]/div/div[3]/main/div[3]/div[3]/div[1]/table[1]/tbody/tr[2]/td/span/a/img"
    img_elements = tree.xpath(xpath)
    if not img_elements:
        print("Attenzione: nessuna immagine trovata sul dato XPath.")
        return None

    # Estrazione dell'attributo 'src' dell'immagine
    img = img_elements[0]
    src = img.get('src')

    # Normalizzazione URL (gestione URL relativi)
    if src.startswith("//"):
        src = "https:" + src
    elif src.startswith("/"):
        src = "https://en.wikipedia.org" + src

    return src

    # end

def download_image(url, filename) -> None:
    """Scarica l'immagine dall'URL e la salva localmente con il nome specificato.

    Args:
        url (str): L'URL dell'immagine da scaricare.
        filename (str): Il nome del file in cui salvare l'immagine.
    
    Returns:
        None
    """

    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        print(f"Immagine salvata in {filename}!")
    else:
        print(f"Attenzione: è fallito il download dell'immagine: status code {response.status_code}")
    
    # end

#   ########################################################################    #
#   ESEMPIO DI UTILIZZO

if __name__ == "__main__":
    wiki_url = "https://en.wikipedia.org/wiki/The_Dark_Knight_(film)"
    poster_url = get_wikipedia_poster_url(wiki_url)
    if poster_url:
        print("Poster URL:", poster_url)
        download_image(poster_url, "dark_knight_poster.jpg")