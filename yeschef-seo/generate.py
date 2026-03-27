import json
import os
import re

def slugify(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')

with open("recipes.json", encoding="utf-8") as f:
    data = json.load(f)

# ✅ THIS IS THE KEY FIX
recipes = data["recipes"]

template = open("template.html", encoding="utf-8").read()

for entry in recipes:
    recipe = entry["recipe"]

    # Basic fields
    name = recipe.get("name", "recipe")
    slug = slugify(name)

    output_dir = f"output/{slug}"
    os.makedirs(output_dir, exist_ok=True)

    # Ingredients
    ingredients_json = []
    ingredients_html = []

    for i in recipe.get("ingredients", []):
        parts = []
        if i.get("quantity"):
            parts.append(i["quantity"])
        parts.append(i.get("item", ""))
        if i.get("note"):
            parts.append(f"({i['note']})")

        text = " ".join(parts).strip()

        ingredients_json.append(f'"{text}"')
        ingredients_html.append(f"<li>{text}</li>")

    # Steps
    instructions_json = []
    instructions_html = []

    for s in recipe.get("steps", []):
        text = s.get("instruction", "")
        instructions_json.append(f'"{text}"')
        instructions_html.append(f"<li>{text}</li>")

    # Replace template
    page = template
    page = page.replace("{{name}}", name)
    page = page.replace("{{description}}", recipe.get("description", ""))
    page = page.replace("{{keywords}}", recipe.get("keywords", ""))
    page = page.replace("{{imageUrl}}", recipe.get("imageUrl", ""))
    page = page.replace("{{chef}}", recipe.get("chef", "").strip())
    page = page.replace("{{source}}", recipe.get("source", ""))
    page = page.replace("{{yield}}", recipe.get("yield", ""))
    page = page.replace("{{category}}", recipe.get("category", ""))
    page = page.replace("{{ingredients_json}}", ",".join(ingredients_json))
    page = page.replace("{{instructions_json}}", ",".join(instructions_json))
    page = page.replace("{{ingredients_html}}", "\n".join(ingredients_html))
    page = page.replace("{{instructions_html}}", "\n".join(instructions_html))

    # Write file
    with open(f"{output_dir}/index.html", "w", encoding="utf-8") as f:
        f.write(page)

    print(f"✅ Generated: {slug}")

print("🎉 Done!")
sitemap_entries = []

for entry in recipes:
    recipe = entry["recipe"]
    slug = slugify(recipe["name"])

    url = f"https://tryyeschef.app/recipes/{slug}/"
    sitemap_entries.append(f"""
  <url>
    <loc>{url}</loc>
  </url>""")

# Build sitemap
sitemap_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

  <url>
    <loc>https://tryyeschef.app/</loc>
  </url>

{''.join(sitemap_entries)}

</urlset>
"""

with open("sitemap.xml", "w", encoding="utf-8") as f:
    f.write(sitemap_content)

print("✅ sitemap.xml generated")