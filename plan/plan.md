# PAINT — Project Plan & Roadmap

**Project:** PAINT — *Pigmentation Analysis of (…) Neanderthal Traits* (acronym under revision — see §5)
**Team:** Tina Lasisi (PI / advisor), Lily Heald, Yemko Pryor
**Last updated:** 2026-07-22
**Status:** living ground-truth document.

## How these files fit together
- **`plan.md`** (this file) — the canonical roadmap. Edit here first.
- **`changelog.md`** — dated log of what was done / found / decided, so anyone (or another Claude) can pick up cold. Append, don't rewrite.
- **`paint-plan.html`** — styled, shareable rendering of this plan for Lily & collaborators. Regenerated from this file; if the two ever disagree, `plan.md` wins.

---

## 1. Where things stand (July 2026)

Three sources have been reviewed and reconciled:

| Source | What it is | Status |
|---|---|---|
| **Repo** `lasisilab/paint-workflowr` | Thesis workflowr site + small data + analysis/back-end scripts | reviewed |
| **Thesis** (41 pp, 20 Apr 2026) | Honors thesis; 222-SNP GWAS panel; evaluates *feasibility* of archaic pigmentation prediction; conclusion = caution | reviewed |
| **Cluster** Great Lakes Turbo `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` (110 GB) | Full 19-job SLURM pipeline + all genomic data (archaic BAMs, SGDP subsets, PCA outputs) | inventoried 2026-07-22 |

**Dataset-source decision (2026-07-22):** the four pigmentation datasets from the 17 Jun plan already exist, harmonized on **hg38**, in the **`pigmentation-gene-network`** repo — GWAS Catalog, Bajpai 2023 CRISPR, Raghunath/D'Arcy melanogenesis network, Baxter cross-species — plus **HIrisPlex-S** markers. Use that repo as the dataset source. Do **not** use `melanogenesis-constraints` (older; its GWAS content was already absorbed into pigmentation-gene-network).

---

## 2. Open questions for Lily — please confirm

- **[A1] Denisova 3 chromosome naming.** Denisova 3's BAM uses `chr`-prefixed contigs (`chr1`, `chrM`) while every other archaic sample and the reference (`hs37d5.fa`) use bare names (`1`, `2`). Result: a flagship ~30× Denisovan comes out near-empty at the pigmentation loci and sits in the *sparse* group of thesis Fig 5. **Confirm this was an accident (naming mismatch), not intentional**, so we can re-run it with matched contigs.
- **[A2–A5] Other flagged issues** (see §3.A) — skim them and flag which were deliberate choices vs. bugs. Most useful: was `--ploidy 1` (haploid) calling intentional, and which of the two ancient-calling scripts is the "real" one?

---

## 3. Roadmap

Owner tags: **(TL)** Tina · **(LH)** Lily · **(YP)** Yemko. Priority: 🔴 high · 🟡 med · ⚪ low.

### A. Bugs & fixes
> **Every item below was reproduced with commands + captured output on 2026-07-22 — see [`verify/BUG_EVIDENCE.md`](verify/BUG_EVIDENCE.md) (runnable: [`verify/verify_bugs.sh`](verify/verify_bugs.sh)).** One earlier claim (A4) did **not** hold and is downgraded.

- [ ] **A2 · Genome-build mismatch (hg38 panel vs hg19 data) — the root defect** 🔴 (TL/LH) · **CONFIRMED**. The 222-SNP panel is on **GRCh38/hg38** (e.g. SLC24A5/rs1426654 at `15:48134288`; MC1R/HERC2/SLC45A2 likewise) but the reference and all sequence data are **GRCh37/hg19**, so every pigmentation-SNP measurement lands at the wrong coordinates. Effects: **(a)** 221/222 sites are monomorphic in SGDP → the pigmentation PCA is **rank-1** (PC1 only; PC2–10 ≈ 3e-18) → all archaic samples project to **identical** coordinates (whole-genome PCA on the *same* samples is full-rank, ruling out "too few samples"); **(b)** the depth/missingness arm measures **shifted loci** (depth reported at `15:48134288`, ~292 kb from the true hg19 SLC24A5 SNP). This is precisely what **B2** fixes → do B2 first. Evidence: `verify/BUG_EVIDENCE.md` §⓵ & §A2.
- [ ] **A1 · Denisova 3 chr-naming** 🔴 (LH confirm → TL/LH re-run) · **CONFIRMED**. Denisova 3's BAM is the only one with `chr`-prefixed contigs vs bare-named reference/panels/other BAMs, so its extraction fails (mean depth 0.5, 69/222) and it looks sparse despite being high-coverage. *Independent of A2* — this is why D3 specifically is empty. Fix: harmonize contigs (or use the `chr`-aware reheader in `pca_ancient.slurm`); re-run. Evidence: §A1.
- [ ] **A3 · `--ploidy 1` (haploid) whole-genome ancient calling** 🟡 (LH confirm) · **CONFIRMED**. `ancient_wg.slurm` line 83 calls all sites (incl. autosomes, line 64 `CHRS=( {1..22} X Y )`) haploid; output GTs are single-allele → heterozygotes never emitted. Confirm intent. Evidence: §A3.
- [ ] **A4 · Two competing ancient-calling scripts (cleanup, not a bug)** ⚪ (LH/TL) · **DOWNGRADED**. `pigmentation_ancient_call.slurm` uses `bcftools call -mv` (variants-only) and `pig_call_miss.slurm` uses `-c` (keeps all). The committed `ancient_pigmentation.vcf.gz` has **all 222 sites**, so nothing was actually dropped — the keep-all script is the one used. Just delete the unused `-mv` script. *(My earlier "ascertainment bias" framing was wrong for the committed output.)* Evidence: §A4.
- [ ] **A5 · Orphan / broken scripts** ⚪ (LH/TL) · **CONFIRMED**. `ancient_merge.slurm` globs `*.wg.vcf.gz` → matches nothing (real output is `ancient_sgdp_wg.vcf.gz`); `pca_ancient.slurm` references a missing `hg19.fa` and its `pca_snps` output is used nowhere. Delete/clean up. Evidence: §A5.
- [ ] **A6 · Repo housekeeping** ⚪ (LH). Fix `introduction.Rmd` "395 SNPs" → 222; the stale "View genetic PCAs" link (`analysis.html` → `pca.html`); empty `LICENSE`; orphaned `docs/analysis.html` & `docs/depth_spinoff.html`; laptop-absolute paths in `cleaning.Rmd` / `process_links.R`.

