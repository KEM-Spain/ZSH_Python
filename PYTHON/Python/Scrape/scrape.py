import re

import requests
from bs4 import BeautifulSoup as bs

r = requests.get("https://keithgalli.github.io/web-scraping/example.html")

soup = bs(r.content, features="html.parser")

print(soup.prettify())

first_header = soup.find("h2")
print('first:', first_header)

first_header = soup.find_all("h2")
print('all:', first_header)

first_header = soup.find(["h1", "h2"])
print('first:', first_header)

first_header = soup.find_all(["h1", "h2"])
print('all:', first_header)

paragraph = soup.find_all("p")
print('paragraph:', paragraph)

paragraph = soup.find_all("p", attrs={"id": "paragraph-id"})
print('paragraph:', paragraph)

body = soup.find('body')
div = body.find('div')
header = div.find('h1')
print('header:', header)

paragraph = soup.find_all("p", string=re.compile("Some"))
print('paragraph:', paragraph)

headers = soup.find_all("h2", string=re.compile("([Hh])eader"))
print('headers:', headers)

content = soup.select("div p")
print('content:', content)

# h2 preceded by p
paragraphs = soup.select("h2 ~ p")
print('paragraphs:', paragraphs)

bold_text = soup.select("p#paragraph-id b")
print('bold_text:', bold_text)

# p is direct descendant of body
paragraphs = soup.select("body > p")
print('paragraphs:', paragraphs)

for paragraph in paragraphs:
    print(paragraph.select("i"))

middle = soup.select("[align=middle]")
print('middle:', middle)

div = soup.find("div")
print("\ndiv prettify\n", div.prettify())
print("\ndiv get_text\n", div.get_text())

link = soup.find("a")
print('link:', link)

paragraphs = soup.select("p#paragraph-id")
print(paragraphs[0]['id'])
