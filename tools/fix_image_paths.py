#!/usr/bin/env python3
"""
YesChef — Fix Image URL Paths
================================
Scans all recipe JSON files in the recipes/ folder and updates any
imageUrl that points to the old path (assets/<slug>) to the correct
path (assets/Photos/Recipes/<slug>).

Usage:
  python tools/fix_image_paths.py                        # dry run — shows what would change
  python tools/fix_image_paths.py --apply                # applies the changes
  python tools/fix_image_paths.py --input path/to/recipes  # custom folder

After running with --apply:
  git add recipes/
  git commit -m "fix: update imageUrl paths to assets/Photos/Recipes/"
  git push
"""

import json, os, re, argparse, glob

parser = argparse.ArgumentParser()
parser.add_argument('--input',  default='recipes', help='Folder of individual recipe JSONs')
parser.add_argument('--apply',  action='store_true', help='Apply changes (default is dry run)')
args = parser.parse_args()

R2_BASE    = 'https://pub-3ae50d56fa834654954be23601470560.r2.dev'
OLD_PREFIX = f'{R2_BASE}/assets/'
NEW_PREFIX = f'{R2_BASE}/assets/Photos/Recipes/'

recipe_files = sorted(glob.glob(os.path.join(args.input, '*.json')))
if not recipe_files:
    print(f'❌ No recipe JSON files found in {args.input}/')
    exit(1)

print(f'Scanning {len(recipe_files)} recipe files...\n')

needs_fix = []

for path in recipe_files:
    with open(path, encoding='utf-8') as f:
        data = json.load(f)

    recipe = data.get('recipe', data)
    image_url = recipe.get('imageUrl', '')

    # Check if URL starts with old prefix but NOT already has Photos/Recipes
    if image_url.startswith(OLD_PREFIX) and 'Photos/Recipes' not in image_url:
        # Extract just the filename part
        filename = image_url[len(OLD_PREFIX):]
        new_url  = NEW_PREFIX + filename
        needs_fix.append({
            'path':    path,
            'data':    data,
            'recipe':  recipe,
            'old_url': image_url,
            'new_url': new_url,
            'name':    recipe.get('name', 'Untitled'),
            'filename': filename,
        })

if not needs_fix:
    print('✅ All imageUrl paths are already correct — nothing to fix.')
    exit(0)

print(f'Found {len(needs_fix)} recipe(s) with incorrect image paths:\n')
for item in needs_fix:
    print(f'  📄 {os.path.basename(item["path"])}')
    print(f'     Name:    {item["name"]}')
    print(f'     Old URL: {item["old_url"]}')
    print(f'     New URL: {item["new_url"]}')
    print(f'     File to move in Cloudflare: assets/{item["filename"]} → assets/Photos/Recipes/{item["filename"]}')
    print()

if not args.apply:
    print('─' * 60)
    print('DRY RUN — no files changed.')
    print('Run with --apply to apply these changes.')
    print('\nFiles you will need to move in Cloudflare R2:')
    for item in needs_fix:
        print(f'  assets/{item["filename"]}  →  assets/Photos/Recipes/{item["filename"]}')
    exit(0)

# Apply changes
fixed = 0
for item in needs_fix:
    item['recipe']['imageUrl'] = item['new_url']
    with open(item['path'], 'w', encoding='utf-8') as f:
        json.dump(item['data'], f, indent=2, ensure_ascii=False)
        f.write('\n')
    print(f'  ✓ Fixed {os.path.basename(item["path"])}')
    fixed += 1

print(f'\n✅ Fixed {fixed} recipe files.')
print('\nNext steps:')
print('  1. Move these files in Cloudflare R2 (assets/ → assets/Photos/Recipes/):')
for item in needs_fix:
    print(f'       {item["filename"]}')
print('  2. git add recipes/')
print('  3. git commit -m "fix: update imageUrl paths to assets/Photos/Recipes/"')
print('  4. git push')
print('  5. Delete the old files from assets/ root in Cloudflare once site looks correct')
