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
