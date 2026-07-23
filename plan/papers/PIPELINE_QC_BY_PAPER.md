# PAINT — per-paper QC & pipeline (what each source actually did)

For every genome, this records **what the source authors report doing for QC and their bioinformatic pipeline** — extracted from each paper's Methods *and* Supplementary. It's the evidence base for the "reuse vs. rerun" decision in [`../rebuild_from_raw.md`](../rebuild_from_raw.md): to reuse a published call set responsibly, we have to know exactly how it was made.

> **Status: being populated.** A paper-extraction workflow (one agent per paper → adversarial verify) is running; each entry below is filled from the verified extraction (Methods + SOM), with parameters quoted verbatim and every value sourced. Fields the paper doesn't state are marked *not found* rather than guessed. Papers grouped as in [`REFERENCES.md`](REFERENCES.md).

For each paper: **reference build · read processing (trim/merge/aligner+params) · duplicate removal · MQ/BQ & length filters · damage handling (UDG, trimming, PMD/rescale) · genotype calling (tool+params+ploidy) · masks & site filters (mappability, min/max depth, repeat/segdup, FilterBed) · contamination · sex · coverage · reuse implication.**

---

## Tier A — high-coverage (we reuse the published genotype VCFs)
- **Prüfer et al. 2017 (Vindija 33.19; Mezmaiskaya 1 +1.4×)** — _pending extraction._
- **Prüfer et al. 2014 (Altai = Denisova 5)** — _pending extraction._ (Defines the high-coverage pipeline reused by later releases.)
- **Meyer et al. 2012 (Denisova 3)** — _pending extraction._
- **Mafessoni et al. 2020 (Chagyrskaya 8)** — _pending extraction._
- **Peyrégne et al. 2025 (Denisova 25, preprint)** — _pending extraction._
- **Prüfer 2018 (snpAD genotyper — the caller behind all the above VCFs)** — _pending extraction._

## Tier B — low-coverage (we re-acquire BAMs → ANGSD genotype likelihoods)
- **Hajdinjak et al. 2018 (Goyet Q56-1, Les Cottés Z4-1514, Spy 94a, Mezmaiskaya 2, Vindija 87)** — _pending extraction._ (Key low-coverage-processing reference.)
- **Slon et al. 2018 (Denisova 11 "Denny")** — _pending extraction._
- **Peyrégne et al. 2019 (Hohlenstein-Stadel, Scladina — early ~120 ka)** — _pending extraction._

## Tier C — excluded
- **Castellano et al. 2014 (El Sidrón 1253 exome)** — _pending extraction._ (Confirm exome-only, no shotgun genome.)

## Modern reference
- **Mallick et al. 2016 (SGDP)** — _pending extraction._ (Processing + genotyping + filter levels of the 15-sample reference.)
