#!/usr/bin/env python3
"""Publish single packages into the XC system feed without rebuilding the whole feed.

Usage (from the repository root): tools/add_package.py <ipk> [<ipk>...]
Each ipk replaces any older file of the same package in its architecture directory,
and Packages, Packages.gz and manifest.json are updated in the same format
build_system_feed.py writes.
"""
import gzip
import hashlib
import json
import pathlib
import shutil
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_system_feed as b

OUT = pathlib.Path('feeds/openbh-6.0/xconn')


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    manifest = json.loads((OUT / 'manifest.json').read_text())
    for arg in sys.argv[1:]:
        ipk = pathlib.Path(arg)
        control, blob = b.read_control(ipk)
        fields = b.parse(control)
        name, arch = fields['Package'], fields['Architecture']
        dest = OUT / arch
        blocks = [x for x in (dest / 'Packages').read_text().strip().split('\n\n') if b.parse(x)['Package'] != name]
        blocks.append('%s\nFilename: %s\nSize: %d\nMD5Sum: %s\nSHA256sum: %s' % (
            control.strip(), ipk.name, len(blob), hashlib.md5(blob).hexdigest(), hashlib.sha256(blob).hexdigest()))
        blocks.sort(key=lambda x: b.parse(x)['Package'])
        text = '\n\n'.join(blocks) + '\n\n'
        for old in dest.glob(name + '_*.ipk'):
            old.unlink()
        shutil.copy2(ipk, dest / ipk.name)
        (dest / 'Packages').write_text(text)
        (dest / 'Packages.gz').write_bytes(gzip.compress(text.encode(), mtime=0))
        manifest['packages'] = [p for p in manifest['packages'] if p['Package'] != name] + [{
            'Package': name, 'Version': fields['Version'], 'Architecture': arch,
            'License': fields.get('License', ''), 'SHA256sum': hashlib.sha256(blob).hexdigest(), 'Size': len(blob)}]
        print('%s %s -> %s' % (name, fields['Version'], dest))
    order = {a: i for i, a in enumerate(b.ARCHS + b.STATIC)}
    manifest['packages'].sort(key=lambda p: (order.get(p['Architecture'], 99), p['Package']))
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=1))


if __name__ == '__main__':
    main()
