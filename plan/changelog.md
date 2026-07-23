# PAINT — Changelog & Decision Log

Reverse-chronological log of what was **done**, **found**, and **decided**, with dates, so anyone picking this up cold has the full context. Companion to [`plan.md`](plan.md) (the forward-looking roadmap). Append new entries at the top; don't rewrite history.

Legend: **DONE** = action taken · **FOUND** = finding/evidence · **DECIDED** = decision made · **OPEN** = unresolved.

---

## 2026-07-22 — Evidence pass: reproduced (and corrected) the flagged bugs

Every flagged bug was re-checked with explicit commands + captured output → [`verify/BUG_EVIDENCE.md`](verify/BUG_EVIDENCE.md) (runnable `verify/verify_bugs.sh`). Results:

- **FOUND (root cause, confirmed)** — **Genome-build mismatch.** The committed 222-SNP panel is on **GRCh38/hg38** (`data/snps.txt` has SLC24A5/rs1426654 at `15:48134288`, MC1R/HERC2/SLC45A2 likewise) while the reference (`hs37d5.fa` header = GRCh37) and all data are **hg19**. Evidence of impact: `pigmentation_snps_freq.afreq` shows 221/222 sites monomorphic (ALT=".", OBS_CT=30) in SGDP; `pigmentation.pca.eigenval` = one nonzero eigenvalue (PC1 0.0628; PC2–10 ≈ 3e-18) vs full-rank whole-genome PCA on the same samples; `ancient.projected.pig.sscore` identical across all samples. Depth arm also affected: `vindija33_depth.txt` reports depth at the hg38 coordinate `15:48134288` (~292 kb off the true hg19 SLC24A5 SNP).
- **CONFIRMED** — A1 (Denisova 3 chr-prefixed BAM vs bare reference/panels), A3 (`--ploidy 1` on autosomes; output GTs single-allele), A5 (`ancient_merge` glob matches nothing; `pca_ancient` needs missing `hg19.fa`, output `pca_snps` unused).
- **CORRECTED / DOWNGRADED** — A4. Earlier flagged as "`-mv` drops non-variant sites → ascertainment bias." The committed `ancient_pigmentation.vcf.gz` has **all 222 sites**, so nothing was dropped; the `-c` keep-all script is the one used. Reclassified as cleanup (delete the unused `-mv` script). *My earlier framing was wrong for the committed output.*
- **DECIDED** — A2 reframed as the build mismatch (root cause) and **B2 (hg38 normalization) promoted to the critical path**: the pigmentation PCA and pigmentation-SNP depth/missingness results are provisional until build is harmonized. Updated `plan.md` §3.A/§4 and `paint-plan.html` accordingly.
- **NOTE** — cluster inspection kept strictly text-only (grep/ls/`samtools view -H`/`bcftools view -H`) to avoid a repeat of the binary-to-terminal issue.

## 2026-07-22 — Cluster inventory, bug hunt, dataset decision, plan docs created

