# XC audio r13 — experimental alternative

For XC OpenBH 6 / cortexa55 with the existing xc-audiod r11 dependencies only. Not a universal Enigma2 package. This does not change the kernel, video backend, or normal feed index.

Persists picture-clock validation across stale decoded frames, so startup catch-up does not sleep again for every discarded frame. Refuses an unaligned start after timeout and retries instead. Aligns audio before playback and uses bounded resampling for subsequent drift rather than audible silence insertion or sample cuts. A receiver listening test confirmed synchronization before and after channel switching. This does not establish compatibility on other receivers or all codecs; broader testing remains necessary. Not a guaranteed fix.

Install (brief audio interruption):
```sh
wget -O /tmp/xc-audiod-r13.ipk https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-audiod_0.1-r13_cortexa55.ipk
opkg install /tmp/xc-audiod-r13.ipk && /etc/init.d/xc-audiod restart
```

Return to r11:
```sh
wget -O /tmp/xc-audiod-r11.ipk https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/testing/xc-audiod_0.1-r11_cortexa55.ipk
opkg install --force-downgrade /tmp/xc-audiod-r11.ipk && /etc/init.d/xc-audiod restart
```

Source and GPL license: `xc-audiod-r13-source.tar.gz`. No package architecture forcing or dependency forcing should be used.
