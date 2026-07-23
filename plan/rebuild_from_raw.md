# Rebuild from raw — the clean-slate pipeline

**Decision (2026-07-23).** Given the confirmed QC failures in the existing pipeline — the hg38/hg19 build mismatch (A2), the Denisova 3 contig-naming bug (A1), haploid autosomal calling (A3), the projection collapse, and the fact that the full sorted BAMs are no longer on the cluster (only wrong-region `filtered_*.bam` + already-called VCFs remain) — we do **not** trust Lily's derived data. We rebuild the pipeline **from the raw, public, re-downloaded BAMs**, with a QC gate at every stage. This is the scientifically defensible path: every number in the paper will trace to raw data through a re-runnable, verified pipeline.

> This plan supersedes the "patch the panel from the existing VCFs" quick route in [`b2a_runbook.md`](b2a_runbook.md). That VCF-only route stays available as an *optional 1-hour preview* to sanity-check the corrected panel while the re-download runs — but it is not the deliverable.

**How this maps to the roadmap.** This is Phases 0–4 of [`plan.md`](plan.md) executed *from raw*, in order, so the QC items (`Q1`–`Q9`) are gates rather than afterthoughts, and the bug fixes (A1/A2/A3 + the projection fix) fall out of doing it right the first time.

---

## What we keep vs. re-derive

| Keep (re-fetch from source of truth) | Re-derive (discard the existing copy) |
|---|---|
| The **raw public archaic BAMs** (re-downloaded + checksummed) | Lily's sorted/filtered BAMs, `ancient_pigmentation.vcf.gz`, `ancient_sgdp_wg.vcf.gz` |
| The **SNP panel definition** (rsIDs + source), re-pulled and put on ONE build | The committed `snps.txt` / `snps.chr.bed` coordinates (hg38-on-hg19) |
| The **SGDP modern genotypes** (re-fetch or re-verify `sgdp.wg`) | `pca/*` eigenvec/eigenval/sscore and every downstream figure |
| Tool/reference provenance | any hand-typed number in the thesis prose |

---

## Genome-build decision (read first)
The raw data is **hg19**. Two options, same as B2 in `plan.md`:
- **Rebuild on hg19** (recommended for the rebuild itself): the data is already hg19, so *move the panel to hg19* and keep everything native — no lossy read re-mapping, fewer moving parts, fastest to a correct answer. The four new pigmentation datasets (hg38) are then lifted **down** to hg19 for integration, or handled in a later hg38 pass.
- **Rebuild on hg38**: re-map the raw reads to GRCh38 first (heaviest; only worth it if we commit to hg38 as the project standard now). Defer unless you want the hg38 datasets integrated immediately.

**Default: rebuild on hg19**, lift panels to match. (One decision to confirm.)

---

## Stages (each ends with a QC gate that must pass before the next)

### Stage 0 — Provenance & environment  · gate: every input traced (Q1, Q10a)
- Build `qc/manifest.tsv`: one row per input (raw BAM, panel, SGDP, reference) with `path · sha256 · source(accession/URL) · build · N · date`.
- Pin the environment (conda env / container) and record `samtools`, `bcftools`, `plink2`, `mapDamage`, `R` versions.
- **Recover the acquisition URLs for all 15 samples.** Known so far (from `sort_wget.slurm`/`phased_get.slurm`): Denisova 11 = ENA `ERR2273828`; Scladina = ENA `ERR9741105`; Hohlenstein-Stadel = MPI-EVA `L5386.bam`; Mezmaiskaya 1 = ENA `ERR257722`; Spy = MPI-EVA `A9416`; Vindija 33.19 = MPI-EVA Prüfer 2017 per-chromosome. **Still to locate (9):** Chagyrskaya 8, Denisova 5 (Altai), Denisova 25, Denisova 3, Goyet, Les Cottés, Mezmaiskaya 2, Vindija 87, El Sidrón — from the missing acquisition scripts on the cluster or the source papers (MPI-EVA `ftp.eva.mpg.de`, ENA `ftp.sra.ebi.ac.uk`).
- **Gate:** every sample has a documented, resolvable source + expected coverage; no `unknown`.