- **DONE** — Established read access to the Great Lakes cluster over an SSH ControlMaster socket (Tina's authenticated session; UMich requires Kerberos password + Duo, so key-based / the "Add SSH connection" dialog does not work — the terminal socket does). Inventoried `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` (110 GB).
- **DONE** — Reconstructed the full pipeline: **19 SLURM jobs** (acquire archaic BAMs → depth/filter → ancient calling → SGDP download/subset → merge + PCA → project). Only 4 of these scripts were in the repo; the rest live on the cluster.
- **FOUND / confirmed** — **Denisova 3 chromosome-naming bug (A1).** Denisova 3's BAM alone uses `chr`-prefixed contigs (`SN:chr1`, `SN:chrM`); all other archaic BAMs and the `hs37d5.fa` reference use bare names (`SN:1`). Evidence: `samtools view -H` on the filtered BAMs; `Denisova3_depth.txt` uses `chr1`-style labels while `vindija33_depth.txt` uses `1`; the panel exists in both `snps.bed` (bare) and `snps.chr.bed` (chr) forms. Consequence: Denisova 3 (a ~30× genome) is under-recovered and appears sparse in thesis Fig 5. High confidence.
- **FOUND / preliminary** — Adversarial **bug hunt** (multi-agent workflow) run over repo code + the 19 SLURM scripts. **Stopped early** by Tina because agents streaming raw binary genomics output (`.bcf`/`.bam`) scrambled the terminal display (read-only; nothing damaged). Cause: the finders were given SSH access to a binary-heavy filesystem without a no-binary-dump constraint. Findings below are **preliminary — to be re-verified in a clean, local-only pass** (no SSH, no binary viewing):
  - **A2** — Pigmentation-SNP PCA panel comes out ~monomorphic (PC1 ≈ 1 SNP; PC2–10 eigenvalues ~3e-18; SLC24A5/SLC45A2 with zero minor alleles). Whole-genome PCA on the same 15 samples is full-rank → it's the **panel extraction**, not sample count. Suspected coordinate/build mismatch in the SGDP pigmentation extraction (ties to the hg38 decision).
  - **A3** — `ancient_wg.slurm` uses `bcftools call --ploidy 1` (haploid) across autosomes.
  - **A4** — `pigmentation_ancient_call.slurm` uses `bcftools call -mv` (variants-only), dropping non-variant sites; a second script (`pig_call_miss.slurm`, `-c`) keeps all sites. Two competing versions.
  - **A5** — `ancient_merge.slurm` glob `*.wg.vcf.gz` matches no file; `pca_ancient.slurm` is dead code referencing a missing `hg19.fa`.
- **DECIDED** — **Dataset source = `pigmentation-gene-network`**, not `melanogenesis-constraints`. Verified that pigmentation-gene-network already contains all four datasets on hg38 (`data/external/gwas_catalog/pigmentation_gwas_catalog.csv` with `pos_hg38`; `bajpai2023_crispr_hits.csv`; Raghunath/D'Arcy network tables; `baxter2018_650_pigmentation_genes.csv`) **plus** HIrisPlex-S markers (`hirisplexs2018_markers.csv`, full MC1R red-hair set + blue-eye HERC2/OCA2). Its gene-level GWAS file was frozen *from* melanogenesis-constraints, so that repo is not needed.
- **FOUND** — HIrisPlex-S **model coefficients** are the one gap in pigmentation-gene-network (markers present; per-SNP β / intercepts are not — they live in Walsh 2011/2013/2017 + the Erasmus MC tool). Not needed for the directionality PGS; only for quantitative probabilities.
- **DECIDED** — Confirmed reconciliations against the thesis: the **222-SNP** panel is correct (the "395" appears only in the website's `introduction.Rmd` prose); advisor/mentor/acknowledgements are in the thesis (the website omitted them); El Sidrón (Sid1253) genuinely has no data → **14 analyzed, not 15**.
- **DONE** — Created `plan/` docs: `plan.md`, `changelog.md`, `paint-plan.html`.
- **DONE** — Documented dataset provenance in `plan.md` §6 (Raghunath 2015 melanogenesis backbone = curated in-lab as prior PAINT work; GWAS Catalog / Bajpai / Baxter / D'Arcy / HIrisPlex origins), pointing to `pigmentation-gene-network/DATA_SOURCES.md` as authoritative.
- **DONE (uncommitted)** — Added `.github/workflows/publish-site.yml`: a **workflowr-adapted** version of the Quarto `publish-site.yml` deploy from `pigmentation-gene-network`. It does NOT re-run R; it assembles the committed `docs/` + `plan/*.html` into a Pages artifact and deploys via Pages-from-Actions (self-enabling). The plan is served at `/plan/` (direct link, **not** in the workflowr navbar); `plan.md`/`changelog.md` are kept off the public site. Added `plan/index.html` (redirect → `paint-plan.html`) and `noindex` on the plan HTML.
- **DECIDED / OPEN** — Repo `lasisilab/paint-workflowr` is **public** and has **no Pages yet** (Lily's live thesis site is the separate `lilyheald/PAINT`). Enabling this workflow makes the plan publicly reachable-by-URL (unlisted + noindex, not truly private). Not committed/pushed — awaiting Tina's go-ahead on public exposure vs. a private option. `paint-workflowr` is workflowr, not Quarto; a full Quarto migration would be a separate, larger task if ever wanted.

## 2026-06-17 — Planning meeting (Tina, Lily, Yemko; from Otter.ai transcript)

Decisions and directions set for the next phase (recorded verbatim-in-spirit; see `plan.md` §3 for the actionable form):

- **DECIDED** — Expand the coverage analysis from GWAS-Catalog-only (222 SNPs) to **four pigmentation datasets** (GWAS Catalog + a CRISPR study + a melanogenesis network + a cross-species/"animal-wide" set), analyzed in a layered way.
- **DECIDED** — **Normalize everything to hg38.** (Yemko's data already on hg38; the plan is to standardize the whole project there.)
- **DECIDED** — Answer "what color were they?" in two steps: (1) GWAS betas → directionality-only **polygenic score** (+1/−1), optionally skin-only / ≥2-hit; (2) **MC1R** red-hair-variant check (expected null, reconfirm).
- **DECIDED** — Redo PCA in **three variants** (pigmentation SNPs / whole pigmentation-related genes / genome-wide), with two designs (everybody-together vs. moderns-with-ancients-projected).
- **DECIDED** — Move the repo into the **Lasisi Lab GitHub org**; set up a **PODFRIDGE-style** cluster-compatible workflow (Lily develops locally, Tina runs cluster steps).
- **DECIDED** — Prioritize the **TIG review** manuscript (no new analysis); keep it differentiated from the primary **PAINT** paper. Draft PAINT title: *"The genetic landscape of pigmentation in archaic hominins."*
- **OPEN** — Whether any datasets are gene-level vs. SNP-level (network is genes) — affects weighting; to be checked (now largely resolved by the pigmentation-gene-network structure).
- **ACTIONS assigned** — Lily: lit review (Undermind → Claude paper screen), move repo, "where everything lives" doc, subset to skin-specific genes. Tina: update code for 4 datasets, curate gene lists, organize cluster runs, target-journal scoping. Yemko: archaic-data API queries (e.g. EGA), skin-specific expression.

## ~2025-11 → 2026-05 — Thesis development (for reference)

- Honors thesis (workflowr project) developed Nov 2025 – May 2026; manuscript dated **20 Apr 2026**; repo wrapped up ~**7 May 2026**. Two analytical arms: depth/missingness and PCA. Conclusion: archaic pigmentation prediction is not yet well-supported → caution. Full artifact-by-artifact inventory was produced separately (project inventory dossier).
