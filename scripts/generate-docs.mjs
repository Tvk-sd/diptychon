#!/usr/bin/env node
// Generates the /docs pages on diptychon.com from the markdown sources in
// docs/. The web copy is NEVER edited by hand — DocsKeyboardReferenceTests
// guards the repo markdown against Keymap.default, and this script carries
// that guarded source to the web. Hand-edited HTML here would drift unguarded
// (issue 42, bundled into issue 71).
//
// Usage: node scripts/generate-docs.mjs
// Output: .scratch/landing-page/docs/*.html (+ mirrored to dist/docs/)

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const LP = join(ROOT, ".scratch", "landing-page");

const PAGES = [
  { src: "user-guide.md", slug: "user-guide", label: "User Guide" },
  { src: "keyboard-reference.md", slug: "keyboard-reference", label: "Keyboard Reference" },
  { src: "gadgets.md", slug: "gadgets", label: "Gadgets" },
];

// ---------------------------------------------------------------- markdown →
// Minimal converter for the subset our docs use: #/##/### headings, GFM
// tables, fenced code, > blockquotes, -/* and 1. lists, inline code/bold/
// em/links. Anything fancier belongs in the docs only after extending this.

const esc = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function inline(s) {
  // escape first, then re-introduce our own tags
  s = esc(s);
  s = s.replace(/`([^`]+)`/g, (_, c) => `<code>${c}</code>`);
  s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  s = s.replace(/(^|[^*])\*([^*\s][^*]*)\*/g, "$1<em>$2</em>");
  s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
  return s;
}

function mdToHtml(md) {
  const lines = md.split("\n");
  const out = [];
  let i = 0;
  const peek = () => lines[i];

  while (i < lines.length) {
    const line = peek();

    if (line === undefined) break;
    if (/^\s*$/.test(line)) { i++; continue; }

    if (line.startsWith("```")) {
      i++;
      const code = [];
      while (i < lines.length && !lines[i].startsWith("```")) code.push(lines[i++]);
      i++; // closing fence
      out.push(`<pre><code>${esc(code.join("\n"))}</code></pre>`);
      continue;
    }

    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      const level = h[1].length;
      const text = h[2];
      const id = text.toLowerCase().replace(/<[^>]+>/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
      out.push(`<h${level} id="${id}">${inline(text)}</h${level}>`);
      i++;
      continue;
    }

    if (line.startsWith(">")) {
      const quote = [];
      while (i < lines.length && lines[i].startsWith(">")) quote.push(lines[i++].replace(/^>\s?/, ""));
      out.push(`<blockquote><p>${inline(quote.join(" "))}</p></blockquote>`);
      continue;
    }

    if (/^\|/.test(line)) {
      const rows = [];
      while (i < lines.length && /^\|/.test(lines[i])) rows.push(lines[i++]);
      const cells = (r) => r.replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
      const head = cells(rows[0]);
      const body = rows.slice(2); // skip the |---| separator
      let t = '<div class="tablewrap" role="region" tabindex="0"><table><thead><tr>';
      t += head.map((c) => `<th scope="col">${inline(c)}</th>`).join("");
      t += "</tr></thead><tbody>";
      for (const r of body) t += "<tr>" + cells(r).map((c) => `<td>${inline(c)}</td>`).join("") + "</tr>";
      t += "</tbody></table></div>";
      out.push(t);
      continue;
    }

    if (/^\s*[-*]\s+/.test(line)) {
      const items = [];
      while (i < lines.length && /^\s*[-*]\s+/.test(lines[i])) {
        let item = lines[i++].replace(/^\s*[-*]\s+/, "");
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !/^\s*[-*]\s+/.test(lines[i]))
          item += " " + lines[i++].trim();
        items.push(`<li>${inline(item)}</li>`);
      }
      out.push(`<ul>${items.join("")}</ul>`);
      continue;
    }

    if (/^\s*\d+\.\s+/.test(line)) {
      const items = [];
      while (i < lines.length && /^\s*\d+\.\s+/.test(lines[i])) {
        let item = lines[i++].replace(/^\s*\d+\.\s+/, "");
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !/^\s*\d+\.\s+/.test(lines[i]))
          item += " " + lines[i++].trim();
        items.push(`<li>${inline(item)}</li>`);
      }
      out.push(`<ol>${items.join("")}</ol>`);
      continue;
    }

    if (/^---+\s*$/.test(line)) { out.push("<hr>"); i++; continue; }

    // paragraph: consume until blank line or a block starter
    const para = [];
    while (i < lines.length && !/^\s*$/.test(lines[i]) &&
           !/^(#{1,4}\s|```|>|\||\s*[-*]\s|\s*\d+\.\s|---+\s*$)/.test(lines[i]))
      para.push(lines[i++]);
    out.push(`<p>${inline(para.join(" "))}</p>`);
  }
  return out.join("\n");
}

// ------------------------------------------------------------------ template

const nav = (src) => `
<nav>
  <div class="in nav-in">
    <a class="brand" href="/"><img src="/icon.png" alt="" width="26" height="26"><span>diptychon</span></a>
    <span class="nav-right">
      <button class="theme-toggle" id="theme-toggle" type="button" aria-label="Switch between light and dark theme">
        <svg class="tt-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4.4"/><path d="M12 2.5v2.6M12 18.9v2.6M2.5 12h2.6M18.9 12h2.6M5.2 5.2l1.9 1.9M16.9 16.9l1.9 1.9M18.8 5.2l-1.9 1.9M7.1 16.9l-1.9 1.9"/></svg>
        <svg class="tt-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.6 14.2A8.6 8.6 0 0 1 9.8 3.4a8.6 8.6 0 1 0 10.8 10.8Z"/></svg>
      </button>
      <a class="nav-cta" href="/download?src=${src}">Download free beta</a>
    </span>
  </div>
</nav>`;

