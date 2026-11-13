# XC OpenBH dependency feed

A curated dependency feed for the custom XCONN X-CYBER OpenBH 6.0 build:
Python 3.14.9, glibc 2.44, ARM64 cortexa55.

This is an independent XC build feed, not an official OpenBH repository.
It contains Python runtime libraries built together with this image, not firmware,
receiver settings, accounts, softcams, Enigma2, bootloaders or XC drivers.

The first snapshot includes permissively licensed runtime packages. Package licenses
and upstream links are in `manifest.json`; supplied notices are under `licenses/`.
Packages excluded from this snapshot are listed explicitly in the manifest.
Not every third-party plugin or native Python extension is supported.

## Installation on the matching image

Download `install-feed.sh`, inspect it and run it as root. It checks the XCONN model,
ARM64, Python 3.14 and glibc 2.44 before writing one feed configuration.
It refreshes package indexes; it does not upgrade installed packages.

Example check after setup: `opkg install python3-compile` then `python3 -c "import py_compile"`.

## Feed URLs

- `https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/feeds/openbh-6.0/py3.14/all`
- `https://raw.githubusercontent.com/3bdlios/xc-openbh-feed/main/feeds/openbh-6.0/py3.14/cortexa55`

Feed entries contain original package versions, sizes and SHA256 hashes.
Use only on the matching XC image. Do not replace a different receiver's feeds.

## Rebuild

Run `python3 tools/build_feed.py /path/to/matching/build/tmp/deploy`.
The exporter verifies original SHA256 hashes and copies only selected runtime packages.
