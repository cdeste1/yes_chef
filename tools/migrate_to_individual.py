#!/usr/bin/env python3
"""
YesChef — One-Time Migration Script
=====================================
Splits your existing recipes.json into one file per recipe inside
a recipes/ folder. Run this once locally, then commit the results.

Usage:
  python3 migrate_to_individual.py
  python3 migrate_to_individual.py --input path/to/recipes.json --output recipes/

After running:
  1. Review the recipes/ folder — each recipe gets its own .json file
  2. Commit the recipes/ folder to GitHub
  3. Delete the old recipes.json from the repo (R2 copy stays untouched)
"""

import json, os, re, argparse, shutil
from datetime import datetime

# ── Args ──────────────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument("--input",  default="recipes.json", help="Path to existing recipes.json")
parser.add_argument("--output", default="recipes",      help="Output folder for individual files")
parser.add_argument("--dry-run", action="store_true",   help="Preview without writing files")
args = parser.parse_args()

def to_slug(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

# ── Load ──────────────────────────────────────────────────────────────────────
if not os.path.exists(args.input):
    print(f"❌ File not found: {args.input}")
    exit(1)

with open(args.input, encoding="utf-8") as f:
    raw = json.load(f)

items   = raw if isinstance(raw, list) else raw.get("recipes", [])
recipes = [item.get("recipe", item) for item in items]
print(f"✓ Loaded {len(recipes)} recipes from {args.input}")

# ── Create output folder ──────────────────────────────────────────────────────
if not args.dry_run:
    os.makedirs(args.output, exist_ok=True)

# ── Split ─────────────────────────────────────────────────────────────────────
written   = 0
skipped   = 0
slug_seen = {}

for r in recipes:
    name = r.get("name", "Untitled")
    slug = to_slug(name)

    # Handle duplicate slugs
    if slug in slug_seen:
        slug_seen[slug] += 1
        slug = f"{slug}-{slug_seen[slug]}"
    else:
        slug_seen[slug] = 0

    out_path = os.path.join(args.output, f"{slug}.json")

    if args.dry_run:
        print(f"  [DRY RUN] Would write → {out_path}")
        written += 1
        continue

    if os.path.exists(out_path):
        print(f"  ⚠️  Skipping (already exists): {out_path}")
        skipped += 1
        continue

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(r, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"  ✓  {out_path}")
    written += 1

print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Done — {written} files written, {skipped} skipped.")
if not args.dry_run:
    print(f"\nNext steps:")
    print(f"  1. Review the {args.output}/ folder")
    print(f"  2. git add {args.output}/")
    print(f"  3. git commit -m 'migrate: split recipes into individual files'")
    print(f"  4. git push")
    print(f"  (Keep your R2 recipes.json as-is — the deploy Action will regenerate it)")
