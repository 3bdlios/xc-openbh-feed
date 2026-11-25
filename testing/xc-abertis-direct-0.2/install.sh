#!/bin/sh
set -eu
[ "$(uname -m)" = aarch64 ] || { echo 'XC Abertis 0.6 requires ARM64 OpenBH XC'; exit 1; }
TASKDIR=$(mktemp -d /tmp/xc-abertis.XXXXXX)
trap 'rm -rf "$TASKDIR"' EXIT HUP INT TERM
wget -q -O "$TASKDIR/xc-abertis.ipk" https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-abertis-direct-0.2/enigma2-plugin-extensions-xcabertisdirect_0.6-r0_cortexa55.ipk
printf '%s  %s\n' 33ab4ffdf01e555fdf78ebe0ebf2052bb112516c101236f57b62725e3b9c5d68 "$TASKDIR/xc-abertis.ipk" | sha256sum -c -
opkg install "$TASKDIR/xc-abertis.ipk"
echo 'Installed XC Abertis 0.6 (experimental). Restart Enigma2 GUI and open the plugin.'
echo 'Green enables playback. Blue updates keys. Yellow scans Hispasat 30W.'
echo 'Receiver reception and channel playback still require testing.'
