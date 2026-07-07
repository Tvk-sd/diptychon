export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/download") {
      if (request.method === "GET") {
        // Don't make the user wait for the bookkeeping
        ctx.waitUntil(recordDownload(env));
      }
      return Response.redirect(new URL("/Diptychon.zip", url).toString(), 302);
    }

    return env.ASSETS.fetch(request);
  },
};

async function recordDownload(env) {
  const day = new Date().toISOString().slice(0, 10);
  for (const key of ["total", `day:${day}`]) {
    const current = parseInt((await env.DOWNLOADS.get(key)) ?? "0", 10);
    await env.DOWNLOADS.put(key, String(current + 1));
  }
}
