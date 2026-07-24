# SEPIA — source-paper references & data provenance (every genome)

Provenance for **every** genome in the project, verified against MPI-EVA / ENA / the source papers (2026-07-23). This is the citation + data-source manifest; it feeds the Q1 provenance manifest.

**On the PDFs.** Actual paper PDFs are downloaded into `plan/papers/pdf/` **which is git-ignored** — the repo is public and most of these are paywalled (Nature/Science/PNAS), so committing them would redistribute copyrighted material. Open-access / author-copy / preprint PDFs were pulled automatically (marked ✅ local); paywalled ones are linked for download via institutional (UMich) access into the same folder (marked 🔒).

**Two clarifications that matter for the reanalysis:**
- The MPI-EVA high-coverage VCFs are **damage-aware `snpAD` *genotype* calls, not statistically phased** haplotypes. "Phased VCF" = a downstream step we'd run ourselves if needed. QC details per release: [`VCF_QC.md`](VCF_QC.md).
- **Vindija 87 is the same individual as Vindija 33.19** (the 30× genome) — so called genotypes for it exist via the Vindija 33.19 VCF; the 1.3× "Vi87" BAM is a separate low-coverage library of the same person.

---

## Tier A — high-coverage archaics: **use the published snpAD genotype VCFs** (don't re-call)

| Genome | Site · type | Coverage | Paper | DOI | Data (VCF / BAM) | PDF |
|---|---|---|---|---|---|---|
| **Altai Neanderthal** (= Denisova 5) | Denisova Cave · Neanderthal | ~52× | Prüfer et al. 2014, *Nature* 505:43–49 | 10.1038/nature12886 | VCF (snpAD 2017 reprocess): `cdna.eva.mpg.de/neandertal/Vindija/VCF/Altai/chr{1..22,X}_mq25_mapab100.vcf.gz`; original: `cdna.eva.mpg.de/neandertal/altai/AltaiNeandertal/VCF/`; BAM: `.../AltaiNeandertal/bam/` | 🔒 Nature |
| **Vindija 33.19** | Vindija Cave, Croatia · Neanderthal | ~30× | Prüfer et al. 2017, *Science* 358:655–658 | 10.1126/science.aao1887 | VCF: `cdna.eva.mpg.de/neandertal/Vindija/VCF/Vindija33.19/chr{1..22,X}_mq25_mapab100.vcf.gz`; ENA **PRJEB21157**; BAM under `ftp.eva.mpg.de/neandertal/Vindija/` | ✅ `pruefer2017_vindija33_science.pdf` |
| **Chagyrskaya 8** | Chagyrskaya Cave · Neanderthal | ~27–28× | Mafessoni et al. 2020, *PNAS* 117:15132–15136 | 10.1073/pnas.2004944117 | VCF: `ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/chr{1..22,X}.noRB.vcf.gz`; mask: `.../Chagyrskaya/FilterBed/`; BAM: `.../Chagyrskaya/BAM/` | 🔒 PNAS (PMC likely OA) |
| **Denisova 3** | Denisova Cave · Denisovan | ~30× | Meyer et al. 2012, *Science* 338:222–226 | 10.1126/science.1224344 | VCF (snpAD 2017): `cdna.eva.mpg.de/neandertal/Vindija/VCF/Denisova/chr{1..22,X}_mq25_mapab100.vcf.gz`; original: `cdna.eva.mpg.de/denisova/VCF/human/`; BAM: `cdna.eva.mpg.de/denisova/BAM/` | 🔒 Science |
| **Denisova 25** ⚠ preprint | Denisova Cave (S. Chamber, ~200 ka molar) · Denisovan | ~24× | Peyrégne et al. 2025, *bioRxiv* | 10.1101/2025.10.20.683404 | VCF: `cdna.eva.mpg.de/denisova/Den25/VCF/chr{1..22,X,Y}.Den25.L35MQ25.B30.map35_100.vcf.gz`; mask: `.../Den25/FilterBed/`; BAM: `.../Den25/BAM/` | ✅ `den25_peyregne2025_biorxiv.pdf` |

*The Altai + Vindija 33.19 + Denisova 3 VCFs share one 2017 **snpAD** release (same pipeline, reference, filters, one README) → most directly comparable, and the Mez1 low-cov snpAD calls sit in the same release tree. The **original** Altai (2014) and Denisova 3 (2012) releases are **GATK UnifiedGenotyper** calls — prefer the snpAD reprocess for a harmonized cohort. Chagyrskaya 8 and Denisova 25 are separate snpAD releases with their own masks — apply each release's FilterBed and harmonize before merging (see `VCF_QC.md`). Denisova 25 is a **preprint** whose data are **not yet deposited** → provisional. **The published VCFs are not the final call set — the companion `FilterBed` mask (cov≥10, GC central-95%, tandem-repeats, indels) must be applied on top.***

## Tier B — low-coverage archaics: **BAM only → ANGSD genotype likelihoods** (no published VCF)

