#!/usr/bin/env python3

import requests
import sys
from bs4 import BeautifulSoup

if len(sys.argv) < 3:
    print('Downloads the reference(s) starting with the prefix\n\nUsage: %s url prefix_for_rpm [index]' % sys.argv[0])
    sys.exit(-1)

url = sys.argv[1]
prefix = sys.argv[2]
index = sys.argv[3] if len(sys.argv) > 3 else None

index_url = url + '/' + index if index is not None else url

r = requests.get(url)
soup = BeautifulSoup(r.text, 'html.parser')
for link in soup.find_all('a'):
    l = link.get('href')
    if l.find(prefix) > 0:
        if url[-1] != '/': u = url + '/' + l
        else: u = url + l
        print('Downloading', u)
        data = requests.get(u)
        filename = l.strip('/')
        with open(filename, 'wb') as fd:
            for chunk in data.iter_content(chunk_size=1024):
                fd.write(chunk)
