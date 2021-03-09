#!/usr/bin/env python3
import sys, glob
import lxml.etree as ET
from datetime import datetime

base = sys.argv[1]
for f in glob.glob(base + ('/*/_service')):
    tree = ET.parse(f)
    root = tree.getroot()
    for c in root:
        if c.tag is ET.Comment and c.text.find('Bump Config:') >= 0:
            root.remove(c)
        elif c.attrib['name'] == 'webhook':
            root.remove(c)
    comment = ET.Comment(' Bump Config: ' + datetime.now().isoformat(sep=' ', timespec='seconds') + ' ')
    root.append(comment)
    tree.write(f)
