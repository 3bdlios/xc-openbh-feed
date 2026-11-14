#!/usr/bin/env python3
"""Build the XC OpenBH system feed (Software Update) from one XC build.

Feed layout: feeds/openbh-6.0/xconn/{all,cortexa55,xconn,static-*}/Packages(.gz)
Package set: everything in the image manifest + the given extra packages + their
dependency closure (Depends/Pre-Depends, resolving Provides). The newest build of each
package is taken straight from the ipk control data (no reliance on a stale index).
Only files referenced by the new index are kept, so the feed holds one version each.
"""
import argparse, gzip, hashlib, io, json, re, shutil, tarfile
from pathlib import Path

ARCHS = ("all", "cortexa55", "xconn")
STATIC = ("static-all", "static-cortexa55", "static-xconn")
SKIP_SUFFIX = ("-dbg", "-dev", "-src", "-staticdev", "-doc", "-ptest", "-locale")
MAX_FILE = 95 * 1024 * 1024


def verrevcmp(a, b):
    def order(c):
        if c.isdigit(): return 0
        if c.isalpha(): return ord(c)
        if c == "~": return -1
        return ord(c) + 256 if c else 0
    i = j = 0
    while i < len(a) or j < len(b):
        diff = 0
        while (i < len(a) and not a[i].isdigit()) or (j < len(b) and not b[j].isdigit()):
            ac = order(a[i]) if i < len(a) else 0
            bc = order(b[j]) if j < len(b) else 0
            if ac != bc: return ac - bc
            i += 1; j += 1
        while i < len(a) and a[i] == "0": i += 1
        while j < len(b) and b[j] == "0": j += 1
        while i < len(a) and j < len(b) and a[i].isdigit() and b[j].isdigit():
            if not diff: diff = ord(a[i]) - ord(b[j])
            i += 1; j += 1
        if i < len(a) and a[i].isdigit(): return 1
        if j < len(b) and b[j].isdigit(): return -1
        if diff: return diff
    return 0


def vercmp(a, b):
    def split(v):
        epoch, _, rest = v.rpartition(":") if ":" in v else ("0", "", v)
        ver, _, rev = rest.rpartition("-") if "-" in rest else (rest, "", "")
        return int(epoch or 0), ver, rev
    ea, va, ra = split(a); eb, vb, rb = split(b)
    return (ea - eb) or verrevcmp(va, vb) or verrevcmp(ra, rb)


def read_control(ipk):
    data = ipk.read_bytes()
    pos = 8
    while pos < len(data):
        name = data[pos:pos + 16].decode().strip().rstrip("/")
        size = int(data[pos + 48:pos + 58].decode().strip())
        body = data[pos + 60:pos + 60 + size]
        pos += 60 + size + (size & 1)
        if name.startswith("control.tar"):
            if name.endswith(".zst"):
                import zstandard
                body = zstandard.ZstdDecompressor().decompressobj().decompress(body)
                mode = "r:"
            else:
                mode = "r:*"
            with tarfile.open(fileobj=io.BytesIO(body), mode=mode) as t:
                member = next(m for m in t.getmembers() if m.name.lstrip("./") == "control")
                return t.extractfile(member).read().decode(), data
    raise ValueError("no control in " + str(ipk))


def parse(text):
    fields, key = {}, None
    for line in text.splitlines():
        if line.startswith((" ", "\t")) and key:
            fields[key] += "\n" + line
        elif ": " in line:
            key, value = line.split(": ", 1); fields[key] = value
    return fields