### Stage 1 — Re-acquire the raw reads  · gate: checksums match, headers sane
Two acquisition modes — pick per the compute you want to spend (see §Compute):
- **1a. Targeted (recommended):** download only the reads overlapping the SNP positions we need, by streaming from the remote indexed BAMs: `samtools view -b <remote-or-local>.bam -L targets.hg19.bed`. Targets = the ~9.2M whole-genome ancestry SNPs ∪ the pigmentation panel windows. This cuts hundreds of GB of whole genomes down to tens of GB of relevant reads, and is enough for depth, calling, ancestry PCA, and (representatively) mapDamage.
- **1b. Full genomes:** download the complete BAMs (needed only if we later want genome-wide analyses beyond the SNP panels). Heaviest.
- Sort, index, and **harmonize contig naming to bare `1..22,X,Y`** for *every* sample as they land (`samtools reheader`) — this fixes A1 for the whole set at the source, not as a special case.
- **Gate:** `sha256` matches the manifest (1b) or read counts are sane per region (1a); every BAM header is bare-named and matches `hs37d5.fa`.

### Stage 2 — Raw-data QC  · gate: authentic, correctly labelled, damage-characterized (Q6, Q7, Q8)
- **Coverage vs expectation (Q6):** realized depth per sample vs its published coverage; the 5 declared high-coverage genomes (incl. Denisova 3, now correctly named) must land in the high band.
- **Sex & contamination (Q7):** X/Y depth-ratio sex check; X-chromosome / mtDNA contamination estimate; assert < threshold.
- **Damage / authenticity (Q8):** **mapDamage** per sample → 5′ C>T / 3′ G>A misincorporation curves; record UDG status; this is what your mapDamage request feeds.
- **Gate:** damage in the authentic-aDNA range; contamination below threshold; coverage matches expectation (Denisova 3 no longer sparse).

### Stage 3 — One build + a verified, harmonized panel  · gate: build lint + allele check (Q2, Q4)
- Put the pigmentation panel on **hg19** by rsID (re-pull hg19 coordinates for each panel rsID; keep both builds in the manifest so the bug cannot recur). Reconcile the panel-size mess (committed 222 vs cluster 395-line BED vs 225 unique rsIDs vs 129 overlapping the modern reference) — settle on one documented analysis panel.
- **Tracer-SNP lint (Q2):** rs1426654 → `15:48426484`, rs12913832 → `15:28365618`; all inputs one build, one naming.
- **Allele harmonization (Q4):** REF base at each panel position == panel/VCF REF (`samtools faidx`); effect allele ∈ {REF,ALT}; **flag palindromes**; decide policy.
- **Gate:** lint exits 0; 0 REF mismatches on retained SNPs.

### Stage 4 — Re-call genotypes properly  · gate: calls sane, damage-aware
This is where the earlier bugs get fixed by construction, and your calling-filter requests apply:
- **Diploid autosomes** (fix A3): `bcftools call -m` with default (diploid) ploidy on 1–22; haploid only on X/Y for males as appropriate.
- **Keep-all at the panel** (not `-mv`): emit every panel site so hom-ref is retained.
- **Max-depth cap** (your request): reject sites whose depth is an extreme outlier (pileup artifacts in repetitive/collapsed regions) — e.g. cap at a per-sample multiple of median depth, and flag+drop sites above it. Set both a floor (min depth for a confident call) and a ceiling.
- **Damage handling** (your request, applied carefully):
  - **mapDamage `--rescale`** the base qualities so likely-deaminated bases are down-weighted — this keeps the transition SNPs (see caveat) while mitigating damage.
  - **Transversion policy — important:** a blanket *transversion-only* filter would delete ~71% of the pigmentation panel, **including SLC24A5 (rs1426654) and HERC2 (rs12913832)**, which are transitions (measured: of 129 panel SNPs overlapping the reference, 92 are transitions vs 37 transversions). So: use **transversion-only for the whole-genome ancestry PCA** (standard, damage-robust) but **keep transitions for the pigmentation panel**, relying on rescaling + higher depth + high-coverage samples there. Report both.
- **Gate:** genotypes are diploid on autosomes; no sites above the max-depth ceiling remain; a transition-heavy vs transversion-only call set are both produced for comparison.

### Stage 5 — Modern reference  · gate: SGDP verified or rebuilt
- Verify the existing `sgdp.wg` (15 samples, 9.2M hg19 SNPs — confirmed hg19, contains the pigmentation SNPs by rsID) via the Stage-3 lint + a checksum, OR rebuild it from the SGDP source if provenance can't be established (Q1). Decide 15-sample (matches the thesis) vs expanding to the 279-sample set.
- **Gate:** modern reference passes the same build/allele lint as the archaic data.

