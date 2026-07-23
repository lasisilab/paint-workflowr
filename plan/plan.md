# PAINT — Project Plan & Roadmap

**Project:** PAINT — a study of what skin/hair/eye pigmentation genetics can (and can't) tell us about Neanderthals and Denisovans, and how they compare to modern humans.
**Team:** Tina Lasisi (PI / advisor) · Lily Heald · Yemko Pryor.
**Last updated:** 2026-07-23. **Status:** living document.

## How to read this
- **`plan.md`** (this file) = the single canonical plan. Edit here first. It now holds **everything**: the bug fixes, the analysis redesign, the infrastructure work, the writing, **and** the reviewer-driven QC/verification checks (items `Q1`–`Q10`). There is no separate to-do list.
- **`changelog.md`** = dated log of what was done / found / decided.
- **`paint-plan.html`** = a nicer, shareable rendering of this file.
- **`evaluation_plan.md`** = retired. Its 10 QC items are now tracked here as `Q1`–`Q10` (Phases 0–5). It survives only as a one-line pointer so old links don't break.
- **The roadmap (§4) is ordered as execution order.** It is grouped into **phases**, not categories. Each phase is a goal you can't safely pass until its items are done, and it deliberately puts each *fix/build* next to *the check that proves it worked*. Do the phases top to bottom.
- **Every item is written to stand on its own** — you should be able to jump to any single item and understand what it is, why it matters, and what to do, without having read anything else. Terms are in the Glossary just below, and load-bearing ones are re-explained inline.

### Item format & status vocabulary
Each item's header line looks like:
`- [ ] **<ID> · <title>** · <priority> (<owner>) · <STATUS>`

- **ID** — permanent. `A1`–`A6` (bugs), `B1`–`B7` (analysis redesign), `C1`–`C4` (infrastructure), `D1`–`D3` (writing), `Q1`–`Q10` (QC/verification). **IDs never get renumbered** — other docs (`changelog.md`, `pipeline_workbook.md`, `verify/BUG_EVIDENCE.md`) reference them.
- **Priority** — 🔴 high · 🟡 medium · ⚪ low.
- **Owner** — **(TL)** Tina · **(LH)** Lily · **(YP)** Yemko.
- **STATUS** — one of:
  - `TODO` — not started.
  - `IN PROGRESS` — being worked on now.
  - `BLOCKED(<dep>)` — can't start until `<dep>` is done (e.g. `BLOCKED(B2)`).
  - `DONE` — finished (box checked `- [x]`).
  - For **bugs (A-items)** the status also carries the evidence verdict from the investigation: `CONFIRMED` (reproduced with commands + output) or `DOWNGRADED` (turned out not to be a real problem). A confirmed-but-not-yet-fixed bug reads `CONFIRMED · TODO`.
- **QC items (Q…)** additionally carry: **Verifies/relates** (which A/B item this proves), **Deliverable** (the script/file it produces), **Acceptance** (the exact assertion that must pass), **Subtasks** (checkboxes), **Artifact** (the one figure/table a reader should look at). A/B/C/D items keep the **What / Why / Do / Evidence** structure.

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
- **Checksum / manifest:** a *checksum* (e.g. an `sha256` hash) is a short fingerprint computed from a file's bytes; if even one byte changes, the fingerprint changes — so it proves a file is intact and is the exact copy you think it is. A *manifest* is a table listing every input file with its checksum, source, and genome build — the project's "these are the exact ingredients we used" ledger.
- **Tracer SNP:** a single SNP whose coordinate is known *by heart in both builds* (e.g. SLC24A5/rs1426654 = `15:48,426,484` hg19 / `15:48,134,288` hg38), used as a probe: look up where a file puts that SNP and you instantly know which build the file is on. A cheap, decisive build check.
- **Positive control:** a test where you already know the right answer, run first to prove the machinery works before you trust it on a new question. Here: does the whole-genome PCA reproduce the *textbook* result (Africans separate from non-Africans on PC1)? If it can't reproduce the known, don't believe the novel result.
- **Palindromic SNP (a.k.a. ambiguous / strand-ambiguous SNP):** a SNP whose two alleles are DNA complements — **A/T** or **C/G**. DNA has two strands (A pairs with T, C with G), and for these two allele-pairs you can't tell from the letters alone which strand a dataset reported — so merging two datasets can silently flip the allele and invert a score. They need special handling (flag and usually drop, or resolve by allele frequency).
- **Contamination (in ancient DNA):** modern human DNA (from excavators, lab staff, or the environment) mixed into an ancient sample's sequencing. Because it looks like extra "normal" DNA, it inflates heterozygosity and creates false variant calls, so its fraction must be estimated and kept low.
- **Pipeline DAG (Snakemake / Nextflow / Makefile):** a "directed acyclic graph" describing the pipeline as *which step feeds which* — the recipe written so a tool can run it in the right order automatically. Encoding the pipeline this way removes any ambiguity about which script is canonical and can **auto-generate the flow diagram** so the picture always matches reality.

Owner tags: **(TL)** Tina · **(LH)** Lily · **(YP)** Yemko. Priority: 🔴 high · 🟡 medium · ⚪ low.

---

## 1. What this project is
The recurring public question is "what did Neanderthals and Denisovans look like?" PAINT asks whether their **pigmentation** (skin/hair/eye color) can actually be read off their ancient DNA. The honest finding so far is *not confidently* — the ancient DNA is patchy and shallow, and pigmentation genes don't behave like ancestry markers — so the project's contribution is an honest **map of what the pigmentation genetics does and doesn't support**, with the uncertainty made explicit.

## 2. Where things stand (July 2026)
Three places hold the work, all now reviewed:
- **The repo** `lasisilab/paint-workflowr` — the analysis website (built with the R tool *workflowr*), plus small data files and the analysis scripts.
- **The thesis** — Lily's 41-page honors thesis (20 Apr 2026); the completed first version of this work.
- **The cluster** — a 110 GB working directory on the University of Michigan "Great Lakes" system (`/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data`) holding the full computational pipeline (~19 batch jobs) and all the genomic data (the big files too large for the repo). **Full inventory:** [`cluster_inventory.md`](cluster_inventory.md) (directory layout, the pipeline stages, data products, access instructions). **Step-by-step pipeline audit:** [`pipeline_workbook.md`](pipeline_workbook.md).

**Data-source decision:** the pigmentation datasets we want for the next phase already exist, all on the hg38 build, in the public repo `tinalasisi/pigmentation-gene-network` (details in §5). We use that repo; we do **not** use the older `melanogenesis-constraints` repo.

## 3. Open questions for Lily (please confirm)
- **The genome-build mismatch (see item A2).** Did you know the pigmentation SNP list uses hg38 coordinates while the sequence data is aligned to hg19? And how would you rather fix it — move the SNP list to hg19, or move all the data up to hg38 (which matches the rest of the plan)?
- **Denisova 3 (see item A1).** Was the chromosome-naming difference on that one sample accidental? If so we just re-run it.
- **Haploid calling (see item A3).** Was `--ploidy 1` on the whole-genome calling intentional?

---

## 4. Roadmap (phased execution order)

The work is grouped into **seven phases**. Each phase has a **goal (a gate)** — you shouldn't trust anything built on top of a phase until that phase's checks pass. Within a phase, fixes/builds are paired with the QC item that verifies them. Phases 0–3 are the "make the foundation trustworthy" gates; Phase 4 is the actual science; Phases 5–6 are reproducibility and writing (and can run partly in parallel).

The **single most unblocking step** is **B2** (put everything on the hg38 build): it is literally the fix for the root bug **A2** *and* the prerequisite for using the four hg38 datasets (**B1**). **A1** (Denisova 3) is an independent naming fix that can happen in parallel.

### QC already in place vs. what these phases add
The QC phases below (0–3, the `Q` items) are **not starting from zero** — they build on the quality work already in Lily's thesis. Knowing the split matters so we credit what's done and target only the gaps.

**Already in place (Lily's thesis pipeline):**
- **The coverage/depth + missingness arm** — this *was* the QC-minded half of the thesis: per-sample per-base depth across the whole panel (`samtools depth -a`, zero-coverage sites included), a missingness model (`glmer(Missing ~ chromosome + age + (1|Coverage) + (1|Sample))`), and genotype-confidence simulations — including a Monte-Carlo term that decays confidence toward the read ends (an *implicit* nod to ancient-DNA damage). See [`analysis/depth.Rmd`](../analysis/depth.Rmd).
- **Standard pipeline hygiene:** `samtools quickcheck -v` on downloaded BAMs; MAPQ ≥ 30 / BaseQ ≥ 30 filtering in the whole-genome calling; biallelic-SNP filtering and LD-pruning (`--indep-pairwise 200 25 0.4`) before the whole-genome PCA; deduplication + biallelic restriction + deterministic variant IDs in the projection, scored against modern reference frequencies (the correct choice); and correctly labelling Denisova 11 as an F1 hybrid in the figures.
- **The honest framing itself** — the thesis's headline conclusion (archaic pigmentation prediction is *not yet well-supported*) was a QC-minded verdict, not over-claiming.

**Not yet done (exactly what `Q1`–`Q10` add):** build/contig-naming lint (**Q2**), a provenance manifest + checksums (**Q1**), a positive control (**Q3**), allele/ref-alt/palindrome harmonization (**Q4**), PCA/projection non-degeneracy checks (**Q5**), coverage-vs-published-expectation alerting (**Q6**), sample identity/sex/contamination (**Q7**), formal aDNA-damage assessment — mapDamage/PMDtools (**Q8**), cross-validation against published genotypes (**Q9**), and reproducibility infrastructure — version pinning, seeds, DAG, CI (**Q10**). Their absence is precisely why the three serious bugs slipped through: the build mismatch (**A2**), Denisova 3's naming (**A1**), and the projection collapse were never caught by an automated check. Quality filtering was also **inconsistent** — the `-q 30 -Q 30` filter is in the whole-genome calling but *not* in the depth step or the pigmentation-panel calling.

### Phase overview

| Phase | Goal (the gate) | Items | Status |
|---|---|---|---|
| **0 · Provenance & environment** | Nothing is trusted until every input is traced to a source, build, and checksum | Q1, Q10a (see Q10) | TODO |
| **1 · One genome build, verified** | Panel + all sequence data on one build, proven — and the called genotypes correct | A2, B2, A1, A3, Q2, Q4, A4, A5 | TODO |
| **2 · Positive controls & PCA correctness** | Reproduce a known result before building novel ones | Q3, Q5, Q6 | TODO |
| **3 · aDNA sample QC** | Samples are authentic, correctly labelled, and damage-aware | Q7, Q8 | TODO |
| **4 · Analysis redesign (the science)** | Deliver the analyses agreed on 17 June | B1, B3, B4, B5, B6, B7, Q9 | TODO |
| **5 · Infrastructure & reproducibility** | A re-runnable, unambiguous pipeline; repo tidy | C2, C3, C4, Q10, A6, C1 (DONE) | in progress |
| **6 · Writing** | Two manuscripts out | D1, D2, D3 | TODO |

---

### Phase 0 — Provenance & environment
**Gate:** every file the pipeline touches has a known source, a known genome build, and a checksum; tool versions are captured. Until this passes, every later result is "guilty until proven innocent." Most confirmed bugs so far are provenance/harmonization failures, so this comes first.

- [ ] **Q1 · Data-provenance manifest + checksums** · 🔴 (TL/LH) · **TODO**
  - **What it is:** a single table, `qc/manifest.tsv`, with one row per pipeline input — every genome/BAM, every SNP panel, every gene-coordinate set, and the metadata (SGDP sample→population, ages, coverage) — recording `path · sha256 · source (DOI/URL/accession) · genome_build · N (samples or SNPs) · date_obtained · produced_by (script or "external")`. **A specific unknown to resolve:** the pigmentation panel is currently read from a personal home dir (`/home/lheald/gwas_loci/snps.bed`) with no documentation — locate that file, characterize it (which SNPs, which build), and give it a real provenance row.
  - **Why it matters:** you cannot verify an analysis whose inputs you can't name. A wrong/undocumented source, a wrong build, a truncated download, or a silently-substituted file will corrupt everything downstream invisibly. This is the prerequisite for every other check.
  - **Verifies/relates:** foundational for all of Phases 1–4; directly supports Q2 (build), Q4 (alleles), Q6 (expected coverage), Q8 (UDG status), Q10 (versions).
  - **Deliverable:** `qc/manifest.tsv` + a small builder script `qc/build_manifest.sh` that fills checksums.
  - **Acceptance:** every file used by the pipeline appears in the manifest with a **non-empty** source **and** build **and** checksum; the run **fails** if any input is `external/unknown`. Re-downloading one archaic BAM and one SGDP VCF reproduces the recorded `sha256`. The `snps.bed` panel is located and its build recorded.
  - **Subtasks:**
    - [ ] Enumerate every input the ~19-job pipeline reads (cross-check against `pipeline_workbook.md`).
    - [ ] Compute `sha256` for each; record source + build + N + date.
    - [ ] Locate & characterize `/home/lheald/gwas_loci/snps.bed` (which SNPs, which build, how produced).
    - [ ] Record how the committed `data/snps.txt` / `pigmentation_snps.csv` was generated (GWAS Catalog trait EFO + access date).
    - [ ] For gene coordinates (needed by B4 ii / B6): record source (Ensembl/RefSeq release # + build) and assert every gene resolves to exactly one region.
  - **Artifact:** the manifest table itself + a one-line "inputs ledger" badge (N inputs · N fully-provenanced · N unknown), modeled on `pigmentation-gene-network/DATA_SOURCES.md`.

- **Q10a (environment capture) — do the first slice of Q10 now.** Alongside Q1, pin and record the tool versions (`bcftools`, `plink2`, `samtools`, R + packages) into the manifest so Phase 1's results are reproducible from the start. The full reproducibility build (DAG + CI) is tracked as **Q10** in Phase 5.

---

### Phase 1 — One genome build, verified
**Gate:** the panel, the gene coordinates, and all sequence data are on **one** build (the plan: hg38), proven by an automated lint; the called genotypes are correct (diploid where they should be); and the dead/competing scripts are gone so there's no ambiguity about what ran. This phase is the critical path — nothing pigmentation-SNP-related is trustworthy until it passes.

All A-items here were reproduced with commands + real output — see [`verify/BUG_EVIDENCE.md`](verify/BUG_EVIDENCE.md) (runnable: [`verify/verify_bugs.sh`](verify/verify_bugs.sh)). None of these damaged any data; they affect results.

- [ ] **A2 · The SNP list and the sequence data are on different genome builds (hg38 vs hg19) — the root problem** · 🔴 (TL/LH) · **CONFIRMED · TODO (fixed by B2)**
  - **What it is:** The project measures 222 specific pigmentation SNP positions ("the panel"). Those position numbers were taken from the GWAS Catalog, which reports them on the **hg38** genome build. But every individual's actual DNA — the archaic Neanderthal/Denisovan samples **and** the modern SGDP genomes — was aligned to the **hg19** build. Because the same SNP sits at different coordinates in hg19 vs hg38 (e.g. SLC24A5 is `15:48,134,288` in hg38 but `15:48,426,484` in hg19), reading the panel's hg38 positions out of the hg19 data lands on the **wrong places** in the genome.
  - **Why it matters:** it corrupts both halves of the analysis. (1) **PCA:** the wrong hg19 positions are essentially random spots, and at random spots all 15 modern genomes happen to carry the same letter (221 of the 222 are *monomorphic* — no variation). Positions with no variation give the PCA nothing to tell samples apart on, so the pigmentation PCA collapses to a single axis and every archaic sample lands on the *same* point — the figure is meaningless. (2) **Depth/missingness:** the coverage reported "at each pigmentation SNP" is actually measured at a spot that can be far from the real SNP — hundreds of kb off (e.g. ~292 kb for SLC24A5), and the offset differs per SNP — so those numbers don't describe the intended loci.
  - **Do:** put the panel and the sequence data on the *same* build before re-running any pigmentation-SNP analysis. The chosen direction is to lift the **data up to hg38** (item B2), because the four new datasets are already hg38. Alternatively, lift the **panel down to hg19** using a standard coordinate-conversion tool (UCSC `liftOver` or `CrossMap` with an hg38→hg19 "chain file"), or re-pull the SNPs' hg19 coordinates from the GWAS Catalog. Either way, pick one build and make everything match. Until then, treat the pigmentation PCA and pigmentation-SNP depth results as unreliable.
  - **Evidence:** `BUG_EVIDENCE.md` §⓵/§A2 — panel carries the hg38 SLC24A5 coordinate; reference file header says GRCh37; 221/222 sites monomorphic in SGDP; all archaic PCA projections identical. **Proven fixed by Q2 (build lint) and Q5 (PCA non-degeneracy) once B2 is done.**
  - **Consequence (demonstrated):** the pigmentation PCA is rank-1 (`pigmentation.pca.eigenval`: PC1 = 0.063, PC2–10 ≈ 3e-18); only 1 of 222 SNPs (a non-canonical rs76285708) carries any loading; modern PC1 takes just 3 discrete values, so the thesis's "PC1 differentiates Bantu and Yoruba" (Fig 8, §3.5) and the "archaics fall near Africans / small number of loci" reading (Discussion, p.32) are one-SNP artifacts. The whole-genome PCA (Fig 7) and the *aggregate* missingness result are **not** affected. Full trace: `verify/BUG_EVIDENCE.md`.

- [ ] **B2 · Put everything on one genome build: hg38** · 🔴 (TL/LH) · **TODO (critical path)**
  - **What it is:** as item A2 shows, the SNP panel is on hg38 but the sequence data is on hg19, which is why the pigmentation analyses are broken. The four new datasets (B1) are also on hg38. So standardize the whole project on **hg38**: convert the archaic + SGDP sequence data (and anything else on hg19) up to hg38 so it matches the panels.
  - **Why it matters:** this is the fix for the root bug (A2) *and* the prerequisite for using the four hg38 datasets (B1) and for every matched-build analysis (B3, B4, B7, Q9). Nothing pigmentation-SNP-related is trustworthy until builds match.
  - **Do:** lift the data to hg38 (or, if easier, lift the panels to hg19 — but pick one build and make everything match). Then re-run depth + PCA. **This is the critical-path first step.**
  - **Evidence:** its correctness is *proven* by Q2 (tracer-SNP lint passes) and Q5 (PCA no longer collapses) — B2 isn't "done" until both pass.

- [ ] **A1 · Denisova 3 uses different chromosome names than everything else** · 🔴 (LH confirm → TL/LH re-run) · **CONFIRMED · TODO**
  - **What it is:** Chromosomes can be labelled two ways — bare (`1`, `2`, … `15`) or prefixed (`chr1`, `chr2`, … `chr15`). The reference genome, the SNP panel, and every archaic sample use the **bare** style — *except the Denisova 3 sample*, whose alignment file (BAM) uses the **`chr`-prefixed** style. When the pipeline looks up the (bare-named) SNP positions in Denisova 3's (`chr`-named) file, the names don't match, so almost nothing is found.
  - **Why it matters:** Denisova 3 is a **high-coverage** Denisovan genome, yet it shows near-empty coverage over the panel (mean depth 0.5×, only 69 of 222 SNPs covered — versus 30.7× and all 222 for **Vindija 33.19**, a comparable high-coverage sample) and sits in the sparse group of the thesis's Figure 5. Because the reference genome and the SNP panels are bare-named, any step that pairs Denisova 3's `chr`-named reads with them (the whole-genome genotype calling, the PCA inputs) fails to match and drops most of its data — so its apparent sparseness is very likely a naming artifact, not real biology. (Separate from A2: A2 makes the *panel* wrong for *every* sample; A1 makes *this one sample* look empty.)
  - **Do:** relabel Denisova 3's chromosomes to the bare style — e.g. `samtools reheader` with a name map (`chr1`→`1`, …) — then re-run its depth and genotype calling and confirm the coverage is really there (expect it to jump into the high-coverage group and move in the PCA). An alternate cluster script, `pca_ancient.slurm`, already contains logic that normalizes `chr` names; that approach can be reused instead of editing the file by hand.
  - **Evidence:** `BUG_EVIDENCE.md` §A1. **Proven by Q2 (naming lint flags it) and Q6 (its coverage jumps into the high band after the fix).**
  - **Consequence (demonstrated):** in the committed depth files Denisova 3 recovers at **0.5×, 69/222 SNPs** (vs Vindija 33.19 at 30.7×, 222/222), so Fig 5 draws this 30× genome in the *sparse* band — contradicting the thesis's own Table 3, which lists it as high-coverage. In the whole-genome projection its recovered dosage is 221k vs ~1.66M for its peers, placing it at the empty-sample point near the origin (PC1 = +0.011) instead of with the other Denisovan (Denisova 25, PC1 = −0.058) in Fig 7. (No effect on Fig 8, where the caller emits all 222 sites regardless.) Full trace: `verify/BUG_EVIDENCE.md`.

- [ ] **A3 · Whole-genome ancient calling treats chromosomes as single-copy (`--ploidy 1`)** · 🟡 (LH confirm) · **CONFIRMED · TODO (confirm intent)**
  - **What it is:** Humans have two copies of each non-sex chromosome (diploid), so a genotype should be a pair like `A/G`. One of the genotype-calling jobs (`ancient_wg.slurm`) is set to `--ploidy 1` (haploid) across all chromosomes including the non-sex ones, which forces a single allele per position.
  - **Why it matters:** with haploid calling, a heterozygous individual (who carries both `A` and `G`) can never be recorded as such — you lose half the genotype information on the autosomes, which biases anything downstream that depends on it (including the whole-genome PCA that Q3 uses as a positive control).
  - **Do:** confirm whether this was intentional; for diploid autosomes it normally should not be `--ploidy 1`. Re-run diploid if it was a mistake.
  - **Evidence:** `BUG_EVIDENCE.md` §A3 (the setting is on line 83 over all chromosomes; output genotypes are single-allele).
  - **Consequence (demonstrated / latent):** the committed whole-genome projection scores these haploid archaics against a PCA basis built from **diploid** SGDP moderns — a real ploidy mismatch. The heterozygote loss itself is on the (cluster-only) VCF, so it's latent locally. Honest note: the whole-genome PCA **conclusion survives** — archaics still sit clearly on the non-African side of PC1 (Fig 7 / §3.4). Full trace: `verify/BUG_EVIDENCE.md`.

- [ ] **Q2 · Genome-build & contig-naming lint (tracer-SNP assertions)** · 🔴 (TL) · **TODO**
  - **What it is:** an automated check that *everything* is on the same build with the same chromosome naming. It uses **tracer SNPs** — SNPs whose coordinates are known in both builds, e.g. `rs1426654` SLC24A5 (hg19 `15:48426484` / hg38 `15:48134288`) and `rs12913832` HERC2 (hg19 `15:28365618` / hg38 `15:28120472`). For each input that carries positions (BAM `@SQ` / `.fai`, VCF/BCF contig lines, panel/BED chrom column, gene coords), it asserts the tracer sits at exactly one build's coordinate and that all inputs agree. It also extracts each file's contig set and asserts one consistent naming convention (`chr1` vs `1`).
  - **Why it matters:** this is the highest signal-to-effort check in the whole plan — ~20 lines that catch the two worst confirmed bugs automatically: the panel-vs-data build mismatch (**A2**) and Denisova 3's `chr` naming (**A1**). Run it before trusting any coordinate-based step, and re-run it to *prove* B2 worked.
  - **Verifies/relates:** A2, A1, B2.
  - **Deliverable:** `qc/check_build.sh`.
  - **Acceptance:** all inputs agree on one build and one naming convention; the tracer SNPs resolve to that build in every positioned file; the script **exits 0**. Before B2 it should exit non-zero (flagging A2/A1); after B2 it should exit 0.
  - **Subtasks:**
    - [ ] Encode the two tracer SNPs' hg19/hg38 coordinates.
    - [ ] Extract contig sets + tracer positions from every BAM/VCF/BED/`.fai`.
    - [ ] Assert single build + single naming; list any file that differs.
  - **Artifact:** a **build-harmonization matrix** — files (rows) × build/naming (cols), green/red. One glance answers "are we internally consistent?"

- [ ] **Q4 · Allele & annotation harmonization** · 🟡 (TL) · **BLOCKED(B2)**
  - **What it is:** even on the right build, the *alleles* have to be right. This check catches ref/alt swaps, strand flips, and palindromic (A/T, C/G) SNPs, which silently invert polygenic scores and PCA projections. For every panel SNP it does a **REF-base check** — assert the reference-genome base at that position (`samtools faidx`) equals the panel/VCF `REF` allele; it asserts each GWAS effect allele is one of the record's REF/ALT alleles; it flags palindromic SNPs and sets a policy (drop, or exclude by MAF > 0.4); and for any annotation step (VEP/SnpEff in B7) it asserts the annotator's genome build equals the data build.
  - **Why it matters:** allele mismatches are the classic *silent* killer — they don't error, they just flip signs, so the directional score (B3) and projections (B4) come out subtly or badly wrong. The REF-base check in particular fails loudly on build/coordinate *and* allele errors, so it's a very high-value single test.
  - **Verifies/relates:** B3 (score sign), B4 (projection), B7 (annotation build), and re-confirms B2.
  - **Deliverable:** `qc/check_alleles.sh`.
  - **Acceptance:** **0 REF-base mismatches** on the SNPs retained for analysis; every GWAS effect allele present as the record's REF or ALT; palindromic SNPs flagged with a documented policy; annotator build equals data build. The full harmonization funnel is reported.
  - **Subtasks:**
    - [ ] REF-base check: reference base equals panel/VCF REF for every panel SNP.
    - [ ] Effect-allele-present check; count mismatches.
    - [ ] Flag palindromes; decide drop-vs-MAF policy.
    - [ ] Assert/pin: annotator cache release + build recorded in the manifest (Q1).
  - **Artifact:** a **SNP funnel** — N panel SNPs → matched / ref-alt-swapped / effect-allele-absent / palindromic-dropped / lost.

- [ ] **A4 · Two versions of the ancient pigmentation-calling script exist (tidy-up, not a bug)** · ⚪ (LH/TL) · **DOWNGRADED · TODO (cleanup)**
  - **What it is:** there are two scripts that call ancient genotypes at the pigmentation panel: one keeps every site (`bcftools call -c`), the other keeps only sites that vary (`bcftools call -mv`).
  - **Why it (barely) matters:** I originally flagged the "-mv, variants-only" one as dropping sites and biasing the analysis. **On checking, it didn't:** the actual output file has all 222 sites, so the keep-everything script is clearly the one that was used. Nothing was lost.
  - **Do:** just delete the unused `-mv` script so there's no confusion about which is canonical. (No re-analysis needed.)
  - **Evidence:** `BUG_EVIDENCE.md` §A4 (committed output has 222 records).
  - **Consequence: none.** Every row of `ancient.projected.pig.sscore` has ALLELE_CT = 444 (= 2 × 222), so the keep-all `-c` output is what was scored; nothing downstream traces to the `-mv` script. Deleting it is pure hygiene.

- [ ] **A5 · Two dead/broken scripts on the cluster** · ⚪ (LH/TL) · **CONFIRMED · TODO (cleanup)**
  - **What it is:** (i) `ancient_merge.slurm` tries to merge files matching `*.wg.vcf.gz`, but the real output file is named `ancient_sgdp_wg.vcf.gz` (`_wg`, not `.wg`), so that pattern matches nothing and the script does nothing. (ii) `pca_ancient.slurm` points at a reference file `hg19.fa` that isn't present (only `hs37d5.fa` exists), so it can't run, and its output isn't used anywhere else.
  - **Why it matters:** only as clutter/confusion — neither is part of the working pipeline. (Cleaning these up also removes the "which script is canonical?" ambiguity that Q10 formalizes.)
  - **Do:** delete or fix them so the cluster directory reflects what actually runs.
  - **Evidence:** `BUG_EVIDENCE.md` §A5.
  - **Consequence: none.** No committed artifact or figure traces to either script (the real WG projection came from `ancient_wg.slurm`; the WG-PCA axes from `modern_pca.slurm`). Deleting them is pure hygiene — though `pca_ancient.slurm` is worth reading first, since it holds the `chr`-reheader logic that fixes A1.

---

### Phase 2 — Positive controls & PCA correctness
**Gate:** before trusting any *novel* pigmentation result, the pipeline reproduces a result we already know (SGDP clusters by continental ancestry), and the PCA machinery is proven non-degenerate. If it can't reproduce the known, don't build on it.

- [ ] **Q3 · Positive control — reproduce the SGDP whole-genome PCA** · 🔴 (TL/LH) · **BLOCKED(Phase 1)**
  - **What it is:** before believing any novel pigmentation PCA, prove the PCA/merge/projection plumbing reproduces *textbook* human population structure. Encode the known result as assertions on the whole-genome PCA (`modern_pca` / `sgdp_merge_pca`) and the ancient projection.
  - **Why it matters:** if the pipeline can't recover continental structure from whole-genome data, the merge/subset/PCA machinery is broken and nothing downstream is trustworthy. This is the fastest single read on whether the core method works — and the eigenvec files already exist.
  - **Verifies/relates:** validates the machinery that B4 depends on; depends on A3 (correct diploid WG calls) and Phase-1 build harmonization.
  - **Deliverable:** `qc/positive_control_pca.R`.
  - **Acceptance:** PC1 of the SGDP WG-PCA separates **African vs non-African** beyond a set margin (Yoruba/Bantu/Khomani-San on one side); East-Asian / West-Eurasian / Oceanian form distinct clusters on PC2–PC3 (label-recovery via silhouette or k-means concordance); and the **projected archaics fall among non-Africans on PC1** (the established introgression-driven expectation — a positive control for the projection machinery specifically).
  - **Subtasks:**
    - [ ] Label SGDP samples by continental region from the metadata (Q1).
    - [ ] Assert AFR / non-AFR separation on PC1 beyond margin; assert cluster recovery on PC2–3.
    - [ ] Project archaics; assert they land among non-Africans.
    - [ ] Compare qualitatively to a published SGDP PCA figure.
  - **Artifact:** the control PCA figure with the *expected* groupings annotated, shipped next to the real analysis so a reader sees the sanity check passed.

- [ ] **Q5 · PCA / projection non-degeneracy sanity checks** · 🟡 (TL/LH) · **BLOCKED(B2)**
  - **What it is:** automated checks that the PCA isn't rank-deficient and the projection didn't collapse. On the eigenvalues, per-allele loadings, and projected `.sscore`: assert at least `k` panel SNPs are polymorphic; assert the eigenvalue ratio λ2/λ1 exceeds a floor (flags rank-1 collapse); assert the projected ancient coordinates have non-zero spread (`sd(PC1) > ε` and at least two archaics differ); and **grep the projection script to assert it uses `no-mean-imputation`**.
  - **Why it matters:** this directly catches the two confirmed degeneracies — the monomorphic panel (from **A2**) that collapses the pigmentation PCA to one axis, and the **projection collapse** where all 15 archaics get byte-identical coordinates. That second collapse has its own root cause beyond the build mismatch: `plink2 --score` mean-imputes missing genotypes, and with `--variance-standardize` + high ancient missingness every sample collapses to the reference centroid. **Fix: add `no-mean-imputation` to the `--score` modifiers in `pca_proj.py`** (confirmed canonical vs `pig_pca_proj.py`).
  - **Verifies/relates:** A2, B4; includes the concrete `pca_proj.py` fix.
  - **Deliverable:** `qc/check_pca_degeneracy.R` + the one-line edit to `pca_proj.py`.
  - **Acceptance:** at least `k` polymorphic panel SNPs; λ2/λ1 above the floor; `sd(PC1)` across archaics above ε with at least 2 archaics differing; `pca_proj.py` contains `no-mean-imputation`. After B2 + the `no-mean-imputation` fix, all four pass.
  - **Subtasks:**
    - [ ] Add `no-mean-imputation` to `pca_proj.py`'s `--score` modifiers; document the missingness policy.
    - [ ] Assert polymorphic-SNP count, eigenvalue ratio, projection spread.
  - **Artifact:** a scree plot + a "projection spread" strip plot (are samples spread out, or stacked on one point?).
  - **Consequence already visible (demonstrated):** the committed `data/ancient.projected.pig.sscore` has **byte-identical PC coordinates for all 15 archaics** (PC1 = 0.0335547 for every one) despite differing input dosages, while the whole-genome `.sgdp.sscore` keeps them distinct — so Fig 8 currently stacks every archaic on one point, and the thesis's "archaics cluster with Africans" rests on where that single point landed (which is actually 4.6× closer to the non-African cluster). Full trace: `verify/BUG_EVIDENCE.md` (projection-collapse §).

- [ ] **Q6 · Per-sample coverage / depth expectations** · 🟡 (LH) · **TODO**
  - **What it is:** for each sample, compare its **realized** panel depth and covered-SNP fraction against the **expected** genome-wide coverage from its source publication (recorded in the Q1 manifest). Alert on any nominally high-coverage genome that comes out sparse.
  - **Why it matters:** a "high-coverage" genome showing near-zero coverage is exactly the Denisova 3 red flag (**A1**) — this check would have caught it automatically, and it's the acceptance test that A1's fix worked (Denisova 3 should jump into the high band). It's also the gate for choosing the "high-coverage set" used in the everyone-together PCA (B4 a).
  - **Verifies/relates:** A1 (confirms the fix); feeds B4 (which samples qualify as high-coverage), B5 (missingness).
  - **Deliverable:** `qc/coverage_report.R`.
  - **Acceptance:** every nominally high-coverage genome exceeds its depth / covered-fraction threshold; outliers (a high-coverage genome extracting sparse) raise an alert. After A1's fix, Denisova 3 passes.
  - **Subtasks:**
    - [ ] Record expected genome-wide coverage per sample in the manifest (Q1).
    - [ ] Compute realized panel mean-depth + covered-SNP fraction per sample.
    - [ ] Assert high-coverage set is above threshold; alert on outliers.
  - **Artifact:** a per-sample QC table (expected vs realized coverage, covered/222, tier) with red/amber/green — the most scannable "are the samples OK?" view. (This table is the seed of the combined QC dashboard extended by Q7/Q8.)

---

### Phase 3 — Ancient-DNA sample QC
**Gate:** the archaic BAMs are the individuals we think they are, their sex is concordant, contamination is low, and DNA damage is assessed. Mislabeling and modern contamination are endemic in aDNA and would invalidate everything downstream — reviewers of ancient DNA will require this.

- [ ] **Q7 · Sample identity, sex & contamination** · 🟡 (YP/LH) · **TODO**
  - **What it is:** per archaic BAM: a **sex check** (X/Y normalized depth ratio vs recorded sex), a **contamination estimate** (X-chromosome for males, or mtDNA-based, `contamMix`/`schmutzi`-style), and, where a published reference genotype exists (Vindija/Altai), a **genotype-concordance** check at a handful of sites to confirm identity.
  - **Why it matters:** a sample swap (is `den11` really Denisova 11?) or modern-human contamination (which inflates heterozygosity and creates false variant calls) invalidates the downstream results silently. These are standard, expected aDNA controls.
  - **Verifies/relates:** guards all archaic genotype use (B3, B4, B7, Q9).
  - **Deliverable:** `qc/sex_contam.sh` (+ a concordance step).
  - **Acceptance:** sex concordant with metadata for every sample; contamination below a set threshold (e.g. 2–5%); identity confirmed where a reference genotype exists.
  - **Subtasks:**
    - [ ] X/Y depth-ratio sex check vs recorded sex.
    - [ ] Contamination estimate per sample; assert below threshold.
    - [ ] Genotype concordance at published sites where available.
  - **Artifact:** rows added to the per-sample QC dashboard: sex, contamination %, identity-confirmed flag.

- [ ] **Q8 · Ancient-DNA authenticity / damage handling** · ⚪ (YP/LH) · **TODO**
  - **What it is:** run `mapDamage`/`PMDtools` on each BAM and assert the characteristic post-mortem deamination signal (5′ C>T and 3′ G>A) is present, in the authentic-aDNA range, and decays from the read ends as expected; record each sample's UDG-treatment status in the manifest; and run a robustness test — re-call with terminal bases trimmed/masked and assert the pigmentation genotype calls are stable.
  - **Why it matters:** this is ancient DNA — deamination at read ends creates false variants (C>T/G>A), which are called as real ALT alleles (worse under a `-mv` caller). No damage handling is visible in the current scripts, and reviewers will require it. Transition-heavy pigmentation sites are exactly the ones at risk.
  - **Verifies/relates:** guards B3/B7 (false-variant risk); pairs with A4 (caller choice).
  - **Deliverable:** `qc/damage.sh`.
  - **Acceptance:** damage rates in the authentic-aDNA range with expected end-decay; UDG status recorded per sample; pigmentation calls stable under terminal-base trimming.
  - **Subtasks:**
    - [ ] Run mapDamage/PMDtools; record rates + UDG status.
    - [ ] Re-call with trimmed ends; assert call stability at panel SNPs.
  - **Artifact:** per-sample damage plots + a "damage-handled: yes/no" column in the QC dashboard.

---

### Phase 4 — Analysis redesign (the science)
**Gate:** deliver the analyses agreed on the **17 June** call, on the now-trustworthy foundation, and cross-validate them against published results. This is the actual scientific contribution.

**The analyses agreed on the 17 June call** (source: meeting transcript) — each maps to an item below:
1. Layered **coverage** of pigmentation loci across the four datasets (GWAS-only, then + CRISPR, + melanogenesis network, + cross-species) → **B1**.
2. **"What color were they?"** in two steps: (a) GWAS betas → a **directionality** score (optionally restricted to skin-pigmentation and/or ≥2-hit SNPs); (b) the **MC1R** red-hair-variant check → **B3**.
3. **PCA redone** three ways (pigmentation SNPs / whole pigmentation genes / genome-wide) × two designs (moderns + high-coverage archaics together; moderns-only with all ancients projected) → **B4**.
4. **Missingness** strategy (full masking leaves <50 SNPs → focus high-coverage, move to gene level) → **B5**.
5. Keep **genes vs SNPs** distinct (network = genes; pull gene start/stop coordinates) → **B6**.
6. **Functional / exome:** synonymous:non-synonymous ratio; annotate coding effects → **B7**.
7. **Skin-specific gene** focus (TYR, OCA2, TYRP1, DCT, PMEL, MLANA) across modern populations and archaics → **B7**.
Plus the call's "normalize everything to hg38" → **B2** (Phase 1; also the fix for bug A2).

**How the two kinds of dataset are actually used — directionality vs. genes-without-SNPs** (the part that's been unclear):
- **SNP-level sources (GWAS Catalog, HIrisPlex-S)** carry a *signed effect per SNP* — an effect allele and a known direction (increases or decreases pigmentation). These are the **only** sources that feed the directional polygenic score (**B3**): for each SNP, count the individual's copies (0/1/2) of the pigmentation-increasing allele and sum. The direction comes straight from the GWAS effect sign (already in the GWAS Catalog export's `or_beta` / `direction_raw` columns); a missing genotype means that SNP is skipped for that individual.
- **Gene-level sources (melanogenesis network / Raghunath, Baxter, Bajpai, D'Arcy)** are lists of *genes* (regions), not signed SNPs, so they **cannot** go into the +1/−1 score — a gene region has no single effect allele. They're used instead as **gene-region sets** (take each gene's start/end coordinates and use *all* variants inside it), which feed the gene-level PCA (**B4 (ii)**) and the layered coverage (**B1**); and for **functional interpretation** (**B7**) — e.g. "does this archaic carry a protein-changing variant in a network gene?" — via a variant-effect annotator, kept descriptive.
- **The bridge is optional and heavier:** to give a gene-level source a per-individual "direction" you'd need per-variant functional prediction (is *this* variant damaging?), not a GWAS effect size — shaky on low-coverage archaic data, so keep it descriptive (B7), not part of the score.
- **Bottom line:** the directional score is **SNP-only**; the gene sources drive the gene-level PCA, coverage, and functional annotation. Don't force gene lists into the additive score.

- [ ] **B1 · Base the coverage analysis on four pigmentation datasets, not just one** · 🔴 (TL builds, LH runs) · **TODO**
  - **What it is:** so far the pigmentation SNP list came from a single source (the GWAS Catalog). Broaden it to four complementary sources of pigmentation genes/SNPs (all already assembled in `pigmentation-gene-network`, see §5): the **GWAS Catalog**, a **CRISPR screen**, a **melanogenesis gene network**, and a **cross-species** gene set.
  - **Why it matters:** each source captures different pigmentation biology; a single source undercounts. Report coverage in layers — GWAS-only first, then each additional set — so it's clear what each contributes.
  - **Do:** wire the four datasets into the coverage code; produce the layered coverage summary.

- [ ] **B3 · Score pigmentation direction, and specifically check MC1R (red hair)** · 🟡 (TL/LH) · **BLOCKED(B2)**
  - **What it is:** a **polygenic score** = one darker-vs-lighter number per individual. For each pigmentation SNP that has a known direction of effect, count how many copies of the pigmentation-*increasing* allele the individual carries (0, 1, or 2 — everyone is diploid) and add them into a signed sum: increasing alleles push the score up, decreasing alleles push it down, so **higher score = predicted darker**. The main version uses **sign only** (each SNP counts equally, just its direction); an optional version weights each SNP by its GWAS effect size. Fix the rules up front: heterozygotes count by allele copies (as above); a SNP with a missing genotype in an individual is skipped for that individual. Separately, the **MC1R red-hair check**: look up MC1R's known red-hair variant positions in each archaic individual and report whether any carries a red-hair (loss-of-function) allele — we expect *none*, and confirming that is itself a citable result.
  - **Why it matters:** it directly answers the "what color were they?" question at the level the evidence can actually support, without over-claiming. The MC1R check is a specific, frequently-asked point.
  - **Do:** score the 14 archaic individuals (and, for comparison, the 15 SGDP moderns) at the pigmentation-SNP panel — this **needs genotype calls at the panel positions on a matched genome build, so it depends on B2 being done first.** Take each SNP's effect direction from the GWAS Catalog. The forensic **HIrisPlex-S** panel supplies a well-characterized marker subset, including the exact MC1R red-hair variants (e.g. rs1805007, rs1805008, rs1805006) and the blue-eye HERC2/OCA2 markers; its numeric prediction weights are an *optional* fetch (Walsh 2017, *Human Genetics*) needed only for full quantitative color probabilities. Because those weights are European-trained, the sign-only score is the more defensible choice for archaic samples. **Its correctness is guarded by Q4 (allele sign) and Q9 (MC1R null + HIrisPlex-S concordance).**

- [ ] **B4 · Redo the PCAs three ways, two designs each** · 🟡 (LH) · **BLOCKED(B2)**
  - **What it is:** build the "where do samples sit relative to each other" plots (PCA) using three different sets of positions — (i) just the 222 pigmentation SNPs, (ii) whole pigmentation-related *genes* (every position inside those genes, not just the known SNPs — take the gene list from the four datasets in §5, and their start/end coordinates from a gene database such as Ensembl/BioMart, on the matched build), and (iii) the whole genome as a baseline. For each, do two versions: **(a)** build the plot from the modern samples plus the few high-coverage archaics together (here "high-coverage" = the 4 flagship genomes: Vindija 33.19, Chagyrskaya 8, Denisova 5, Denisova 25); **(b)** build it from moderns only and then *project* all 14 archaics (including the low-coverage ones) onto it.
  - **Why it matters:** it tests a hypothesis — that pigmentation-gene clustering should *not* mirror whole-genome (ancestry) clustering. Confirming they differ is the point; don't assume it. The two designs handle the low-coverage samples honestly (design (b) is exactly how you place gappy samples without letting their gaps distort the axes).
  - **Do:** after **B2** (put the panel, the gene coordinates, and the sequence data all on the same genome build), generate the six plots. **Depends on Q3 (the WG variant reproduces known structure), Q5 (no collapse), and Q6 (which samples qualify as high-coverage).**

- [ ] **B5 · Decide how to handle missing data** · 🟡 (TL/LH) · **TODO**
  - **What it is:** many pigmentation SNPs are missing in many archaic samples. If we require every sample to have data at a SNP ("masking across everyone"), fewer than 50 of the 222 SNPs survive — too few.
  - **Why it matters:** the approach to missingness changes which samples and SNPs we can use.
  - **Do:** for SNP-level work, focus on the high-coverage samples (as identified by Q6); to escape the SNP-level sparsity, move to gene-level summaries (item B4 (ii)).

- [ ] **B6 · Keep gene-level and SNP-level sources separate** · 🟡 (YP/TL) · **TODO**
  - **What it is:** of the four datasets, three (the melanogenesis network, the cross-species set, the CRISPR screen) are lists of **genes**; two (the GWAS Catalog, HIrisPlex-S) are lists of individual **SNPs**. Genes cover a whole region; SNPs are single positions.
  - **Why it matters:** they can't be pooled naively — a gene isn't one position. Analyses and weighting differ.
  - **Do:** carry the gene-level and SNP-level layers explicitly and analyze each appropriately.

- [ ] **B7 · Look at functional impact and the skin-specific genes** · ⚪ (YP/LH) · **BLOCKED(B2)**
  - **What it is:** two things. **(1) A functional-impact summary:** among the DNA changes in/around the pigmentation genes, report the ratio of *synonymous* (silent) to *non-synonymous* (protein-changing) changes — a rough read on whether the variation is functional / under selection. This needs each variant's coding effect, produced by running a **variant-effect annotator** (Ensembl VEP, SnpEff, or ANNOVAR) on the matched genome build. Note most of the 222 panel SNPs are non-coding (regulatory), so this ratio is computed over **coding variants in the pigmentation genes** (from exome or whole-genome data), *not* the panel SNPs — if suitable coding/exome data isn't readily available for these samples, flag that and defer. **(2) A profile of the six skin-specific pigmentation genes** (TYR, OCA2, TYRP1, DCT, PMEL, MLANA — see Glossary): for each gene, a per-population allele-frequency / genotype comparison of moderns vs archaics.
  - **Why it matters:** those six genes are switched on mainly in skin (tissue-specific expression), so they're the cleanest "this is really about *skin* pigmentation" story and easy to explain. (Source of the six-gene shortlist: a conference poster by Yemko Pryor on skin-specific pigmentation-gene expression.)
  - **Do:** run the annotator to get coding effects and the synonymous:non-synonymous ratios (and state which direction of the ratio indicates functional constraint); build the per-gene moderns-vs-archaics frequency profiles. **The annotator build must match the data build — asserted by Q4.**

- [ ] **Q9 · Cross-validation against published results + an orthogonal predictor** · 🟡 (TL/LH) · **BLOCKED(B2)**
  - **What it is:** check that the project's archaic calls agree with what's already published, and that the home-grown directional score agrees with an established method. Assert MC1R known red-hair variants (rs1805007/8/6, etc.) are **absent/reference** in the archaics; assert genotypes at a set of loci with published archaic calls (from the Neanderthal/Denisovan genome papers) match; and compute both the directional score **and** a HIrisPlex-S-style prediction on the same samples and assert rank concordance.
  - **Why it matters:** disagreeing with well-established archaic genotypes is a red flag for calling errors; the MC1R null is both the expected, citable result *and* a check that MC1R is even being genotyped; and an orthogonal predictor guards against a bug in the home-grown score. This is the credibility check for the whole science phase.
  - **Verifies/relates:** B3 (score), B7 (calls); the MC1R part is the QC twin of B3's MC1R check.
  - **Deliverable:** `qc/cross_validate.R`.
  - **Acceptance:** MC1R red-hair variants absent/reference in all archaics; published-locus genotypes match; directional score and HIrisPlex-S-style prediction are rank-concordant (no wild disagreement).
  - **Subtasks:**
    - [ ] Assert MC1R red-hair variants absent/reference.
    - [ ] Assert concordance at a panel of published archaic genotypes.
    - [ ] Compute directional score vs HIrisPlex-S-style prediction; assert rank concordance.
  - **Artifact:** a "known results reproduced" table (locus → expected → observed → ✓/✗).

---

### Phase 5 — Infrastructure & reproducibility
**Gate:** the pipeline is re-runnable by someone else, there's one unambiguous canonical path (no competing/dead scripts), derived data is preserved, and the repo is tidy. This can run partly in parallel with Phase 4.

- [x] **C1 · Move the repo into the Lasisi Lab GitHub org** · (TL) · **DONE** — `lasisilab/paint-workflowr`; just confirm Lily has access.

- [ ] **C2 · Let Lily develop locally while heavy jobs run on the cluster** · 🟡 (TL) · **TODO**
  - **What it is:** Lily's laptop (8 GB RAM) can't run the big steps (the PCAs and genotype calling must run on the cluster); only the visualization runs locally. Set up the repo so the code runs "as if the cluster folder were local" — i.e. list the huge cluster files in `.gitignore` (so they never enter GitHub) but structure the code so Lily edits it locally and pings Tina to run the heavy steps on the cluster. (Same pattern as the lab's PODFRIDGE project.)
  - **Do:** wire up the gitignore + path conventions; agree which files are small enough to commit.

- [ ] **C3 · Back up the derived data** · 🟡 (TL) · **TODO**
  - The cluster's Turbo storage is not permanent archival storage. The raw archaic BAMs can be re-downloaded from public sources, but the *derived* products (the merged SGDP reference panels, the archaic genotype call sets, the PCA outputs) are expensive to regenerate — back them up or deposit them.

- [ ] **C4 · Write a "where everything lives" doc** · ⚪ (LH) · **TODO**
  - A short Google Doc listing where the dissertation, the repos, and the Drive folders are, so collaborators aren't hunting.

- [ ] **Q10 · Reproducibility infrastructure (versions, seeds, pipeline-as-DAG, CI)** · 🟡 (TL) · **TODO**
  - **What it is:** make the whole pipeline re-runnable to the same numbers. Pin the environment (conda `environment.yml` / a container / R `renv.lock`) and record tool versions in the manifest (the version-capture slice is **Q10a**, started in Phase 0); add `set.seed()` to the depth simulations so re-runs reproduce the figures (hash-checkable); **encode the pipeline as a Snakemake/Nextflow (or Makefile) DAG** so run order is explicit, the "which script is canonical" ambiguity (see A4/A5) disappears, and the flow figure **auto-generates** and stays in sync; and add a tiny **end-to-end fixture test** (a few samples, a few SNPs) that runs in CI and asserts the key invariants from Q2–Q6.
  - **Why it matters:** currently there's no version pinning, no seeds, competing/dead scripts, and manual per-sample submission — so a reviewer (or future Lily) can't reproduce the numbers, and it's unclear which script ran. This pays down the two-pipeline confusion permanently.
  - **Verifies/relates:** formalizes the cleanup begun in A4/A5; the fixture test exercises Q2–Q6; feeds C2/C3.
  - **Deliverable:** `environment.yml` (or `renv.lock`/container) + `Snakefile` (or `Makefile`) + a CI workflow.
  - **Acceptance:** a fresh checkout reproduces the key figures/numbers from pinned versions + seeds; the DAG builds and auto-emits the flow figure; CI runs the fixture test green on every push.
  - **Subtasks:**
    - [ ] Pin environment + record versions in the manifest (Q10a).
    - [ ] Add seeds to simulations; assert figure reproducibility by hash.
    - [ ] Encode the pipeline as a DAG; auto-generate the flow figure.
    - [ ] Add the CI fixture test asserting Q2–Q6 invariants.
  - **Artifact:** the auto-generated DAG figure + a green/red CI badge on the repo.

- [ ] **A6 · Repo tidy-ups** · ⚪ (LH) · **CONFIRMED · TODO (cleanup)**
  - In the website source: `introduction.Rmd` says the panel is "395 SNPs" but it's 222 (fix the number); the "View genetic PCAs" link points to the old `analysis.html` (should be `pca.html`); the `LICENSE` file is empty (the license text only lives in `license.Rmd`); two built pages (`docs/analysis.html`, `docs/depth_spinoff.html`) have no source and should be removed; and `cleaning.Rmd` / `process_links.R` hard-code file paths from Lily's laptop, so they won't run elsewhere.
  - **Consequence (demonstrated, reader-facing):** these are confined to the published site (the thesis itself is correct), but they mislead a reader — the live Background page states "395 SNPs" (contradicting both the 222 in the thesis and the ~226-bar chart right below it), the "View genetic PCAs" link 404s on a clean rebuild, the empty `LICENSE` means the promised MIT reuse grant is legally unsupported, and because `.gitignore` drops all `*.csv` while the derived tables are written only to Lily's laptop paths, **the committed site cannot be rebuilt from a fresh clone** (every page reading a derived CSV errors). Full trace: `verify/BUG_EVIDENCE.md` §A6.

---

### Phase 6 — Writing
**Gate:** the two manuscripts are out. The review (D2) needs no new analysis — only the lit review (D1) — so it can start immediately and in parallel with the earlier phases.

- [ ] **D1 · Literature review of archaic pigmentation** · 🔴 (LH) · **TODO**
  - **What it is:** become the person who knows everything published about pigmentation genes in archaic humans. Method: search the "Undermind" tool for "archaic skin", then use Claude to screen 50–100 papers (start from new-data / selection papers on archaics since ~2000, pull their supplements, then search them for the project's gene list).
  - **Why it matters:** feeds both papers (below) and gives Lily authority in the field. Must-know anchors: the Lalueza-Fox 2007 MC1R paper and its rebuttals; Omer Gokcumen's (Buffalo) archaic/skin work.

- [ ] **D2 · The TIG review manuscript** · 🔴 (LH/TL) · **TODO**
  - A review article for *Trends in Genetics*. Prioritize it — it needs no new analysis, just the lit review (D1). Keep its tasks distinct from the primary paper (D3).

- [ ] **D3 · The PAINT primary paper** · 🟡 (TL/LH/YP) · **TODO**
  - Draft title: *"The genetic landscape of pigmentation in archaic hominins."* Resolve the PAINT acronym (§6); Tina scopes target journals. Aim: publish the honest landscape of archaic pigmentation genetics before someone else does; added complexity can come during review.

---

## 5. Datasets & provenance
The next phase uses four complementary pigmentation datasets plus one prediction panel, all already assembled — on the **hg38** build — in the **public** repo `tinalasisi/pigmentation-gene-network`. Full provenance (exact endpoints, licenses, freeze dates) is in that repo's [`DATA_SOURCES.md`](https://github.com/tinalasisi/pigmentation-gene-network/blob/main/DATA_SOURCES.md). (Establishing the *project's own* input provenance — the genomes, the panel BED, the gene coordinates — is item **Q1**.)

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

## 6. The name "PAINT"
PAINT currently stands for "Pigmentation Analysis of **IN**trogressed Neanderthal Traits," but the study never actually looked at introgression (the mixing of archaic DNA into modern humans). So the acronym should be re-worked (e.g. "integumentary" — skin/hair/nail — traits), to be settled together with the manuscript title in D3.