def deps(field):
    out = []
    for group in filter(None, (g.strip() for g in field.split(","))):
        out.append([re.split(r"\s|\(", alt.strip())[0] for alt in group.split("|")])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("deploy", type=Path, help="tmp/deploy")
    ap.add_argument("manifest", type=Path, help="image .manifest")
    ap.add_argument("--extra", default="", help="extra package names, comma separated")
    ap.add_argument("--allow-same-version", action="store_true",
                    help="publish rebuilt content under an unchanged version (devices will not see it)")
    ap.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "feeds/openbh-6.0/xconn")
    args = ap.parse_args()

    pkgs = {}
    for arch in ARCHS:
        for ipk in sorted((args.deploy / "ipk" / arch).glob("*.ipk")):
            text, blob = read_control(ipk)
            f = parse(text); name = f["Package"]
            cur = pkgs.get(name)
            if cur and vercmp(f["Version"], cur["f"]["Version"]) <= 0:
                continue
            pkgs[name] = {"f": f, "text": text.rstrip("\n"), "ipk": ipk, "arch": arch, "blob_size": len(blob),
                          "sha256": hashlib.sha256(blob).hexdigest(), "md5": hashlib.md5(blob).hexdigest()}
    provides = {}
    for name, p in pkgs.items():
        provides.setdefault(name, name)
        for prov in deps(p["f"].get("Provides", "")):
            provides.setdefault(prov[0], name)

    wanted = [l.split()[0] for l in args.manifest.read_text().splitlines() if l.strip()]
    wanted += [e.strip() for e in args.extra.split(",") if e.strip()]
    chosen, missing, queue = set(), set(), list(wanted)
    while queue:
        n = queue.pop()
        real = provides.get(n)
        if real is None:
            missing.add(n); continue
        if real in chosen: continue
        chosen.add(real)
        f = pkgs[real]["f"]
        for group in deps(f.get("Depends", "")) + deps(f.get("Pre-Depends", "")):
            pick = next((alt for alt in group if alt in provides), group[0])
            queue.append(pick)
    chosen = {n for n in chosen if not n.endswith(SKIP_SUFFIX) or n in wanted}

    # Guard: a fix must reach devices as an upgrade. Content that differs from what is
    # already published under the same version would never be installed by opkg.
    published = {}
    for arch in ARCHS:
        idx = args.out / arch / "Packages"
        if idx.exists():
            for rec in idx.read_text().strip().split("\n\n"):
                f = parse(rec)
                if f.get("Package"):
                    published[f["Package"]] = (f.get("Version", ""), f.get("SHA256sum", ""), f.get("Filename", ""))
    stale = []
    for n in sorted(chosen):
        old = published.get(n)
        if not old:
            continue
        ver = pkgs[n]["f"]["Version"]
        if old[0] == ver and old[1] != pkgs[n]["sha256"] and not args.allow_same_version:
            stale.append("%s %s" % (n, ver))
        elif vercmp(ver, old[0]) < 0:
            stale.append("%s %s < published %s" % (n, ver, old[0]))
    if stale:
        raise SystemExit("Refusing to publish: content changed without a higher version. Bump PR in these recipes:\n  "
                         + "\n  ".join(stale))
    changed = [n for n in sorted(chosen) if published.get(n, ("",))[0] != pkgs[n]["f"]["Version"]]

    manifest = []
    for arch in ARCHS + STATIC:
        dest = args.out / arch; dest.mkdir(parents=True, exist_ok=True)
        blocks, keep = [], set()
        for name in sorted(n for n in chosen if pkgs[n]["arch"] == arch):
            p = pkgs[name]
            if p["blob_size"] > MAX_FILE:
                raise SystemExit("too large for GitHub: %s (%d bytes)" % (p["ipk"].name, p["blob_size"]))
            target = dest / p["ipk"].name; keep.add(target.name)
            if not target.exists() or target.stat().st_size != p["blob_size"]:
                shutil.copy2(p["ipk"], target)
            blocks.append("%s\nFilename: %s\nSize: %d\nMD5Sum: %s\nSHA256sum: %s" % (
                p["text"], target.name, p["blob_size"], p["md5"], p["sha256"]))
            manifest.append({"Package": name, "Version": p["f"]["Version"], "Architecture": arch,
                             "License": p["f"].get("License", ""), "SHA256sum": p["sha256"], "Size": p["blob_size"]})
        for old in dest.glob("*.ipk"):
            if old.name not in keep: old.unlink()
        text = "\n\n".join(blocks) + ("\n\n" if blocks else "")
        (dest / "Packages").write_text(text)
        (dest / "Packages.gz").write_bytes(gzip.compress(text.encode(), mtime=0))
    (args.out / "manifest.json").write_text(json.dumps({"target": "XCONN X-CYBER OpenBH 6.0 (XC)", "packages": manifest,
        "unresolved": sorted(missing)}, indent=1))
    total = sum(m["Size"] for m in manifest)
    print("feed: %d packages, %.1f MiB; new or upgraded versions: %d; unresolved names: %d"
          % (len(manifest), total / 1048576, len(changed), len(missing)))
    if changed and published:
        print("upgrades for devices:", ", ".join(changed[:60]))
    if missing: print("unresolved (provided by nothing in the build):", ", ".join(sorted(missing)[:40]))


if __name__ == "__main__":
    main()
