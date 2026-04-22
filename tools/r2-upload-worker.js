/**
 * YesChef R2 Upload Worker
 * ==========================
 * Accepts image file uploads from the contributor portal and saves
 * them to your Cloudflare R2 bucket. Your R2 credentials never leave
 * Cloudflare — the portal never touches them directly.
 *
 * Deploy steps:
 *   1. Install Wrangler:  npm install -g wrangler
 *   2. Login:             wrangler login
 *   3. Create R2 binding in wrangler.toml (see below)
 *   4. Deploy:            wrangler deploy
 *   5. Copy the worker URL into portal/index.html CONFIG.r2WorkerUrl
 *
 * wrangler.toml should contain:
 * ─────────────────────────────
 *   name = "yeschef-upload"
 *   main = "r2-upload-worker.js"
 *   compatibility_date = "2024-01-01"
 *
 *   [[r2_buckets]]
 *   binding = "BUCKET"
 *   bucket_name = "your-actual-bucket-name"
 *
 *   [vars]
 *   PORTAL_SECRET = "yeschef2024"   # must match portal password
 * ─────────────────────────────
 */

export default {
  async fetch(request, env) {

    // ── CORS preflight ─────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin':  '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-Portal-Secret',
        },
      });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    // ── Auth — simple shared secret ────────────────────────────────
    const secret = request.headers.get('X-Portal-Secret') || '';
    if (secret !== env.PORTAL_SECRET) {
      return json({ error: 'Unauthorized' }, 401);
    }

    // ── Parse multipart form ───────────────────────────────────────
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

    // ── Validate ───────────────────────────────────────────────────
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowed.includes(file.type)) {
      return json({ error: 'Only JPG, PNG, WebP allowed' }, 400);
    }

    const MAX_SIZE = 5 * 1024 * 1024; // 5MB
    if (file.size > MAX_SIZE) {
      return json({ error: 'File exceeds 5MB limit' }, 400);
    }

    // ── Build filename ─────────────────────────────────────────────
    const ext      = file.type === 'image/webp' ? 'webp' : file.type === 'image/png' ? 'png' : 'jpg';
    const key      = `assets/${slug}.${ext}`;
    const buffer   = await file.arrayBuffer();

    // ── Upload to R2 ───────────────────────────────────────────────
    try {
      await env.BUCKET.put(key, buffer, {
        httpMetadata: { contentType: file.type },
      });
    } catch (e) {
      return json({ error: `Upload failed: ${e.message}` }, 500);
    }

    // ── Return public URL ──────────────────────────────────────────
    // Adjust this base URL to match your R2 public bucket URL
    const publicUrl = `https://pub-3ae50d56fa834654954be23601470560.r2.dev/${key}`;

    return json({ url: publicUrl, key }, 200);
  }
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type':                 'application/json',
      'Access-Control-Allow-Origin':  '*',
    },
  });
}
