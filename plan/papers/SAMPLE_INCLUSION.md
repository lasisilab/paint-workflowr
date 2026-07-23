# PAINT — which archaic genomes to include, and why

**Decision goal (Tina, 2026-07-23):** *not* to maximize the number of genomes, but to choose — and explicitly justify — the **best subset that maximizes the number of pigmentation SNPs of interest we can genotype reliably.** Anything that is not whole-genome shotgun (i.e. exome-capture), redundant, or too unreliable to contribute trustworthy calls at the panel is excluded, with the reason recorded here.

## The criteria
1. **C1 — whole-genome shotgun only.** Exclude exome-capture data (covers ~coding regions only; most pigmentation SNPs are regulatory/non-coding).
2. **C2 — non-redundant.** Exclude a genome that is a lower-coverage library of an individual we already have at high coverage.
3. **C3 — enough coverage to contribute reliable panel genotypes.** Reliable *diploid* genotypes need ~≥10×; snpAD/GL genome-wide estimates ~≥4×; below that a covered site yields at most a single **pseudo-haploid** allele.
4. **C4 — reliability at the SNPs of interest specifically.** The panel is **transition-heavy** (of the 129 panel SNPs present in the modern reference, **92 are transitions vs 37 transversions**, and the headline loci — **SLC24A5 rs1426654, HERC2 rs12913832, MC1R red-hair set — are all transitions**). Ancient-DNA deamination damage (C→T, G→A) falls **exactly on transition sites**, so low-coverage genomes are *least* reliable precisely at the SNPs we care about; their trustworthy contribution is mostly the ~1/3 transversion SNPs. Contamination must also be low.

## Quantitative basis — expected usable panel SNPs per genome
Expected number of the 222 panel SNPs with ≥k reads, from each genome's **published genome-wide coverage** (Poisson, mean = coverage). "≥10×" ≈ reliable diploid call; "≥4×" ≈ snpAD/GL usable; "≥1×" = at most a pseudo-haploid allele (and damage-suspect at transitions).

| Genome | Cov (×) | SNPs ≥1× | SNPs ≥4× | SNPs ≥10× | Diploid-callable? | VCF? |
|---|---|---|---|---|---|---|
| Altai / Denisova 5 | 52 | 222 | 222 | 222 | yes | snpAD |
| Vindija 33.19 | 30 | 222 | 222 | 222 | yes | snpAD |
| Denisova 3 | 30 | 222 | 222 | 222 | yes | snpAD |
| Chagyrskaya 8 | 27.6 | 222 | 222 | 222 | yes | snpAD |
| Denisova 25 | 23.6 | 222 | 222 | 222 | yes | snpAD (preprint) |
| Les Cottés Z4-1514 | 2.7 | 207 | 63 | 0 | no (pseudo-haploid/GL) | — |
| Denisova 11 (hybrid) | 2.6 | 206 | 59 | 0 | no | — |
| Goyet Q56-1 | 2.2 | 197 | 40 | 0 | no | — |
| Mezmaiskaya 1 | 1.9 | 189 | 28 | 0 | no | snpAD (low-cov) |
| Mezmaiskaya 2 | 1.7 | 181 | 21 | 0 | no | — |
| Vindija 87 | 1.3 | 161 | 10 | 0 | no | — (redundant) |
| Spy 94a | 1.0 | 140 | 4 | 0 | no | — |
| Hohlenstein-Stadel | 0.05 | 11 | 0 | 0 | no | — |
| Scladina I-4A | 0.02 | 4 | 0 | 0 | no | — |
| El Sidrón 1253 | exome | — | — | — | — | exome only |

**Reading of the table:** the five high-coverage genomes reliably genotype **all 222** SNPs (including transitions); every low-coverage genome yields **0** SNPs at diploid-callable depth and only pseudo-haploid alleles at ≥1×, concentrated (for reliability) on transversions. So the SNP-of-interest count is driven overwhelmingly by the high-coverage set; low-coverage genomes add *samples*, not *reliable SNPs of interest*.

