export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Canonical host: everything funnels to the apex, which carries the
    // Access wall — www must never serve content of its own
    if (url.hostname === "www.diptychon.com") {
      url.hostname = "diptychon.com";
      return Response.redirect(url.toString(), 301);
    }

    if (url.pathname === "/download") {
      if (request.method === "GET") {
        // Don't make the user wait for the bookkeeping
        ctx.waitUntil(recordDownload(env, normalizeSrc(url.searchParams.get("src"))));
      }
      // Serve the zip directly (no redirect hop) so an Access login
      // round-trip can land back here and still end in the download
      const asset = await env.ASSETS.fetch(new URL("/Diptychon.zip", url));
      const headers = new Headers(asset.headers);
      headers.set("content-disposition", 'attachment; filename="Diptychon.zip"');
      return new Response(asset.body, { status: asset.status, headers });
    }

    // Interest capture (reach test): email + optional wishes → KV, keyed by
    // email so a follow-up wishes POST updates the same signup record.
    if (url.pathname === "/api/notify" && request.method === "POST") {
      return handleNotify(request, env);
    }

    return env.ASSETS.fetch(request);
  },
};

// A download is a real commitment act, unlike an email address — so it is the
// signal worth splitting by channel. Existing bare `total` / `day:*` keys stay
// untouched; the per-channel counter is namespaced so a KV listing stays
// readable next to `signups:src:*`.
async function recordDownload(env, src) {
  const day = new Date().toISOString().slice(0, 10);
  for (const key of ["total", `day:${day}`, `downloads:src:${src}`]) {
    await bump(env, key);
  }
}

// One normalizer for both routes: lowercase, drop anything that would make a KV
// key awkward, cap the length, and fall back to "direct" when empty or missing.
function normalizeSrc(raw) {
  return (
    String(raw ?? "direct")
      .toLowerCase()
      .replace(/[^a-z0-9._-]/g, "")
      .slice(0, 40) || "direct"
  );
}

async function handleNotify(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ ok: false, error: "bad request" }, 400);
  }
  const email = String(body.email ?? "").trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) {
    return json({ ok: false, error: "invalid email" }, 400);
  }
  const key = `signup:${email}`;
  const existing = await env.DOWNLOADS.get(key, "json");
  const wishes = Array.isArray(body.wishes)
    ? [...new Set(body.wishes.map((w) => String(w).slice(0, 40)))].slice(0, 12)
    : existing?.wishes ?? [];
  // Channel of the *first* touch wins — a later wishes POST never rewrites it.
  const src = existing?.src ?? normalizeSrc(body.src);
  await env.DOWNLOADS.put(
    key,
    JSON.stringify({ ts: existing?.ts ?? new Date().toISOString(), wishes, src })
  );
  if (!existing) {
    await bump(env, "signups:total");
    await bump(env, `signups:src:${src}`);
  }
  return json({ ok: true });
}

async function bump(env, key) {
  const n = parseInt((await env.DOWNLOADS.get(key)) ?? "0", 10);
  await env.DOWNLOADS.put(key, String(n + 1));
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}
