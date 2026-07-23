# PAINT — Project Plan & Roadmap

**Project:** PAINT — a study of what skin/hair/eye pigmentation genetics can (and can't) tell us about Neanderthals and Denisovans, and how they compare to modern humans.
**Team:** Tina Lasisi (PI / advisor) · Lily Heald · Yemko Pryor.
**Last updated:** 2026-07-22. **Status:** living document.

## How to read this
- **`plan.md`** (this file) = the canonical plan. Edit here first.
- **`changelog.md`** = dated log of what was done / found / decided.
- **`paint-plan.html`** = a nicer, shareable rendering of this file.
- **Every item below is written to stand on its own** — you should be able to jump to any single item and understand what it is, why it matters, and what to do, without having read anything else. Terms are defined in the Glossary just below, and the load-bearing ones are re-explained inline where they're used.

---

## Glossary (read once; everything else assumes nothing beyond this)

- **Reference genome / genome build (hg19 vs hg38):** The "reference genome" is the standard map of the human genome that everyone's DNA is compared against. It has been re-released over the years. Two versions matter here: **hg19** (a.k.a. GRCh37, from 2009) and **hg38** (a.k.a. GRCh38, from 2013). **The same physical SNP has a *different* coordinate number in each version.** Example: the well-known SLC24A5 skin-color SNP (rs1426654) is at position `15:48,134,288` in hg38 but `15:48,426,484` in hg19 — about 292,000 letters apart. So a coordinate written in one build, if looked up in data stored in the other build, points at the **wrong place** in the genome.
- **SNP:** a single position in the genome where people differ by one DNA letter (e.g. A vs G). "Pigmentation SNPs" are positions known to influence skin/hair/eye color.
- **The panel:** the fixed list of **222 pigmentation SNP positions** this project focuses on (file: `snps.txt`). Its coordinates came from the GWAS Catalog and are on **hg38**.
- **The sequence data (a.k.a. "the data"):** the actual DNA reads for each individual. This covers **both** groups: the **archaic samples** (Neanderthal/Denisovan) and the **modern SGDP genomes**. All of it is aligned to the **hg19** reference genome (`hs37d5.fa`, which is GRCh37).
- **Archaic samples:** the ancient Neanderthal and Denisovan individuals (14 analyzed).
- **SGDP:** the Simons Genome Diversity Project — modern human genomes (15 individuals here) used as the present-day comparison set.
- **BAM / VCF:** a BAM file holds one sample's sequencing reads aligned to the reference; a VCF file holds the genetic variants (genotypes) called from those reads.
- **Coverage / depth:** how many times a position was sequenced. Higher = more reliable. Ancient DNA is often very low-coverage.
- **Missingness:** positions where no reliable genotype could be called (no usable data).
- **PCA (principal component analysis):** a way to squash genome-wide variation down to a few axes (PC1, PC2, …) and plot samples, so that genetically similar people sit near each other. Used here to see where archaic samples fall relative to modern populations.
- **Projection:** rather than letting the low-coverage archaic samples help *build* the PCA (where their gaps would distort it), you build the PCA from the modern samples and then drop the archaic samples onto it.
- **Monomorphic:** a position where every sampled individual has the same allele — no variation, so it tells PCA nothing.
- **Ploidy (diploid / haploid):** humans are **diploid** — two copies of each non-sex chromosome — so a genotype is a pair (e.g. `A/G`). Forcing **haploid** calling (`--ploidy 1`) records only one allele per position, so a heterozygote (`A/G`) can't be represented.
- **Allele:** one of the alternative DNA letters at a SNP (at an A/G SNP, `A` and `G` are the two alleles). Being diploid, a person carries two — e.g. `A/A`, `A/G` (a "heterozygote"), or `G/G`.
- **GWAS / GWAS Catalog:** a GWAS (Genome-Wide Association Study) scans many people's genomes to find SNPs statistically associated with a trait. The **GWAS Catalog** (run by NHGRI-EBI) is a public database of those association hits; it reports coordinates on **hg38**. Our 222-SNP panel came from it.
- **Effect size / direction:** from a GWAS, how strongly a SNP's allele shifts a trait. "Direction" is just the sign — whether the allele *increases* or *decreases* pigmentation.
- **kb (kilobase):** 1,000 DNA letters. "~292 kb apart" = about 292,000 letters apart.
- **Aligned / BAM:** "aligning" = matching a sample's short sequencing reads to where they belong on the reference genome. The result is a **BAM** file (Binary Alignment Map) — the standard file of one sample's aligned reads.
- **Genotype calling / VCF:** working out each individual's alleles at each position from their aligned reads (done with tools like `samtools`/`bcftools`). The output is a **VCF** file (the called variants).
- **SLURM / `.slurm` script:** the cluster's job scheduler; a `.slurm` file is a batch-job script you submit to it to run something on the cluster.
- **liftOver / CrossMap:** standard tools that convert genome coordinates from one build to another (e.g. hg38→hg19) using a "chain file." This is how you'd fix a build mismatch.
- **MC1R:** the melanocortin-1-receptor gene; disabling ("loss-of-function") variants in it cause red hair and pale skin. A frequently-asked target for archaic humans.
- **HIrisPlex-S:** a published forensic system that predicts skin/hair/eye color from a fixed set of DNA markers. We use its marker list (not, for now, its full prediction math).
- **Exome:** the protein-coding portion of the genome (~1–2%). "Exome data" = sequencing focused there.
- **Synonymous vs non-synonymous:** a DNA change inside a gene is *synonymous* (silent — protein unchanged) or *non-synonymous* (changes the protein). Their ratio is a rough signal of whether the variation is doing something functional / is under selection.
- **Tissue-specific expression:** a gene is "expressed" in a tissue where it's switched on. "Skin-specific" pigmentation genes are switched on mainly in skin (vs. genes active all over the body).
- **The six skin-specific pigmentation genes** (referenced in B7): TYR (tyrosinase, the key melanin-making enzyme), OCA2, TYRP1, DCT, PMEL, MLANA — all melanocyte/melanin-pathway genes.

Owner tags: **(TL)** Tina · **(LH)** Lily · **(YP)** Yemko. Priority: 🔴 high · 🟡 medium · ⚪ low.

---

## 1. What this project is
The recurring public question is "what did Neanderthals and Denisovans look like?" PAINT asks whether their **pigmentation** (skin/hair/eye color) can actually be read off their ancient DNA. The honest finding so far is *not confidently* — the ancient DNA is patchy and shallow, and pigmentation genes don't behave like ancestry markers — so the project's contribution is an honest **map of what the pigmentation genetics does and doesn't support**, with the uncertainty made explicit.

## 2. Where things stand (July 2026)
Three places hold the work, all now reviewed:
- **The repo** `lasisilab/paint-workflowr` — the analysis website (built with the R tool *workflowr*), plus small data files and the analysis scripts.
- **The thesis** — Lily's 41-page honors thesis (20 Apr 2026); the completed first version of this work.
- **The cluster** — a 110 GB working directory on the University of Michigan "Great Lakes" system (`/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data`) holding the full computational pipeline (~19 batch jobs) and all the genomic data (the big files too large for the repo). **Full inventory:** [`cluster_inventory.md`](cluster_inventory.md) (directory layout, the pipeline stages, data products, access instructions).

**Data-source decision:** the pigmentation datasets we want for the next phase already exist, all on the hg38 build, in the public repo `tinalasisi/pigmentation-gene-network` (details in §6). We use that repo; we do **not** use the older `melanogenesis-constraints` repo.

## 3. Open questions for Lily (please confirm)
- **The genome-build mismatch (see item A2).** Did you know the pigmentation SNP list uses hg38 coordinates while the sequence data is aligned to hg19? And how would you rather fix it — move the SNP list to hg19, or move all the data up to hg38 (which matches the rest of the plan)?
- **Denisova 3 (see item A1).** Was the chromosome-naming difference on that one sample accidental? If so we just re-run it.
- **Haploid calling (see item A3).** Was `--ploidy 1` on the whole-genome calling intentional?

---

## 4. Roadmap

### A. Bugs & fixes
Every item here was reproduced with commands + real output — see [`verify/BUG_EVIDENCE.md`](verify/BUG_EVIDENCE.md) (runnable: [`verify/verify_bugs.sh`](verify/verify_bugs.sh)). None of these damaged any data; they affect results.

- [ ] **A2 · The SNP list and the sequence data are on different genome builds (hg38 vs hg19) — the root problem** · 🔴 (TL/LH) · **CONFIRMED**
  - **What it is:** The project measures 222 specific pigmentation SNP positions ("the panel"). Those position numbers were taken from the GWAS Catalog, which reports them on the **hg38** genome build. But every individual's actual DNA — the archaic Neanderthal/Denisovan samples **and** the modern SGDP genomes — was aligned to the **hg19** build. Because the same SNP sits at different coordinates in hg19 vs hg38 (e.g. SLC24A5 is `15:48,134,288` in hg38 but `15:48,426,484` in hg19), reading the panel's hg38 positions out of the hg19 data lands on the **wrong places** in the genome.
  - **Why it matters:** it corrupts both halves of the analysis. (1) **PCA:** the wrong hg19 positions are essentially random spots, and at random spots all 15 modern genomes happen to carry the same letter (221 of the 222 are *monomorphic* — no variation). Positions with no variation give the PCA nothing to tell samples apart on, so the pigmentation PCA collapses to a single axis and every archaic sample lands on the *same* point — the figure is meaningless. (2) **Depth/missingness:** the coverage reported "at each pigmentation SNP" is actually measured at a spot that can be far from the real SNP — hundreds of kb off (e.g. ~292 kb for SLC24A5), and the offset differs per SNP — so those numbers don't describe the intended loci.
  - **Do:** put the panel and the sequence data on the *same* build before re-running any pigmentation-SNP analysis. The plan's chosen direction is to lift the **data up to hg38** (item B2), because the four new datasets are already hg38. Alternatively, lift the **panel down to hg19** using a standard coordinate-conversion tool (UCSC `liftOver` or `CrossMap` with an hg38→hg19 "chain file"), or re-pull the SNPs' hg19 coordinates from the GWAS Catalog. Either way, pick one build and make everything match. Until then, treat the pigmentation PCA and pigmentation-SNP depth results as unreliable.
  - **Evidence:** `BUG_EVIDENCE.md` §⓵/§A2 — panel carries the hg38 SLC24A5 coordinate; reference file header says GRCh37; 221/222 sites monomorphic in SGDP; all archaic PCA projections identical.

- [ ] **A1 · Denisova 3 uses different chromosome names than everything else** · 🔴 (LH confirm → TL/LH re-run) · **CONFIRMED**
  - **What it is:** Chromosomes can be labelled two ways — bare (`1`, `2`, … `15`) or prefixed (`chr1`, `chr2`, … `chr15`). The reference genome, the SNP panel, and every archaic sample use the **bare** style — *except the Denisova 3 sample*, whose alignment file (BAM) uses the **`chr`-prefixed** style. When the pipeline looks up the (bare-named) SNP positions in Denisova 3's (`chr`-named) file, the names don't match, so almost nothing is found.
  - **Why it matters:** Denisova 3 is a **high-coverage** Denisovan genome, yet it shows near-empty coverage over the panel (mean depth 0.5×, only 69 of 222 SNPs covered — versus 30.7× and all 222 for **Vindija 33.19**, a comparable high-coverage sample) and sits in the sparse group of the thesis's Figure 5. Because the reference genome and the SNP panels are bare-named, any step that pairs Denisova 3's `chr`-named reads with them (the whole-genome genotype calling, the PCA inputs) fails to match and drops most of its data — so its apparent sparseness is very likely a naming artifact, not real biology. (Separate from A2: A2 makes the *panel* wrong for *every* sample; A1 makes *this one sample* look empty.)
  - **Do:** relabel Denisova 3's chromosomes to the bare style — e.g. `samtools reheader` with a name map (`chr1`→`1`, …) — then re-run its depth and genotype calling and confirm the coverage is really there (expect it to jump into the high-coverage group and move in the PCA). An alternate cluster script, `pca_ancient.slurm`, already contains logic that normalizes `chr` names; that approach can be reused instead of editing the file by hand.
  - **Evidence:** `BUG_EVIDENCE.md` §A1.

- [ ] **A3 · Whole-genome ancient calling treats chromosomes as single-copy (`--ploidy 1`)** · 🟡 (LH confirm) · **CONFIRMED**
  - **What it is:** Humans have two copies of each non-sex chromosome (diploid), so a genotype should be a pair like `A/G`. One of the genotype-calling jobs (`ancient_wg.slurm`) is set to `--ploidy 1` (haploid) across all chromosomes including the non-sex ones, which forces a single allele per position.
  - **Why it matters:** with haploid calling, a heterozygous individual (who carries both `A` and `G`) can never be recorded as such — you lose half the genotype information on the autosomes, which biases anything downstream that depends on it.
  - **Do:** confirm whether this was intentional; for diploid autosomes it normally should not be `--ploidy 1`. Re-run diploid if it was a mistake.
  - **Evidence:** `BUG_EVIDENCE.md` §A3 (the setting is on line 83 over all chromosomes; output genotypes are single-allele).

- [ ] **A4 · Two versions of the ancient pigmentation-calling script exist (tidy-up, not a bug)** · ⚪ (LH/TL) · **DOWNGRADED**
  - **What it is:** there are two scripts that call ancient genotypes at the pigmentation panel: one keeps every site (`bcftools call -c`), the other keeps only sites that vary (`bcftools call -mv`).
  - **Why it (barely) matters:** I originally flagged the "-mv, variants-only" one as dropping sites and biasing the analysis. **On checking, it didn't:** the actual output file has all 222 sites, so the keep-everything script is clearly the one that was used. Nothing was lost.
  - **Do:** just delete the unused `-mv` script so there's no confusion about which is canonical. (No re-analysis needed.)
  - **Evidence:** `BUG_EVIDENCE.md` §A4 (committed output has 222 records).

- [ ] **A5 · Two dead/broken scripts on the cluster** · ⚪ (LH/TL) · **CONFIRMED**
  - **What it is:** (i) `ancient_merge.slurm` tries to merge files matching `*.wg.vcf.gz`, but the real output file is named `ancient_sgdp_wg.vcf.gz` (`_wg`, not `.wg`), so that pattern matches nothing and the script does nothing. (ii) `pca_ancient.slurm` points at a reference file `hg19.fa` that isn't present (only `hs37d5.fa` exists), so it can't run, and its output isn't used anywhere else.
  - **Why it matters:** only as clutter/confusion — neither is part of the working pipeline.
  - **Do:** delete or fix them so the cluster directory reflects what actually runs.
  - **Evidence:** `BUG_EVIDENCE.md` §A5.

- [ ] **A6 · Repo tidy-ups** · ⚪ (LH). In the website source: `introduction.Rmd` says the panel is "395 SNPs" but it's 222 (fix the number); the "View genetic PCAs" link points to the old `analysis.html` (should be `pca.html`); the `LICENSE` file is empty (the license text only lives in `license.Rmd`); two built pages (`docs/analysis.html`, `docs/depth_spinoff.html`) have no source and should be removed; and `cleaning.Rmd` / `process_links.R` hard-code file paths from Lily's laptop, so they won't run elsewhere.

### B. Analysis redesign (the plan from the 17 June meeting)

**The analyses agreed on the 17 June call** (source: meeting transcript) — each maps to an item below:
1. Layered **coverage** of pigmentation loci across the four datasets (GWAS-only, then + CRISPR, + melanogenesis network, + cross-species) → **B1**.
2. **"What color were they?"** in two steps: (a) GWAS betas → a **directionality** score (optionally restricted to skin-pigmentation and/or ≥2-hit SNPs); (b) the **MC1R** red-hair-variant check → **B3**.
3. **PCA redone** three ways (pigmentation SNPs / whole pigmentation genes / genome-wide) × two designs (moderns + high-coverage archaics together; moderns-only with all ancients projected) → **B4**.
4. **Missingness** strategy (full masking leaves <50 SNPs → focus high-coverage, move to gene level) → **B5**.
5. Keep **genes vs SNPs** distinct (network = genes; pull gene start/stop coordinates) → **B6**.
6. **Functional / exome:** synonymous:non-synonymous ratio; annotate coding effects → **B7**.
7. **Skin-specific gene** focus (TYR, OCA2, TYRP1, DCT, PMEL, MLANA) across modern populations and archaics → **B7**.
Plus the call's "normalize everything to hg38" → **B2** (which we now know is also the fix for bug A2).

**How the two kinds of dataset are actually used — directionality vs. genes-without-SNPs** (the part that's been unclear):
- **SNP-level sources (GWAS Catalog, HIrisPlex-S)** carry a *signed effect per SNP* — an effect allele and a known direction (increases or decreases pigmentation). These are the **only** sources that feed the directional polygenic score (**B3**): for each SNP, count the individual's copies (0/1/2) of the pigmentation-increasing allele and sum. The direction comes straight from the GWAS effect sign (already in the GWAS Catalog export's `or_beta` / `direction_raw` columns); a missing genotype means that SNP is skipped for that individual.
- **Gene-level sources (melanogenesis network / Raghunath, Baxter, Bajpai, D'Arcy)** are lists of *genes* (regions), not signed SNPs, so they **cannot** go into the +1/−1 score — a gene region has no single effect allele. They're used instead as **gene-region sets** (take each gene's start/end coordinates and use *all* variants inside it), which feed the gene-level PCA (**B4 (ii)**) and the layered coverage (**B1**); and for **functional interpretation** (**B7**) — e.g. "does this archaic carry a protein-changing variant in a network gene?" — via a variant-effect annotator, kept descriptive.
- **The bridge is optional and heavier:** to give a gene-level source a per-individual "direction" you'd need per-variant functional prediction (is *this* variant damaging?), not a GWAS effect size — shaky on low-coverage archaic data, so keep it descriptive (B7), not part of the score.
- **Bottom line:** the directional score is **SNP-only**; the gene sources drive the gene-level PCA, coverage, and functional annotation. Don't force gene lists into the additive score.

- [ ] **B1 · Base the coverage analysis on four pigmentation datasets, not just one** · 🔴 (TL builds, LH runs)
  - **What it is:** so far the pigmentation SNP list came from a single source (the GWAS Catalog). Broaden it to four complementary sources of pigmentation genes/SNPs (all already assembled in `pigmentation-gene-network`, see §6): the **GWAS Catalog**, a **CRISPR screen**, a **melanogenesis gene network**, and a **cross-species** gene set.
  - **Why it matters:** each source captures different pigmentation biology; a single source undercounts. Report coverage in layers — GWAS-only first, then each additional set — so it's clear what each contributes.
  - **Do:** wire the four datasets into the coverage code; produce the layered coverage summary.

- [ ] **B2 · Put everything on one genome build: hg38** · 🔴 (TL/LH)
  - **What it is:** as item A2 shows, the SNP panel is on hg38 but the sequence data is on hg19, which is why the pigmentation analyses are broken. The four new datasets (B1) are also on hg38. So standardize the whole project on **hg38**: convert the archaic + SGDP sequence data (and anything else on hg19) up to hg38 so it matches the panels.
  - **Why it matters:** this is the fix for the root bug (A2) *and* the prerequisite for using the four hg38 datasets. Nothing pigmentation-SNP-related is trustworthy until builds match.
  - **Do:** lift the data to hg38 (or, if easier, lift the panels to hg19 — but pick one build and make everything match). Then re-run depth + PCA. **This is the critical-path first step.**

- [ ] **B3 · Score pigmentation direction, and specifically check MC1R (red hair)** · 🟡 (TL/LH)
  - **What it is:** a **polygenic score** = one darker-vs-lighter number per individual. For each pigmentation SNP that has a known direction of effect, count how many copies of the pigmentation-*increasing* allele the individual carries (0, 1, or 2 — everyone is diploid) and add them into a signed sum: increasing alleles push the score up, decreasing alleles push it down, so **higher score = predicted darker**. The main version uses **sign only** (each SNP counts equally, just its direction); an optional version weights each SNP by its GWAS effect size. Fix the rules up front: heterozygotes count by allele copies (as above); a SNP with a missing genotype in an individual is skipped for that individual. Separately, the **MC1R red-hair check**: look up MC1R's known red-hair variant positions in each archaic individual and report whether any carries a red-hair (loss-of-function) allele — we expect *none*, and confirming that is itself a citable result.
  - **Why it matters:** it directly answers the "what color were they?" question at the level the evidence can actually support, without over-claiming. The MC1R check is a specific, frequently-asked point.
  - **Do:** score the 14 archaic individuals (and, for comparison, the 15 SGDP moderns) at the pigmentation-SNP panel — this **needs genotype calls at the panel positions on a matched genome build, so it depends on B2 being done first.** Take each SNP's effect direction from the GWAS Catalog. The forensic **HIrisPlex-S** panel supplies a well-characterized marker subset, including the exact MC1R red-hair variants (e.g. rs1805007, rs1805008, rs1805006) and the blue-eye HERC2/OCA2 markers; its numeric prediction weights are an *optional* fetch (Walsh 2017, *Human Genetics*) needed only for full quantitative color probabilities. Because those weights are European-trained, the sign-only score is the more defensible choice for archaic samples.

- [ ] **B4 · Redo the PCAs three ways, two designs each** · 🟡 (LH)
  - **What it is:** build the "where do samples sit relative to each other" plots (PCA) using three different sets of positions — (i) just the 222 pigmentation SNPs, (ii) whole pigmentation-related *genes* (every position inside those genes, not just the known SNPs — take the gene list from the four datasets in §6, and their start/end coordinates from a gene database such as Ensembl/BioMart, on the matched build), and (iii) the whole genome as a baseline. For each, do two versions: **(a)** build the plot from the modern samples plus the few high-coverage archaics together (here "high-coverage" = the 4 flagship genomes: Vindija 33.19, Chagyrskaya 8, Denisova 5, Denisova 25); **(b)** build it from moderns only and then *project* all 14 archaics (including the low-coverage ones) onto it.
  - **Why it matters:** it tests a hypothesis — that pigmentation-gene clustering should *not* mirror whole-genome (ancestry) clustering. Confirming they differ is the point; don't assume it. The two designs handle the low-coverage samples honestly (design (b) is exactly how you place gappy samples without letting their gaps distort the axes).
  - **Do:** after **B2** (put the panel, the gene coordinates, and the sequence data all on the same genome build — see B2/A2), generate the six plots.

- [ ] **B5 · Decide how to handle missing data** · 🟡 (TL/LH)
  - **What it is:** many pigmentation SNPs are missing in many archaic samples. If we require every sample to have data at a SNP ("masking across everyone"), fewer than 50 of the 222 SNPs survive — too few.
  - **Why it matters:** the approach to missingness changes which samples and SNPs we can use.
  - **Do:** for SNP-level work, focus on the high-coverage samples; to escape the SNP-level sparsity, move to gene-level summaries (item B4 (ii)).

- [ ] **B6 · Keep gene-level and SNP-level sources separate** · 🟡 (YP/TL)
  - **What it is:** of the four datasets, three (the melanogenesis network, the cross-species set, the CRISPR screen) are lists of **genes**; two (the GWAS Catalog, HIrisPlex-S) are lists of individual **SNPs**. Genes cover a whole region; SNPs are single positions.
  - **Why it matters:** they can't be pooled naively — a gene isn't one position. Analyses and weighting differ.
  - **Do:** carry the gene-level and SNP-level layers explicitly and analyze each appropriately.

- [ ] **B7 · Look at functional impact and the skin-specific genes** · ⚪ (YP/LH)
  - **What it is:** two things. **(1) A functional-impact summary:** among the DNA changes in/around the pigmentation genes, report the ratio of *synonymous* (silent) to *non-synonymous* (protein-changing) changes — a rough read on whether the variation is functional / under selection. This needs each variant's coding effect, produced by running a **variant-effect annotator** (Ensembl VEP, SnpEff, or ANNOVAR) on the matched genome build. Note most of the 222 panel SNPs are non-coding (regulatory), so this ratio is computed over **coding variants in the pigmentation genes** (from exome or whole-genome data), *not* the panel SNPs — if suitable coding/exome data isn't readily available for these samples, flag that and defer. **(2) A profile of the six skin-specific pigmentation genes** (TYR, OCA2, TYRP1, DCT, PMEL, MLANA — see Glossary): for each gene, a per-population allele-frequency / genotype comparison of moderns vs archaics.
  - **Why it matters:** those six genes are switched on mainly in skin (tissue-specific expression), so they're the cleanest "this is really about *skin* pigmentation" story and easy to explain. (Source of the six-gene shortlist: a conference poster by Yemko Pryor on skin-specific pigmentation-gene expression.)
  - **Do:** run the annotator to get coding effects and the synonymous:non-synonymous ratios (and state which direction of the ratio indicates functional constraint); build the per-gene moderns-vs-archaics frequency profiles.

### C. Repository & cluster infrastructure

- [x] **C1 · Move the repo into the Lasisi Lab GitHub org** · (TL) — done (`lasisilab/paint-workflowr`); just confirm Lily has access.
- [ ] **C2 · Let Lily develop locally while heavy jobs run on the cluster** · 🟡 (TL)
  - **What it is:** Lily's laptop (8 GB RAM) can't run the big steps (the PCAs and genotype calling must run on the cluster); only the visualization runs locally. Set up the repo so the code runs "as if the cluster folder were local" — i.e. list the huge cluster files in `.gitignore` (so they never enter GitHub) but structure the code so Lily edits it locally and pings Tina to run the heavy steps on the cluster. (Same pattern as the lab's PODFRIDGE project.)
  - **Do:** wire up the gitignore + path conventions; agree which files are small enough to commit.
- [ ] **C3 · Back up the derived data** · 🟡 (TL). The cluster's Turbo storage is not permanent archival storage. The raw archaic BAMs can be re-downloaded from public sources, but the *derived* products (the merged SGDP reference panels, the archaic genotype call sets, the PCA outputs) are expensive to regenerate — back them up or deposit them.
- [ ] **C4 · Write a "where everything lives" doc** · ⚪ (LH). A short Google Doc listing where the dissertation, the repos, and the Drive folders are, so collaborators aren't hunting.

### D. Writing

- [ ] **D1 · Literature review of archaic pigmentation** · 🔴 (LH)
  - **What it is:** become the person who knows everything published about pigmentation genes in archaic humans. Method: search the "Undermind" tool for "archaic skin", then use Claude to screen 50–100 papers (start from new-data / selection papers on archaics since ~2000, pull their supplements, then search them for the project's gene list).
  - **Why it matters:** feeds both papers (below) and gives Lily authority in the field. Must-know anchors: the Lalueza-Fox 2007 MC1R paper and its rebuttals; Omer Gokcumen's (Buffalo) archaic/skin work.
- [ ] **D2 · The TIG review manuscript** · 🔴 (LH/TL). A review article for *Trends in Genetics*. Prioritize it — it needs no new analysis, just the lit review (D1). Keep its tasks distinct from the primary paper (D3).
- [ ] **D3 · The PAINT primary paper** · 🟡 (TL/LH/YP). Draft title: *"The genetic landscape of pigmentation in archaic hominins."* Resolve the PAINT acronym (§7); Tina scopes target journals. Aim: publish the honest landscape of archaic pigmentation genetics before someone else does; added complexity can come during review.

## 5. Do B2 first
The single most unblocking step is **B2 (put everything on the hg38 build)**, because it is literally the fix for the root bug **A2** (the build mismatch that breaks the pigmentation PCA and the pigmentation-SNP depth results) *and* the prerequisite for adopting the four hg38 datasets (**B1**). **A1 (Denisova 3)** is an independent naming fix that can happen in parallel as soon as Lily confirms it was accidental.

## 6. Datasets & provenance
The next phase uses four complementary pigmentation datasets plus one prediction panel, all already assembled — on the **hg38** build — in the **public** repo `tinalasisi/pigmentation-gene-network`. Full provenance (exact endpoints, licenses, freeze dates) is in that repo's [`DATA_SOURCES.md`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/DATA_SOURCES.md).

| Dataset | Where it came from | What it is | Gene- or SNP-level |
|---|---|---|---|
| **Melanogenesis network** ("Raghunath") | Raghunath et al. 2015, *BMC Res Notes* — cleaned/curated **in-lab as earlier PAINT work** | A 265-gene, 429-link map of how melanin-making genes regulate each other; the mechanistic backbone everything else attaches to | genes |
| **GWAS Catalog** | NHGRI-EBI GWAS Catalog (Sollis 2023), pulled via its API | 1,072 pigmentation-associated lead SNPs found in association studies | SNPs |
| **CRISPR screen** | Bajpai et al. 2023, *Science* | 169 genes whose disruption changed pigmentation in a genome-wide lab screen | genes |
| **Cross-species** | Baxter et al. 2018/19, *Pigment Cell Melanoma Res* | 635 curated pigmentation genes with mouse/zebrafish counterparts | genes |
| **PPI expansion** | D'Arcy et al. 2023, *Bioengineering* | A 243-gene disease-gene table + a protein–protein interaction network | genes |
| **HIrisPlex-S** (prediction panel) | Chaitanya 2018 / Walsh 2017 | The forensic skin/hair/eye-color prediction marker set: 36 markers → 16 genes (incl. the full MC1R red-hair set and the blue-eye HERC2/OCA2 markers) | SNPs |

**Direct links** (public repo `tinalasisi/pigmentation-gene-network`, branch `main`):
- Manifest: [`DATA_SOURCES.md`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/DATA_SOURCES.md)
- GWAS Catalog: [`data/external/gwas_catalog/pigmentation_gwas_catalog.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/external/gwas_catalog/pigmentation_gwas_catalog.csv)
- CRISPR (Bajpai): [`data/processed/bajpai2023_crispr_hits.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/bajpai2023_crispr_hits.csv)
- Cross-species (Baxter): [`data/processed/baxter2018_650_pigmentation_genes.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/baxter2018_650_pigmentation_genes.csv)
- Melanogenesis network (Raghunath): [`data/processed/raghunath_edges_typed_signed.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/raghunath_edges_typed_signed.csv) (+ `raghunath_nodes_typed.csv`; raw in `data/raw/raghunath2015/`)
- PPI (D'Arcy): [`data/raw/darcy2023/`](https://github.com/tinalasisi/pigmentation-gene-network/tree/main/data/raw/darcy2023)
- **HIrisPlex-S markers:** [`data/processed/hirisplexs2018_markers.csv`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/data/processed/hirisplexs2018_markers.csv) (extraction notebook: [`notebooks/01c_extract_hirisplex_markers.ipynb`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/notebooks/01c_extract_hirisplex_markers.ipynb))

## 7. The name "PAINT"
PAINT currently stands for "Pigmentation Analysis of **IN**trogressed Neanderthal Traits," but the study never actually looked at introgression (the mixing of archaic DNA into modern humans). So the acronym should be re-worked (e.g. "integumentary" — skin/hair/nail — traits), to be settled together with the manuscript title in D3.
