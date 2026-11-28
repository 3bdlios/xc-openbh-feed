#!/bin/sh
# XC OpenATV 8.0.1 timeshift test: trick play driver (fast forward, rewind, slow motion,
# no 7 s freeze), enigma2 xcyber9 (no jump to live at the start of the recording) and the
# stock timeline control (XCTimeshiftPreview removed). Undo: sh /home/root/xc-timeshift-test-backup/restore.sh
URL=https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-openatv-timeshift-test
B=/home/root/xc-timeshift-test-backup
M=/lib/modules/5.15.196/extra/aml_hardware_dmx.ko
P=/usr/lib/enigma2/python/Plugins/SystemPlugins/XCTimeshiftPreview
grep -q '^box_type=xconn' /etc/image-version && grep -q '^distro=openatv' /etc/image-version || { echo 'For XC OpenATV 8.0.1 only'; exit 1; }
[ "$(uname -r)" = 5.15.196 ] && [ -f $M ] || { echo 'XC kernel 5.15.196 and its demux driver are required'; exit 1; }
opkg status enigma2 | grep -q 'Version: .*b4ac3bd' || { echo 'This enigma2 build is not supported'; exit 1; }
cd /tmp
for f in aml_hardware_dmx.ko enigma2_8.0.1+git1+b4ac3bd0+b4ac3bd50a-r1.xcyber9_xconn.ipk; do wget -q -O "/tmp/$f" "$URL/$f" || { echo "Download failed: $f"; exit 1; }; done
sha256sum -c - <<SUMS || { echo 'Checksum mismatch'; exit 1; }
30cad7d897eedb7151d4067c2b4a003cea92744002b70d126d1373b4aca4ccf4  aml_hardware_dmx.ko
df4662d4f19c5750b4e0e3370da081b5fbf39725414cacc40850931f692a6d0d  enigma2_8.0.1+git1+b4ac3bd0+b4ac3bd50a-r1.xcyber9_xconn.ipk
SUMS
if [ ! -d $B ]; then
	mkdir -p $B
	cp -p $M $B/aml_hardware_dmx.ko
	cp -p /usr/bin/enigma2 $B/enigma2
	tar czf $B/enigma2-python.tar.gz -C /usr/lib/enigma2 python
	opkg status enigma2 | sed -n 's/^Version: //p' > $B/enigma2.version
	[ -d $P ] && cp -a $P $B/
	cat > $B/restore.sh <<'RESTORE'
#!/bin/sh
B=/home/root/xc-timeshift-test-backup
cp $B/aml_hardware_dmx.ko /lib/modules/5.15.196/extra/aml_hardware_dmx.ko
cp $B/enigma2 /usr/bin/enigma2
tar xzf $B/enigma2-python.tar.gz -C /usr/lib/enigma2
[ -d $B/XCTimeshiftPreview ] && cp -a $B/XCTimeshiftPreview /usr/lib/enigma2/python/Plugins/SystemPlugins/
sync; echo 'Restored. Restart the receiver.'
RESTORE
	chmod 755 $B/restore.sh
fi
cp /tmp/aml_hardware_dmx.ko $M.new && mv $M.new $M
opkg install /tmp/enigma2_8.0.1+git1+b4ac3bd0+b4ac3bd50a-r1.xcyber9_xconn.ipk || { echo 'enigma2 install failed'; exit 1; }
rm -rf $P
rm -f /tmp/aml_hardware_dmx.ko /tmp/enigma2_8.0.1+git1+b4ac3bd0+b4ac3bd50a-r1.xcyber9_xconn.ipk
sync
echo '>>> Done. Restart the receiver to load the new driver. Undo: sh /home/root/xc-timeshift-test-backup/restore.sh'
