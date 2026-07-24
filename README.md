# SEPIA

**Systematic Evaluation of Pigmentation In Archaic hominins**

SEPIA asks what skin/hair/eye **pigmentation genetics** can — and can't — tell us about
Neanderthals and Denisovans, and how they compare to modern humans. It is a careful,
QC-first re-analysis: the archaic DNA is patchy and shallow and pigmentation genes don't
behave like ancestry markers, so the contribution is an **honest map of what the
pigmentation genetics does and doesn't support**, with the uncertainty made explicit.

This repository is the working anchor for the project. It continues and re-evaluates the
prior honors thesis **PAINT** (Lily Heald), rebuilding the analysis from clearly-traced
inputs; Lily's original thesis repository is separate and unchanged.

## Where things are

- **[`plan/plan.md`](plan/plan.md)** — the single canonical roadmap (phased; bug fixes,
  analysis redesign, QC checks `Q1`–`Q10`, infrastructure, writing). Shareable rendering:
  **[`plan/sepia-plan.html`](plan/sepia-plan.html)**.
- **[`plan/changelog.md`](plan/changelog.md)** — dated log of what was done / found / decided.
- **[`plan/docs.html`](plan/docs.html)** — hub linking every project document (data &
  pipeline record, rebuild plan, per-genome provenance & QC, bug-evidence log).
- **`analysis/`** — the [workflowr](https://workflowr.github.io/workflowr/) R Markdown site
  (rendered output in `docs/`, deployed to GitHub Pages).

## Build

The website is a workflowr project built locally with `wflow_publish()`; the rendered
`docs/` is committed and deployed by `.github/workflows/publish-site.yml` (CI does not
re-run R). Project documents under `plan/` are regenerated with `bash plan/build_docs.sh`.
