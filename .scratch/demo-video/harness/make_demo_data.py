#!/usr/bin/env python3
"""Build the Diptychon demo-video showcase tree: a creative-studio mix of
photo shoots (real JPEGs so previews render), client assets, and a small dev
project. Images are smooth two-tone gradients + noise written as PPM and
converted with sips."""
import os, random, struct, subprocess, sys, time

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Studio")
random.seed(7)

PALETTES = {
    "harbor":   ((28, 58, 94), (214, 168, 120)),
    "portrait": ((72, 48, 60), (226, 200, 186)),
    "aurora":   ((16, 84, 76), (240, 196, 92)),
    "album":    ((30, 24, 54), (198, 84, 110)),
    "stock":    ((40, 90, 60), (222, 226, 200)),
    "icon":     ((36, 40, 48), (120, 190, 230)),
}

def write_image(path, palette, w=1600, h=1067, fmt="jpeg"):
    (r1, g1, b1), (r2, g2, b2) = PALETTES[palette]
    ang = random.uniform(0.2, 0.8)
    rows = []
    for y in range(h):
        row = bytearray()
        fy = y / h
        for x in range(0, w, 4):          # 4px blocks keep it fast
            t = min(1.0, max(0.0, ang * (x / w) + (1 - ang) * fy + random.uniform(-0.03, 0.03)))
            px = struct.pack("BBB", int(r1 + (r2 - r1) * t), int(g1 + (g2 - g1) * t), int(b1 + (b2 - b1) * t))
            row += px * 4
        rows.append(bytes(row[: w * 3]))
    ppm = path + ".ppm"
    with open(ppm, "wb") as f:
        f.write(b"P6\n%d %d\n255\n" % (w, h))
        f.writelines(rows)
    subprocess.run(["sips", "-s", "format", fmt, ppm, "--out", path],
                   check=True, capture_output=True)
    os.remove(ppm)

def write_text(path, text):
    with open(path, "w") as f:
        f.write(text)

def write_pdf(path, title, lines):
    body = "BT /F1 18 Tf 72 740 Td (%s) Tj ET\n" % title
    y = 700
    for ln in lines:
        body += "BT /F1 11 Tf 72 %d Td (%s) Tj ET\n" % (y, ln)
        y -= 18
    objs = ["1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n",
            "2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n",
            "3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R"
            "/Resources<</Font<</F1 5 0 R>>>>>>endobj\n",
            "4 0 obj<</Length %d>>stream\n%sendstream endobj\n" % (len(body), body),
            "5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\n"]
    out = "%PDF-1.4\n"
    offsets = []
    for o in objs:
        offsets.append(len(out)); out += o
    xref = len(out)
    out += "xref\n0 6\n0000000000 65535 f \n"
    for off in offsets:
        out += "%010d 00000 n \n" % off
    out += "trailer<</Size 6/Root 1 0 R>>\nstartxref\n%d\n%%%%EOF" % xref
    with open(path, "wb") as f:
        f.write(out.encode("latin-1"))

def raw_file(path, mb):
    with open(path, "wb") as f:
        f.write(os.urandom(mb * 1024 * 1024))

D = lambda *p: os.path.join(ROOT, *p)
for d in ["Clients/Aurora Coffee/Moodboard", "Clients/Aurora Coffee/Logo Exports",
          "Clients/Nordwind Records/Album Art", "Clients/Nordwind Records/Contracts",
          "Shoots/2026-06 Harbor Editorial/RAW", "Shoots/2026-06 Harbor Editorial/Selects",
          "Shoots/2026-07 Studio Portraits/RAW", "Shoots/2026-07 Studio Portraits/Selects",
          "Dev/portfolio-site/src", "Dev/tools", "Assets/Fonts", "Assets/Icons",
          "Assets/Stock", "Archive/2025"]:
    os.makedirs(D(d), exist_ok=True)

# --- Shoots ---
for i, n in enumerate([142, 155, 161, 178, 190, 204]):
    raw_file(D("Shoots/2026-06 Harbor Editorial/RAW", "DSC_0%d.dng" % n), 18 + i % 5)
for i in range(1, 6):
    write_image(D("Shoots/2026-06 Harbor Editorial/Selects", "harbor-editorial-%02d.jpg" % i), "harbor")
for i, n in enumerate([311, 324, 330, 347]):
    raw_file(D("Shoots/2026-07 Studio Portraits/RAW", "DSC_0%d.dng" % n), 19 + i % 4)
for i in range(1, 5):
    write_image(D("Shoots/2026-07 Studio Portraits/Selects", "portrait-session-%02d.jpg" % i), "portrait")

# --- Clients ---
for i in range(1, 5):
    write_image(D("Clients/Aurora Coffee/Moodboard", "moodboard-%02d.jpg" % i), "aurora")
