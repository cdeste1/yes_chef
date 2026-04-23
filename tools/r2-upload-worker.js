/**
 * YesChef R2 Upload + GitHub Proxy Worker
 * ==========================================
 * Handles two jobs so no secrets ever touch the browser:
 *   POST /upload   — uploads an image to R2
 *   POST /github   — proxies GitHub API calls (create branch, file, PR)
 *
 * Secrets (set via `wrangler secret put`):
 *   GITHUB_TOKEN   — your ghp_xxx token
 *   PORTAL_SECRET  — shared password (must match portal CONFIG.password)
 *
 * wrangler.toml bindings needed:
 *   [[r2_buckets]]
 *   binding = "BUCKET"
 *   bucket_name = "your-bucket-name"
 *
 *   [vars]
 *   PORTAL_SECRET = "yeschef2024"
 */
 
export default {
  async fetch(request, env) {
 
    // ── CORS preflight ─────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return cors(new Response(null));
    }
 
    if (request.method !== 'POST') {
      return cors(json({ error: 'Method not allowed' }, 405));
    }
 
    // ── Auth ───────────────────────────────────────────────────────
    const secret = request.headers.get('X-Portal-Secret') || '';
    if (secret !== env.PORTAL_SECRET) {
      return cors(json({ error: 'Unauthorized' }, 401));
    }
 
    const url  = new URL(request.url);
    const path = url.pathname;
 
    // ── Route: /upload ─────────────────────────────────────────────
    if (path === '/upload') {
      return cors(await handleUpload(request, env));
    }
 
    // ── Route: /github ─────────────────────────────────────────────
    if (path === '/github') {
      return cors(await handleGitHub(request, env));
    }
 
    return cors(json({ error: 'Not found' }, 404));
  }
};
 
// ══════════════════════════════════════════════════════════
// IMAGE UPLOAD → R2
// ══════════════════════════════════════════════════════════
async function handleUpload(request, env) {
  let formData;
  try {
    formData = await request.formData();
  } catch (e) {
    return json({ error: 'Invalid form data' }, 400);
  }
 
  const file = formData.get('file');
  const slug = (formData.get('slug') || 'recipe').replace(/[^a-z0-9-]/g, '');
 
  if (!file || !(file instanceof File)) {
    return json({ error: 'No file provided' }, 400);
  }
 
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (!allowed.includes(file.type)) {
    return json({ error: 'Only JPG, PNG, WebP allowed' }, 400);
  }
 
  if (file.size > 5 * 1024 * 1024) {
    return json({ error: 'File exceeds 5MB limit' }, 400);
  }
 
  const ext    = file.type === 'image/webp' ? 'webp' : file.type === 'image/png' ? 'png' : 'jpg';
  const key    = `assets/${slug}.${ext}`;
  const buffer = await file.arrayBuffer();
 
  try {
    await env.BUCKET.put(key, buffer, {
      httpMetadata: { contentType: file.type },
    });
  } catch (e) {
    return json({ error: `Upload failed: ${e.message}` }, 500);
  }
 
  const publicUrl = `https://pub-3ae50d56fa834654954be23601470560.r2.dev/${key}`;
  return json({ url: publicUrl, key });
}
 
// ══════════════════════════════════════════════════════════
// GITHUB API PROXY
// ══════════════════════════════════════════════════════════
async function handleGitHub(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (e) {
    return json({ error: 'Invalid JSON body' }, 400);
  }
 
  const { endpoint, method = 'GET', payload } = body;
 
  if (!endpoint || !endpoint.startsWith('/')) {
    return json({ error: 'Invalid endpoint' }, 400);
  }
 
  // Whitelist — only allow the specific GitHub API calls the portal needs
  const allowed = [
    /^\/repos\/[^/]+\/[^/]+\/git\/refs\/heads\//,
    /^\/repos\/[^/]+\/[^/]+\/git\/refs$/,
    /^\/repos\/[^/]+\/[^/]+\/contents\//,
    /^\/repos\/[^/]+\/[^/]+\/pulls$/,
  ];
 
  const permitted = allowed.some(re => re.test(endpoint));
  if (!permitted) {
    return json({ error: 'Endpoint not permitted' }, 403);
  }
 
  const ghResponse = await fetch(`https://api.github.com${endpoint}`, {
    method,
    headers: {
      'Authorization': `token ${env.GITHUB_TOKEN}`,
      'Accept':        'application/vnd.github+json',
      'Content-Type':  'application/json',
      'User-Agent':    'YesChef-Portal',
    },
    body: payload ? JSON.stringify(payload) : undefined,
  });
 
  const data = await ghResponse.json();
  return json(data, ghResponse.status);
}
 
// ── Helpers ───────────────────────────────────────────────
function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
 
function cors(response) {
  const r = new Response(response.body, response);
  r.headers.set('Access-Control-Allow-Origin',  '*');
  r.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  r.headers.set('Access-Control-Allow-Headers', 'Content-Type, X-Portal-Secret');
  return r;
}