# XC audio r12 — experimental alternative

For XC OpenBH 6 / cortexa55 with the existing xc-audiod r11 dependencies only. Not a universal Enigma2 package. This does not change the kernel, video backend, or normal feed index.

Aligns audio before playback and uses bounded resampling for subsequent drift rather than audible silence insertion or sample cuts. A short receiver test completed without logged underruns; broader channel/codec and listening tests remain necessary. Not a guaranteed fix.

Install (brief audio interruption):
```sh
wget -O /tmp/xc-audiod-r12.ipk https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-audiod_0.1-r12_cortexa55.ipk
opkg install /tmp/xc-audiod-r12.ipk && /etc/init.d/xc-audiod restart
```

Return to r11:
```sh
wget -O /tmp/xc-audiod-r11.ipk https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-audiod_0.1-r11_cortexa55.ipk
opkg install --force-downgrade /tmp/xc-audiod-r11.ipk && /etc/init.d/xc-audiod restart
```

Source and GPL license: `xc-audiod-r12-source.tar.gz`. No package architecture forcing or dependency forcing should be used.
