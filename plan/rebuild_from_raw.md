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

## Reuse vs. rerun — the decision, per genome

**Principle.** For each genome, start from the *highest-quality product that already exists*, and rerun only what is needed to (a) fix the confirmed bugs (build A2, contig-naming A1, haploid A3, projection collapse) and (b) harmonize the independently-produced sources onto one comparable footing. Concretely: for **high-coverage** genomes the authors already did careful, damage-aware genotype calling (`snpAD`) that we cannot improve on at 30–52× — so we **reuse their published VCFs and do not re-call**. For **low-coverage** genomes hard calls neither exist nor are appropriate — so we **re-acquire the reads and compute genotype likelihoods ourselves (ANGSD)**. (The per-paper QC/pipeline each of these calls came from is documented in [`papers/PIPELINE_QC_BY_PAPER.md`](papers/PIPELINE_QC_BY_PAPER.md).)

| Genome | Take (source of truth) | Re-call genotypes? | What we rerun | Why |
|---|---|---|---|---|
| Altai / Denisova 5, Vindija 33.19, Denisova 3 | published snpAD **genotype VCF** (2017 release, hg19) + its mappability mask | **No** | build/naming lint (Q2), apply + intersect masks to a common set, allele/REF harmonization (Q4), subset to panels, PCA | 52×/30× damage-aware calls; re-calling adds nothing and loses the authors' QC |
| Chagyrskaya 8 | published snpAD VCF (`.noRB`) + `FilterBed` mask | **No** | as above (+ apply its own FilterBed before intersecting) | 27–28×, own release/mask |
| Denisova 25 ⚠ | published VCF (`L35 MQ25 B30 map35_100`) + `FilterBed` | **No** (provisional) | as above; flag preprint | 24×, but preprint — mark provisional |
| Vindija 87 | **the Vindija 33.19 VCF** (same individual) | **No** | none extra — use Vi 33.19 | Vi 87 is the same person; the 1.3× library adds nothing for genotypes |
| Denisova 11 "Denny" | BAM (ENA PRJEB24663) | **No hard call → ANGSD GLs** | re-acquire reads, reheader, mapDamage, max-depth cap, ANGSD GLs at panels, het-vs-depth, PCAngsd | ~2.6× hybrid; too low for hard calls; no VCF exists |
| Goyet, Les Cottés, Spy, Mez 2 | BAM (ENA, Hajdinjak 2018) | **No hard call → ANGSD GLs** | full low-cov path (as Denisova 11) | 1–2.7×; BAM-only |
| Mezmaiskaya 1 | **low-cov snpAD VCF** (`…/Vindija/VCF/Mez1/`) or BAM | reuse VCF (low-cov, with care) or GLs | apply FilterBed + lint; or GL path | ~1.9×; a snpAD VCF *does* exist (correction) |
| Hohlenstein-Stadel, Scladina | BAM (ENA PRJEB29475) | **No hard call → ANGSD GLs** | full low-cov path; expect very few usable panel sites | ultra-low ~0.02–0.05× early Neanderthals |
| El Sidrón 1253 | — | **Exclude** | (optional) check its exome VCF only for panel SNPs that fall in coding regions — most pigmentation SNPs are regulatory, so expect ~none | exome-capture only; no shotgun genome |
| SGDP (15 moderns) | existing `pca/modern/sgdp.wg` (hg19, 9.2 M SNPs) | reuse | build/allele lint (Q2/Q4); subset to panels; positive-control PCA (Q3) | already on hg19 with the pigmentation SNPs by rsID; no re-acquisition |
| **Pigmentation panel** | rsIDs (from `skin_pigmentation.tsv` / GWAS Catalog) | — | **lift to hg19 by rsID**, keep both builds; tracer lint (Q2) | fixes the root bug A2 |

**Two method notes from the per-paper QC extraction** ([`papers/PIPELINE_QC_BY_PAPER.md`](papers/PIPELINE_QC_BY_PAPER.md)):
- *Reused VCFs need their FilterBed.* Every published snpAD VCF carries only `mq25`+`map35_100`; the min-cov-10, GC-corrected central-95% (the max-depth cap), tandem-repeat, and indel filters ship as a **separate companion `FilterBed` mask that we must apply**, then intersect across genomes to a common site set. Prefer the **2017 snpAD reprocess** for Altai/Vindija/Denisova (the originals are GATK).
- *Tier-B calling choice.* The low-coverage papers (Hajdinjak 2018, Peyrégne 2019, Slon 2018) did **not** genotype — they used **pseudo-haploid random single-read sampling + a deamination filter + transversions** (heffalump). Our default is **ANGSD genotype likelihoods** (retains more information at these depths), but we will **cross-check against the pseudo-haploid approach** since it is the field-validated method for these exact genomes; and for HST/Scladina the **deamination filter is load-bearing** (raw contamination 22.9%/64.8% → 2.0%/5.5%).

