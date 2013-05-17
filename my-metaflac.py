#!/usr/bin/env python
import mutagen.flac
import sys
for file in sys.argv[1:]:
    meta = mutagen.flac.FLAC(file)
    for key in meta:
        print key, meta[key]
