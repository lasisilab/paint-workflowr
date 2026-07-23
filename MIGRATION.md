# workflowr → Quarto migration

**Branch:** `quarto-migration`. **Status:** scaffold complete and prose pages verified; the R-heavy analysis pages need **one local render** before this can be merged to `main` and go live. The old workflowr site on `main` is untouched until then.

## Why it's on a branch (and not yet live)
The analysis pages run R against data files (`data/pigmentation_snps.csv`, `data/neo_uvi.csv`, `data/ancient_depth_clean.csv`, `data/modern_metadata.csv`), and those files are **git-ignored / not present in this working copy** — so `introduction.qmd`, `depth.qmd`, `pca.qmd`, and `cleaning.qmd` cannot be rendered without them. CI deliberately does **not** run R (`execute: freeze: auto`), so it relies on committed `_freeze/` results. Those must be produced once on a machine that has R **and** the data (your laptop with the data present, or the cluster).

## What changed
- **Pages** ported `analysis/*.Rmd` → root `*.qmd`: `index` (rewritten to a project-level landing page — thesis is now framed as "v1"), `introduction` (Background), `depth`, `pca`, `about`, `license`, `cleaning`. Quarto reads the existing ```{r}``` chunks natively; only the YAML front matter changed.
- **`_quarto.yml`** — website config, `theme: cosmo` (same as before), navbar matching the old one, `execute-dir: project` (so `data/...` paths resolve from the repo root as they did under workflowr's `knit_root_dir: "."`), `execute: freeze: auto`.
- **`.github/workflows/publish-site.yml`** — replaced the workflowr-static-deploy with a Quarto render + Pages deploy (Node-24 action majors), and it still copies `plan/*.html` into `/plan/`.
- **Removed** the workflowr scaffolding: `analysis/_site.yml`, `_workflowr.yml`, and the `analysis/*.Rmd` page sources (now `.qmd` at root). The pipeline scripts (`analysis/*.py`, `*.slurm`, `analysis/introgression_app/`) were left in place.
- **`.gitignore`** — added `/_site/`, `/.quarto/`; `_freeze/` is intentionally tracked.

## To finish the migration (do this locally, with R + the data files)
1. Put the four data files above in `data/` (from the cluster or your archive).
2. `quarto render` — this executes the R pages and writes `_freeze/`. Confirm `introduction`, `depth`, `pca` show their figures in `_site/`.
3. `git add _freeze && git commit` the frozen results.
4. Remove the now-vestigial workflowr output: `git rm -r docs/` (Quarto publishes `_site/`, not `docs/`). Optionally also drop `.Rprofile` and `PAINT.Rproj` if you're done with the RStudio/workflowr setup.
5. Merge `quarto-migration` → `main`. The push triggers the publish workflow, which serves the Quarto `_site/` (with the frozen figures) at <https://lasisilab.github.io/paint-workflowr/>, plan still at `/plan/`.

## Verified in the migration environment
- `quarto render index.qmd about.qmd license.qmd` → builds cleanly (these have no R dependency). The R pages are ported and correct in form but await step 2 above.

*Note:* Lily's personal repo `lilyheald/PAINT` still serves the original workflowr thesis site independently; this migration only affects `lasisilab/paint-workflowr`.
