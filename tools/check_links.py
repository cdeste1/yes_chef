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

import json, os, sys, time, glob, urllib.request, urllib.error
from datetime import datetime, timezone
from collections import defaultdict

_HERE        = os.path.dirname(os.path.abspath(__file__))
RECIPES_DIR  = os.path.join(_HERE, "..", "recipes")
STATUS_FILE  = os.path.join(_HERE, "link_status.json")

# A link is hidden from users (published with link="") after this many
# consecutive daily checks come back broken / out_of_stock. It is restored
# the first time a check comes back healthy. Network errors never count:
# Amazon bot-blocking would otherwise hide good links.
DISABLE_AFTER = 2

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

# The page loads fine (200, real product page) but the listing itself says
# the item can't be ordered. These are the phrases Amazon shows in the buy
# box / availability block for that case. Checked case-insensitively against
# the page HTML.
OUT_OF_STOCK_PATTERNS = [
    "currently unavailable",
    "we don't know when or if this item will be back in stock",
    "out of stock",
    "temporarily out of stock",
    "unavailable at this time",
    "see all buying options",   # shown when the default offer is gone
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
# Default to the source recipe files: the published R2 copy has disabled links
# blanked out, so it can't be used to detect when a product comes back.
if RECIPES_FILE and os.path.exists(RECIPES_FILE):
    print(f"Loading from local file: {RECIPES_FILE}")
    with open(RECIPES_FILE, encoding="utf-8") as f:
        raw = json.load(f)
elif os.path.isdir(RECIPES_DIR):
    print(f"Loading source recipes from {RECIPES_DIR}/")
    raw = []
    for path in sorted(glob.glob(os.path.join(RECIPES_DIR, "*.json"))):
        with open(path, encoding="utf-8") as f:
            raw.append(json.load(f))
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
            body = resp.read().decode("utf-8", errors="ignore")

        # Check if we landed on a dead-product page
        for pattern in DEAD_URL_PATTERNS:
            if pattern in final_url:
                return {
                    "status":    "broken",
                    "http_code": http_code,
                    "final_url": final_url,
                    "reason":    f"Redirected to unavailable page (matched '{pattern}')",
                }

        # Page loaded fine, but the product itself may be out of stock —
        # Amazon keeps the listing live and just swaps the buy box text.
        body_lower = body.lower()
        for pattern in OUT_OF_STOCK_PATTERNS:
            if pattern in body_lower:
                return {
                    "status":    "out_of_stock",
                    "http_code": http_code,
                    "final_url": final_url,
                    "reason":    f"Page live but unorderable (matched '{pattern}')",
                }

        # amzn.to short links always redirect to a full amazon.com URL by
        # design — that's not a signal of anything wrong, so only flag a
        # redirect as noteworthy for direct amazon.com/dp/... links, where
        # it usually means the ASIN was delisted or swapped.
        is_short_link = "amzn.to" in url
        if not is_short_link and final_url.rstrip("/") != url.rstrip("/"):
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
ok           = [r for r in results if r["status"] == "ok"]
broken       = [r for r in results if r["status"] == "broken"]
redirects    = [r for r in results if r["status"] == "redirect"]
errors       = [r for r in results if r["status"] == "error"]
out_of_stock = [r for r in results if r["status"] == "out_of_stock"]

checked_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
today      = datetime.now(timezone.utc).strftime("%Y-%m-%d")

# ── Update persistent link status (drives which links get hidden) ─────────────
try:
    with open(STATUS_FILE, encoding="utf-8") as f:
        status = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    status = {}

newly_disabled, restored = [], []
for r in results:
    s = status.setdefault(r["url"], {
        "disabled": False, "fail_count": 0, "failing_since": None,
        "last_ok": None, "last_status": None, "disabled_since": None,
    })
    s["last_status"] = r["status"]
    if r["status"] in ("broken", "out_of_stock"):
        s["fail_count"] += 1
        s["failing_since"] = s["failing_since"] or today
        if not s["disabled"] and s["fail_count"] >= DISABLE_AFTER:
            s["disabled"], s["disabled_since"] = True, today
            newly_disabled.append(r["url"])
    elif r["status"] in ("ok", "redirect"):
        if s["disabled"]:
            restored.append(r["url"])
        s.update(disabled=False, fail_count=0, failing_since=None,
                 disabled_since=None, last_ok=today)
    # "error" → inconclusive; leave counters untouched

# Drop entries for URLs no longer used in any recipe
status = {u: s for u, s in status.items() if u in link_map}
for r in results:
    r["disabled"] = status[r["url"]]["disabled"]
    r["disabled_since"] = status[r["url"]]["disabled_since"]
disabled = [r for r in results if r["disabled"]]

with open(STATUS_FILE, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2, sort_keys=True)
    f.write("\n")
print(f"✓ Written {STATUS_FILE} ({len(disabled)} disabled, "
      f"{len(newly_disabled)} newly, {len(restored)} restored)")

# ── Write link_report.json ────────────────────────────────────────────────────
report_data = {
    "checked_at":      checked_at,
    "total":           len(results),
    "ok_count":            len(ok),
    "broken_count":        len(broken),
    "redirect_count":      len(redirects),
    "error_count":         len(errors),
    "out_of_stock_count":  len(out_of_stock),
    "disabled_count":      len(disabled),
    "results":             results,
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
    f"📦 Out of stock: {len(out_of_stock)} | "
    f"↩️ Redirected: {len(redirects)} | "
    f"⚠️ Error: {len(errors)} | "
    f"🙈 Hidden from users: {len(disabled)}",
    "",
]

if disabled:
    lines += ["## 🙈 Currently Hidden From Users — Needs Correction", "",
              "These items still appear in the app, but without a link. "
              "They reappear automatically once the product is orderable again; "
              "replace the URL in the recipe file if it is permanently dead.", ""]
    for r in disabled:
        lines.append(f"### `{r['url']}`")
        lines.append(f"- **Hidden since:** {r['disabled_since']}")
        lines.append(f"- **Latest check:** {r['status']} — {r['reason']}")
        lines.append(f"- **Used in:**")
        for u in r["usages"]:
            lines.append(f"  - *{u['recipe']}* → `{u['tool']}`")
        lines.append("")

if restored:
    lines += ["## ✅ Restored Today — Product Back, Link Re-enabled", ""]
    lines += [f"- `{u}`" for u in restored] + [""]

if out_of_stock:
    lines += ["## 📦 Out of Stock — Still Live, Can't Be Ordered", ""]
    for r in out_of_stock:
        lines.append(f"### `{r['url']}`")
        lines.append(f"- **Reason:** {r['reason']}")
        lines.append(f"- **Used in:**")
        for u in r["usages"]:
            lines.append(f"  - *{u['recipe']}* → `{u['tool']}`")
        lines.append("")

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

if not broken and not redirects and not errors and not out_of_stock and not disabled:
    lines.append("## ✅ All links are healthy!")

with open(REPORT_MD, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print(f"✓ Written {REPORT_MD}")

# ── Exit code: non-zero if anything needs attention ───────────────────────────
# The GitHub Action uses this to decide whether to send the alert email.
if broken or errors or out_of_stock or disabled:
    print(f"\n⚠️  {len(broken)} broken + {len(errors)} errors + {len(out_of_stock)} out of stock found.")
    sys.exit(1)   # triggers email alert in the Action
else:
    print(f"\n✅ All links OK (redirects: {len(redirects)}).")
    sys.exit(0)
