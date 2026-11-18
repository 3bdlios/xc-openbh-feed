#!/bin/sh
# XC Support Report installer: always installs the latest xc-report from the XC feed, then restarts the GUI.
# Usage: wget https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/xc-report-installer.sh -O - | /bin/sh
FEED=https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/feeds/openbh-6.0/xconn/cortexa55
TMP=/tmp/xc-report.ipk

echo '>>> XC Support Report installer'
[ "$(id -u)" = 0 ] || { echo 'Run as root'; exit 1; }
case "$(uname -m)" in aarch64|arm64) ;; *) echo 'Requires an ARM64 (XC) receiver'; exit 1;; esac

IPK=$(wget -qO- "$FEED/Packages.gz" | gunzip -c | sed -n 's/^Filename: \(xc-report_.*\.ipk\)$/\1/p' | head -n 1)
[ -n "$IPK" ] || { echo 'Could not read the XC feed (check the internet connection)'; exit 1; }
echo ">>> Downloading $IPK"
wget -qO "$TMP" "$FEED/$IPK" || { rm -f "$TMP"; echo 'Download failed'; exit 1; }

echo '>>> Installing'
opkg update >/dev/null 2>&1
if ! opkg install --force-reinstall "$TMP"; then
	rm -f "$TMP"; echo 'Install failed'; exit 1
fi
rm -f "$TMP"

echo '>>> Done. Restarting the GUI: open Plugins > XC Support Report'
sleep 2
wget -qO- "http://127.0.0.1/api/powerstate?newstate=3" >/dev/null 2>&1 || killall -9 enigma2
exit 0
