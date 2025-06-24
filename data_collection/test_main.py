import requests
from lxml import html


def get_wikipedia_poster_url(wiki_url):
    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; example-bot/1.0; +https://example.com/bot)"
    }
    response = requests.get(wiki_url, headers=headers)
    if response.status_code != 200:
        print(
            f"Failed to fetch Wikipedia page: status code {response.status_code}")
        return None

    tree = html.fromstring(response.content)
    xpath = "/html/body/div[2]/div/div[3]/main/div[3]/div[3]/div[1]/table[1]/tbody/tr[2]/td/span/a/img"
    img_elements = tree.xpath(xpath)
    if not img_elements:
        print("No image found at given XPath.")
        return None

    img = img_elements[0]
    src = img.get('src')
    if src.startswith("//"):
        src = "https:" + src
    elif src.startswith("/"):
        src = "https://en.wikipedia.org" + src
    return src


def download_image(url, filename):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        print(f"✅ Image saved to {filename}")
    else:
        print(
            f"❌ Failed to download image: status code {response.status_code}")


# Example usage:
wiki_url = "https://en.wikipedia.org/wiki/The_Dark_Knight_(film)"
poster_url = get_wikipedia_poster_url(wiki_url)
if poster_url:
    print("Poster URL:", poster_url)
    download_image(poster_url, "dark_knight_poster.jpg")
