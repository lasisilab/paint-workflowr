# PAINT — evaluation & QC plan (reviewer-driven, unit-test style)

**Purpose.** Work backwards from a skeptical reviewer of an archaic-DNA pigmentation study — *"what would I not believe, and what are the classic ways these pipelines go wrong?"* — and turn each doubt into a concrete, runnable **test** on a well-defined **unit** (a data file, a transformation, a result). The aim is to (a) evaluate the state of the project fast and (b) catch bugs before they propagate.

**Two principles:**
- **Provenance before analysis.** Every input is guilty until proven innocent: known source, known genome build, known checksum. Most of the confirmed bugs so far are provenance/harmonization failures (build mismatch, contig naming, panel from an undocumented file).
- **Reproduce known truth first (positive controls).** Before trusting any novel result, make the pipeline reproduce something we already know (e.g. SGDP clusters by continental ancestry; MC1R has no red-hair variants in archaics). If it can't reproduce the known, don't build on it.

**How to read each item:** *Reviewer's doubt → Unit(s) & failure modes → Test(s) (runnable) → Communication artifact (like the flow figure — a visual/table that makes state legible at a glance) → Effort.*

Ordered by importance for quickly learning the state and catching the worst bugs. Items 1–5 are gates (should pass before results are trustworthy).

---

## 1. Data-provenance manifest + checksums  ⭐ foundational
**Reviewer's doubt:** "What *exactly* are these files, where did they come from, and are they intact? The pigmentation panel is read from a personal home dir with no documentation — I don't even know which SNPs it is."

**Units & failure modes:** every genome/BAM; the SNP panel(s) (`snps.bed`, `sgdp.snps.pos`, `pigmentation_snps.*`); gene-coordinate sets (for the "whole pigmentation genes" PCA — where do gene start/end come from?); metadata (SGDP sample→population, ages, coverage). Failure modes: wrong/undocumented source, wrong build, truncated download, silent version drift, LP-ID↔sample mismapping, hand-typed tables presented as data.