for n in ["aurora-logo-dark.png", "aurora-logo-light.png", "aurora-icon.png"]:
    write_image(D("Clients/Aurora Coffee/Logo Exports", n), "aurora", 800, 800, "png")
write_text(D("Clients/Aurora Coffee/Brief.md"),
    "# Aurora Coffee — Brand Refresh\n\n**Deliverables:** logo suite, packaging, "
    "web assets\n**Deadline:** 2026-08-15\n\n- Warm, hand-crafted feel\n- Keep the "
    "kettle mark\n- Print + digital variants\n")
for i in range(1, 4):
    write_image(D("Clients/Nordwind Records/Album Art", "nordwind-cover-v%d.jpg" % i), "album", 1400, 1400)
write_pdf(D("Clients/Nordwind Records/Contracts", "Invoice-2026-018.pdf"),
          "Invoice 2026-018", ["Nordwind Records", "Album artwork, 3 concepts",
                               "Amount: EUR 2.400,00", "Due: 2026-08-01"])
write_text(D("Clients/Nordwind Records/Contracts", "Usage-Rights.md"),
    "# Usage Rights — Nordwind Records\n\nArtwork licensed for physical + "
    "streaming release.\nTerritory: worldwide. Term: unlimited.\n")

# --- Dev ---
write_text(D("Dev/portfolio-site/src", "index.html"),
    "<!doctype html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n"
    "  <title>Studio Portfolio</title>\n  <link rel=\"stylesheet\" href=\"styles.css\">\n"
    "</head>\n<body>\n  <main id=\"gallery\"></main>\n  <script src=\"gallery.js\"></script>\n"
    "</body>\n</html>\n")
write_text(D("Dev/portfolio-site/src", "styles.css"),
    ":root { --ink: #1c1c1e; --paper: #faf9f7; }\nbody { margin: 0; background: "
    "var(--paper); color: var(--ink); }\n#gallery { display: grid; grid-template-columns: "
    "repeat(3, 1fr); gap: 12px; padding: 24px; }\n")
write_text(D("Dev/portfolio-site/src", "gallery.js"),
    "const shots = await fetch('/api/shots').then(r => r.json());\n"
    "const gallery = document.getElementById('gallery');\nfor (const shot of shots) {\n"
    "  const img = new Image();\n  img.src = shot.thumb;\n  img.loading = 'lazy';\n"
    "  gallery.append(img);\n}\n")
write_text(D("Dev/portfolio-site", "package.json"),
    '{\n  "name": "studio-portfolio",\n  "private": true,\n  "scripts": {\n'
    '    "dev": "vite",\n    "build": "vite build"\n  },\n  "devDependencies": '
    '{\n    "vite": "^6.0.0"\n  }\n}\n')
write_text(D("Dev/portfolio-site", "README.md"),
    "# Studio Portfolio\n\nStatic gallery site. `npm run dev` to start.\n")
write_text(D("Dev/tools", "batch-export.sh"),
    "#!/bin/zsh\n# Export selects to web-ready JPEGs\nfor f in \"$1\"/*.jpg; do\n"
    "  sips -Z 2048 -s formatOptions 82 \"$f\" --out \"web/${f:t}\"\ndone\n")
write_text(D("Dev/tools", "metadata.py"),
    "#!/usr/bin/env python3\n\"\"\"Strip GPS EXIF from delivery files.\"\"\"\n"
    "import sys\nfrom exif_tool import scrub\n\nfor path in sys.argv[1:]:\n"
    "    scrub(path, drop=[\"gps\"])\n")

# --- Assets ---
for n in ["GrotesqueText-Regular.otf", "GrotesqueText-Bold.otf"]:
    with open(D("Assets/Fonts", n), "wb") as f:
        f.write(os.urandom(180 * 1024))
for i, n in enumerate(["camera.png", "folder-open.png", "export-arrow.png"]):
    write_image(D("Assets/Icons", n), "icon", 512, 512, "png")
for i in range(1, 5):
    write_image(D("Assets/Stock", "texture-%02d.jpg" % i), "stock")
write_text(D("Notes.md"),
    "# Studio Notes\n\n- Harbor selects → Nordwind by Friday\n- Aurora moodboard "
    "review Tue 10:00\n- Order 2x 4TB backup drives\n")
write_text(D("Archive/2025", "year-summary.md"), "# 2025 — Archived projects\n")

# --- staggered mtimes (June–July 2026) ---
t0 = time.mktime((2026, 6, 2, 10, 0, 0, 0, 0, -1))
paths = []
for base, dirs, files in os.walk(ROOT):
    paths += [os.path.join(base, f) for f in files]
for i, p in enumerate(sorted(paths)):
    ts = t0 + i * 86400 * 49 / max(1, len(paths) - 1)   # spread across ~7 weeks
    os.utime(p, (ts, ts))

print("done:", ROOT, "|", len(paths), "files")
