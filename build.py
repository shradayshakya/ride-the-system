#!/usr/bin/env python3
"""Inline a ride-the-system data file into the template.

usage: python3 build.py <data.js> <out.html> [--standalone]

The data file must assign `window.RIDE = { ... }` (see examples/online-store.data.js).
By default the output is an artifact body (the claude.ai artifact host adds <!doctype>, <head>
and the charset). Pass --standalone for a complete HTML document you can open locally or host
anywhere (GitHub Pages, S3...).
"""
import html, pathlib, re, sys

args = [a for a in sys.argv[1:] if not a.startswith('--')]
standalone = '--standalone' in sys.argv[1:]
if len(args) != 2:
    sys.exit(__doc__)
here = pathlib.Path(__file__).resolve().parent
data_path, out_path = map(pathlib.Path, args)
data = data_path.read_text(encoding='utf-8')
if 'window.RIDE' not in data:
    sys.exit('data file must assign window.RIDE = {...}')
if '</script' in data.lower():
    sys.exit('data file must not contain </script>')
m = re.search(r"title:\s*(['\"])(.*?)\1", data)
title = html.escape(m.group(2) if m else 'Ride the system')
page = (here / 'template.html').read_text(encoding='utf-8').replace('__TITLE__', title, 1).replace('/*RIDE_DATA*/', data, 1)
if standalone:
    page = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            '<style>html{color-scheme:light dark}body{margin:0}[hidden]{display:none!important}img{max-width:100%}</style>\n'
            '</head>\n<body>\n' + page + '\n</body>\n</html>\n')
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(page, encoding='utf-8')
print(f'wrote {out_path} ({len(page)} bytes){" [standalone]" if standalone else ""}')
