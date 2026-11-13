#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || { echo 'Run as root'; exit 1; }
[ "$(python3 -c 'import sys;print("%d.%d" % sys.version_info[:2])')" = 3.14 ] || { echo 'Requires matching XC Python 3.14 image'; exit 1; }
case "$(uname -m)" in aarch64|arm64) ;; *) echo 'Requires ARM64'; exit 1;; esac
python3 - <<'PY'
from pathlib import Path
import platform,shutil
model=Path('/proc/device-tree/model').read_bytes().rstrip(b'\0').decode()
if model != 'XCONN' or platform.libc_ver() != ('glibc','2.44'):
    raise SystemExit('Requires matching XCONN XC glibc 2.44 build')
p=Path('/etc/opkg/xc-openbh-python-feed.conf')
if p.exists():shutil.copy2(p,Path('/etc/opkg/xc-openbh-python-feed.conf.before'))
p.write_text('src/gz xc-openbh-python https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/feeds/openbh-6.0/py3.14/cortexa55\n')
PY
opkg update
