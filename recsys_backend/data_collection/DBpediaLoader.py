import requests
from lxml import html
from SPARQLWrapper import SPARQLWrapper, JSON


class DBpediaLoader:
    def __init__(self, title, year=None, endpoint="https://dbpedia.org/sparql"):
        self.sparql = SPARQLWrapper(endpoint)
        self.title = title
        self.year = year
        self.film_uri = None
        self.results = {}

        self.use_attributes = {
            "actors": True,
            "directors": True,
            "genres": True,
            "producers": True,
            "composers": True,
            "writers": True,
            "production_companies": True,
            "subjects": True,
            "wikipedia": True  # NEW: treat like a normal attribute
        }

    def configure(self, **kwargs):
        for key, value in kwargs.items():
            if key in self.use_attributes:
                self.use_attributes[key] = value

    def build_query(self, property_name, use_label=True):
        resource_uri = f"<{self.film_uri}>"

        # Use special property for foaf:isPrimaryTopicOf (Wikipedia URL)
        if property_name == "foaf:isPrimaryTopicOf":
            return f"""
            PREFIX foaf: <http://xmlns.com/foaf/0.1/>
            SELECT DISTINCT ?sharedValue WHERE {{
                {resource_uri} foaf:isPrimaryTopicOf ?sharedValue .
            }} LIMIT 1
            """

        # Standard label-based query
        if use_label:
            query = f"""
            SELECT DISTINCT ?sharedValueLabel
            WHERE {{
                {resource_uri} dbo:{property_name} ?sharedValue .
                ?sharedValue rdfs:label ?sharedValueLabel .
                FILTER(lang(?sharedValueLabel) = "en")
            }}
            ORDER BY ?sharedValueLabel
            """
        else:
            query = f"""
            SELECT DISTINCT ?sharedValue
            WHERE {{
                {resource_uri} dcterms:{property_name} ?sharedValue .
            }}
            ORDER BY ?sharedValue
            """
        return query

    def run_query(self, query):
        self.sparql.setQuery(query)
        self.sparql.setReturnFormat(JSON)
        results = self.sparql.query().convert()
        return results["results"]["bindings"]

    def resolve_film_uri(self):
        base_title = self.title.replace(',', '').replace(' ', '_')

        candidates = []
        if self.year:
            candidates.append(
                f"http://dbpedia.org/resource/{base_title}_({self.year}_film)")
        candidates.append(f"http://dbpedia.org/resource/{base_title}_(film)")
        candidates.append(f"http://dbpedia.org/resource/{base_title}")

        for candidate in candidates:
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
        if not self.resolve_film_uri():
            print(f"⚠️  Film \"{self.title}\" not found on DBpedia.")
            print(f"🚫 Skipping results due to missing DBpedia resource.")
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
            "wikipedia": "foaf:isPrimaryTopicOf"  # Treat like other predicates
        }

        for key, enabled in self.use_attributes.items():
            if enabled:
                property_name = mapping[key]

                if key == "subjects":
                    query = self.build_query(property_name, use_label=False)
                elif key == "wikipedia":
                    query = self.build_query(property_name, use_label=False)
                else:
                    query = self.build_query(property_name)

                self.results[key] = self.run_query(query)

    def print_results(self, max_results=3, limit_results=True):
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

                if shared_value.startswith("http://dbpedia.org/resource/Category:"):
                    shared_value = shared_value.rsplit(
                        "Category:", 1)[-1].replace("_", " ")

                print(f"🎬 {shared_value}")

        if all_empty:
            print("\n⚠️  Nessun risultato trovato per nessuna categoria.")

    def get_results_dict(self, limit_results=False, max_results=3):
        """
        Returns a dictionary mapping each category to a list of its results.
        Useful for programmatic use instead of console output.
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
        Extract the poster image from Wikipedia using XPath.
        """
        if "wikipedia" not in self.results or not self.results["wikipedia"]:
            print("Wikipedia URL not available.")
            return None

        wikipedia_url = self.results["wikipedia"][0]["sharedValue"]["value"]
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; DBpediaLoaderBot/1.0; +https://example.com/bot)"
        }

        try:
            response = requests.get(wikipedia_url, headers=headers)
            if response.status_code != 200:
                print(
                    f"Failed to fetch Wikipedia page, status code: {response.status_code}")
                return None

            tree = html.fromstring(response.content)
            xpath = "/html/body/div[2]/div/div[3]/main/div[3]/div[3]/div[1]/table[1]/tbody/tr[2]/td/span/a/img"
            img_elements = tree.xpath(xpath)
            if not img_elements:
                print("Poster image not found on Wikipedia page using XPath.")
                return None

            img = img_elements[0]
            src = img.get("src")
            if src.startswith("//"):
                src = "https:" + src
            elif src.startswith("/"):
                src = "https://en.wikipedia.org" + src
            return src

        except Exception as e:
            print(f"Error extracting poster URL: {e}")
            return None

    def download_poster(self, output_filename="poster.jpg"):
        """
        Download the poster image if available.
        """
        poster_url = self.get_poster_url()
        if not poster_url:
            print("No poster URL found to download.")
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
                print(f"✅ Poster downloaded as: {output_filename}")
                return True
            else:
                print(
                    f"❌ Failed to download poster, status code: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Error downloading poster image: {e}")
            return False