**Net rerun surface (much smaller than "redo everything"):**
- **Re-acquire reads for ~8 low-coverage genomes only** (Tier B) — targeted extraction at the SNP positions; the 5 high-coverage genomes need **no re-acquisition and no re-calling** (download the published VCFs).
- **Never re-run** the high-coverage genotype calling, the SGDP genotyping, or (for Vindija 87) a separate low-cov calling.
- **Always re-run** (because they were bugged or absent): the panel→hg19 lift, contig-naming harmonization, allele lint, the depth/coverage QC, mapDamage + het-vs-depth on the low-cov reads, and the entire PCA/projection (PCAngsd, positive control, no-mean-imputation).

---

## Genome-build decision (read first)
The raw data is **hg19**, and — confirmed from the thesis §2.3 — the archaic data is distributed as **BAM files already mapped to GRCh37/hg19** (there is **no FASTQ**; Lily inherited the data producers' alignments and did no re-mapping). This makes the choice lopsided:
- **Rebuild on hg19** (strongly recommended): the reads are already aligned to hg19, so we *move the panel to hg19* and keep everything native — no re-alignment, no FASTQ hunt, fewest moving parts, fastest to a correct answer. The four new pigmentation datasets (hg38) are lifted **down** to hg19 for integration, or handled in a later hg38 pass.
- **Rebuild on hg38**: would require going back to **FASTQ** (raw reads) and re-running the full aDNA read-processing chain — adapter removal, read collapsing, alignment to GRCh38, damage-aware post-processing — for every sample. FASTQ exists at ENA for some accessions but the MPI-EVA genomes are published only as processed BAMs, so this is both the heaviest option *and* partly blocked by data availability. Only worth it if hg38 becomes the committed project standard.

**Default: rebuild on hg19** (lift panels to match). The BAM-only reality makes this the practical as well as the cheap choice.

---

## Stages (each ends with a QC gate that must pass before the next)

### Stage 0 — Provenance & environment  · gate: every input traced (Q1, Q10a)
- Build `qc/manifest.tsv`: one row per input (raw BAM, panel, SGDP, reference) with `path · sha256 · source(accession/URL) · build · N · date`.
- Pin the environment (conda env / container) and record versions of `samtools`, `bcftools`, `plink2`, **`ANGSD`**, **`PCAngsd`**, **`mapDamage`**, and `R`. (ANGSD + PCAngsd are the primary genotype-likelihood engine — see Stage 4/6 — and are conda-installable: `conda install -c bioconda angsd pcangsd mapdamage2`.)
- **Recover the acquisition URLs for all 15 samples.** Known so far (from `sort_wget.slurm`/`phased_get.slurm`): Denisova 11 = ENA `ERR2273828`; Scladina = ENA `ERR9741105`; Hohlenstein-Stadel = MPI-EVA `L5386.bam`; Mezmaiskaya 1 = ENA `ERR257722`; Spy = MPI-EVA `A9416`; Vindija 33.19 = MPI-EVA Prüfer 2017 per-chromosome. **Still to locate (9):** Chagyrskaya 8, Denisova 5 (Altai), Denisova 25, Denisova 3, Goyet, Les Cottés, Mezmaiskaya 2, Vindija 87, El Sidrón — from the missing acquisition scripts on the cluster or the source papers (MPI-EVA `ftp.eva.mpg.de`, ENA `ftp.sra.ebi.ac.uk`).
- **Gate:** every sample has a documented, resolvable source + expected coverage; no `unknown`.

### Stage 1 — Re-acquire the source data  · gate: checksums match, headers sane
**Data-form choice per sample (Tina's point — "or phased VCFs?").** Provenance search result (verified against the MPI-EVA servers, 2026-07-23): the high-coverage archaics are published by Max Planck as **damage-aware diploid *genotype* VCFs** (called with `snpAD`, an aDNA-damage-aware genotyper) — **not statistically phased haplotype VCFs** (if we ever need phased haplotypes, phasing is a separate downstream step we run ourselves). For the high-coverage genomes these published, carefully-called VCFs are a *better* source of truth than re-calling from reads. So:
- **High-coverage genomes — use the published snpAD genotype VCFs** (hg19): **Altai / Denisova 5**, **Vindija 33.19**, **Denisova 3** (all three in the shared 2017 snpAD release at `cdna.eva.mpg.de/neandertal/Vindija/VCF/{Altai,Vindija33.19,Denisova}/`, `chrN_mq25_mapab100.vcf.gz` — same pipeline/reference/filters ⇒ most directly comparable), **Chagyrskaya 8** (`ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/`, `.noRB.vcf.gz` — its own mask), and **Denisova 25** (`cdna.eva.mpg.de/denisova/Den25/VCF/` — a ~24× Denisovan from Peyrégne et al. 2025, currently a **preprint**, so mark provisional). Verify build + lint each; re-call from BAM only as a cross-check. Each release has its own README/filter-mask — check before merging across releases.
- **Correction (important):** **Denisova 11 "Denny" is low-coverage (~2.6×)**, an F1 hybrid, and has **no** genotype VCF — only raw sequences in ENA **PRJEB24663**. It belongs in the low-coverage BAM→GL tier below, *not* the high-coverage-VCF tier. (Lily's realized panel depth for it, 1.25×, is consistent with this.)
- **Low-coverage genomes** (Denisova 11, the Hajdinjak-2018 late Neanderthals, HST, Scladina, Mez1, …): BAMs → **ANGSD genotype likelihoods** (Stage 4). Hard-called VCFs generally don't exist for these, and shouldn't — the coverage can't support hard calls.
- Whichever form, record source + checksum in the manifest (Q1). Full per-genome URL/accession table is compiled in the provenance manifest (both provenance searches feed it).

Two read-acquisition modes for the BAM route — pick per the compute you want to spend (see §Compute):
- **1a. Targeted (recommended):** download only the reads overlapping the SNP positions we need, by streaming from the remote indexed BAMs: `samtools view -b <remote-or-local>.bam -L targets.hg19.bed`. Targets = the ~9.2M whole-genome ancestry SNPs ∪ the pigmentation panel windows. This cuts hundreds of GB of whole genomes down to tens of GB of relevant reads, and is enough for depth, calling, ancestry PCA, and (representatively) mapDamage.
- **1b. Full genomes:** download the complete BAMs (needed only if we later want genome-wide analyses beyond the SNP panels). Heaviest.
- Sort, index, and **harmonize contig naming to bare `1..22,X,Y`** for *every* sample as they land (`samtools reheader`) — this fixes A1 for the whole set at the source, not as a special case.
- **Gate:** `sha256` matches the manifest (1b) or read counts are sane per region (1a); every BAM header is bare-named and matches `hs37d5.fa`.

### Stage 2 — Raw-data QC  · gate: authentic, correctly labelled, damage-characterized (Q6, Q7, Q8)
- **Coverage vs expectation (Q6):** realized depth per sample vs its published coverage; the 5 declared high-coverage genomes (incl. Denisova 3, now correctly named) must land in the high band.
- **Sex & contamination (Q7):** X/Y depth-ratio sex check; X-chromosome / mtDNA contamination estimate; assert < threshold.
- **Damage / authenticity (Q8):** **mapDamage** per sample → 5′ C>T / 3′ G>A misincorporation curves; record UDG status; this is what your mapDamage request feeds.
- **Genetic diversity — individual heterozygosity vs depth (Tina's request):** estimate per-individual **heterozygosity** the depth-aware way, from genotype likelihoods, **ANGSD → `realSFS`** (per-sample folded site-frequency spectrum → heterozygosity = the proportion of heterozygous sites), *not* from hard calls. Then **plot individual heterozygosity against individual depth.** This is a double-duty diagnostic: (1) it is a real diversity metric (Neanderthals are expected to have *low* heterozygosity from small long-term population size), and (2) the het-vs-depth plot exposes confounding — at low depth heterozygosity is systematically *under*-called (missed hets) while **modern contamination or damage *inflates* it**, so a sample sitting off the expected het-vs-depth trend is a red flag (feeds Q7). Report it as a labelled scatter (one point per individual, het on y, mean depth on x, expected-range band).
- **Gate:** damage in the authentic-aDNA range; contamination below threshold; coverage matches expectation (Denisova 3 no longer sparse); heterozygosity-vs-depth reviewed — no sample is an unexplained outlier (high het at low depth ⇒ suspect contamination/damage; investigate before use).

### Stage 3 — One build + a verified, harmonized panel  · gate: build lint + allele check (Q2, Q4)
- Put the pigmentation panel on **hg19** by rsID (re-pull hg19 coordinates for each panel rsID; keep both builds in the manifest so the bug cannot recur). Reconcile the panel-size mess (committed 222 vs cluster 395-line BED vs 225 unique rsIDs vs 129 overlapping the modern reference) — settle on one documented analysis panel.
- **Tracer-SNP lint (Q2):** rs1426654 → `15:48426484`, rs12913832 → `15:28365618`; all inputs one build, one naming.
- **Allele harmonization (Q4):** REF base at each panel position == panel/VCF REF (`samtools faidx`); effect allele ∈ {REF,ALT}; **flag palindromes**; decide policy.
- **Gate:** lint exits 0; 0 REF mismatches on retained SNPs.

### Stage 4 — Genotype **likelihoods** (not hard calls)  · gate: GLs sane, damage-aware
**Design change (2026-07-23, Tina):** the samples are mostly **low coverage** — 10 of the 14 are under ~3.2× at the panel and several are <1× (exact table in `coverage_current.tsv`). **Hard-calling with VCF tools is the wrong tool here**: forcing a definite genotype from 1–2 reads either invents a call or drops the site, and it bakes in aDNA damage as false alleles. So the primary engine is **genotype likelihoods via ANGSD**, which keep the per-genotype probability and propagate uncertainty; hard calls are reserved for the few high-coverage genomes and for specific per-SNP *reporting* (e.g. does a high-coverage archaic carry an MC1R red-hair allele).

- **Primary — ANGSD genotype likelihoods** at the SNP panels (`-GL 1|2 -doGlf`, `-sites` = the panel positions, `-minMapQ 30 -minQ 20`), from the mapDamage-rescaled BAMs. No hard genotype is committed; the downstream PCA (Stage 6, PCAngsd) consumes the GLs directly.
- **Diploid model** (fix A3): ANGSD models autosomes as diploid; the old `--ploidy 1` haploid autosomal calling is not reproduced. (X/Y handled by sex from Stage 2.)
- **Max-depth cap** (Tina's request): impose a per-sample depth ceiling to reject pileup artifacts — the current data already shows these (e.g. **Vindija 87 mean 3.2× but max 147×; Scladina mean 1.9× but max 91×** — collapsed/repetitive regions). ANGSD `-setMaxDepth` (and `-setMinDepth`) drop sites outside a sane band; set the ceiling from each sample's depth distribution (e.g. a high percentile or a multiple of the mode), and log how many sites are dropped.
- **Damage handling** (Tina's request, applied per analysis):
  - **mapDamage `--rescale`** the base qualities so likely-deaminated bases are down-weighted — keeps the transition SNPs while mitigating damage. ANGSD can additionally `-trim` read ends and `-noTrans 1` where wanted.
  - **Transversion policy — important:** a blanket *transversion-only* filter would delete ~71% of the pigmentation panel, **including SLC24A5 (rs1426654) and HERC2 (rs12913832)** (transitions; measured 92 Ti / 37 Tv among the 129 panel SNPs in the reference, and the MC1R red-hair set is transitions too). So use **transversion-only (`-noTrans 1`) for the whole-genome ancestry PCA** (standard, damage-robust) but **keep transitions for the pigmentation panel**, leaning on rescaling + GL uncertainty + the high-coverage samples. Report both.
- **Hard calls — secondary, high-coverage only:** for the 4–5 high-coverage genomes, `bcftools mpileup | bcftools call -m` (diploid, keep-all) at the panel gives a conventional VCF for per-SNP reporting and cross-checking against published archaic genotypes (Q9). These are *not* the basis of the low-coverage PCA.
- **Gate:** GLs produced at the panels with documented quality/depth/damage filters; max-depth ceiling applied (dropped-site counts logged); transition-kept vs transversion-only GL sets both available; high-coverage hard-call VCF produced for reporting only.

### Stage 5 — Modern reference  · gate: SGDP verified or rebuilt
- Verify the existing `sgdp.wg` (15 samples, 9.2M hg19 SNPs — confirmed hg19, contains the pigmentation SNPs by rsID) via the Stage-3 lint + a checksum, OR rebuild it from the SGDP source if provenance can't be established (Q1). Decide 15-sample (matches the thesis) vs expanding to the 279-sample set.
- **Gate:** modern reference passes the same build/allele lint as the archaic data.

### Stage 6 — PCA + projection (GL-based)  · gate: positive control + non-degeneracy (Q3, Q5)
- **Primary — PCAngsd on the genotype likelihoods** from Stage 4: this is the low-coverage-appropriate PCA (covariance estimated from GLs with per-sample uncertainty), for both the ancestry (whole-genome) and pigmentation panels. It replaces the old `plink2 --pca` + `--score` hard-genotype projection that produced the collapse.
- **Positive control (Q3):** the whole-genome PCAngsd run must reproduce known structure (Africans separate on PC1; archaics among non-Africans). If it can't, stop.
- **Non-degeneracy (Q5):** the pigmentation PCA is multi-dimensional (not rank-1) and samples spread out — the collapse was a symptom of hard-call mean-imputation on a monomorphic (wrong-build) panel; GL-based PCA on the corrected hg19 panel should not collapse. (If a plink hard-genotype projection is run at all — high-coverage only — it must use `no-mean-imputation`.)
- **Three panels × two designs (B4):** pigmentation SNPs / whole pigmentation genes / genome-wide × (high-coverage-together, moderns-with-all-projected). Low-coverage samples enter via GLs (PCAngsd), not forced hard calls.
- **Gate:** control reproduces known structure; no collapse; before/after figures rendered (`make_consequence_figures.R after`).

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
