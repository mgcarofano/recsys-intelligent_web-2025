import requests
from lxml import html
from SPARQLWrapper import SPARQLWrapper, JSON


class DBpediaLoader:
    def __init__(self, title, year=None, endpoint="https://dbpedia.org/sparql"):
        """
        Classe per estrarre metadati di film da DBpedia.
        - title: titolo del film
        - year: anno (opzionale, usato per disambiguare)
        - endpoint: endpoint SPARQL (default: DBpedia pubblico)
        """
        self.sparql = SPARQLWrapper(endpoint)
        self.title = title
        self.year = year
        self.film_uri = None
        self.results = {}

        # Attributi attivi per default (si possono disattivare con configure)
        self.use_attributes = {
            "actors": True,
            "directors": True,
            "genres": True,
            "producers": True,
            "composers": True,
            "writers": True,
            "production_companies": True,
            "subjects": True,
            "wikipedia": True,
            "abstract": True
        }

    def configure(self, **kwargs):
        """
        Permette di attivare/disattivare il recupero di specifiche categorie.
        Esempio: loader.configure(actors=False, abstract=True)
        """
        for key, value in kwargs.items():
            if key in self.use_attributes:
                self.use_attributes[key] = value

    def build_query(self, property_name, use_label=True, is_literal=False):
        """
        Costruisce dinamicamente una query SPARQL in base alla proprietà.
        - use_label: se True, usa rdfs:label per ottenere etichette leggibili.
        - is_literal: se True, filtra i valori letterali (es. abstract in inglese).
        """
        resource_uri = f"<{self.film_uri}>"

        # Caso speciale: URL Wikipedia (foaf:isPrimaryTopicOf)
        if property_name == "foaf:isPrimaryTopicOf":
            return f"""
            PREFIX foaf: <http://xmlns.com/foaf/0.1/>
            SELECT DISTINCT ?sharedValue WHERE {{
                {resource_uri} foaf:isPrimaryTopicOf ?sharedValue .
            }} LIMIT 1
            """

        # Query per valori testuali (es. abstract)
        if is_literal:
            return f"""
            SELECT DISTINCT ?sharedValue
            WHERE {{
                {resource_uri} dbo:{property_name} ?sharedValue .
                FILTER(lang(?sharedValue) = "en")
            }}
            LIMIT 1
            """

        # Query per entità collegate con etichetta
        if use_label:
            return f"""
            SELECT DISTINCT ?sharedValueLabel
            WHERE {{
                {resource_uri} dbo:{property_name} ?sharedValue .
                ?sharedValue rdfs:label ?sharedValueLabel .
                FILTER(lang(?sharedValueLabel) = "en")
            }}
            ORDER BY ?sharedValueLabel
            """
        else:
            # Query più diretta (senza label)
            return f"""
            SELECT DISTINCT ?sharedValue
            WHERE {{
                {resource_uri} dcterms:{property_name} ?sharedValue .
            }}
            ORDER BY ?sharedValue
            """

    def run_query(self, query):
        """Esegue una query SPARQL e restituisce i risultati come lista di binding."""
        self.sparql.setQuery(query)
        self.sparql.setReturnFormat(JSON)
        results = self.sparql.query().convert()
        return results["results"]["bindings"]

    def resolve_film_uri(self):
        """
        Tenta di risolvere l’URI DBpedia del film costruendo possibili varianti:
        - Titolo con anno + "_film"
        - Titolo + "_film"
        - Solo titolo
        """
        base_title = self.title.replace(',', '').replace(' ', '_')

        candidates = []
        if self.year:
            candidates.append(
                f"http://dbpedia.org/resource/{base_title}_({self.year}_film)")
        candidates.append(f"http://dbpedia.org/resource/{base_title}_(film)")
        candidates.append(f"http://dbpedia.org/resource/{base_title}")

        for candidate in candidates:
            # Verifica se la risorsa candidata esiste e ha proprietà tipiche dei film
            ask_query = f"""
            ASK WHERE {{
            <{candidate}> ?p ?o .
            FILTER(?p IN (
                dbo:starring,
                dbo:director,
                dbo:writer,
                dbo:genre,
                dbo:producer,
                dbo:musicComposer
            ))
            }}
            """
            self.sparql.setQuery(ask_query)
            self.sparql.setReturnFormat(JSON)
            try:
                if self.sparql.query().convert()["boolean"]:
                    self.film_uri = candidate
                    return True
            except Exception as e:
                print(f"⚠️  Error checking {candidate}: {e}")
        return False

    def execute(self) -> None:
        """
        Esegue il caricamento dei metadati del film su DBpedia in base
        alle categorie abilitate da `self.use_attributes`.
        """
        if not self.resolve_film_uri():
            print(f"Attenzione: film \"{self.title}\" non trovato su DBpedia.")
            print(f"Attenzione. skip perché non esiste una risorsa DBpedia valida.")
            return

        mapping = {
            "actors": "starring",
            "directors": "director",
            "genres": "genre",
            "producers": "producer",
            "composers": "musicComposer",
            "writers": "writer",
            "production_companies": "productionCompany",
            "subjects": "subject",
            "wikipedia": "foaf:isPrimaryTopicOf",
            "abstract": "abstract"
        }

        for key, enabled in self.use_attributes.items():
            if not enabled:
                continue

            property_name = mapping[key]

            # Ogni categoria ha una query leggermente diversa
            if key == "subjects":
                query = self.build_query(property_name, use_label=False)
            elif key == "wikipedia":
                query = self.build_query(property_name, use_label=False)
            elif key == "abstract":
                query = self.build_query(property_name, is_literal=True)
            else:
                query = self.build_query(property_name)

            self.results[key] = self.run_query(query)

    def print_results(self, max_results=3, limit_results=True):
        """
        Stampa i risultati ottenuti in console.
        - max_results: massimo numero di elementi da mostrare per categoria
        - limit_results: se True limita, altrimenti mostra tutti
        """
        all_empty = True

        for category, bindings in self.results.items():
            print(f"\n🟦 {category.replace('_', ' ').capitalize()}:")
            if not bindings:
                print("   Nessun risultato.")
                continue

            all_empty = False
            to_display = bindings[:max_results] if limit_results else bindings

            for result in to_display:
                shared_value = result.get("sharedValueLabel", {}).get("value") \
                    or result.get("sharedValue", {}).get("value", "N/A")

                # Rimozione prefisso "Category:" dalle categorie DBpedia
                if shared_value.startswith("http://dbpedia.org/resource/Category:"):
                    shared_value = shared_value.rsplit(
                        "Category:", 1)[-1].replace("_", " ")

                print(f"🎬 {shared_value}")

        if all_empty:
            print("\nAttenzione: nessun risultato trovato per nessuna categoria.")

    def get_results_dict(self, limit_results=False, max_results=3):
        """
        Restituisce i risultati come dizionario: {categoria: [valori]}.
        Utile per uso programmatico invece che per la stampa.
        """
        results_dict = {}

        for category, bindings in self.results.items():
            entries = []
            to_process = bindings[:max_results] if limit_results and max_results else bindings

            for result in to_process:
                shared_value = result.get("sharedValueLabel", {}).get("value") \
                    or result.get("sharedValue", {}).get("value", "N/A")

                if shared_value.startswith("http://dbpedia.org/resource/Category:"):
                    shared_value = shared_value.rsplit(
                        "Category:", 1)[-1].replace("_", " ")

                entries.append(shared_value)

            results_dict[category] = entries

        return results_dict

    def get_poster_url(self):
        """
        Estrae l’URL del poster da Wikipedia usando XPath.
        Ritorna None se non trovato.
        """
        if "wikipedia" not in self.results or not self.results["wikipedia"]:
            print("Wikipedia URL non disponibile.")
            return None

        wikipedia_url = self.results["wikipedia"][0]["sharedValue"]["value"]
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; DBpediaLoaderBot/1.0; +https://example.com/bot)"
        }

        try:
            response = requests.get(wikipedia_url, headers=headers)
            if response.status_code != 200:
                print(f"Attenzione: impossibile caricare pagina Wikipedia, codice: {response.status_code}")
                return None

            tree = html.fromstring(response.content)
            xpath = "/html/body/div[2]/div/div[3]/main/div[3]/div[3]/div[1]/table[1]/tbody/tr[2]/td/span/a/img"
            img_elements = tree.xpath(xpath)
            if not img_elements:
                print("Poster non trovato nella pagina Wikipedia.")
                return None

            img = img_elements[0]
            src = img.get("src")
            if src.startswith("//"):
                src = "https:" + src
            elif src.startswith("/"):
                src = "https://en.wikipedia.org" + src
            return src

        except Exception as e:
            print(f"Attenzione: errore nell estrazione dell immagine poster: {e}")
            return None

    def download_poster(self, output_filename="poster.jpg"):
        """
        Scarica il poster (se disponibile) e lo salva in un file.
        Ritorna True se il download ha successo, False altrimenti.
        """
        poster_url = self.get_poster_url()
        if not poster_url:
            print("Nessun URL di poster trovato.")
            return False

        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; DBpediaLoaderBot/1.0; +https://example.com/bot)"
        }

        try:
            response = requests.get(poster_url, headers=headers, stream=True)
            if response.status_code == 200:
                with open(output_filename, "wb") as f:
                    for chunk in response.iter_content(1024):
                        f.write(chunk)
                print(f"Poster salvato come: {output_filename}!")
                return True
            else:
                print(f"Attenzione: errore nel download poster, codice: {response.status_code}")
                return False
        except Exception as e:
            print(f"Attenzione: eccezione durante il download poster: {e}")
            return False
