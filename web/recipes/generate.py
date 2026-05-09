#!/usr/bin/env python3
"""
YesChef Recipe Page Generator
===============================
Reads recipes.json and recipe-template.html, outputs one
  <OUTPUT_DIR>/<slug>/index.html  per recipe.

SEO enhancements (v2):
  1. <title> prepends the source restaurant name when available
     e.g. "Don Angie Pinwheel Lasagna – Yes Chef"
  2. <meta description> also mentions the restaurant/chef
  3. Recipe JSON-LD schema injected into <head> (invisible to visitors,
     read by Google for rich results)

Usage (local):
  cd web/recipes
  python3 generate.py

Usage (CI / SEO folder):
  OUTPUT_DIR_OVERRIDE=output python3 generate.py
"""

import json, os, re, html

# ── Config ────────────────────────────────────────────────────────────────────
RECIPES_FILE  = "recipes.json"
TEMPLATE_FILE = "recipe-template.html"
SITE_URL      = "https://tryyeschef.app"

# CI sets OUTPUT_DIR_OVERRIDE env var; locally falls back to original default
OUTPUT_DIR = os.environ.get("OUTPUT_DIR_OVERRIDE", "web/recipes")

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

def ing_plain(ing: dict) -> str:
    """Plain text ingredient string for schema (no HTML escaping)"""
    qty  = ing.get('quantity', '').strip()
    item = ing.get('item', '')
    note = ing.get('note', '')
    parts = []
    if qty:
        parts.append(f"{qty} – {item}")
    else:
        parts.append(item)
    if note:
        parts.append(f"({note})")
    return ' '.join(parts)

def extract_restaurant(source: str) -> str:
    """
    Pull the venue name from a source string for use in SEO title/description.
    Returns empty string for generic/internal sources.
    """
    if not source:
        return ''
    # Remove common prefixes (handles both "adapted from X" and "adapted from: X")
    s = re.sub(r'^(adapted from|adpated from)(:\s*|\s+)', '', source, flags=re.IGNORECASE).strip()
    # Remove location suffixes after ( , or -
    s = re.sub(r'\s*[\(,\-].*$', '', s).strip()
    # Skip generic sources that don't add SEO value
    generic = {
        'Modern Italian', 'Modern fine dining technique', 'Modern Pastry',
        'Classic French Bistro', 'French Cuisine', 'Chef-inspired',
        'Gemini Culinary Laboratory', "Yes Chef! Kitchen", 'Chef'
    }
    if s in generic:
        return ''
    return s

# ── Load template ─────────────────────────────────────────────────────────────
with open(TEMPLATE_FILE, encoding='utf-8') as f:
    TEMPLATE = f.read()

# ── Load recipes ──────────────────────────────────────────────────────────────
with open(RECIPES_FILE, encoding='utf-8') as f:
    raw = json.load(f)

items   = raw if isinstance(raw, list) else raw.get('recipes', [])
recipes = [item.get('recipe', item) for item in items]

print(f"Loaded {len(recipes)} recipes → outputting to ./{OUTPUT_DIR}/")

