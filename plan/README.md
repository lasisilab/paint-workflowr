# plan/ — SEPIA planning, QC & provenance

This directory holds the project's planning, quality-control, and provenance documents.
**Markdown is the source of truth;** the `.html` files are styled renderings — rebuild them with
`bash plan/build_docs.sh` — *except* three hand-built pages (`sepia-plan.html`, `pipeline.html`,
`docs.html`). The styled hub that links every rendered doc is **`docs.html`**.

## Read first
| File | What it is |
|---|---|
| **`STATE.md`** | Living snapshot — decisions locked in, what's in flight, open questions. **Start here on a cold pickup.** |
| **`plan.md`** | The single phased roadmap (bug fixes `A*`, analysis redesign `B*`, QC `Q1`–`Q10`, infra `C*`, writing `D*`). |
| **`changelog.md`** | Dated log of what was done / found / decided. |
| **`docs.html`** | Styled hub linking every rendered doc *(hand-built)*. |
| **`sepia-plan.html`** | Shareable rendering of the roadmap *(hand-built; the published plan)*. |

## Roadmap / execution
| File | What it is |
|---|---|
| **`rebuild_from_raw.md`** | Clean-slate, QC-gated pipeline: stages, reuse-vs-rerun matrix, compute estimates. |
| **`b2a_runbook.md`** | The panel build-fix runbook (rsID↔hg19↔hg38 map, commands, SLURM, compute). |
| **`build_docs.sh`** | Regenerates the `.html` renderings from the `.md` sources (pandoc). |
| **`rebuild_stage0.sh`** | Superseded early draft (panel-only Stage 0); kept for reference. |

*(The runnable cluster pipeline — `wg_modern_merge.slurm`, `acquire_archaic.slurm` — lives in the repo's top-level `code/`, not here.)*

## Data & pipeline record
| File | What it is |
|---|---|
| **`pipeline.html`** | Living "data & pipeline" doc — BAM vs VCF, the data flow, the run log *(hand-built)*. |
| **`pipeline_workbook.md`** | Step-by-step audit of the original pipeline. |
| **`cluster_inventory.md`** | The Great Lakes layout + data products. |
| **`coverage_current.tsv`** | Per-sample panel depth + published coverage. |
| **`CLUSTER_ACCESS.md`** | The SSH tunnel + binding cluster-access rules. |

## Provenance & QC — `papers/`
| File | What it is |
|---|---|
| **`papers/REFERENCES.md`** | Per-genome source paper, DOI, coverage, download URLs, data tier. |
| **`papers/SAMPLE_INCLUSION.md`** | The justified include/exclude subset (+ Poisson table). |
| **`papers/VCF_QC.md`** | QC baked into each published VCF + the harmonization we must add. |
| **`papers/PIPELINE_QC_BY_PAPER.md`** | Per-paper pipeline/QC, verbatim parameters. |
| **`papers/GENE_NETWORK_DATASETS.md`** | Inventory of the `pigmentation-gene-network` datasets (B1 integration prep). |
| **`papers/pdf/`** | Source-paper PDFs *(git-ignored — copyright; not redistributed)*. |

## Evidence — `verify/`
| File | What it is |
|---|---|
| **`verify/BUG_EVIDENCE.md`** | Every bug reproduced + traced to its downstream consequence. |
| **`verify/verify_bugs.sh`** | Runnable reproduction of the bug evidence. |

## Figures — `figures/`
| File | What it is |
|---|---|
| **`figures/before_*.png`** | Buggy-state "before" figures (rank-1 scree, collapsed projection, Denisova-3 coverage). |
| **`figures/make_consequence_figures.R`** | Regenerates the before/after figures. |

## Other
| File | What it is |
|---|---|
| **`evaluation_plan.md`** | Retired stub — its QC items are now `Q1`–`Q10` in `plan.md`. |
| **`assets/`** | Doc style + template used by `build_docs.sh` for the pandoc HTML build. |

*If a `.html` (other than the three hand-built ones) disagrees with its `.md`, the `.md` wins — edit the `.md` and re-run `build_docs.sh`.*