### Stage 6 — PCA + projection  · gate: positive control + non-degeneracy (Q3, Q5)
- **Positive control (Q3):** whole-genome PCA must reproduce known structure (Africans separate on PC1; archaics among non-Africans). If it can't, stop.
- **Non-degeneracy (Q5):** pigmentation PCA is multi-dimensional (not rank-1); projection uses **`no-mean-imputation`**; projected archaics have non-zero spread.
- **Three panels × two designs (B4):** pigmentation SNPs / whole pigmentation genes / genome-wide × (high-coverage-together, moderns-with-all-projected).
- **Gate:** control reproduces known structure; no collapse; before/after figures rendered.

### Stage 7 — Science on the clean base  · (B3, B7)
- Directional pigmentation score + **MC1R** red-hair check (B3); functional / skin-specific-gene profile (B7). Cross-validate against published archaic genotypes (Q9).

### Stage 8 — Reproducibility  · (Q10)
- Encode the whole thing as a **Snakemake/Nextflow DAG** (auto-generates the flow figure), seed all simulations, pin the env, add a CI fixture test. Now the paper's numbers regenerate from raw with one command.

---

## Compute resources

The dominant cost is **Stage 1 (re-acquisition)**; everything else is modest. You said compute isn't a constraint, so any of these is fine — the table is to set expectations and to choose targeted vs full download.

| Stage | Job shape | Cores / Mem | Walltime | Disk | Notes |
|---|---|---|---|---|---|
| 0 provenance/env | login + tiny | 1 / 2 GB | minutes | — | conda solve needs internet (login node) |
| **1a targeted re-acquire** | `--array=1-15` | 2 / 8 GB each | ~1–4 h total | ~10–50 GB | streams only SNP-overlapping reads; **recommended** |
| **1b full genomes** | `--array=1-15` | 4 / 16 GB each | many hours–~1 day | ~0.5–1 TB | whole BAMs; bandwidth-bound from MPI-EVA/ENA |
| 2 QC (mapDamage/sex/contam) | `--array=1-15` | 4 / 16 GB each | ~15 min–1 h each | small | mapDamage is the heaviest here |
| 3 panel/build lint | single | 1 / 4 GB | minutes | tiny | 222-site scale |
| 4 re-call genotypes | `--array` by sample or chr | 4–8 / 16–32 GB | ~1–3 h | ~10 GB | region-restricted mpileup |
| 5 SGDP verify/rebuild | single (verify) / array (rebuild) | 8 / 32 GB | minutes (verify) | reuse | rebuild only if provenance fails |
| 6 PCA/projection | single | 4 / 16 GB | minutes | tiny | plink2 |
| 7 score/functional | single | 2 / 8 GB | minutes | tiny | |
| 8 DAG/CI | dev | — | — | — | one-time setup |

**Bottom line:** with **targeted re-acquisition (1a)** the whole rebuild is roughly a **half-day of mostly-download wall-clock** on a single standard node + a couple of small array jobs — no GPU, no large-memory node, well within Turbo's 8.7 TB free / scratch's 300 TB. Full-genome download (1b) turns it into a ~1-day job. Recommend **1a** unless you specifically need whole genomes.

---

## What I need from you
1. **Confirm the two decisions:** rebuild on **hg19** (default) vs hg38; and **targeted (1a)** vs **full (1b)** re-acquisition.
2. **The 9 missing acquisition sources** (Stage 0) — I'll hunt the cluster for the other acquisition scripts first; if they're not there I'll pull standard accessions from the source papers for you to confirm.
3. **Keep the authenticated Great Lakes session open** (as now) so I can run the SLURM jobs, or run them and paste back the QC summaries.
4. Nothing else — no data from Lily/Yemko; the raw archives, the SGDP data, and the reference are all public/present.

## Decision points recorded
- Build: hg19 (default) | hg38.
- Acquisition: targeted 1a (default) | full 1b.
- SGDP: verify existing 15-sample (default) | rebuild | expand to 279.
- Transversion policy: transitions kept for pigmentation + transversion-only for ancestry (default) | stricter (not recommended — drops SLC24A5/HERC2).
