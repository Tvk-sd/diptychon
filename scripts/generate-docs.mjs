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
  // sibling docs become their web page; other repo files (../CONTEXT.md)
  // don't exist on the site, so they stay plain text
  s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, text, href) => {
    const page = PAGES.find((p) => p.src === href);
    if (page) return `<a href="/docs/${page.slug}">${text}</a>`;
    if (/^\.\.\/|\.md$/.test(href)) return text;
    return `<a href="${href}">${text}</a>`;
  });
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

const cur = (here, path) => (here === path ? ' aria-current="page"' : "");

const nav = (src, here) => `
<nav>
  <div class="in nav-in">
    <a class="brand" href="/" aria-label="Diptychon home"><img src="/icon-mark.png" alt="" width="26" height="26"><span>diptychon</span></a>
    <span class="nav-links">
      <a href="/#move">Features</a>
      <a href="/#shortcuts">Shortcuts</a>
      <a href="/vs"${cur(here, "/vs")}>Compare</a>
      <a href="/docs/"${cur(here, "/docs/")}>Docs</a>
    </span>
    <span class="nav-right">
      <button class="theme-toggle" id="theme-toggle" type="button" aria-label="Switch between light and dark theme">
        <svg class="tt-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4.4"/><path d="M12 2.5v2.6M12 18.9v2.6M2.5 12h2.6M18.9 12h2.6M5.2 5.2l1.9 1.9M16.9 16.9l1.9 1.9M18.8 5.2l-1.9 1.9M7.1 16.9l-1.9 1.9"/></svg>
        <svg class="tt-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.6 14.2A8.6 8.6 0 0 1 9.8 3.4a8.6 8.6 0 1 0 10.8 10.8Z"/></svg>
      </button>
      <a class="nav-cta" href="/download?src=${src}">Download for macOS</a>
    </span>
  </div>
</nav>`;