### B. Analysis redesign (from the 17 Jun plan)
- [ ] **B1 · Four-dataset coverage analysis** 🔴 (TL updates code, LH runs). Layered: GWAS-Catalog-only coverage, then coverage across each of the four subsets (GWAS / CRISPR / melanogenesis network / cross-species). Source: `pigmentation-gene-network`.
- [ ] **B2 · Normalize everything to hg38** 🔴 (TL/LH). The datasets are already hg38; the **archaic + SGDP side** is on hs37d5/GRCh37 and needs lifting (or lift the panel to hg19 for extraction — decide once). This likely also resolves **A2**.
- [ ] **B3 · Directionality polygenic score** 🟡 (TL/LH). GWAS betas → +1 / −1 per pigment-increasing / decreasing allele (subset to skin-pigmentation and/or ≥2-hit). **MC1R red-hair variant check** — reconfirm no loss-of-function in Neanderthals/Denisovans (expected null; a citable paper point). HIrisPlex-S markers are in-hand; model **coefficients** are an optional fetch (Walsh 2017) only if quantitative probabilities are wanted — and are European-trained, so directionality is the more defensible route for archaics.
- [ ] **B4 · Three-variant PCA** 🟡 (LH). (i) pigmentation SNPs, (ii) whole pigmentation-related **genes** (pull start/stop coords), (iii) genome-wide. Two designs each: (a) everybody together (moderns + the 3 high-coverage archaics — expect segregation); (b) moderns only, **project all ancients** including low-coverage.
- [ ] **B5 · Missingness strategy** 🟡 (TL/LH). Masking across all samples leaves <50 SNPs (too few) → focus high-coverage samples for SNP-level work, and move to **gene-level** to escape SNP sparsity.
- [ ] **B6 · Genes-vs-SNPs handling** 🟡 (YP/TL). Network / Baxter / Bajpai are gene-level (need coordinates); GWAS / HIrisPlex are SNP-level. Keep the two layers explicit.
- [ ] **B7 · Functional / skin-specific focus** ⚪ (YP/LH). Report synonymous:non-synonymous ratios (annotate coding effect; look for exome data). Highlight the handful of **skin-specific** pigmentation genes (TYR, OCA2, TYRP1, DCT, PMEL, MLANA — from YP's PQG poster) across modern populations and archaics.

### C. Repo & cluster infrastructure
- [x] **C1 · Move repo into Lasisi Lab org** — done (`lasisilab/paint-workflowr`); confirm LH access.
- [ ] **C2 · Cluster-compatible workflow** 🟡 (TL). PODFRIDGE-style: gitignore the cluster tree but structure code to run "as if the cluster were a local folder"; LH develops locally (8 GB RAM → PCAs/calling stay on cluster, viz local) and pings TL to run cluster steps. Decide which files are small enough to commit.
- [ ] **C3 · Preserve derived data** 🟡 (TL). Turbo is not archival — back up/deposit the merged SGDP panels, archaic call sets, and PCA outputs (raw BAMs are re-downloadable from MPI-EVA/ENA).
- [ ] **C4 · "Where everything lives" doc** ⚪ (LH). Google Doc listing dissertation, repos, Drive folders.

### D. Writing & lit review
- [ ] **D1 · Archaic-pigmentation lit review** 🔴 (LH). Undermind search "archaic skin" → use Claude to screen 50–100 papers (new-data / selection papers on archaics since ~2000; pull supplementaries; then search the curated gene list for mentions). Must-know anchors: Lalueza-Fox 2007 (MC1R) + its rebuttals; Omer Gokcumen (Buffalo) archaic/skin work. Feeds both TIG and PAINT.
- [ ] **D2 · TIG review manuscript** 🔴 (LH/TL). Prioritize — no new analysis needed. Keep TIG vs PAINT tasks differentiated.
- [ ] **D3 · PAINT paper** 🟡 (TL/LH/YP). Draft title: *"The genetic landscape of pigmentation in archaic hominins."* Resolve the acronym (§5); TL to scope target journals. Framing: get the archaic-pigmentation *landscape* out before anyone else scoops it; complexity can come in review.

---

## 4. Sequencing note
**B2 (hg38 normalization) is now the critical path, not just an enhancement** — it *is* the fix for the confirmed build mismatch (A2), which is the root cause of the degenerate pigmentation PCA and the wrong-locus depth measurements, and it's the prerequisite for adopting the four hg38 datasets (B1). Do it first; the pigmentation PCA and the pigmentation-SNP depth/missingness results should be regarded as provisional until it's done. **A1 (Denisova 3)** is an independent naming fix that can proceed as soon as Lily confirms.

## 5. Naming
PAINT currently expands to "Pigmentation Analysis of **IN**trogressed Neanderthal Traits," but introgression was not actually studied. Candidate re-expansion (e.g. *integumentary* traits) loses nothing. Decide alongside the manuscript title.

## 6. Datasets & provenance
All the pigmentation datasets — including the melanogenesis-network backbone — live in the **`pigmentation-gene-network`** repo, harmonized on **hg38**. That repo's [`DATA_SOURCES.md`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/DATA_SOURCES.md) is the authoritative provenance manifest (endpoints, licenses, freeze timestamps). Summary of where each piece comes from:

| Dataset (our shorthand) | Origin | What it is / how acquired | Level |
|---|---|---|---|
| **Melanogenesis network** ("Raghunath") | **Raghunath et al. 2015**, *BMC Res Notes* (Additional Files 1–5) | 265-node / 429 **signed, directed** melanogenesis backbone, cleaned/curated **in-lab as prior PAINT work** — the mechanistic core that every other source annotates or expands. (`raghunath_edges_clean.csv`, `raghunath_nodes_typed.csv`) | genes |
| **GWAS Catalog** | **NHGRI-EBI GWAS Catalog** (Sollis et al. 2023) | Pigmentation associations pulled live via API (`scripts/gwas_catalog.py`); 1,072 lead SNPs by trait ontology (+ a 723-row gene-level file for the ≥2-hit replication filter). | SNPs |
| **CRISPR screen** | **Bajpai et al. 2023**, *Science* | Genome-wide CRISPR pigmentation screen; 169 hits at q<0.10, with perturbation direction. | genes |
| **Cross-species ("animal-wide")** | **Baxter et al. 2018/2019**, *Pigment Cell Melanoma Res* | 635 curated human pigmentation genes with mouse/zebrafish orthologs (Table S7). | genes |
| **PPI expansion** | **D'Arcy et al. 2023**, *Bioengineering* | 243-gene OMIM disease-gene table + a 451-node / 4668-edge STRING protein–protein network. | genes |
| **Prediction panel** | **HIrisPlex-S** — Chaitanya et al. 2018 (+ Walsh 2017 skin model) | 36 markers → 16 genes (full MC1R red-hair set + blue-eye HERC2/OCA2). Numeric coefficients are an **optional fetch** (Walsh 2017 + Erasmus MC tool), needed only for quantitative probabilities. | SNPs |

Supporting identity/annotation databases (UniProt, MyGene, HGNC gene groups, OmniPath, KEGG hsa04916, STRING v12) and additional population GWAS (**Kim 2024** East-Asian; **Martin 2017** KhoeSan) are also in that repo. **Key structural point (→ B6):** Raghunath / Baxter / Bajpai / D'Arcy are **gene-level**; GWAS Catalog / HIrisPlex are **SNP-level**.

**Direct links** (public repo `tinalasisi/pigmentation-gene-network`, branch `main`):
- Manifest: [`DATA_SOURCES.md`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/DATA_SOURCES.md)
- GWAS Catalog: [`data/external/gwas_catalog/pigmentation_gwas_catalog.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/external/gwas_catalog/pigmentation_gwas_catalog.csv)
- CRISPR (Bajpai): [`data/processed/bajpai2023_crispr_hits.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/bajpai2023_crispr_hits.csv)
- Cross-species (Baxter): [`data/processed/baxter2018_650_pigmentation_genes.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/baxter2018_650_pigmentation_genes.csv)
- Melanogenesis network (Raghunath): [`data/processed/raghunath_edges_typed_signed.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/raghunath_edges_typed_signed.csv) (+ `raghunath_nodes_typed.csv`, raw in `data/raw/raghunath2015/`)
- PPI (D'Arcy): [`data/raw/darcy2023/`](https://github.com/tinalasisi/pigmentation-gene-network/tree/main/data/raw/darcy2023)
- **HIrisPlex-S markers:** [`data/processed/hirisplexs2018_markers.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/hirisplexs2018_markers.csv) (extraction: [`notebooks/01c_extract_hirisplex_markers.ipynb`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/notebooks/01c_extract_hirisplex_markers.ipynb))
