# SEPIA — per-paper QC & pipeline (what each source actually did)

For every genome, this records **what the source authors report doing for QC and their bioinformatic pipeline** — extracted from each paper's Methods **and** Supplementary, with load-bearing parameters quoted verbatim, then **adversarially verified** (a second agent re-read each source; all 11 verdicts were SOLID). Evidence base for the "reuse vs. rerun" decision in [`../rebuild_from_raw.md`](../rebuild_from_raw.md). Provenance/URLs: [`REFERENCES.md`](REFERENCES.md); baked-in VCF QC summary: [`VCF_QC.md`](VCF_QC.md).

## Cross-cutting findings (read first)
- **Two caller generations.** The *original* high-coverage VCFs — **Altai/Denisova 5 (Prüfer 2014)** and **Denisova 3 (Meyer 2012)** — are **GATK UnifiedGenotyper v1.3**, EMIT_ALL_SITES, diploid, with **UDG+EndoVIII** libraries + a **2 bp terminal base-quality→2** damage mask, **MQ≥30**. The *reprocessed* **2017 snpAD release** (Prüfer 2017) re-genotyped Vindija 33.19 **+ Altai + Denisova 3 (+ Mezmaiskaya 1)** with the damage-aware **snpAD** caller at **MQ≥25, BQ≥30, map35_100**. **For a harmonized cohort, use the 2017 snpAD reprocess** (same caller/reference/filters across those four), not the original GATK calls.
- **The published VCF is NOT the final filtered call set.** The snpAD VCFs carry only `mq25` + `map35_100` (in the filename). The **min-coverage-10 + GC-corrected central-95% (the effective max-depth cap) + Tandem-Repeats-Finder + GATK-indel** filters ship as a **separate companion `FilterBed` mask** (e.g. `cdna.eva.mpg.de/neandertal/Vindija/FilterBed/`). You **must apply FilterBed**, then **intersect across genomes** to a common site set before comparing.
- **Correction — Mezmaiskaya 1 has a snpAD VCF.** `cdna.eva.mpg.de/neandertal/Vindija/VCF/Mez1/chr*_mq25_mapab100.vcf.gz` exists (a ~1.9× snpAD call set), even though the README lists only Vindija/Altai/Denisova. So Mez1 can be reused as a (low-coverage) VCF, not only as a BAM.
- **The low-coverage genomes were never diploid-genotyped.** Hajdinjak 2018 (Goyet/Les Cottés/Spy/Mez2/Vi87), Peyrégne 2019 (HST/Scladina), and Slon 2018 (Denisova 11) all used **pseudo-haploid random single-read sampling** (heffalump), restricted to **deaminated fragments + transversions**, with a **strand-orientation filter** — *not* genotype calls. For our rebuild this means Tier B has two defensible routes: **(a) reproduce their pseudo-haploid + deamination-filter approach** (field standard, well-validated), or **(b) ANGSD genotype likelihoods** (retains more information). We default to ANGSD GLs but will cross-check against the pseudo-haploid approach.
- **Damage is handled by the caller, not by trimming, in the modern MPI pipeline.** snpAD models position/orientation-dependent error; the non-UDG single-stranded libraries are called directly. Only the GATK-era genomes used UDG + terminal masking.
- **Contamination is uniformly low for the high-coverage genomes (<1–~1%)** but **~3.2% for Denisova 25** and **very high on the raw ultra-low-coverage data** (HST 22.9%, Scladina 64.8%) — where the **deamination filter is load-bearing** (drops those to 2.0% / 5.5%).
- **Denisova 25 data are not public yet** (preprint; "will be deposited" in ENA) — provisional, can't download today.

---

## Tier A — high-coverage (reuse published genotype VCFs)

