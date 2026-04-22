#!/usr/bin/env python3
"""
YesChef Recipe Page Generator
===============================
Reads recipes.json and recipe-template.html, then outputs one
  <OUTPUT_DIR>/<slug>/index.html
per recipe.

Usage:
  python3 generate.py                        # uses default OUTPUT_DIR in script
  OUTPUT_DIR_OVERRIDE=seo/recipes python3 generate.py   # override for SEO folder

In CI (GitHub Actions) the OUTPUT_DIR_OVERRIDE env var is set automatically.
"""

import json, os, re, html

# ── Config ────────────────────────────────────────────────────────────────────
RECIPES_FILE   = "recipes.json"
TEMPLATE_FILE  = "recipe-template.html"

# Allow CI to override the output directory via environment variable
OUTPUT_DIR = os.environ.get("OUTPUT_DIR_OVERRIDE", ".")

# ── Helpers ───────────────────────────────────────────────────────────────────
def to_slug(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

def h(text) -> str:
    return html.escape(str(text or ''))

def ing_line(ing: dict) -> str:
    qty  = ing.get('quantity', '').strip()
    item = h(ing.get('item', ''))
    note = h(ing.get('note', ''))
    parts = []
    if qty:
        parts.append(f"{h(qty)} – {item}")
    else:
        parts.append(item)
    if note:
        parts.append(f"({note})")
    return ' '.join(parts)

# ── Load template ─────────────────────────────────────────────────────────────
with open(TEMPLATE_FILE, encoding='utf-8') as f:
    TEMPLATE = f.read()

# ── Load recipes ──────────────────────────────────────────────────────────────
with open(RECIPES_FILE, encoding='utf-8') as f:
    raw = json.load(f)

items = raw if isinstance(raw, list) else raw.get('recipes', [])
recipes = [item.get('recipe', item) for item in items]

print(f"Loaded {len(recipes)} recipes → outputting to ./{OUTPUT_DIR}/")

# ── Generate pages ────────────────────────────────────────────────────────────
generated = 0
for r in recipes:
    name     = r.get('name', 'Untitled')
    slug     = to_slug(name)
    desc     = r.get('description', '')
    source   = r.get('source', '')
    chef     = r.get('chef', '').strip()
    yield_   = r.get('yield', '')
    category = r.get('category', '')
    keywords = r.get('keywords', '')
    image    = r.get('imageUrl', '')

    hero_html = (
        f'<img class="recipe-hero-img" src="{h(image)}" alt="{h(name)}" itemprop="image" loading="eager">'
        if image else ''
    )

    meta_parts = []
    if source: meta_parts.append(f"Source: {h(source)}")
    if chef:   meta_parts.append(f"Inspiring Chef: {h(chef)}")
    meta_html = '<br>'.join(meta_parts)

    desc_html  = f'<p class="recipe-description" itemprop="description">{h(desc)}</p>' if desc else ''
    yield_html = f'<p class="recipe-yield" itemprop="recipeYield">{h(yield_)}</p>' if yield_ else ''

    ingredients = r.get('ingredients', [])
    ing_html = '\n'.join(f'<li>{ing_line(i)}</li>' for i in ingredients)

    tools = r.get('specialtools', [])
    if tools:
        tool_items = []
        for t in tools:
            item_text = h(t.get('item', ''))
            link      = t.get('link', '').strip()
            link_html = (
                f' <a href="{h(link)}" class="amazon-link" target="_blank" rel="noopener sponsored">'
                f'Need it? Click here to start cooking</a>'
            ) if link else ''
            tool_items.append(f'<li>{item_text}{link_html}</li>')
        tools_html = (
            '<hr class="divider">'
            '<h2 class="section-heading">Speciality Items:</h2>'
            f'<ul class="tools-list">{"".join(tool_items)}</ul>'
            '<p class="amazon-disclosure">As an Amazon Associate, Yes Chef! may earn from qualifying purchases.</p>'
        )
    else:
        tools_html = ''

    wines = r.get('winePairings', [])
    if wines:
        wine_items = []
        for w in wines:
            wname  = h(w.get('name', ''))
            wnotes = h(w.get('notes', ''))
            notes_html = f'<div class="wine-notes">{wnotes}</div>' if wnotes else ''
            wine_items.append(f'<div class="wine-item"><div class="wine-name">{wname}</div>{notes_html}</div>')
        sommelier_html = (
            '<div class="sommelier-block">'
            '<div class="sommelier-header"><span style="font-size:20px">🍷</span>'
            '<span class="sommelier-title">Sommelier\'s Recommendation</span></div>'
            + ''.join(wine_items) +
            '</div>'
        )
    else:
        sommelier_html = ''

    steps = r.get('steps', [])
    steps_html = '\n'.join(
        f'<li><span class="step-num">{i+1}.</span><span>{h(s.get("instruction",""))}</span></li>'
        for i, s in enumerate(steps)
    )

    subs = r.get('sub_recipes', [])
    if subs:
        sub_blocks = []
        for sub in subs:
            sub_name      = h(sub.get('name', ''))
            sub_yield     = sub.get('yield', sub.get('yieldInfo', ''))
            sub_yield_html = f'<div class="sub-recipe-yield">Yield: {h(sub_yield)}</div>' if sub_yield else ''
            sub_ings      = sub.get('ingredients', [])
            sub_ing_html  = '\n'.join(f'<li>{ing_line(i)}</li>' for i in sub_ings)
            sub_steps     = sub.get('steps', [])
            sub_step_html = '\n'.join(
                f'<li><span class="step-num">{i+1}.</span><span>{h(s.get("instruction",""))}</span></li>'
                for i, s in enumerate(sub_steps)
            )
            sub_blocks.append(
                f'<div class="sub-recipe">'
                f'<div class="sub-recipe-name">{sub_name}</div>'
                f'{sub_yield_html}'
                f'<div class="sub-label">Ingredients:</div>'
                f'<ul class="ing-list">{sub_ing_html}</ul>'
                f'<div class="sub-label">Steps:</div>'
                f'<ol class="steps-list">{sub_step_html}</ol>'
                f'</div>'
            )
        sub_recipes_html = (
            '<hr class="divider">'
            '<h2 class="section-heading">Sub-Recipes:</h2>'
            + ''.join(sub_blocks)
        )
    else:
        sub_recipes_html = ''

    schema = {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": name,
        "description": desc,
        "image": image,
        "author": {"@type": "Organization", "name": "YesChef!"},
        "publisher": {"@type": "Organization", "name": "YesChef!", "url": "https://tryyeschef.app"},
        "recipeCategory": category,
        "keywords": keywords,
        "recipeYield": yield_,
        "recipeIngredient": [ing_line(i) for i in ingredients],
        "recipeInstructions": [
            {"@type": "HowToStep", "text": s.get('instruction', '')}
            for s in steps
        ]
    }
    schema_json = json.dumps(schema, ensure_ascii=False, indent=2)

    page = TEMPLATE
    page = page.replace('{{NAME}}',             h(name))
    page = page.replace('{{SLUG}}',             slug)
    page = page.replace('{{DESCRIPTION}}',      h(desc))
    page = page.replace('{{KEYWORDS}}',         h(keywords))
    page = page.replace('{{IMAGE_URL}}',        h(image))
    page = page.replace('{{SCHEMA_JSON}}',      schema_json)
    page = page.replace('{{HERO_IMAGE_HTML}}',  hero_html)
    page = page.replace('{{META_HTML}}',        meta_html)
    page = page.replace('{{DESCRIPTION_HTML}}', desc_html)
    page = page.replace('{{YIELD_HTML}}',       yield_html)
    page = page.replace('{{INGREDIENTS_HTML}}', ing_html)
    page = page.replace('{{TOOLS_HTML}}',       tools_html)
    page = page.replace('{{SOMMELIER_HTML}}',   sommelier_html)
    page = page.replace('{{STEPS_HTML}}',       steps_html)
    page = page.replace('{{SUB_RECIPES_HTML}}', sub_recipes_html)

    out_dir  = os.path.join(OUTPUT_DIR, slug)
    out_file = os.path.join(out_dir, 'index.html')
    os.makedirs(out_dir, exist_ok=True)
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write(page)

    print(f"  ✓  {out_file}")
    generated += 1

print(f"\nDone — {generated} recipe pages generated in ./{OUTPUT_DIR}/")
print("\nExample URLs:")
for r in recipes[:3]:
    slug = to_slug(r.get('name', ''))
    print(f"  https://tryyeschef.app/recipes/{slug}/")