const footer = (src) => `
<footer>
  <div class="in foot-in">
    <span>© Diptychon, native macOS, ~2.7 MB</span>
    <span class="foot-links">
      <a href="/">Home</a>
      <a href="/docs/">Docs</a>
      <a href="/download?src=${src}">Download free beta</a>
      <a href="/impressum">Impressum</a>
      <a href="/datenschutz">Datenschutz</a>
    </span>
  </div>
</footer>`;

const themeScript = `
<script>
  (function(){
    var btn = document.getElementById('theme-toggle');
    if (!btn) return;
    btn.addEventListener('click', function(){
      var root = document.documentElement;
      var effective = root.getAttribute('data-theme') ||
        (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
      var next = effective === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try{ localStorage.setItem('theme', next); }catch(e){}
    });
  })();
</script>`;

// prose styles page.css doesn't carry (it styles the marketing shells)
const docsCss = `
<style>
  .docmain{max-width:820px;margin-inline:auto;padding:48px 24px 80px}
  .docmain h1{margin:0 0 6px}
  .docmain h2{margin:44px 0 12px;font-size:24px}
  .docmain h3{margin:30px 0 10px;font-size:18.5px}
  .docmain p,.docmain li{line-height:1.65}
  .docmain pre{background:var(--bg-inset,rgba(127,127,127,.08));border:1px solid var(--line,#8884);border-radius:8px;padding:14px 16px;overflow-x:auto;font-size:13.5px}
  .docmain blockquote{margin:16px 0;padding:2px 18px;border-inline-start:3px solid var(--line-strong,#8886);color:var(--ink-dim,inherit)}
  .docmain .tablewrap{overflow-x:auto;margin:16px 0}
  .docmain table{border-collapse:collapse;width:100%;font-size:14.5px}
  .docmain th,.docmain td{border:1px solid var(--line,#8884);padding:7px 12px;text-align:left}
  .docmain th{background:var(--bg-inset,rgba(127,127,127,.06))}
  .docmain code{font-family:var(--mono,ui-monospace,monospace);font-size:.86em;background:var(--bg-inset,rgba(127,127,127,.1));border:1px solid var(--line,#8884);border-radius:5px;padding:.08em .35em}
  .docmain pre code{background:none;border:none;padding:0}
  .docnav{font-family:var(--mono,monospace);font-size:12.5px;margin:0 0 26px}
  .docnav a{margin-right:14px}
  .docstamp{font-family:var(--mono,monospace);font-size:12px;color:var(--ink-faint,inherit);margin-top:48px}
</style>`;

function page({ title, description, slug, body, src }) {
  const canonical = `https://diptychon.com/docs/${slug === "index" ? "" : slug}`;
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>${esc(title)} — Diptychon Docs</title>
<meta name="description" content="${esc(description)}" />
<link rel="canonical" href="${canonical}" />
<link rel="icon" type="image/png" href="/icon.png" />
<script>
  (function(){
    try{
      var t = localStorage.getItem('theme');
      if (t === 'dark' || t === 'light') document.documentElement.setAttribute('data-theme', t);
    }catch(e){}
  })();
</script>
<link rel="stylesheet" href="/page.css" />
${docsCss}
</head>
<body>
<div class="rails" aria-hidden="true"></div>
${nav(src)}
<main class="docmain">
<p class="label">Docs · Diptychon</p>
<nav class="docnav" aria-label="Docs">
  <a href="/docs/">Overview</a><a href="/docs/user-guide">User Guide</a><a href="/docs/keyboard-reference">Keyboard Reference</a><a href="/docs/gadgets">Gadgets</a>
</nav>
${body}
<p class="docstamp">Generated from the repository docs (guarded by tests against the app's real key table) · ${new Date().toISOString().slice(0, 10)}</p>
</main>
${footer(src)}
${themeScript}
</body>
</html>
`;
}

// ----------------------------------------------------------------------- run

mkdirSync(join(LP, "docs"), { recursive: true });
mkdirSync(join(LP, "dist", "docs"), { recursive: true });

const indexCards = [];
for (const p of PAGES) {
  const md = readFileSync(join(ROOT, "docs", p.src), "utf8");
  const title = (md.match(/^#\s+(.*)$/m) || [, p.label])[1];
  const firstPara = (md.split(/\n\s*\n/).find((b) => !b.startsWith("#")) || "")
    .replace(/\s+/g, " ").replace(/[*`>#|]/g, "").trim().slice(0, 155);
  const html = page({
    title,
    description: firstPara,
    slug: p.slug,
    body: mdToHtml(md),
    src: `docs-${p.slug}`,
  });
  writeFileSync(join(LP, "docs", `${p.slug}.html`), html);
  writeFileSync(join(LP, "dist", "docs", `${p.slug}.html`), html);
  indexCards.push(`<h2><a href="/docs/${p.slug}">${esc(title)}</a></h2><p>${esc(firstPara)}…</p>`);
  console.log(`docs/${p.slug}.html ← docs/${p.src}`);
}

const indexHtml = page({
  title: "Documentation",
  description: "Diptychon documentation: user guide, the complete keyboard reference, and gadgets.",
  slug: "index",
  body: `<h1>Documentation</h1>\n${indexCards.join("\n")}`,
  src: "docs",
});
writeFileSync(join(LP, "docs", "index.html"), indexHtml);
writeFileSync(join(LP, "dist", "docs", "index.html"), indexHtml);
console.log("docs/index.html (hub)");