| Genome | Site · type | Coverage | Paper | DOI | Archive | PDF |
|---|---|---|---|---|---|---|
| **Denisova 11 "Denny"** | Denisova Cave · **F1 hybrid** (Nea mother × Den father) | ~2.6× | Slon et al. 2018, *Nature* 561:113–116 | 10.1038/s41586-018-0455-x | ENA **PRJEB24663** (raw); BAM | 🔒 Nature |
| **Goyet Q56-1** | Goyet, Belgium · late Neanderthal | 2.2× | Hajdinjak et al. 2018, *Nature* 555:652–656 | 10.1038/nature26151 | ENA **PRJEB21870**; EVA `neandertal/GoyetQ56-1/` | 🔒 (OA: PMC6485383) |
| **Les Cottés Z4-1514** | Les Cottés, France · late Neanderthal | 2.7× | Hajdinjak et al. 2018 | 10.1038/nature26151 | ENA **PRJEB21875**; EVA `LesCottes_Z4-1514/` | 🔒 (OA: PMC6485383) |
| **Spy 94a** | Spy, Belgium · late Neanderthal | 1.0× | Hajdinjak et al. 2018 | 10.1038/nature26151 | ENA **PRJEB21883**; EVA `Spy94a/` | 🔒 (OA: PMC6485383) |
| **Mezmaiskaya 2** | Mezmaiskaya, Russia · late Neanderthal (~44 ka) | 1.7× | Hajdinjak et al. 2018 | 10.1038/nature26151 | ENA **PRJEB21881**; EVA `Mezmaiskaya2/` | 🔒 (OA: PMC6485383) |
| **Vindija 87** (= Vi 33.19 individual) | Vindija, Croatia · late Neanderthal | 1.3× | Hajdinjak et al. 2018 | 10.1038/nature26151 | ENA **PRJEB21882**; EVA `Vindija87/`. *Called genotypes: use the Vi 33.19 VCF (Tier A).* | 🔒 (OA: PMC6485383) |
| **Mezmaiskaya 1** | Mezmaiskaya, Russia · Neanderthal (~65 ka) | ~0.5× + 1.4× ≈ 1.9× | Prüfer et al. 2017 (added); Prüfer 2014 (orig.) | 10.1126/science.aao1887 | ENA **PRJEB21195**; **a low-cov snpAD VCF EXISTS: `cdna.eva.mpg.de/neandertal/Vindija/VCF/Mez1/`** (+ BAM `Mezmaiskaya1/`) | ✅ (Prüfer 2017 pdf) |
| **Hohlenstein-Stadel** | Hohlenstein-Stadel, Germany · **early** Neanderthal (~120 ka) | ~0.05× (168 Mbp) | Peyrégne et al. 2019, *Sci. Adv.* 5:eaaw5873 | 10.1126/sciadv.aaw5873 | ENA **PRJEB29475**; EVA `Hohlenstein-Stadel/BAM/All_sequences/L5386.bam` | ✅ `peyregne2019_hst_scladina_sciadv.pdf` |
| **Scladina I-4A** | Scladina, Belgium · **early** Neanderthal (~120 ka) | ~0.02–0.03× (78 Mbp) | Peyrégne et al. 2019 | 10.1126/sciadv.aaw5873 | ENA **PRJEB29475** (2° ERP111781); run **ERR9741105** = `G2160.bam`; EVA `Scladina/BAM/` | ✅ (Peyrégne 2019 pdf) |

## Tier C — no usable genome-wide data (excluded → 14 analyzed, not 15)
| Genome | Status | Paper | DOI | Note |
|---|---|---|---|---|
| **El Sidrón 1253** | **exome-capture only** (~12.5× over coding regions); **no shotgun whole-genome** | Castellano et al. 2014, *PNAS* 111:6666–6671 | 10.1073/pnas.1405138111 | EVA `neandertal/exomes/` (BAM+VCF, coding only). Not comparable to the genome-wide panel → correctly excluded. |

## Modern reference & methods
| Item | Paper | DOI | Source |
|---|---|---|---|
| **SGDP** (15 moderns used) | Mallick et al. 2016, *Nature* 538:201–206 | 10.1038/nature18964 | Seven Bridges CGC, remapped to hs37d5/hg19 (`sgdp_merge` LP-IDs recorded in the Q1 manifest) |
| **snpAD** genotyper (the high-cov VCF caller) | Prüfer 2018, *Bioinformatics* 34:4165–4171 | 10.1093/bioinformatics/bty507 | damage-aware ancient-DNA genotyper |
| **Reference genome** | hs37d5 / GRCh37 (hg19) | — | 1000 Genomes decoy build; all archaic BAMs and SGDP are aligned to it |

## Flagged / unconfirmed
- **Denisova 25** — preprint (not yet peer-reviewed); EVA `Den25/` files are live but formal ENA/SRA accession not yet stated; treat as provisional.
- **El Sidrón exome ENA accession** — unconfirmed; authoritative access is the EVA `exomes/` URL.
- **HST / Scladina fold-coverage** — derived from the paper's Mbp figures (168 / 78 Mbp ÷ ~3.2 Gb), not stated as fold in the text.
- **Chagyrskaya `.noRB`** filename meaning — to confirm from the release README (likely "RepeatBed/reliable-blocks mask not yet applied" → apply `FilterBed/` yourself).

*PDFs downloaded locally: `den25_peyregne2025_biorxiv.pdf`, `pruefer2017_vindija33_science.pdf`, `peyregne2019_hst_scladina_sciadv.pdf`. Paywalled papers (Prüfer 2014, Meyer 2012, Slon 2018, Mafessoni 2020, Hajdinjak 2018, Castellano 2014, Mallick 2016) → download via UMich library into `plan/papers/pdf/` using the DOIs above.*