# ── Generate pages ────────────────────────────────────────────────────────────
generated = 0
for r in recipes:
    name       = r.get('name', 'Untitled')
    slug       = to_slug(name)
    desc       = r.get('description', '')
    source     = r.get('source', '')
    chef       = r.get('chef', '').strip()
    yield_     = r.get('yield', '')
    category   = r.get('category', '')
    keywords   = r.get('keywords', '')
    image      = r.get('imageUrl', '')
    ingredients = r.get('ingredients', [])
    steps      = r.get('steps', r.get('instructions', []))

    # ── SEO: extract restaurant for title/description ─────────────────────────
    restaurant = extract_restaurant(source)

    # 1. SEO title — prepend restaurant if available
    if restaurant:
        seo_title = f"{restaurant} {name} – Yes Chef"
    else:
        seo_title = f"{name} – Yes Chef"

    # 2. SEO meta description — mention restaurant/chef for relevance
    if desc:
        base_desc = desc.rstrip('.')
        if restaurant:
            seo_description = f"Inspired by {restaurant} — {base_desc}."
        elif chef:
            seo_description = f"Inspired by {chef}: {base_desc}."
        else:
            seo_description = desc
    else:
        seo_description = f"{name} recipe on Yes Chef."

    # ── Visible page content (unchanged) ─────────────────────────────────────
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

    wine = r.get('winePairings', [])
    if wine:
        wine_items = ''.join(
            f'<div class="wine-item"><strong>{h(w.get("name",""))}</strong>'
            f'<p>{h(w.get("notes",""))}</p></div>'
            for w in wine
        )
        sommelier_html = (
            '<div class="sommelier-block">'
            '<p>🍷Sommelier\'s Recommendation</p>'
            f'{wine_items}</div>'
        )
    else:
        sommelier_html = ''

    steps_html = '\n'.join(
        f'<li>{h(s.get("instruction", ""))}</li>'
        for s in steps
    )

    sub_recipes = r.get('sub_recipes', [])
    sub_parts = []
    for sr in sub_recipes:
        sr_name  = h(sr.get('name', ''))
        sr_yield = sr.get('yield', '')
        sr_ings  = sr.get('ingredients', [])
        sr_steps = sr.get('steps', sr.get('instructions', []))
        sr_yield_html = f'<p>Yield: {h(sr_yield)}</p>' if sr_yield else ''
        sr_ing_html   = '\n'.join(f'<li>{ing_line(i)}</li>' for i in sr_ings)
        sr_steps_html = '\n'.join(
            f'<li>{h(s.get("instruction", ""))}</li>' for s in sr_steps
        )
        sub_parts.append(
            f'<div class="sub-recipe">'
            f'<h3>{sr_name}</h3>'
            f'{sr_yield_html}'
            f'<h4>Ingredients:</h4><ul>{sr_ing_html}</ul>'
            f'<h4>Steps:</h4><ol>{sr_steps_html}</ol>'
            f'</div>'
        )
    sub_recipes_html = ''.join(sub_parts)

    # ── 3. Recipe JSON-LD Schema ──────────────────────────────────────────────
    schema = {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": name,
        "description": desc,
        "url": f"{SITE_URL}/recipes/{slug}/",
        "author": {
            "@type": "Organization" if not chef else "Person",
            "name": chef if chef else "Yes Chef!"
        },
        "publisher": {
            "@type": "Organization",
            "name": "Yes Chef!",
            "url": SITE_URL
        },
        "recipeCategory": category,
        "keywords": keywords,
        "recipeYield": yield_,
        "recipeIngredient": [ing_plain(i) for i in ingredients],
        "recipeInstructions": [
            {"@type": "HowToStep", "text": s.get('instruction', '')}
            for s in steps
        ]
    }
    if image:
        schema["image"] = image
    if restaurant:
        schema["creditText"] = source
        schema["isBasedOn"] = {"@type": "CreativeWork", "name": restaurant}

    schema_json = json.dumps(schema, ensure_ascii=False, indent=2)
    schema_tag  = f'<script type="application/ld+json">\n{schema_json}\n</script>'

    # ── Inject into template ──────────────────────────────────────────────────
    page = TEMPLATE

    # SEO meta replacements
    page = page.replace('{{SEO_TITLE}}',        h(seo_title))
    page = page.replace('{{SEO_DESCRIPTION}}',  h(seo_description))
    page = page.replace('{{SCHEMA_TAG}}',       schema_tag)

    # Existing replacements (keep all of these the same as before)
    page = page.replace('{{NAME}}',             h(name))
    page = page.replace('{{SLUG}}',             slug)
    page = page.replace('{{DESCRIPTION}}',      h(desc))
    page = page.replace('{{KEYWORDS}}',         h(keywords))
    page = page.replace('{{IMAGE_URL}}',        h(image))
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

    print(f"  ✓  {slug}/")
    generated += 1

print(f"\nDone — {generated} recipe pages generated.")