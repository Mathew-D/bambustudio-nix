#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_file="${repo_root}/pkgs/bambu/default.nix"

release_json="$(curl -fsSL -H 'User-Agent: bambustudio-nix-updater' https://api.github.com/repos/bambulab/BambuStudio/releases/latest)"
version="$(printf '%s' "$release_json" | python3 -c 'import json, sys; data = json.load(sys.stdin); print(data["name"].split()[0])')"
tag_name="$(printf '%s' "$release_json" | python3 -c 'import json, sys; data = json.load(sys.stdin); print(data["tag_name"])')"

asset_url="$(printf '%s' "$release_json" | python3 -c 'import json, sys; data = json.load(sys.stdin); assets = data.get("assets", []); appimages = [a for a in assets if a.get("name", "").endswith(".AppImage")];
if appimages:
    for candidate in appimages:
        name = candidate.get("name", "")
        if "ubu24" in name.lower() or "ubuntu24" in name.lower():
            print(candidate["browser_download_url"])
            raise SystemExit
    print(appimages[0]["browser_download_url"])
else:
    raise SystemExit("No AppImage asset found in the latest release.")')"

tmp_file="$(mktemp /tmp/bambustudio-XXXXXX.AppImage)"
trap 'rm -f "$tmp_file"' EXIT

curl -fsSL -o "$tmp_file" "$asset_url"
sha256="$(nix hash file --type sha256 --sri "$tmp_file")"

python3 - "$package_file" "$version" "$asset_url" "$sha256" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
url = sys.argv[3]
digest = sys.argv[4]

text = path.read_text(encoding="utf-8")
text, replaced_version = re.subn(r'(\s*version = )"[^"]+";', rf'\1"{version}";', text, count=1)
pattern = r'(\s*src = pkgs\.fetchurl \{\n\s*url = )"[^"]+";\n(\s*hash = )"[^"]+";\n\s*\};'
text, replaced_block = re.subn(
    pattern,
    lambda m: m.group(1) + '"' + url + '";\n' + m.group(2) + '"' + digest + '";\n  };',
    text,
    count=1,
)

if replaced_version != 1 or replaced_block != 1:
    raise SystemExit("Could not update the package metadata in pkgs/bambu/default.nix")

path.write_text(text, encoding="utf-8")
print(f"Updated {path} to version {version} using {url}")
PY

echo "Release tag: ${tag_name}"
echo "Package file: ${package_file}"
