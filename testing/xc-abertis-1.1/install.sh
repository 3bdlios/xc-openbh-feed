#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || { echo "Run as root"; exit 1; }
[ "$(uname -m)" = aarch64 ] || { echo "XC OpenBH ARM64 build only"; exit 1; }
command -v opkg >/dev/null || exit 1
[ -d /usr/lib/enigma2/python/Plugins/Extensions ] || exit 1
TASKDIR=$(mktemp -d /tmp/xc-abertis-install.XXXXXX)
trap 'rm -rf "$TASKDIR"' EXIT HUP INT TERM
URL=https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-abertis-1.1
wget -O "$TASKDIR/abertis.ipk" "$URL/enigma2-plugin-extensions-xcabertis_1.1.0-r1_cortexa55.ipk"
printf '%s  %s\n' 01a8d83565115617d0ef48b5de51ca59c4509d17522b7bcf6a24e5f44f757c22 "$TASKDIR/abertis.ipk" | sha256sum -c -
opkg install "$TASKDIR/abertis.ipk"
echo 'Installed. Restart GUI, open XC Abertis, press Green. Reboot is not automatic.'
