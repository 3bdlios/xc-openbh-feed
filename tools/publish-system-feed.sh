#!/bin/sh
# Publish the XC OpenBH system feed (Software Update) from the current XC build.
#   tools/publish-system-feed.sh            build the feed, show the change, ask, push
#   tools/publish-system-feed.sh --dry-run  build the feed only
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)
BUILD=/home/user/Documents/ChatGPT/DreamPc/xconn-multiboot/openbh-xc-full/upstream/build-environment
DEPLOY=$BUILD/builds/openbh/release/xconn/tmp/deploy
LAYER=$BUILD/meta-oe-alliance/meta-brands/meta-xconn
MANIFEST=$(ls -t $DEPLOY/images/xconn/*.manifest | head -1)
EXTRA=$(ls $LAYER/recipes-bsp | grep '^xc-' | tr '\n' ',')openbh-bootlogo
EXTRA=$EXTRA,$(grep -v '^#' "$(dirname "$0")/extra-packages.txt" | grep . | tr '\n' ',')

# Compare against what is published (origin/main), never against a previous local run.
cd $REPO
git fetch -q origin
git reset -q -- feeds/openbh-6.0/xconn 2>/dev/null || true
git checkout -q origin/main -- feeds/openbh-6.0/xconn 2>/dev/null || true
git clean -fdq feeds/openbh-6.0/xconn
python3 $REPO/tools/build_system_feed.py $DEPLOY $MANIFEST --extra "$EXTRA"
cd $REPO
git add -A feeds/openbh-6.0/xconn
git status --short feeds/openbh-6.0/xconn | awk '{print $1}' | sort | uniq -c
[ "$1" = "--dry-run" ] && exit 0
printf 'Push this feed update to GitHub? [y/N] '; read answer
[ "$answer" = y ] || { echo "not pushed"; exit 0; }
git commit -m "System feed: $(basename $MANIFEST .manifest) $(date +%Y-%m-%d)"
git push origin main