const footer = (src) => `
<footer>
  <div class="foot">
    <div class="fcol">
      <a class="brand" href="/"><img src="/icon-mark.png" alt="" width="26" height="26"><span>diptychon</span></a>
      <p class="fine">Native macOS, 2.7&nbsp;MB.<br>Built by Till von Krueger.</p>
    </div>
    <div class="fcol">
      <h4>Product</h4>
      <a href="/download?src=${src}-footer">Download</a>
      <a href="/#shortcuts">Keyboard shortcuts</a>
      <a href="/docs/">Docs</a>
    </div>
    <div class="fcol">
      <h4>Compare</h4>
      <a href="/vs">All file managers</a>
      <a href="/marta-alternative">Marta</a>
      <a href="/forklift-alternative">ForkLift</a>
      <a href="/path-finder-alternative">Path Finder</a>
      <a href="/total-commander-for-mac">Total Commander</a>
    </div>
    <div class="fcol">
      <h4>Legal</h4>
      <a href="/impressum">Impressum</a>
      <a href="/datenschutz">Datenschutz</a>
    </div>
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
  /* docs sit in the homepage lattice: ruled sub-nav strip, section bands
     from page.css h2, row-ruled tables, flat code blocks */
  .docmain{width:var(--col);margin-inline:auto;padding:104px 24px 0}
  /* page is homepage-wide; prose keeps a readable line length */
  .docmain > :not(.tablewrap):not(pre):not(.doc-cells){max-width:760px}
  .docmain hr{display:none}
  /* the docs number their own sections; the band label would repeat it */
  .docmain h2::after{content:none}
  .docmain h2{padding-top:96px}
  .docmain h3{margin:36px 0 10px;font-size:20px;font-weight:600;letter-spacing:-.01em}
  .docmain p,.docmain li{line-height:1.65}
  .docmain pre{background:var(--bg-inset);border:0;border-radius:0;padding:16px 20px;overflow-x:auto;font-size:13.5px}
  .docmain blockquote{margin:20px 0;padding:2px 20px;border-inline-start:1px solid var(--line-strong);color:var(--ink-dim)}
  .docmain .tablewrap{overflow-x:auto;margin:20px 0;border-block:1px solid var(--line-soft)}
  .docmain table{min-width:0}
  .docmain code{font-family:var(--mono);font-size:.86em;background:var(--bg-inset);border:1px solid var(--line-soft);border-radius:4px;padding:.08em .35em}
  .docmain pre code{background:none;border:none;padding:0}
  .docbar{border-bottom:1px solid var(--line-soft);position:relative;z-index:1}
  nav.docnav{position:static;background:none;backdrop-filter:none;-webkit-backdrop-filter:none;border:0;display:flex;flex-wrap:wrap;font-family:var(--mono);font-size:12.5px}
  .docnav a{padding:14px 20px;border-left:1px solid var(--line-soft);color:var(--ink-dim)}
  .docnav a:first-child{border-left:0;padding-left:0}
  .docnav a:hover{color:var(--ink)}
  .docnav a[aria-current]{color:var(--ink);box-shadow:inset 0 -1px 0 var(--ink)}
  .doc-cells{display:grid;grid-template-columns:repeat(3,1fr);margin:56px -24px 0;border-top:1px solid var(--line-soft)}
  .doc-cell{display:flex;flex-direction:column;gap:12px;padding:28px 24px 40px;border-left:1px solid var(--line-soft);color:var(--ink)}
  .doc-cell:first-child{border-left:0}
  .doc-cell:hover{background:var(--hover);color:var(--ink)}
  .doc-cell h3{margin:0;font-size:19px}
  .doc-cell p{margin:0;font-size:15px;color:var(--ink-dim)}
  .doc-cell .go{color:var(--accent)}
  @media (max-width:760px){.doc-cells{grid-template-columns:1fr}.doc-cell{border-left:0;border-top:1px solid var(--line-soft)}.doc-cell:first-child{border-top:0}.docmain{padding-top:72px}}
  .docstamp{font-family:var(--mono);font-size:12px;color:var(--ink-faint);margin-top:72px}
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
${nav(src, "/docs/")}
<div class="docbar"><nav class="docnav in" aria-label="Docs">
  ${[["/docs/", "Overview", "index"], ...PAGES.map((p) => [`/docs/${p.slug}`, p.label, p.slug])].map(([href, label, s]) => `<a href="${href}"${s === slug ? ' aria-current="page"' : ""}>${label}</a>`).join("")}
</nav></div>
<main class="docmain">
<p class="label">Docs · Diptychon</p>
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
    .replace(/\s+/g, " ").replace(/\[([^\]]+)\]\([^)]*\)/g, "$1").replace(/[*`>#|]/g, "").trim().slice(0, 155);
  const html = page({
    title,
    description: firstPara,
    slug: p.slug,
    body: mdToHtml(md),
    src: `docs-${p.slug}`,
  });
  writeFileSync(join(LP, "docs", `${p.slug}.html`), html);
  writeFileSync(join(LP, "dist", "docs", `${p.slug}.html`), html);
  indexCards.push(`<a class="doc-cell" href="/docs/${p.slug}"><span class="label">${String(indexCards.length + 1).padStart(2, "0")}</span><h3>${esc(title)} <span class="go">→</span></h3><p>${esc(firstPara)}…</p></a>`);
  console.log(`docs/${p.slug}.html ← docs/${p.src}`);
}

const indexHtml = page({
  title: "Documentation",
  description: "Diptychon documentation: user guide, the complete keyboard reference, and gadgets.",
  slug: "index",
  body: `<h1>Documentation</h1>\n<div class="doc-cells">\n${indexCards.join("\n")}\n</div>`,
  src: "docs",
});
writeFileSync(join(LP, "docs", "index.html"), indexHtml);
writeFileSync(join(LP, "dist", "docs", "index.html"), indexHtml);
console.log("docs/index.html (hub)");