### Prüfer et al. 2017, *Science* — Vindija 33.19 (~30×); Mezmaiskaya 1 (+1.4×) — the snpAD release
- **Build:** hg19/GRCh37 = hs37d5 (1000G decoy + ΦX174 + HHV4). **Read proc:** `leeHom --ancientdna` (adapter-trim + mate-merge) → deML demux → **BWA `-n 0.01 -o 2 -l 16500`** (network-aware-bwa 0.5.10-evan; `-l 16500` disables seeding) → drop <35 bp → GATK 1.3.14 indel-realign. **Dedup:** `bam-rmdup 0.6.3`. **Filters:** MQ≥25, **fixed BQ≥30** (base-Q not otherwise used in calling), length≥35.
- **Damage:** ~76% of Vindija + all Mez1 libraries **non-UDG** (single-stranded); **no trimming/rescaling** — snpAD absorbs damage via a position+orientation error profile (15 5′ + 15 3′ + interior bases).
- **Calling:** **snpAD**, diploid, highest-likelihood genotype per site; GQ = log-likelihood-ratio best/2nd; unphased. **Masks:** filename = `mq25` + `map35_100` only; **companion FilterBed** adds cov<10 removed, GC-corrected 2.5% tails removed, TRF simple-repeats, GATK indels (`…/Vindija/FilterBed/…/chr*_mask.bed.gz`, BED = passing).
- **Contam:** mt 1.6%, Y 0.74%, ML-nuclear 0.18–0.23% (Vindija; <1%). **Sex:** female (X≈autosomes). **Coverage:** 30× / 1.4×.
- **Reuse:** Vindija 33.19 VCF as-is **+ apply FilterBed**. **Mez1 VCF exists** (`…/VCF/Mez1/`, ~1.9× — low-cov, use with care or prefer GLs).

### Prüfer et al. 2014, *Nature* — Altai Neanderthal = Denisova 5 (~52×)
- **Build:** GRCh37 (+ panTro2 in parallel). **Read proc:** Ibis 1.1.6 base-call → overlap-merge (≥11 nt) → **BWA 0.5.10 `-n 0.01 -o 2 -l 16500`** → drop <35 bp → GATK 1.3.14 indel-realign; edit-distance >20% removed. **Dedup:** per-library consensus collapse (outer-coordinate). **Filters:** **MQ≥30** (note: 30, not 25), BQ≥30 in analyses, length≥35.
- **Damage:** **UDG + EndoVIII** (all libraries); at genotyping, **T in first/last-2 bases set to BQ 2** (no mapDamage/rescale). **Calling:** **GATK UnifiedGenotyper v1.3**, `--output_mode EMIT_ALL_SITES --genotype_likelihoods_model BOTH`, diploid, + Meyer-2012 two-iteration "re-call" for tri-allelic hets. **Masks (SI 5b minimal set):** TRF + MQ30 + map35_50/map35_100 + GC-binned central-95% coverage + drop GATK indels. **Contam:** mt 0.78%, ML-nuclear 0.8%, ROH 1.16%, Y 0.55% (~1%). **Sex:** female. 
- **Reuse:** original GATK VCFs at `…/altai/AltaiNeandertal/VCF/`; **prefer the 2017 snpAD reprocess** (`…/Vindija/VCF/Altai/`) for comparability.

### Meyer et al. 2012, *Science* — Denisova 3 (~30× Denisovan)
- **Read proc:** Ibis base-call → overlap-merge (≥11 nt; reject >5 bases BQ<15) → **trim first & last 2 bases** → **BWA 0.5.8a `-l 16500 -n 0.01 -o 2`** → drop <35 bp; edit-distance >20% removed → GATK 1.3.14 realign. **Dedup:** per-library consensus collapse. **Damage:** **UDG+EndoVIII** + the 2 bp terminal trim; CpG flag for masking; no rescale. **Calling:** **GATK UnifiedGenotyper v1.3**, EMIT_ALL_SITES, diploid, two-iteration re-call. **Masks:** Duke 20-mer uniqueness (Map20=1), coverage central-95% (Denisova 16–46×), + INFO flags RM/UR/SysErr/CpG. **Contam:** mt 0.35%, nuclear 0.22%, Y <0.1%. **Sex:** female.
- **Reuse:** original GATK "Extended VCF" (`cdna.eva.mpg.de/denisova/VCF/human/`); **prefer the 2017 snpAD reprocess** (`…/Vindija/VCF/Denisova/`).

