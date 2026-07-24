# SEPIA — QC baked into each published archaic VCF

We are reusing the published, damage-aware genotype VCFs for the high-coverage archaics rather than re-calling. This documents **exactly what QC/filters each release already carries** — so we know what we're inheriting, and what we still must add before comparing across genomes. Sources: the MPI-EVA release READMEs, the filename-encoded parameters, and the papers.

> **Not phased.** All of these are **unphased diploid genotype calls** from `snpAD` (Prüfer 2018, an ancient-DNA-damage-aware genotyper) — the genotype with the highest likelihood under an empirical error model is reported per position. Statistical phasing, if ever needed, is a separate downstream step.

## 1. The 2017 snpAD release — Altai (Denisova 5), Vindija 33.19, Denisova 3
Source: `cdna.eva.mpg.de/neandertal/Vindija/VCF/README` (one shared README; files `chr{1..22,X}_mq25_mapab100.vcf.gz`).

| QC element | Value (verbatim / from filename) |
|---|---|
| Genotyper | **snpAD** — "an ancient DNA damage-aware genotyper"; "the genotype with the highest likelihood is reported at each position" |
| Reference build | **hg19 / GRCh37** ("used as reference in all VCFs") |
| Mapping quality | **MQ ≥ 25** ("required a MQ>=25 on sequences") — encoded `mq25` |
| Mappability | **Heng Li's 35-mer filter** — "a position is mappable if none of the overlapping 35mers align to any other position in the genome allowing for up to one mismatch"; encoded `mapab100`; "estimates were restricted to mappable regions" |
| Damage handling | built into snpAD's empirical error profile (damage-aware) |
| **Not specified in the README** (confirm from the paper / apply ourselves) | base-quality threshold; min/max **depth** filters; tandem-repeat / segmental-duplication masking; the per-sample coverage |

**What we still add before use:** a **min/max depth** filter per sample (the papers apply one; the README doesn't state it) and, for cross-genome comparison, a **common mask** (intersect the mappability + any release masks so all genomes are compared on identical sites).

## 2. Chagyrskaya 8
Source: `ftp.eva.mpg.de/neandertal/Chagyrskaya/` (VCF `chr{1..22,X}.noRB.vcf.gz`; a separate `FilterBed/` quality mask; `README`).

| QC element | Value |
|---|---|
| Coverage | ~28× (README) |
| Genotyper | snpAD (Mafessoni et al. 2020) |
| Filter mask | a **separate `FilterBed/` BED must be applied** — the VCF alone is not the final filtered call set |
| `.noRB` filename | **to confirm** from the README — most likely "repeat/reliable-blocks mask NOT yet applied" (i.e. apply `FilterBed/` yourself) |

## 3. Denisova 25  (⚠ preprint — provisional)
Source: `cdna.eva.mpg.de/denisova/Den25/` (VCF `chr{…}.Den25.L35MQ25.B30.map35_100.vcf.gz`; `FilterBed/`; README).

Filters **encoded in the filename**:
| Token | Meaning |
|---|---|
| `L35` | minimum read length 35 bp |
| `MQ25` | mapping quality ≥ 25 |
| `B30` | base quality ≥ 30 |
| `map35_100` | 35-mer mappability, 100% |
Coverage ~24× (README). Separate `FilterBed/` mask to apply. Peer review pending → treat as provisional.

## 4. Vindija 87
Same **individual** as Vindija 33.19 → for called genotypes, use the Vindija 33.19 VCF (§1). The separate 1.3× Vi87 BAM is only needed if you specifically want that library's reads.

## 5. El Sidrón 1253 — exome VCF only
`cdna.eva.mpg.de/neandertal/exomes/` — **coding regions only** (target-capture, Castellano 2014). Not comparable to the genome-wide panel; **excluded** from the analysis.

## 6. Tier-B low-coverage genomes — NO published VCF
Denisova 11, Goyet Q56-1, Les Cottés, Spy 94a, Mezmaiskaya 1 & 2, Hohlenstein-Stadel, Scladina: **BAM only** — coverage is too low for published diploid genotype calls, and it should be. For these we do **not** hard-call; we compute **genotype likelihoods with ANGSD** ourselves ([`rebuild_from_raw.md`](../rebuild_from_raw.md) Stage 4), applying our own documented filters: MQ ≥ 30, BQ ≥ 20, a **max-depth cap** (reject pileup artifacts), the same mappability mask as the Tier-A VCFs, mapDamage rescaling, and `-noTrans` (transversion-only) for the ancestry PCA.

---

## Cross-genome harmonization (the "use them correctly" step)
Reusing the published VCFs is right — but they come from **different releases with different masks and (for Den25) different quality tokens**, so they are not automatically comparable. Before any joint analysis:
1. **Apply each genome's companion FilterBed/mappability mask** (the VCF alone isn't the filtered set).
2. **Intersect to a common mask** so every genome is evaluated on identical, high-confidence sites.
3. **Confirm one build** (all are hg19 — verify with the Q2 tracer-SNP lint).
4. **Apply a uniform per-site depth band** across genomes.
5. Only then merge / subset to the pigmentation + ancestry panels.

This is the QC bridge between "the authors' calls" and "a call set we can compare across samples" — documented so the reanalysis inherits the authors' careful work *and* adds the harmonization they did not (because each was released independently).
