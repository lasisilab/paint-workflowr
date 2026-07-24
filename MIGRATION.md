# workflowr → Quarto migration

**Branch:** `quarto-migration`. **Status:** scaffold complete and prose pages verified; the R-heavy analysis pages need **one local render** before this can be merged to `main` and go live. The old workflowr site on `main` is untouched until then.

## Why it's on a branch (and not yet live)
The analysis pages run R against data files, and those files **could not be located anywhere reachable** — verified 2026-07: they are git-ignored (`*.csv`) and absent from this working copy, **and absent from the cluster** (`/nfs/turbo/lsa-tlasisi1/lheald_thesis`). The original `cleaning.Rmd` read them from `/Users/lilyheald/Documents/GitHub/PAINT/data/`, so they exist **only on Lily's laptop**:

- `data/skin_pigmentation.tsv` — **is** committed (the one input present).
- `data/pigmentation_snps.csv` — derived by `cleaning.qmd` from `skin_pigmentation.tsv` (so regenerable).
- `data/simons_metadata.csv`, `data/simons_whole.csv` — SGDP metadata, **laptop-only** (inputs to `cleaning.qmd`).
- `data/modern_metadata.csv` — derived by `cleaning.qmd` from the two Simons files (needed by `pca.qmd`).
- `data/ancient_depth_clean.csv` — annotated depth table (needed by `depth.qmd`), **laptop-only**.
- `data/neo_uvi.csv` — UV-index grid (needed by `introduction.qmd`), **laptop-only**.

Additionally, `introduction.qmd`'s maps need `sf` / `raster` / `rnaturalearth`, which require the **GDAL/GEOS/PROJ system libraries** — not present in the migration sandbox, so that page can't be rendered there regardless of data. CI deliberately does **not** run R (`execute: freeze: auto`); it serves committed `_freeze/` results, which must be produced once on a machine that has R **and** the data — i.e. **Lily's laptop** (or wherever those six files live), with the geo packages installed.

## R-code fixes already applied on this branch (no data needed)
- `cleaning.qmd` — recovered (the original had no YAML front matter, so the first port left it empty) and its hardcoded `/Users/lilyheald/...` paths changed to repo-relative `data/...`.
- `introduction.qmd` — fixed the SGDP map chunk (it built `modern_sf` from the archaic `sites` data frame instead of `modern_samples`), corrected "395 SNPs" → **222**, and repaired a dangling/incomplete sentence.
- Still open (needs data/intent to fix safely): `pca.qmd` suppresses point labels by hardcoded row indices (`df[20:30,]$labels <- NA`) — fragile; make it name-based when you have the data in front of you.

## What changed
- **Pages** ported `analysis/*.Rmd` → root `*.qmd`: `index` (rewritten to a project-level landing page — thesis is now framed as "v1"), `introduction` (Background), `depth`, `pca`, `about`, `license`, `cleaning`. Quarto reads the existing ```{r}``` chunks natively; only the YAML front matter changed.
- **`_quarto.yml`** — website config, `theme: cosmo` (same as before), navbar matching the old one, `execute-dir: project` (so `data/...` paths resolve from the repo root as they did under workflowr's `knit_root_dir: "."`), `execute: freeze: auto`.
- **`.github/workflows/publish-site.yml`** — replaced the workflowr-static-deploy with a Quarto render + Pages deploy (Node-24 action majors), and it still copies `plan/*.html` into `/plan/`.
- **Removed** the workflowr scaffolding: `analysis/_site.yml`, `_workflowr.yml`, and the `analysis/*.Rmd` page sources (now `.qmd` at root). The pipeline scripts (`analysis/*.py`, `*.slurm`, `analysis/introgression_app/`) were left in place.
- **`.gitignore`** — added `/_site/`, `/.quarto/`; `_freeze/` is intentionally tracked.

## To finish the migration (do this locally, with R + the data files)
1. On a machine that has the data (Lily's laptop): place the `data/` files listed above (the derivable ones — `pigmentation_snps.csv`, `modern_metadata.csv` — regenerate by rendering `cleaning.qmd` once the Simons inputs are present), and install the R packages: `install.packages(c("ggplot2","dplyr","tidyverse","data.table","patchwork","ggrepel","lme4","sf","raster","rnaturalearth","rnaturalearthdata","wesanderson","showtext","sysfonts","reshape2"))`. The `sf`/`raster`/`rnaturalearth` trio needs the **GDAL/GEOS/PROJ** system libraries (e.g. `brew install gdal geos proj` on macOS).
2. `quarto render` — this executes the R pages and writes `_freeze/`. Confirm `introduction`, `depth`, `pca` show their figures in `_site/`.
3. `git add _freeze && git commit` the frozen results.
4. Remove the now-vestigial workflowr output: `git rm -r docs/` (Quarto publishes `_site/`, not `docs/`). Optionally also drop `.Rprofile` and `SEPIA.Rproj` if you're done with the RStudio/workflowr setup.
5. Merge `quarto-migration` → `main`. The push triggers the publish workflow, which serves the Quarto `_site/` (with the frozen figures) at <https://lasisilab.github.io/sepia/>, plan still at `/plan/`.

## Verified in the migration environment
- `quarto render index.qmd about.qmd license.qmd` → builds cleanly (these have no R dependency). The R pages are ported and correct in form but await step 2 above.

*Note:* Lily's personal repo `lilyheald/PAINT` still serves the original workflowr thesis site independently; this migration only affects `lasisilab/sepia`.