## The subset

### Tier 1 — core (always include): the 5 high-coverage genomes + SGDP
**Altai / Denisova 5, Vindija 33.19, Denisova 3, Chagyrskaya 8, Denisova 25**, plus the **15 SGDP moderns** (reference; verified — see below).
*Justification:* ≥23× → the **full 222-SNP panel, including the transition loci of interest, genotyped reliably** with published, damage-aware `snpAD` calls. This set alone covers the entire panel of interest for both Neanderthals and Denisovans and is the backbone of every analysis.

### Tier 2 — extended (include with explicit caution, reported separately): coverage ≥ ~2× or a published VCF
**Les Cottés Z4-1514 (2.7×), Denisova 11 (2.6×, the F1 hybrid), Goyet Q56-1 (2.2×), Mezmaiskaya 1 (1.9×, has a low-cov snpAD VCF).**
*Justification:* each can contribute a pseudo-haploid allele at ~190–207 panel SNPs, but reliably mainly at **transversion** SNPs (transition calls are damage-suspect at this depth). Included for archaic **diversity** (esp. Denisova 11, the only hybrid) and to show low-coverage results honestly — but analysed by **genotype likelihoods / pseudo-haploid** with uncertainty reported, and never given equal weight to Tier 1. Mez1 can use its published VCF (with care) instead of re-acquisition.

### Excluded — with reasons
| Genome | Reason (criterion) |
|---|---|
| **El Sidrón 1253** | C1 — exome-capture only, no shotgun genome |
| **Vindija 87** | C2 — redundant: same individual as Vindija 33.19 (use the 30× VCF) |
| **Mezmaiskaya 2** (1.7×) | C3/C4 — below the ~2× bar, no VCF; few reliable panel SNPs |
| **Spy 94a** (1.0×) | C3/C4 — 1.0×, and the highest contamination in its cohort (~4% qpAdm) |
| **Hohlenstein-Stadel** (0.05×) | C3 — ultra-low: ~11 panel SNPs with any read, contamination-dominated |
| **Scladina I-4A** (0.02×) | C3 — ultra-low: ~4 panel SNPs with any read; raw contamination 65% |

*(The ~2× Tier-1/2 boundary is a documented, adjustable choice; the table above lets the PI move it. Mez2 at 1.7× is the closest call — promote it to Tier 2 if the extended analysis wants one more Neanderthal.)*

## Consequences for acquisition & compute
- **No read re-acquisition for Tier 1** — download the published snpAD VCFs (+ FilterBed).
- **Targeted re-acquisition only for the Tier-2 BAM genomes: Les Cottés, Denisova 11, Goyet** (stream reads at the panel + ancestry-SNP positions). **Mezmaiskaya 1** uses its VCF. So ~3 small targeted extractions — trivial compute.
- **SGDP: verify** the existing `sgdp.wg` (hg19) — do not re-acquire.
- The 6 excluded genomes are not downloaded at all.

## SGDP verification (decided: verify, not rebuild)
Reuse the committed `pca/modern/sgdp.wg` (15 samples, hg19), gated by: the Q2 tracer-SNP/build lint (confirm hg19 + naming), the Q4 allele/REF check on the panel SNPs, and application of the SGDP universal mask + a chosen filter level (default 1; see [`PIPELINE_QC_BY_PAPER.md`](PIPELINE_QC_BY_PAPER.md) → Mallick 2016). Rebuild from source only if the lint fails.

## Bottom line
**Primary analysis = 5 high-coverage archaics + SGDP** (maximizes reliably-genotyped SNPs of interest, including the key transition loci). **Extended/sensitivity = + Les Cottés, Denisova 11, Goyet (+ optionally Mez1/Mez2)** with genotype-likelihood uncertainty, mainly at transversion SNPs. Six genomes excluded for exome-only, redundancy, or unreliability, each recorded above.
