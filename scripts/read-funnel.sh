#!/bin/bash
#
# read-funnel.sh — liest die Download- und Feedback-Zähler aus dem KV-Store
# der Landing Page (issue 80). Nur lesen, nie schreiben.
#
# Läuft von überall im Repo; wrangler-Auth kommt aus dem normalen Login
# (`npx wrangler login`, einmalig). Ausgabe ist als Handoff-Snippet gedacht:
# direkt ins Auswertungs-Ticket kopierbar.
#
# Key-Schema (src/worker.js):
#   total, day:YYYY-MM-DD          — Downloads gesamt / pro Tag (seit #48)
#   downloads:src:<kanal>          — Downloads pro Kanal (seit #70)
#   signups:total, signups:src:<k> — E-Mail-Signups (Alt-Zähler + Rückrufnummer)
#   signup:<email>                 — JSON {ts, wishes[], src} — der Freitext-Kern (#72)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.scratch/landing-page"

NS="160a04f881a84f6fb116fc1d2e6870ef"
KV() { npx wrangler kv key "$@" --namespace-id "$NS" --remote; }

section() { printf '\n== %s ==\n' "$1"; }

# wrangler schreibt Werte auf stdout, Deko auf stderr; ein fehlender Key
# endet mit Fehler → als "0" lesen, aber echte Fehler nicht verschlucken:
# leere Ausgabe trotz Exit 0 wird als "?" markiert.
get() {
  local v
  if v="$(KV get "$1" 2>/dev/null)"; then
    printf '%s' "${v:-?}"
  else
    printf '0'
  fi
}

section "Downloads gesamt"
printf 'total: %s\n' "$(get total)"

section "Downloads pro Kanal (downloads:src:*)"
KV list --prefix "downloads:src:" 2>/dev/null \
  | grep -oE '"name":\s*"[^"]+"' | cut -d'"' -f4 \
  | while read -r k; do printf '%-32s %s\n' "${k#downloads:src:}" "$(get "$k")"; done

section "Downloads pro Tag (letzte 14)"
KV list --prefix "day:" 2>/dev/null \
  | grep -oE '"name":\s*"[^"]+"' | cut -d'"' -f4 | sort | tail -14 \
  | while read -r k; do printf '%s  %s\n' "${k#day:}" "$(get "$k")"; done

section "Signups"
printf 'signups:total: %s\n' "$(get signups:total)"
KV list --prefix "signups:src:" 2>/dev/null \
  | grep -oE '"name":\s*"[^"]+"' | cut -d'"' -f4 \
  | while read -r k; do printf '%-32s %s\n' "${k#signups:src:}" "$(get "$k")"; done

section "Freitext / Wishes (signup:*) — der eigentliche Lernstoff (#72)"
KV list --prefix "signup:" 2>/dev/null \
  | grep -oE '"name":\s*"[^"]+"' | cut -d'"' -f4 \
  | while read -r k; do printf '%s\n  %s\n' "${k#signup:}" "$(get "$k")"; done

cat <<'EOF'

== Abzugsposten (bekannte Test-Treffer, nicht Nutzer) ==
2026-08-10: src:acceptance 1 · src:direct ~3 (Deploy-Verifikation + Abnahme,
            issue 69; der src=release-check-Test wurde nie gezählt — Key fehlt)
2026-08-11: src:direct ~2 (Cache-Propagations-Checks nach den Deploys)
Dazu: die CTA-Kanäle (home-*/vs/marta/…) sind roh und ungefiltert — Crawler
folgen frisch deployten Links; Zählerstände der ersten Tage nicht als
Menschen lesen (bekannte #48-Grenze: raw GETs, kein Bot-Filter, kein Dedupe).
Bei Zweifel gegen day:*-Zähler halten.
EOF
