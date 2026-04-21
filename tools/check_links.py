#!/usr/bin/env python3
"""
YesChef Amazon Link Checker
=============================
Fetches recipes.json from Cloudflare R2, finds every Amazon affiliate link
in specialtools[].link, checks each one, and outputs:

  - link_report.json   — full machine-readable results (used by the Action)
  - link_report.md     — human-readable summary

Because the same link can appear across multiple recipes/tools, the script
deduplicates before checking, then maps results back to every recipe that
uses each link.

Usage:
  python3 check_links.py                        # fetches live from R2
  RECIPES_FILE=recipes.json python3 check_links.py   # use a local file
"""

import json, os, sys, time, urllib.request, urllib.error
from datetime import datetime, timezone
from collections import defaultdict

# ── Config ────────────────────────────────────────────────────────────────────
R2_URL       = "https://pub-3ae50d56fa834654954be23601470560.r2.dev/assets/recipes.json"
RECIPES_FILE = os.environ.get("RECIPES_FILE", "")   # set to use a local file
REPORT_JSON  = "link_report.json"
REPORT_MD    = "link_report.md"

# Amazon returns 200 even for dead links sometimes, but redirects to
# a "product unavailable" page. We check the final URL for known patterns.
DEAD_URL_PATTERNS = [
    "dp/product-unavailable",
    "detail/product-unavailable",
    "/s?k=",          # redirected to a search = product gone
    "ref=cs_503",
    "sorry/index",
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}

# ── Load recipes ──────────────────────────────────────────────────────────────
if RECIPES_FILE and os.path.exists(RECIPES_FILE):
    print(f"Loading from local file: {RECIPES_FILE}")
    with open(RECIPES_FILE, encoding="utf-8") as f:
        raw = json.load(f)
else:
    print(f"Fetching recipes.json from R2...")
    req = urllib.request.Request(R2_URL, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = json.load(resp)

items   = raw if isinstance(raw, list) else raw.get("recipes", [])
recipes = [item.get("recipe", item) for item in items]
print(f"Loaded {len(recipes)} recipes.")

# ── Collect all links, track which recipe+tool each one belongs to ────────────
# link_map[url] = list of {"recipe": name, "tool": item_name}
link_map = defaultdict(list)

for r in recipes:
    recipe_name = r.get("name", "Untitled")
    for tool in r.get("specialtools", []):
        link = tool.get("link", "").strip()
        if link:
            link_map[link].append({
                "recipe": recipe_name,
                "tool":   tool.get("item", "(unnamed tool)"),
            })

unique_links = list(link_map.keys())
print(f"Found {len(unique_links)} unique Amazon links across all recipes.\n")

# ── Check each link ───────────────────────────────────────────────────────────
def check_link(url: str) -> dict:
    """
    Returns a dict with:
      status: "ok" | "broken" | "redirect" | "error"
      http_code: int or None
      final_url: str
      reason: str
    """
    try:
        req = urllib.request.Request(url, headers=HEADERS, method="GET")
        with urllib.request.urlopen(req, timeout=15) as resp:
            http_code = resp.status
            final_url = resp.url

        # Check if we landed on a dead-product page
        for pattern in DEAD_URL_PATTERNS:
            if pattern in final_url:
                return {
                    "status":    "broken",
                    "http_code": http_code,
                    "final_url": final_url,
                    "reason":    f"Redirected to unavailable page (matched '{pattern}')",
                }

        # Check for significant redirect (product ASIN changed)
        if final_url.rstrip("/") != url.rstrip("/"):
            return {
                "status":    "redirect",
                "http_code": http_code,
                "final_url": final_url,
                "reason":    "URL redirected — may still be valid, worth reviewing",
            }

        return {
            "status":    "ok",
            "http_code": http_code,
            "final_url": final_url,
            "reason":    "",
        }

    except urllib.error.HTTPError as e:
        return {
            "status":    "broken",
            "http_code": e.code,
            "final_url": url,
            "reason":    f"HTTP {e.code}: {e.reason}",
        }
    except urllib.error.URLError as e:
        return {
            "status":    "error",
            "http_code": None,
            "final_url": url,
            "reason":    str(e.reason),
        }
    except Exception as e:
        return {
            "status":    "error",
            "http_code": None,
            "final_url": url,
            "reason":    str(e),
        }


results = []   # full results list

for i, url in enumerate(unique_links, 1):
    usages = link_map[url]
    print(f"[{i}/{len(unique_links)}] Checking: {url[:80]}...")
    result = check_link(url)
    result["url"]    = url
    result["usages"] = usages   # every recipe+tool that uses this link
    results.append(result)
    print(f"         → {result['status'].upper()}  {result['reason']}")
    time.sleep(1.5)   # be polite to Amazon's servers

# ── Summarise ─────────────────────────────────────────────────────────────────
ok        = [r for r in results if r["status"] == "ok"]
broken    = [r for r in results if r["status"] == "broken"]
redirects = [r for r in results if r["status"] == "redirect"]
errors    = [r for r in results if r["status"] == "error"]

checked_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

# ── Write link_report.json ────────────────────────────────────────────────────
report_data = {
    "checked_at":      checked_at,
    "total":           len(results),
    "ok_count":        len(ok),
    "broken_count":    len(broken),
    "redirect_count":  len(redirects),
    "error_count":     len(errors),
    "results":         results,
}
with open(REPORT_JSON, "w", encoding="utf-8") as f:
    json.dump(report_data, f, indent=2)
print(f"\n✓ Written {REPORT_JSON}")

# ── Write link_report.md ──────────────────────────────────────────────────────
lines = [
    f"# YesChef Link Check Report",
    f"**Checked:** {checked_at}  ",
    f"**Total links:** {len(results)} | "
    f"✅ OK: {len(ok)} | "
    f"❌ Broken: {len(broken)} | "
    f"↩️ Redirected: {len(redirects)} | "
    f"⚠️ Error: {len(errors)}",
    "",
]

if broken:
    lines += ["## ❌ Broken Links — Action Required", ""]
    for r in broken:
        lines.append(f"### `{r['url']}`")
        lines.append(f"- **Reason:** {r['reason']}")
        lines.append(f"- **Used in:**")
        for u in r["usages"]:
            lines.append(f"  - *{u['recipe']}* → `{u['tool']}`")
        lines.append("")

if redirects:
    lines += ["## ↩️ Redirected Links — Worth Reviewing", ""]
    for r in redirects:
        lines.append(f"### `{r['url']}`")
        lines.append(f"- **Now points to:** {r['final_url']}")
        lines.append(f"- **Used in:**")
        for u in r["usages"]:
            lines.append(f"  - *{u['recipe']}* → `{u['tool']}`")
        lines.append("")

if errors:
    lines += ["## ⚠️ Errors (network / timeout)", ""]
    for r in errors:
        lines.append(f"- `{r['url']}` — {r['reason']}")
        for u in r["usages"]:
            lines.append(f"  - *{u['recipe']}* → `{u['tool']}`")
    lines.append("")

if not broken and not redirects and not errors:
    lines.append("## ✅ All links are healthy!")

with open(REPORT_MD, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print(f"✓ Written {REPORT_MD}")

# ── Exit code: non-zero if anything needs attention ───────────────────────────
# The GitHub Action uses this to decide whether to send the alert email.
if broken or errors:
    print(f"\n⚠️  {len(broken)} broken + {len(errors)} errors found.")
    sys.exit(1)   # triggers email alert in the Action
else:
    print(f"\n✅ All links OK (redirects: {len(redirects)}).")
    sys.exit(0)
