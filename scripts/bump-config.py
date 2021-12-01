#!/usr/bin/env python3
import sys, glob, argparse
import lxml.etree as ET
from datetime import datetime

parser = argparse.ArgumentParser(description='Bump configuration files')

parser.add_argument('base', help='OBS directory of the project')
parser.add_argument('--config-version', default=None, help='Version/tag of config project')
parser.add_argument('--config-only', action="store_true", help='Bump only config files')

args = parser.parse_args()

base = args.base
if args.config_only:
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
            if args.config_version and f.find('-img-boot') < 0:
                for cc in c:
                    if cc.attrib["name"] == 'revision':
                        cc.text = args.config_version
                        print(f, 'Set version', args.config_version)
        comment = ET.Comment(' Bump Config: ' + datetime.now().isoformat(sep=' ', timespec='seconds') + ' ')
        root.append(comment)
        tree.write(f)
