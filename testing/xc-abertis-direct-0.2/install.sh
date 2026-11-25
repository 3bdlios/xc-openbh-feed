#!/bin/sh
set -eu
[ "$(uname -m)" = aarch64 ] || { echo 'XC Abertis 0.6 requires ARM64 OpenBH XC'; exit 1; }
TASKDIR=$(mktemp -d /tmp/xc-abertis.XXXXXX)
trap 'rm -rf "$TASKDIR"' EXIT HUP INT TERM
wget -q -O "$TASKDIR/xc-abertis.ipk" https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-abertis-direct-0.2/enigma2-plugin-extensions-xcabertisdirect_0.6-r1_cortexa55.ipk
printf '%s  %s\n' 57fc4dd61d8687eea8bf6d8947bed1a958383f0be9d0e7c8741aaa7d0481b2e6 "$TASKDIR/xc-abertis.ipk" | sha256sum -c -
opkg install "$TASKDIR/xc-abertis.ipk"
echo 'Installed XC Abertis 0.6 (experimental). Restart Enigma2 GUI and open the plugin.'
echo 'Green enables playback. Blue updates keys. Yellow scans Hispasat 30W.'
echo 'Receiver reception and channel playback still require testing.'
