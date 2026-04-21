#!/usr/bin/env python3
"""
YesChef Link Updater
======================
Replaces an old Amazon link with a new one everywhere it appears in
recipes.json — covers every recipe and every specialtools entry.

Because one link can appear in many recipes, this fixes ALL of them
in a single command. The original file is backed up first.

Usage:
  python3 update_link.py <old_url> <new_url> [--file path/to/recipes.json]

Examples:
  python3 update_link.py \\
    "https://www.amazon.com/dp/OLD123?tag=yeschef-20" \\
    "https://www.amazon.com/dp/NEW456?tag=yeschef-20"

  # Dry run — shows what would change without saving:
  python3 update_link.py OLD_URL NEW_URL --dry-run

  # Use a custom file path:
  python3 update_link.py OLD_URL NEW_URL --file ../web/recipes/recipes.json
"""

import json, os, sys, shutil, argparse
from datetime import datetime
from collections import defaultdict

# ── Args ──────────────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser(description="Replace an Amazon link everywhere in recipes.json")
parser.add_argument("old_url",           help="The broken/old URL to replace")
parser.add_argument("new_url",           help="The new URL to use instead")
parser.add_argument("--file",   default="recipes.json", help="Path to recipes.json")
parser.add_argument("--dry-run", action="store_true",   help="Preview changes without saving")
args = parser.parse_args()

OLD_URL      = args.old_url.strip()
NEW_URL      = args.new_url.strip()
RECIPES_FILE = args.file
DRY_RUN      = args.dry_run

# ── Load ──────────────────────────────────────────────────────────────────────
if not os.path.exists(RECIPES_FILE):
    print(f"❌ File not found: {RECIPES_FILE}")
    sys.exit(1)

with open(RECIPES_FILE, encoding="utf-8") as f:
    raw = json.load(f)

items   = raw if isinstance(raw, list) else raw.get("recipes", [])
recipes = [item.get("recipe", item) for item in items]

# ── Find all occurrences ──────────────────────────────────────────────────────
hits = []   # list of {"recipe": name, "tool": item_name}

for r in recipes:
    for tool in r.get("specialtools", []):
        if tool.get("link", "").strip() == OLD_URL:
            hits.append({
                "recipe": r.get("name", "Untitled"),
                "tool":   tool.get("item", "(unnamed)"),
            })

if not hits:
    print(f"🔍 URL not found in {RECIPES_FILE}:")
    print(f"   {OLD_URL}")
    print("\nDouble-check the URL is an exact match (including query params).")
    sys.exit(0)

# ── Report what will change ───────────────────────────────────────────────────
print(f"\n{'[DRY RUN] ' if DRY_RUN else ''}Found {len(hits)} occurrence(s) of:")
print(f"  OLD: {OLD_URL}")
print(f"  NEW: {NEW_URL}\n")
for h in hits:
    print(f"  • {h['recipe']}  →  {h['tool']}")

if DRY_RUN:
    print("\n[DRY RUN] No changes written. Remove --dry-run to apply.")
    sys.exit(0)

# ── Confirm ───────────────────────────────────────────────────────────────────
confirm = input(f"\nReplace all {len(hits)} occurrence(s)? [y/N] ").strip().lower()
if confirm != "y":
    print("Aborted — no changes made.")
    sys.exit(0)

# ── Backup ────────────────────────────────────────────────────────────────────
ts      = datetime.now().strftime("%Y%m%d_%H%M%S")
backup  = f"{RECIPES_FILE}.bak_{ts}"
shutil.copy2(RECIPES_FILE, backup)
print(f"\n✓ Backup saved to {backup}")

# ── Apply ─────────────────────────────────────────────────────────────────────
replaced = 0
for r in recipes:
    for tool in r.get("specialtools", []):
        if tool.get("link", "").strip() == OLD_URL:
            tool["link"] = NEW_URL
            replaced += 1

# Write back — preserve the original top-level structure (list or {recipes:[...]})
if isinstance(raw, list):
    output = recipes
else:
    raw["recipes"] = [
        ({"recipe": r} if "recipe" in item else r)
        for item, r in zip(items, recipes)
    ]
    output = raw

with open(RECIPES_FILE, "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"✓ Replaced {replaced} occurrence(s) in {RECIPES_FILE}")
print(f"\nNext steps:")
print(f"  1. Upload the updated recipes.json to Cloudflare R2")
print(f"  2. Push to main — the site will rebuild automatically")
