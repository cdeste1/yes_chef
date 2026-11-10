#!/usr/bin/env python3
"""
YesChef — Affiliate Override Builder
======================================
Builds tools/affiliate_overrides.json: a map of {original link -> link tagged
with OUR affiliate tag} for every Amazon link in recipes/ that currently earns
for someone else (or nobody).

The recipe files are never modified. merge_recipes.py applies the map when it
builds the published recipes.json, so the change is fully reversible:
set "enabled": false in affiliate_overrides.json and redeploy.

Links already carrying MY_TAG are left alone. amzn.to shortlinks are resolved
(redirects are read, never the page) and rewritten to the long form
https://www.amazon.com/dp/<ASIN>?tag=<MY_TAG>.

Re-run any time new recipes are added; existing entries are kept, new
non-matching links get appended. Usage:
  python3 tools/build_affiliate_overrides.py [--dry-run]
"""
import glob, json, os, re, sys, urllib.request, urllib.error, urllib.parse
from concurrent.futures import ThreadPoolExecutor

MY_TAG = "yeschef0a02-20"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "affiliate_overrides.json")
RECIPES = os.path.join(HERE, "..", "recipes", "*.json")
DRY = "--dry-run" in sys.argv
UA = {"User-Agent": "Mozilla/5.0 (YesChef affiliate retag)"}

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None
opener = urllib.request.build_opener(NoRedirect)

def is_amazon(u):
    host = urllib.parse.urlparse(u).netloc.lower()
    return host == "amzn.to" or host.endswith("amazon.com")

def resolve(u):
    """Follow redirects manually (no page downloads) up to 5 hops."""
    for _ in range(5):
        try:
            opener.open(urllib.request.Request(u, headers=UA, method="HEAD"), timeout=20)
            return u
        except urllib.error.HTTPError as e:
            loc = e.headers.get("Location")
            if e.code in (301, 302, 303, 307, 308) and loc:
                u = urllib.parse.urljoin(u, loc)
                if "amzn.to" not in u:
                    return u
                continue
            return u
        except Exception:
            return None
    return u

ASIN = re.compile(r"/(?:dp|gp/product|gp/aw/d)/([A-Z0-9]{10})")

def tag_of(u):
    q = urllib.parse.parse_qs(urllib.parse.urlparse(u).query)
    return (q.get("tag") or [""])[0]

def retag(u):
    """Return (new_url|None, reason)."""
    full = u
    if urllib.parse.urlparse(u).netloc.lower() == "amzn.to":
        full = resolve(u)
        if not full:
            return None, "could not resolve shortlink"
    if tag_of(full).lower() == MY_TAG:
        return None, "already mine"
    m = ASIN.search(urllib.parse.urlparse(full).path)
    if not m:
        return None, f"no ASIN in {full[:80]}"
    return f"https://www.amazon.com/dp/{m.group(1)}?tag={MY_TAG}", "ok"

def links():
    found = set()
    def walk(n):
        if isinstance(n, dict):
            for k, v in n.items():
                if k == "link" and isinstance(v, str) and is_amazon(v.strip()):
                    found.add(v.strip())
                else:
                    walk(v)
        elif isinstance(n, list):
            for i in n: walk(i)
    for p in sorted(glob.glob(RECIPES)):
        with open(p, encoding="utf-8") as f:
            d = json.load(f)
        walk(d)
    return sorted(found)

existing = {"enabled": True, "my_tag": MY_TAG, "overrides": {}}
if os.path.exists(OUT):
    with open(OUT, encoding="utf-8") as f:
        existing = json.load(f)
overrides = existing.get("overrides", {})

todo = [u for u in links() if u not in overrides]
print(f"{len(todo)} link(s) to evaluate ({len(overrides)} already mapped)")
with ThreadPoolExecutor(12) as ex:
    results = list(ex.map(retag, todo))

skipped = {}
for u, (new, why) in zip(todo, results):
    if new:
        overrides[u] = new
    else:
        skipped.setdefault(why.split(" in ")[0], []).append(u)

for why, us in skipped.items():
    print(f"  skipped ({why}): {len(us)}")
    if why != "already mine":
        for u in us: print("     ", u)

existing.update(my_tag=MY_TAG, overrides=dict(sorted(overrides.items())))
existing.setdefault("enabled", True)
print(f"{len(overrides)} total override(s)")
if DRY:
    print("[dry run] nothing written")
else:
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2)
        f.write("\n")
    print(f"Wrote {OUT}")
