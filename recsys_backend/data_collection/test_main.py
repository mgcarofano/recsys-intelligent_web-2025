import requests
from lxml import html

# Ottiene l'URL del poster da una pagina Wikipedia
def get_wikipedia_poster_url(wiki_url):
    """
    Estrae l'URL dell'immagine del poster da una pagina Wikipedia del film.
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


# === FUNZIONE: Scarica un'immagine da un URL locale ===
def download_image(url, filename):
    """
    Scarica l'immagine dall'URL e la salva localmente con il nome specificato.
    """
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        print(f"Immagine salvata in {filename}!")
    else:
        print(f"Attenzione: è fallito il download dell'immagine: status code {response.status_code}")


# === ESEMPIO DI UTILIZZO ===
if __name__ == "__main__":
    wiki_url = "https://en.wikipedia.org/wiki/The_Dark_Knight_(film)"
    poster_url = get_wikipedia_poster_url(wiki_url)
    if poster_url:
        print("Poster URL:", poster_url)
        download_image(poster_url, "dark_knight_poster.jpg")
