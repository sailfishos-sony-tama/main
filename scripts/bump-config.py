#!/usr/bin/env python3
import sys, glob
import lxml.etree as ET
from datetime import datetime

base = sys.argv[1]
if len(sys.argv) > 2 and sys.argv[2]=="--config-only":
    S = ['config', 'hal-version']
else:
    S = ['config', 'hal-version', 'droid-hal-*-img-boot']

for T in S:
    for f in glob.glob(base + ('/*%s*/_service' % T)):
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
