#!/bin/sh
# XC Recovery test for XCONN X-CYBER (OpenBH 6.0 XC):
#  - XC Recovery plugin: the recovery screen inside OpenBH, its operations without a restart
#  - recovery update: "Install online" in the recovery screen, DNS/HTTPS fix for network installs
#  - kernel-xc.img with the PiP fix (active after a reboot)
# Usage: wget https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-recovery-test/install.sh -O - | /bin/sh
URL=https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-recovery-test
FILES="e2fsprogs-resize2fs_1.47.4-r0.0_cortexa55.ipk gptfdisk_1.0.10-r0_cortexa55.ipk xc-recovery-live_1.0-r0_cortexa55.ipk xc-boot-files_1.0-r4_xconn.ipk"
echo '>>> XC Recovery test'
[ "$(id -u)" = 0 ] || { echo 'Run as root'; exit 1; }
grep -q '^box_type=xconn\|xconn' /etc/hostname /etc/image-version 2>/dev/null || { echo 'XCONN X-CYBER only'; exit 1; }
cd /tmp || exit 1
for f in $FILES; do
	echo ">>> Downloading $f"
	wget -q -O "/tmp/$f" "$URL/$f" || { echo "Download failed: $f"; rm -f /tmp/*.ipk; exit 1; }
done
(cd /tmp && sha256sum -c - ) <<SUMS || { echo 'Checksum mismatch'; rm -f /tmp/*.ipk; exit 1; }
d47b2cb253be977a3653bc7904ea9029b978c2f36b1aa53c358f80cb49f99f0f  e2fsprogs-resize2fs_1.47.4-r0.0_cortexa55.ipk
07d2e46bb7029df1ec0bee6eb7c4556c0f133976ed913dc79602c2485e213f97  gptfdisk_1.0.10-r0_cortexa55.ipk
b1566dd398dc132f48bb37fda0c7b55c5995649ae22baed601360c2d3794e8d4  xc-boot-files_1.0-r4_xconn.ipk
53a28bbfb7124886bb483ab858de86c4cd9e7ca3c05d6c66e226b3f39377e4f6  xc-recovery-live_1.0-r0_cortexa55.ipk
SUMS
opkg update >/dev/null 2>&1
echo '>>> Installing'
(cd /tmp && opkg install --force-reinstall $FILES) || { echo 'Install failed'; exit 1; }
(cd /tmp && rm -f $FILES)
tail -4 /boot/xc/boot-update.log 2>/dev/null
echo '>>> Done. Plugins > XC Recovery. Reboot the receiver to start the new kernel.'
echo '>>> Old BOOT files are kept in /boot/xc/boot-rollback/'
sleep 2
wget -qO- "http://127.0.0.1/api/powerstate?newstate=3" >/dev/null 2>&1 || killall -9 enigma2
exit 0