### Mafessoni et al. 2020, *PNAS* — Chagyrskaya 8 (~27.6×)
- **Build:** hg19+decoy. **Read proc:** freeIbis/Bustard → **leeHom** (both adapters must match double-index) → **BWA `-n 0.01 -o 2 -l 16500`** → drop <35 bp → GATK 1.3-1.4 indel-realign. **Dedup:** `bam-rmdup` per library. **Filters:** MQ≥25, BQ≥30, length≥35. **Damage:** **non-UDG single-stranded**; snpAD-modeled (no trim/rescale). **Calling:** **snpAD v0.2.1**, per-chromosome error+freq, diploid, highest-likelihood genotype. **Masks (verbatim "general filters"):** map35_100 + **TandemRepeatFinder** simple-repeats + **GATK-indel** positions + **GC-binned central-95% coverage** + **min-coverage 10**; downstream D-stats reuse the **Vindija FilterBed**. **Contam:** mt 0.9%, Y 0.7%, ML-nuclear ~0.14–0.2% (<1%). **Sex:** female. 
- **Reuse:** VCF (`…/Chagyrskaya/VCF/chr*.noRB.vcf.gz`) + its `FilterBed/`. (`.noRB` ≠ a Mafessoni term; it's an MPI pipeline artifact.)

### Peyrégne et al. 2025, *bioRxiv* — Denisova 25 (~23.6×) ⚠ preprint
- **Build:** hg19+decoy. **Read proc:** leeHom → **BWA aln** (aDNA params "per Meyer 2012"; exact string not printed for Den25) → drop <35 bp → GATK 1.3-14. **Dedup:** `bam-rmdup`. **Filters:** MQ≥25, BQ≥30, L≥35 (filename `L35 MQ25 B30 map35_100`). **Damage:** **non-UDG single-stranded**, snpAD-modeled; AuthentiCT for damage-based contam. **Calling:** **snpAD v0.2.1**, diploid autosomes; **X/Y treated haploid (male)** — het X/Y filtered out. **Masks:** map35_100 + TRF + GATK-indel + GC central-95% + autosomal min-10×; PAR-aware. **Contam:** **~3.2% autosomal**, 2.5% X, 6.3% mt, AuthentiCT 1.3% — non-trivial. **Sex:** male. 
- **Reuse:** same standard snpAD pipeline as the others → comparable — **but data not public yet** (preprint); mark provisional; mask X/Y hets; watch the ~3.2% contamination.

### Prüfer 2018, *Bioinformatics* — **snpAD** (the caller behind all the above)
- Damage-aware diploid caller; **EM-like**: estimate genotype frequencies (ML, BOBYQA/nlopt) → call temporary genotypes → re-estimate a **position+orientation error profile** (15+15+interior) per library type → iterate. **Base qualities are deliberately NOT used inside the model** (merged reads rarely low-Q; BQ≥30 pre-filter only). Reports highest-likelihood genotype + GQ. **Coverage guidance:** ≥4× for genotype freqs, ≥6× for error rates, **≥15× for reference-bias**; <15× het transitions inflated → treat low-cov snpAD calls as approximate. Does **not** estimate contamination (reference-bias `r` is only an upper bound). ts/tv ≈ 2.06 (far fewer damage-driven false hets than GATK).

---

## Tier B — low-coverage (BAM-only → we compute genotype likelihoods; authors used pseudo-haploid)

### Hajdinjak et al. 2018, *Nature* — Goyet Q56-1 (2.2×), Les Cottés Z4-1514 (2.7×), Spy 94a (1.0×), Mezmaiskaya 2 (1.7×), Vindija 87 (1.3×)
- **Read proc:** Bustard/FreeIbis → **leeHom** → jivebunny demux → **BWA 0.5.10-evan `-n 0.01 -o 2 -l 16500`** → SAMtools 1.3.1 L>35, **MQ≥25** (chosen over MQ37 to keep deaminated endogenous reads). **Dedup:** `bam-rmdup 0.6.3` (consensus). **Damage:** mostly **non-UDG** (2 libraries UDG); **no trim/rescale** — instead **enrich for deaminated fragments** (C→T within first/last 3 positions; 2 for UDG libs) + strand-orientation filter + **transversions-only** downstream. **Calling:** **none** — **pseudo-haploid random single-read sampling** with **heffalump**, at sites L≥35/MQ≥25/BQ≥30/map35_100, min-depth 1, no max-depth. **Contam:** mt 0.5–5.1%, ML-nuclear 0.18–1.75%, qpAdm ~4% for Spy (→1% on deaminated). **Sex:** Les Cottés/Goyet/Vi87 female; Mez2/Spy male.
- **Reuse:** **no genotype calls exist** — start from ENA BAMs (PRJEB21870/21875/21883/21881/21882) and re-run. **Vindija 87 = the Vindija 33.19 individual** → for genotypes use the Vi 33.19 snpAD VCF instead.

### Slon et al. 2018, *Nature* — Denisova 11 "Denny" (F1 hybrid, ~2.6×)
- **Read proc:** leeHom → jivebunny → BWA aln (aDNA params per Meyer 2012) → SAMtools merge → L≥35, **MQ≥25**. **Dedup:** `bam-rmdup`. **Damage:** **non-UDG single-stranded**; transversions + strand-orientation + deaminated-subset handling. **Calling:** **no per-site diploid VCF** — snpAD used only for genome-wide **heterozygosity frequencies**; ancestry via **pseudo-haploid random 1–2 read draws** at transversion sites. **Contam:** nuclear 1.4%, Y 1.6%, mt 0.3–0.4% (≤1.7%). **Sex:** female.
- **Reuse:** reads only (ENA **PRJEB24663**); re-run; hybrid → expect ~50/50 Neanderthal/Denisovan allele matching.

### Peyrégne et al. 2019, *Sci. Adv.* — Hohlenstein-Stadel (~0.05×, male), Scladina I-4A (~0.02×, female) — early ~120 ka
- **Read proc:** Bustard → **leeHom** → Jivebunny → **BWA `-n 0.01 -o 2 -l 16500`** → **L≥30** (spurious-alignment <1%), MQ≥25, map35_L100. **Dedup:** `bam-rmdup` + `bam-mergeRef`. **Damage:** **non-UDG single-stranded**; **deamination filter is load-bearing** (≥1 C→T within 3 bp of ends) + strand-orientation filter. **Calling:** **none** — pseudo-haploid single random read; third alleles dropped; transversions for divergence. **Reference-bias correction** (dual hg19 + "Neandertalized" hg19) is essential. **Contam (critical):** raw = **22.9% (HST) / 64.8% (Scladina)**; **deamination-filtered = 2.0% / 5.5%** (the numbers used). **Sex:** HST male, Scladina female. **Coverage:** deaminated autosomal ~0.029× / 0.006×.
- **Reuse:** reads only (ENA **PRJEB29475**); expect **very few usable panel sites**; every result contingent on deamination + strand + reference-bias QC — do not skip.

---

## Tier C — excluded
### Castellano et al. 2014, *PNAS* — El Sidrón 1253 (exome-capture only)
- **Exome capture, coding + 100 bp flanks only — NO shotgun genome.** GATK UnifiedGenotyper v1.3, diploid; **El Sidrón called at GQ10** (12.5× exome → hom sites undercalled at GQ30). UDG+EndoVIII + terminal Q→2 masking. Endogenous **0.2%**; ~27 Mb / 17,367 genes. mt-contamination only (<1%); **no nuclear contamination estimate.**
- **Reuse:** exome VCF (`…/neandertal/exomes/`) usable only for coding-region SNPs; **most pigmentation SNPs are regulatory → expect ~none** → **excluded** from the genome-wide analysis (→ 14 analyzed).

---

## Modern reference
### Mallick et al. 2016, *Nature* — SGDP (our copy = cteam_remap to hs37d5)
- **Build:** hs37d5. **Read proc:** trimadap adapter-trim → **BWA-MEM 0.7.10** (paired) → **samblaster** dedup (inline). Modern PCR-free/PCR DNA — **no damage handling** (none needed). **Calling:** **GATK UnifiedGenotyper** (reference-bias-free **flat prior 0.4995/0.001/0.4995**), single-sample, EMIT_ALL_SITES, SNP-only, `-dcov 600`, `stand_call_conf 5`. **Ploidy: diploid throughout — Y/mtDNA/male-X NOT specially treated** (handle ourselves for uniparental/X work). **Masks:** universal mask (75-mer mappability + mDUST/RepeatMasker low-complexity + 1000G-aberrant regions; retains 87%) + per-sample CNV mask; **filter-level system FL 0–9** (level 1 default, level 9 strict, level 0 for pulldown). **No contamination estimate** (QC via Ti/Tv=2.02 + divergence-vector outlier removal 300→235). **Coverage:** median 42× (34–83×).
- **Reuse:** our `sgdp.wg` is this release → reuse per-sample calls via cTools at a chosen filter level (default 1); already hg19; **verify build (Q2) + apply the universal mask**; add contamination/damage only for the ancient samples we merge in.
