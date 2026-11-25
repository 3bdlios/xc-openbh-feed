#!/bin/sh
set -eu
[ "$(uname -m)" = aarch64 ] || { echo 'This test build requires ARM64 XC OpenBH 6'; exit 1; }
TASKDIR=$(mktemp -d /tmp/xc-abertis-direct.XXXXXX)
trap 'rm -rf "$TASKDIR"' EXIT HUP INT TERM
wget -O "$TASKDIR/direct.ipk" https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-abertis-direct-0.2/enigma2-plugin-extensions-xcabertisdirect_0.3-r0_cortexa55.ipk
printf '%s  %s\n' b6e3001eb46ffadf0775003a65baabfb1818fbb33b61fa3086e21614f9b55ce8 "$TASKDIR/direct.ipk" | sha256sum -c -
opkg install "$TASKDIR/direct.ipk"
echo 'Experimental direct path installed DISABLED. Restart GUI, open XC Abertis Direct TEST.'
echo 'Disable old XCAbertis/Astra first. Green adds the direct bouquet; Yellow selects your existing keyfile.'
echo 'Blue updates user-configured key sources with a backup. Hispasat RF/inner-TS playback still needs testing. Normal update feeds are unchanged.'
