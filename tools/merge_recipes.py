#!/usr/bin/env python3
"""
YesChef — Recipe Merger
=========================
Merges all individual recipe JSON files from the recipes/ folder
into a single recipes.json for upload to Cloudflare R2.

This is the file the Flutter app reads. It is auto-generated on
every deploy — never edit it manually.

Usage:
  python3 merge_recipes.py
  python3 merge_recipes.py --input recipes/ --output merged/recipes.json
"""

import json, os, glob, argparse, re

parser = argparse.ArgumentParser()
parser.add_argument("--input",  default="recipes",          help="Folder of individual recipe JSONs")
parser.add_argument("--output", default="recipes.json",     help="Output merged file path")
args = parser.parse_args()

def to_slug(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

# ── Load all individual files ─────────────────────────────────────────────────
recipe_files = sorted(glob.glob(os.path.join(args.input, "*.json")))
if not recipe_files:
    print(f"❌ No recipe JSON files found in {args.input}/")
    exit(1)

recipes = []
for path in recipe_files:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    recipes.append(data.get("recipe", data))

print(f"✓ Merged {len(recipes)} recipes from {args.input}/")

# ── Hide links the daily checker has marked as dead / out of stock ───────────
# The source recipe files keep the real affiliate URL; only the published
# copy gets link="" so the app and website render a plain, non-tappable chip.
# tools/link_status.json is maintained by tools/check_links.py.
STATUS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "link_status.json")
disabled = set()
if os.path.exists(STATUS_FILE):
    with open(STATUS_FILE, encoding="utf-8") as f:
        disabled = {u for u, s in json.load(f).items() if s.get("disabled")}

hidden = 0
def blank_links(node):
    global hidden
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "link" and isinstance(v, str) and v.strip() in disabled:
                node[k] = ""
                hidden += 1
            else:
                blank_links(v)
    elif isinstance(node, list):
        for item in node:
            blank_links(item)

if disabled:
    blank_links(recipes)
    print(f"✓ Hid {hidden} link(s) across {len(disabled)} disabled URL(s)")

# ── Write merged file ─────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
with open(args.output, "w", encoding="utf-8") as f:
    json.dump(recipes, f, indent=2, ensure_ascii=False)
    f.write("\n")

size_kb = os.path.getsize(args.output) / 1024
print(f"✓ Written to {args.output} ({size_kb:.1f} KB)")
print(f"\nExample recipes included:")
for r in recipes[:3]:
    print(f"  • {r.get('name', 'Untitled')}")
