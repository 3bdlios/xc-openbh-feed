#!/usr/bin/env python3
"""Export permissively licensed Python runtime packages from one XC build."""
import argparse,gzip,hashlib,json,shutil,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('deploy',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parents[1];manifest=[];skipped=[]
for arch in ('all','cortexa55'):
    source=args.deploy/'ipk'/arch
    dest=root/'feeds/openbh-6.0/py3.14'/arch;dest.mkdir(parents=True,exist_ok=True)
    blocks=[]
    for rec in (source/'Packages').read_text().strip().split('\n\n'):
        d=dict(line.split(': ',1) for line in rec.splitlines() if ': ' in line and not line.startswith(' '))
        n=d.get('Package','');license=d.get('License','')
        if not n.startswith('python3-') or n.endswith(('-dbg','-dev','-src','-doc','-staticdev','-ptest')):continue
        if any(t in license for t in ('GPL','CLOSED','LicenseRef')):
            skipped.append({'name':n,'reason':'not included in this initial permissive runtime feed','license':license});continue
        f=source/d['Filename']
        if hashlib.sha256(f.read_bytes()).hexdigest()!=d['SHA256sum']:raise SystemExit('SHA256 mismatch: '+n)
        shutil.copy2(f,dest/f.name);blocks.append(rec)
        recipe=d.get('OE','').split(':')[-1]
        licdir=args.deploy/'licenses'/('allarch' if arch=='all' else arch)/recipe
        out=root/'licenses'/recipe
        if licdir.is_dir():
            out.mkdir(parents=True,exist_ok=True)
            for lic in licdir.iterdir():
                if lic.is_file() and lic.name!='recipeinfo':shutil.copy2(lic,out/lic.name)
        manifest.append({k:d.get(k,'') for k in ('Package','Version','Architecture','License','HomePage','Source','SHA256sum','Size')})
    text='\n\n'.join(blocks)+'\n\n'
    (dest/'Packages').write_text(text)
    (dest/'Packages.gz').write_bytes(gzip.compress(text.encode(),mtime=0))
(root/'manifest.json').write_text(json.dumps({'target':'XC OpenBH 6.0 / Python 3.14.9 / glibc 2.44 / cortexa55','packages':manifest,'excluded':skipped},indent=2)+'\n')
print('Exported',len(manifest),'packages;',round(sum(int(d['Size']) for d in manifest)/1024**2,1),'MiB; excluded',len(skipped))
