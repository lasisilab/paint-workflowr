# SEPIA — evaluation & QC plan (retired — now merged into `plan.md`)

> **This file has been retired.** Its 10 reviewer-driven, unit-test-style QC checks are now tracked as first-class items **`Q1`–`Q10`** inside the single master plan, [`plan.md`](plan.md) §4, interleaved with the fixes/builds they verify (each `Q` item sits in the phase whose work it proves, with full acceptance criteria, subtasks, deliverable, and communication artifact). There is no longer a separate QC to-do list — track everything in `plan.md`.

**Where each check went** (same two guiding principles as before — *provenance before analysis*, and *reproduce known truth first / positive controls*):

| Was (evaluation item) | Now (plan.md) | Phase |
|---|---|---|
| 1. Data-provenance manifest + checksums | **Q1** | 0 |
| 2. Genome-build & contig-naming lint (tracer SNPs) | **Q2** | 1 |
| 3. Positive control — reproduce SGDP WG-PCA | **Q3** | 2 |
| 4. Allele & annotation harmonization | **Q4** | 1 |
| 5. PCA / projection non-degeneracy | **Q5** | 2 |
| 6. Per-sample coverage expectations | **Q6** | 2 |
| 7. Sample identity, sex & contamination | **Q7** | 3 |
| 8. aDNA authenticity / damage handling | **Q8** | 3 |
| 9. Cross-validation vs published + orthogonal predictor | **Q9** | 4 |
| 10. Reproducibility infra (versions, seeds, DAG, CI) | **Q10** (+ **Q10a** in Phase 0) | 5 |

See [`plan.md`](plan.md) for the live, checkbox-tracked versions. Dated history is in [`changelog.md`](changelog.md).