**Tests:**
- A `manifest.tsv`: one row per input with `path, sha256, source (DOI/URL/accession), genome_build, N (samples or SNPs), date_obtained, produced_by (script or "external")`. **Test:** assert every file used by the pipeline appears with a non-empty source + build + checksum; fail if any is `external/unknown`.
- Re-download one archaic BAM and one SGDP VCF and assert sha256 matches the manifest (guards against silent corruption / expired-link substitution).
- For the SNP panel: assert the committed `data/skin_pigmentation.tsv` regenerates `pigmentation_snps.csv` deterministically; record the GWAS Catalog query (trait EFO, access date) that produced it.
- For gene coordinates: record the source (Ensembl/RefSeq release #, build) and the exact query; assert every gene resolves to exactly one region.

**Communication artifact:** the manifest table itself, plus a one-line "inputs ledger" badge (N inputs, N with full provenance, N unknown). Model it on `pigmentation-gene-network/DATA_SOURCES.md`.

**Effort:** low–medium. **This is the prerequisite for everything else.**

## 2. Genome-build & contig-naming lint (tracer-SNP assertions)  ⭐ gate
**Reviewer's doubt:** "Is *everything* on the same build with the same chromosome naming? A single hg19/hg38 slip silently ruins coordinates" — this is confirmed issue #1, and Denisova 3's `chr` naming is issue #3.

**Units & failure modes:** BAMs (`@SQ` contigs), VCFs/BCFs (contig lines), panels/BEDs (chrom col), gene coords, reference `.fai`. Failure: mixed builds; `chr1` vs `1`; a panel on hg38 queried against hg19 data (→ wrong loci, monomorphic panel).

**Tests:**
- **Tracer SNPs** with known coordinates in both builds — e.g. `rs1426654` SLC24A5 (hg19 `15:48426484` / hg38 `15:48134288`), `rs12913832` HERC2 (hg19 `15:28365618` / hg38 `15:28120472`). For each input that carries positions, assert the tracer's coordinate matches exactly one build, and that all inputs agree. Fail on mismatch. (This alone catches the panel-vs-data mismatch in ~20 lines.)
- Contig-naming check: extract the contig set from every BAM/VCF/BED/`.fai` and assert one consistent convention; list any file that differs (would immediately flag Denisova 3).

**Communication artifact:** a **build-harmonization matrix** — files (rows) × {build, naming} (cols), green/red. One glance says "are we internally consistent?"

**Effort:** low. **Highest signal-to-effort; run it before trusting any coordinate-based step.**

## 3. Positive control — reproduce the SGDP whole-genome PCA  ⭐ gate ("replicate the known first")
**Reviewer's doubt:** "Before I believe your novel pigmentation result, does your PCA even reproduce the *textbook* population structure?"

**Units & failure modes:** the whole-genome PCA (`modern_pca` / `sgdp_merge_pca`) and the ancient projection. Failure: if it can't recover continental structure, the merge/subset/PCA plumbing is broken and nothing downstream is trustworthy.

**Tests (encode the known result as assertions):**
- Assert PC1 of the SGDP WG PCA separates **African vs non-African** samples (Yoruba/Bantu/Khomani-San on one side) beyond a set margin; assert East-Asian / West-Eurasian / Oceanian form distinct clusters on PC2–PC3 (label-recovery via silhouette or a simple k-means concordance).
- Assert the **projected archaics fall among non-Africans on PC1** — the well-established introgression-driven expectation. (This is a positive control for the projection machinery specifically.)
- Compare to a published SGDP PCA figure qualitatively.

**Communication artifact:** the control PCA figure with the *expected* groupings annotated ("does it match the known map?"), shipped next to the real analysis so a reader sees the sanity check passed.

**Effort:** low (the eigenvec files already exist). **Do this early — it's the fastest read on whether the core method works.**

## 4. Allele & annotation harmonization  ⭐ gate (classic silent killer)
**Reviewer's doubt:** "Even on the right build, are the alleles right? Ref/alt swaps, strand flips, and palindromic SNPs silently invert scores and projections."

**Units & failure modes:** the panel SNPs' `REF/ALT`/effect allele vs the data; the GWAS effect-allele direction (for the polygenic score); annotation harmonization (VEP/gene-model build, dbSNP version). Failure: effect allele not present in data; REF/ALT swapped between panel and VCF (→ sign-flipped dosage); ambiguous A/T & C/G SNPs resolved on the wrong strand; annotating variants on a different build than they were called.

**Tests:**
- **REF-base check:** for every panel SNP, assert the reference-genome base at that position equals the panel/VCF `REF` allele (`samtools faidx` the position vs the record). Fails loudly on build/coordinate *and* allele errors — a very high-value single test.
- Assert each GWAS effect allele ∈ {REF, ALT} of the corresponding data record; count mismatches.
- Flag palindromic SNPs (A/T, C/G) and decide policy (drop, or resolve by MAF > 0.4 exclusion).
- For any annotation step (VEP/SnpEff, item in the workbook's B7): assert the annotator's genome build == the data build; pin the cache/release version in the manifest.

**Communication artifact:** a harmonization report: `N panel SNPs → matched / ref-alt-swapped / effect-allele-absent / palindromic-dropped / lost`. A funnel/Sankey of SNP counts through each filter.

**Effort:** medium.

## 5. PCA / projection non-degeneracy sanity checks
**Reviewer's doubt:** "How do I know the PCA isn't rank-deficient or the projection collapsed?" — confirmed issue #2 (all 15 archaics at identical coordinates) and the monomorphic pigmentation panel.

**Units & failure modes:** eigenvalues; per-allele loadings; projected `.sscore`. Failure: near-zero eigenvalues beyond PC1 (degenerate panel); all projected samples identical (mean-imputation collapse); loadings all zero (monomorphic panel).

**Tests:**
- Assert `>= k` panel SNPs are polymorphic in the reference (else the panel carries no structure).
- Assert eigenvalue ratio (e.g. λ2/λ1) exceeds a floor — flag rank-1 collapse.
- Assert the projected ancient coordinates have non-zero variance across samples (`sd(PC1) > ε`) and that at least two archaics differ — directly catches the collapse.
- Assert the projection command uses `no-mean-imputation` (grep the script) and document the missingness policy.

**Communication artifact:** a scree plot + a "projection spread" strip plot (are the samples actually spread out, or stacked on one point?).

**Effort:** low.

## 6. Per-sample coverage/depth expectations
**Reviewer's doubt:** "Do the coverage numbers make sense per sample?" — a nominally high-coverage genome showing near-zero (Denisova 3, issue #3) is a red flag that would have been caught here.

**Units & failure modes:** `*_depth.txt`, filtered BAMs. Failure: silent all-zero from build/naming mismatch; a "high-coverage" genome extracting sparse; unexpected outliers.

**Tests:**
- Record each sample's **expected** genome-wide coverage (from its source publication) in the manifest; assert realized panel mean-depth and covered-SNP fraction fall in the expected band. **Alert if a nominally high-coverage genome is sparse** (would flag Denisova 3 automatically).
- Assert covered-SNP fraction ≥ threshold for the "high-coverage" set used in the everyone-together PCA.

**Communication artifact:** a per-sample QC table (expected vs realized coverage, covered/222, tier) with red/amber/green — the single most scannable "are the samples OK?" view.

**Effort:** low.

## 7. Sample identity, sex & contamination
**Reviewer's doubt:** "Are these BAMs actually the individuals you think, and are they contaminated?" — mislabeling and modern-human contamination are endemic in aDNA and invalidate everything downstream.

**Units & failure modes:** each archaic BAM. Failure: sample swap/mislabel (e.g. is `den11` really Denisova 11?); modern contamination inflating heterozygosity/variant calls.

**Tests:**
- **Sex check:** X/Y normalized depth ratio vs recorded sex; assert concordance.
- **Contamination estimate:** X-chromosome (males) or mtDNA-based contamination (e.g. `contamMix`/`schmutzi`-style); assert < a set threshold (e.g. 2–5%).
- Where a reference genotype exists (e.g. published Vindija/Altai calls), assert genotype concordance at a handful of sites confirms identity.

**Communication artifact:** extend the per-sample QC dashboard (item 6) with sex, contamination %, and an identity-confirmed flag.

**Effort:** medium.

## 8. Ancient-DNA authenticity / damage handling
**Reviewer's doubt:** "This is ancient DNA — where's the damage assessment? Deamination C>T/G>A at read ends creates false variants." No damage handling is visible in the current scripts.

**Units & failure modes:** BAMs → variant calls. Failure: deamination transitions called as real ALT alleles (worse under the `-mv` caller); library type (UDG-treated vs not) not tracked.

**Tests:**
- Run mapDamage/PMDtools; assert 5′ C>T and 3′ G>A rates are in the authentic-aDNA range and decay as expected; record UDG status per sample in the manifest.
- Robustness test: re-call with terminal bases trimmed/masked and assert the pigmentation genotype calls are stable (transition-heavy sites are the risk).

**Communication artifact:** per-sample damage plots + a "damage-handled: yes/no" column in the QC dashboard.

**Effort:** medium.

## 9. Cross-validation against published results + an orthogonal predictor
**Reviewer's doubt:** "Do your archaic calls agree with what's already published, and does your simple score agree with an established method?"

**Units & failure modes:** archaic genotypes at named loci; the directional pigmentation score. Failure: disagreeing with well-established archaic genotypes (a red flag for calling errors); the home-grown score disagreeing with a validated tool.

**Tests:**
- Assert MC1R known red-hair variants (rs1805007/8/6, etc.) are **absent/reference** in the archaics (the expected, citable null — and a check that MC1R is even being genotyped).
- Assert genotypes at a set of loci with published archaic calls (from the Neanderthal/Denisovan genome papers) match.
- Compute the directional score **and** HIrisPlex-S-style prediction on the same samples; assert rank concordance (they shouldn't wildly disagree).

**Communication artifact:** a "known results reproduced" table (locus → expected → observed → ✓/✗).

**Effort:** medium–high.

## 10. Reproducibility infrastructure (versions, seeds, pipeline-as-DAG, CI)
**Reviewer's doubt:** "Can I re-run this and get the same numbers?" — currently no version pinning, no seeds, competing/dead scripts, and manual per-sample submission.

**Units & failure modes:** the whole pipeline. Failure: unpinned bcftools/plink2/R; unseeded Monte-Carlo (the depth simulation changes every render); ambiguity over which of the competing scripts ran.

**Tests / practices:**
- Pin the environment (conda `environment.yml` / a container / R `renv.lock`); record tool versions in the manifest.
- Add `set.seed()` to the simulations; assert re-run reproduces figures (hash).
- **Encode the pipeline as a Snakemake/Nextflow (or Makefile) DAG** — this makes the run order explicit, removes the "which script is canonical" ambiguity, and the DAG **auto-generates the flow figure** (so the diagram you liked stays in sync with reality).
- A tiny **end-to-end fixture test** (a few samples, a few SNPs) that runs in CI and asserts the key invariants from items 2–6.

**Communication artifact:** the auto-generated DAG figure + a green/red CI badge on the repo.

**Effort:** medium–high (but pays down the "two-pipeline" confusion permanently).

---

## Priority summary

Ordered as above; suggested first pass in bold.

1. **Provenance manifest + checksums** — low effort — unblocks everything; the panel BED is currently unknown.
2. **Build & contig-naming lint** — low — catches issues #1 & #3 automatically.
3. **Positive control: reproduce SGDP WG PCA** — low — fastest read on whether the method works at all.
4. **Allele/annotation harmonization** — medium — the classic silent score/projection killer.
5. **PCA/projection non-degeneracy** — low — directly catches the current collapse (#2).
6. Per-sample coverage expectations — low — would have flagged Denisova 3.
7. Sample identity / sex / contamination — medium — catches swaps & modern contamination.
8. aDNA damage handling — medium — reviewers of ancient DNA will require it.
9. Cross-validation vs published + orthogonal predictor — medium/high — credibility.
10. Reproducibility infra (versions/seeds/DAG/CI) — medium/high — ends the two-pipeline ambiguity.

**Quickest high-value first pass (a day or two):** items 1→2→3→5→6. They're mostly low-effort, reuse files already on disk, and together tell us whether the foundation is sound before investing in the deeper controls (4, 7–10).

**On communication artifacts (per your point about the figure):** the recurring pattern that works is *a single legible view per concern* — the build-harmonization matrix (item 2), the SNP-funnel (item 4), the scree/projection-spread plots (item 5), and above all a **per-sample QC dashboard** (items 6–8 combined: coverage, sex, contamination, damage, identity — one row per sample, red/amber/green). Plus the pipeline-as-DAG (item 10) that regenerates the flow diagram automatically. If you like, the next step after you approve this plan is to build that QC dashboard + the build-lint as the first two concrete deliverables.
