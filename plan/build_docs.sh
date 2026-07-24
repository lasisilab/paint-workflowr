#!/bin/bash
# Build styled, self-contained HTML for every plan/ markdown doc (Tina prefers HTML).
# Uses pandoc + the shared design tokens in assets/doc-style.html.
# Re-run after editing any .md:  bash plan/build_docs.sh
set -euo pipefail
cd "$(dirname "$0")"                 # -> plan/
STYLE="assets/doc-style.html"

# docs to convert (markdown -> sibling .html). sepia-plan.html + pipeline.html are hand-built; skip.
DOCS=(
  changelog.md rebuild_from_raw.md b2a_runbook.md cluster_inventory.md pipeline_workbook.md
  evaluation_plan.md CLUSTER_ACCESS.md papers/REFERENCES.md papers/VCF_QC.md papers/PIPELINE_QC_BY_PAPER.md
  papers/SAMPLE_INCLUSION.md verify/BUG_EVIDENCE.md
)

for md in "${DOCS[@]}"; do
  [ -f "$md" ] || { echo "skip (missing): $md"; continue; }
  out="${md%.md}.html"
  title=$(awk '/^# /{sub(/^# */,"");print;exit}' "$md"); [ -n "$title" ] || title="$md"
  # depth-correct back-link: papers/ and verify/ are one level down
  case "$md" in */*) root="../sepia-plan.html"; hub="../docs.html";; *) root="sepia-plan.html"; hub="docs.html";; esac
  bar="<div class=\"docbar\"><span class=\"b\">SEPIA</span> &nbsp;·&nbsp; <a href=\"$root\">← roadmap</a> &nbsp;·&nbsp; <a href=\"$hub\">all docs</a></div>"
  pandoc "$md" -f gfm -t html5 -s --template=assets/doc-template.html --metadata title="$title" \
    --include-in-header="$STYLE" --include-before-body=<(printf '%s' "$bar") \
    --wrap=preserve -o "$out"
  # wrap body content in <main> is done by our CSS targeting; rewrite relative .md links -> .html
  perl -0pi -e 's/href="(?!https?:|mailto:)([^"]*?)\.md(#[^"]*)?"/href="$1.html$2"/g' "$out"
  # the plan's HTML is the curated sepia-plan.html, not a generated plan.html
  perl -0pi -e 's{href="((?:\.\./)?)plan\.html"}{href="${1}sepia-plan.html"}g' "$out"
  echo "built: $out   ($title)"
done
echo "done: ${#DOCS[@]} docs"
