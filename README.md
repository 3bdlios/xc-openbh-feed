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

## System feed (Software Update)

`feeds/openbh-6.0/xconn/{all,cortexa55,xconn,static-*}` holds every package of the XC
OpenBH image plus the XC packages and their dependencies, one version each. XC images
built from the XC layer point their feed configuration here, so Menu > Setup > System >
Software Update installs every published fix. Package revisions rise automatically with
each rebuild (PR server), which is what makes a fix visible as an update.

Maintainer: `tools/publish-system-feed.sh` (build the index from the last XC build, review, push).
The feed contains GPL software; the corresponding sources are the public upstream
projects (OE-Alliance, OpenEmbedded, BlackHole Enigma2) plus the XC layer changes.
