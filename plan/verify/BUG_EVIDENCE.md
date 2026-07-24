# SEPIA — Bug evidence log

Every issue in [`../plan.md`](../plan.md), with the **exact commands to reproduce it**, the **actual output** observed, **and — added 2026-07-23 — the downstream consequence** each error had on the analyses, figures, and conclusions. Verdicts are honest: one claim (A4) did **not** hold up and is downgraded; several bugs are shown to have had **no** downstream consequence, which is stated plainly.

- **Local** commands run against the committed repo (`sepia/data/`, `analysis/`, `docs/`).
- **Cluster** commands run over SSH against `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` (`$B`). They need the authenticated ControlMaster socket up (`ssh -O check greatlakes` → `Master running`); UMich requires Kerberos+Duo, so establish it once interactively.
- Runnable version of the replication commands: [`verify_bugs.sh`](verify_bugs.sh).

**On the consequence layer.** The "Downstream consequences" blocks were produced by tracing each bug *forward* to a concrete artifact — a degenerate distribution in a committed output, a genome effectively demoted in a figure, a model on shaky footing, or a sentence in the thesis — and then **adversarially re-deriving** each claim from the actual source. Every consequence is tagged **[DEMONSTRATED]** (visible in a committed file / R page / thesis), **[NONE]** (honestly, no effect — the conclusion survives), or **[LATENT]** (a real effect that can only be confirmed on the cluster). Thesis page numbers are the printed numbers.

```
B=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data
```

---

## ⓵ / A2 — hg38 panel vs hg19 data (build mismatch) — **CONFIRMED**

**Claim.** The 222-SNP pigmentation panel is on **GRCh38/hg38**, but the reference genome and all sequence data (SGDP + archaic) are on **GRCh37/hg19**. So every pigmentation-SNP measurement is taken at the wrong coordinates.

**Reproduce — the panel is hg38** (local; rs1426654/SLC24A5 is hg38 15:48134288, hg19 15:48426484):
```bash
grep -E "48134288|48426484" data/snps.txt          # committed 222-SNP panel
for p in 6:396322 16:89919710 15:28120473 5:33951589; do grep -q "^${p}:" data/snps.txt && echo "$p YES"; done
```
```
15:48134288::            ← hg38 SLC24A5 (NOT 48426484 = hg19)
6:396322 YES   16:89919710 YES   15:28120473 YES   5:33951589 YES   (all hg38)
```

**Reproduce — the reference/data is hg19** (cluster):
```bash
ssh greatlakes "head -1 $B/reference/hs37d5.fa"
```
```
>1 dna:chromosome chromosome:GRCh37:1:1:249250621:1     ← GRCh37 / hg19
```

**Reproduce — SGDP is monomorphic at the hg38 positions** (cluster; afreq built by `pig_pca.slurm`):
```bash
ssh greatlakes "awk 'NR>1{n++; if(\$5+0==0)z++} END{print \"sites=\"n\"  ALT_FREQ==0: \"z}' $B/pca/pigmentation/pigmentation_snps_freq.afreq"
```
```
sites=222  ALT_FREQ==0: 221     ← only 1 of 222 sites carries any variation
```

**Verdict: CONFIRMED.** The single biggest issue; the reason [B2 (normalize to hg38)](../plan.md) is a correctness fix.

**Downstream consequences (verified 2026-07-23):**
- **[DEMONSTRATED] The pigmentation PCA is rank-1 (degenerate).** `data/pigmentation.pca.eigenval` and `data/pigmentation_snps_pca.eigenval` are byte-identical: **PC1 = 0.0627529, PC2–PC10 = 2.9703e-18** (machine-epsilon zero). The whole-genome PCA on the same samples is full-rank (2.29579, 1.54548, … 0.95114). PC1/PC2 ratio: **~2×10¹⁶** (pigmentation) vs **1.49** (whole-genome). One informative axis, because 221/222 SNPs carry no variation.
- **[DEMONSTRATED] Only 1 of 222 SNPs contributes any signal.** In `data/pigmentation_snps_pca.eigenvec.var`, **221 rows are monomorphic** (`NONMAJ='.'`, all PC loadings exactly 0) and **only `15 rs76285708 T C` has a nonzero loading (PC1 = 14.8983)**. The canonical loci carry nothing — e.g. SLC24A5 at the hg38 coord `15 48134288 C .` is monomorphic with all-zero loadings. The entire pigmentation PCA is driven by one accidental, non-canonical SNP.
- **[DEMONSTRATED] Modern PC1 collapses to 3 discrete values.** `data/pigmentation_snps_pca.eigenvec` PC1 takes exactly `{-0.101265 (×11), -0.101718 (×2), 0.65822 (×2)}`. The two `0.65822` samples (SGDP `…F01`, `…B02`) are the rs76285708 alt-carriers the thesis labels **Bantu/Yoruba** — so the thesis's "PC1 differentiates Bantu and Yoruba" is a **one-SNP artifact**, not SLC24A5/HERC2 biology. (Whole-genome PC1 is continuous by contrast.)
- **[DEMONSTRATED] The depth arm measures 222 off-target positions.** `data/vindija33_depth.txt` has `15 48134288 19` (real depth at the **hg38** SLC24A5 coord); the true hg19 SLC24A5 coord `48426484` is **absent** from every depth file (`grep -c` = 0). So Fig 5's per-SNP depths are ~292 kb off the intended loci; the "pigmentation loci" framing of the heatmap is invalid. The specific locus the thesis names (p.27, "position 50456592 on chr22 missing in 11/14 samples") is likewise an hg38-on-hg19 off-target coordinate.
- **[DEMONSTRATED — thesis] It shaped the headline conclusions.** Fig 8 + §3.5 ("most populations fall closely near the origin … PC1 differentiates Bantu and Yoruba"; p.30) and the Discussion ("pigmentation may be influenced by a relatively small number of loci"; "archaic individuals fall nearer to African samples", p.32) are direct artifacts: "no structure" is guaranteed when 221/222 SNPs are dead, and the "small number of loci" is literally one accidental SNP. The thesis self-hedges once (p.32, "underrepresentation of African-specific variants in the SNP panel") — the closest it comes to noticing the panel is broken, but it misattributes the cause to panel *composition* rather than the *build mismatch*.
- **[NONE] The whole-genome PCA (Fig 7) is unaffected.** The ~34M-SNP whole-genome panel was derived from the SGDP data itself, so it is on the same hg19 build and produces a healthy full-rank PCA with clear continental structure. The Fig 7 (spread) vs Fig 8 (degenerate) contrast is itself a fingerprint of the build bug.
- **[NONE] The aggregate missingness conclusions survive.** "Older/low-coverage samples miss more" tracks each sample's genome-wide library quality, which is coordinate-independent (per-sample mean panel depth: Vindija33 30.7, Chagyrskaya8 27.4 vs hst 0.12, mez1 0.18) — so the direction of that result is not undermined by the off-target coordinates (it is separately confounded for Denisova 3 by A1, below).

---

## Projection collapse — ancient pigmentation PCA stacks all samples on one point — **CONFIRMED**

**Claim.** The PLINK2 `--score` projection of the archaic genotypes onto the modern pigmentation PCA produces a single point repeated for every sample.

**Reproduce** (local):
```bash
awk -F',' 'NR>1{print $5}' data/ancient.projected.pig.sscore | sort -u        # distinct PC1_AVG values
```
```
0.0335547        ← exactly ONE value for all 15 archaic samples
```

**Verdict: CONFIRMED.** Two compounding causes: (1) the near-monomorphic panel from the build bug (rank-1 substrate), and (2) the `--score` step mean-imputes missing genotypes to the reference-frequency mean without `no-mean-imputation`, so with high archaic missingness every sample maps to the reference centroid. Fix in [Q5](../plan.md): add `no-mean-imputation`, and harmonize the build (B2).

**Downstream consequences (verified 2026-07-23):**
- **[DEMONSTRATED] Zero per-sample resolution.** All 15 rows of `data/ancient.projected.pig.sscore` share `PC1_AVG=0.0335547` and identical PC2–PC10 (~1e-11), **despite differing inputs** (`NAMED_ALLELE_DOSAGE_SUM` = 444, 440, 443, 436, …). Different genotypes → byte-identical outputs. The **whole-genome** projection `data/ancient.projected.sgdp.sscore` does **not** collapse (15 distinct PC1 values), proving the defect is specific to the pigmentation panel.
- **[DEMONSTRATED — thesis] Fig 8 is a single stacked point.** The figure meant to show where each archaic falls in pigmentation space has no resolution: all archaic ×-marks pile up near the origin (left panel PC1≈0.03; right panel PC3/PC4 at ~(0,0), matching the file's `PC3=1.76e-11, PC4=9.33e-11`), with the "Neanderthal"/"Denisovan" labels overplotted at one location.
- **[DEMONSTRATED — thesis] A headline result rests on where that one point landed.** The abstract ("Archaic samples cluster … with Africans in a pigmentation panel", p.2), §3.5 (p.30) and Discussion (p.32) all derive from the single collapsed coordinate, not from per-sample projections.
- **[DEMONSTRATED] Even at face value the "near African" reading is fragile.** The collapsed point (0.0335547) is **4.6× closer** to the main modern cluster (|0.0336−(−0.1013)| = 0.135) than to the African outliers (|0.0336−0.6582| = 0.625) — a marginal +0.13 lean toward Africans with no per-sample support.
- **[DEMONSTRATED] The collapse also hides a sample-count discrepancy.** The projection contains a 15th sample, **`El_Sidron`**, that the thesis never mentions (it reports 14 archaics); because every point is identical, including/excluding it is invisible in Fig 8.
- **[NONE] Blast radius is bounded.** `grep` of `analysis/` shows the projection is consumed only by `pca.Rmd` (Fig 8) and a link in `index.Rmd`; `phenotypic_inference.Rmd` never reads it. The depth/missingness, consensus-accuracy, and phenotype-inference results are untouched.

---

## A1 — Denisova 3 chromosome-naming mismatch — **CONFIRMED**

**Claim.** Denisova 3's BAM uses `chr`-prefixed contigs while every other sample, the reference, and the panels use bare names, so its extraction fails and it looks empty.

**Reproduce** (cluster):
```bash
ssh greatlakes "module load Bioinformatics samtools/1.21;
  samtools view -H $B/results/filtered/filtered_Denisova3.bam | grep '^@SQ' | head -2;
  samtools view -H $B/results/filtered/filtered_vindija33.bam | grep '^@SQ' | head -2"
```
```
D3:    @SQ  SN:chrM ...   @SQ  SN:chr1 ...     ← chr-prefixed (only sample that is)
VI33:  @SQ  SN:1 ...      @SQ  SN:2 ...        ← bare (matches reference & panels)
```

**Verdict: CONFIRMED.** Independent of the build issue (this is why D3 *specifically* is empty). Fix = harmonize contig names (reuse the reheader in `pca_ancient.slurm`), then re-run.

**Downstream consequences (verified 2026-07-23):**
- **[DEMONSTRATED] A high-coverage genome recovers like a low-coverage one.** Recomputed from committed `data/*_depth.txt`: **Denisova 3 = mean 0.495×, 69/222 SNPs covered, max depth 6, 153 zero-depth sites** — sitting among the genuinely sparse samples (hst 0.12×/24, mez1 0.18×/37, spy 0.74×/75). Its true high-coverage peers: Vindija33 30.7× (222/222), Chagyrskaya8 27.4× (222/222), Denisova5 16.1× (222/222), Denisova25 16.7× (183/222). Denisova 3's file is the only non-empty depth file using `chr`-prefixed positions.
- **[DEMONSTRATED — thesis] Fig 5 misrepresents it, contradicting the thesis's own text.** In the log-depth heatmap (p.26) Denisova 3 is drawn in the top black/sparse band (row 4 from top), not with its high-coverage peers — while §1.6 / Table 3 classify Denisova 3 as one of the high-coverage genomes (the 30× Meyer-2012 reconstruction, explicitly distinguished from the 1.9× draft). The row order is reproducible from `depth.Rmd` (sort by missing-count ascending): computed top-to-bottom order matches the figure exactly. *(Caveat: the Table 3 grid did not render in the PDF; its high-coverage classification is verified via the caption + §1.6 prose.)*
- **[DEMONSTRATED] It is a mislabeled point in the whole-genome PCA (Fig 7).** In `data/ancient.projected.sgdp.sscore`, Denisova 3 has **ALLELE_CT = 289,122 (named-allele rate 0.765)** vs ~1.66M (rate 0.9997) for Vindija33/Denisova5/Chagyrskaya8 — below even the low-coverage Neanderthals. Its **PC1 = +0.0111**, sitting at the near-empty-sample attractor (Hohlenstein_Stadel ALLELE_CT=0 → PC1=+0.0165; El_Sidron 262 → +0.0165), **far from its true Denisovan peer Denisova25 (−0.0577)**. So it is projected as an empty sample, not with the other Denisovan.
- **[LATENT] The missingness regression is fed artifactual "missing" rows.** Denisova 3 contributes 222 SNP rows to the `glmer`, ~153 scored `Missing=1` artifactually (for a genome that, if correctly named, would be near-complete like its peers), with residual coverage concentrated on chr5/15/16 — chromosomes flagged significant in §3.2. The direction/size of the resulting bias on the age/chromosome effects **cannot be recomputed locally** (the assembled `ancient_depth_clean.csv` is not committed).
- **[NONE] No effect on the pigmentation PCA (Fig 8).** In `data/ancient.projected.pig.sscore` Denisova 3 has ALLELE_CT=444 (full 222×2) and the identical collapsed coordinate — the keep-all caller emits all 222 sites for every sample regardless of coverage, so A1 leaves no fingerprint there. Fig 8's degeneracy is the build bug, not A1.

---

## A3 — Whole-genome ancient calling is haploid (`--ploidy 1`) on autosomes — **CONFIRMED**

**Reproduce** (cluster):
```bash
ssh greatlakes "grep -nE 'ploidy|CHRS=' $B/ancient_wg.slurm;
  module load Bioinformatics bcftools;
  bcftools view -H -r 1 $B/ancient_wholegenome/ancient_sgdp_wg.vcf.gz | head -3 | cut -f1,2,4,5,10-12"
```
```
64: CHRS=( {1..22} X Y )      ← autosomes included
83:     --ploidy 1 \
1  846808  C  T  0:0,255:27,0   .:0,0:0,0   0:0,67:2,0     ← GT is a single allele, never 0/1
```

**Verdict: CONFIRMED.** Autosomes are called haploid, so heterozygotes are never emitted.

**Downstream consequences (verified 2026-07-23):**
- **[DEMONSTRATED] A ploidy mismatch is baked into the committed projection.** `data/ancient.projected.sgdp.sscore` scores the haploid-called archaics (high-coverage ALLELE_CT ~1.66M) against a PCA basis built from **15 diploid** SGDP moderns (`data/sgdp.wg.pca.eigenvec`), whose allele frequencies used to center/standardize the projection are diploid (2p). Haploid dosages scored against a diploid reference frame — a genuine, committed methodological inconsistency.
- **[LATENT] Half the autosomal genotype information is discarded.** Every true archaic heterozygote is emitted as a single allele, so ~half the autosomal information never reaches the PCA. Directly visible only in the cluster WG VCF: `bcftools view -H -r 1 $B/…/ancient_sgdp_wg.vcf.gz | cut -f10- | grep -cE '0[/|]1|1[/|]0'` → expect **0** heterozygous calls.
- **[NONE] The whole-genome PCA conclusion survives.** Despite haploid calling, the WG projection is non-degenerate and the high-coverage archaics land unambiguously on the non-African side of PC1 (Chagyrskaya8 −0.061, Denisova5 −0.061, Vi33.19 −0.060, Denisova25 −0.058; three African moderns at +0.48/+0.59/+0.46) — exactly as §3.4 states. An honest "conclusion survives" (contrast the pigmentation arm, which the build bug rendered fully degenerate).
- **[LATENT] The ploidy-specific displacement can't be isolated locally.** Archaic WG PC1 is dominated by coverage-driven shrinkage (`r(ALLELE_CT, PC1) = −0.995`; empty samples share one attractor), so the ploidy contribution's direction is ambiguous from committed files. Resolving it needs the cluster (`plink2 --geno-counts` on the ancient bed; compare the pruned-panel SNP count to max ALLELE_CT 1,660,220).
- **[NONE] No spillover to Fig 8, the modern-heterozygosity boxplots, or the phenotype page.** The pigmentation calls are diploid (ALLELE_CT=444); the intro heterozygosity plot uses precomputed modern metadata; the phenotype page is a pure `rbinom` simulation with no real archaic genotypes.

---

## A4 — "`bcftools call -mv` drops non-variant sites" — **DOWNGRADED (not an active bug)**

**Reproduce** (cluster):
```bash
ssh greatlakes "grep -nA1 'bcftools call' $B/pigmentation_ancient_call.slurm $B/pig_call_miss.slurm;
  module load Bioinformatics bcftools;
  bcftools view -H $B/pca/pigmentation/ancient/ancient_pigmentation.vcf.gz | wc -l"
```
```
pigmentation_ancient_call.slurm:  bcftools call -mv     ← variants-only
pig_call_miss.slurm:              bcftools call -c      ← keeps all sites
records in ancient_pigmentation.vcf.gz: 222             ← FULL panel, nothing dropped
```

**Verdict: NOT AN ACTIVE BUG.** The committed output has all 222 sites, so the keep-all (`-c`) script is the one used. Cleanup only (delete the unused `-mv` script).

**Downstream consequences (verified 2026-07-23):**
- **[NONE] Nothing traces to the `-mv` path.** Every row of `data/ancient.projected.pig.sscore` has **ALLELE_CT = 444 = 2 × 222** (confirmed against `data/snps.txt` = 222 SNPs and `pigmentation_snps_pca.eigenvec.var` = 222 variants). Had the variants-only output been used, ALLELE_CT would be a small fraction of 444. The thesis methods (§2.3, p.22) also describe the keep-all rationale ("without depth filtering in order to maximize retention of loci") — the opposite of `-mv`.
- **[LATENT] Cleanup risk only.** If a future re-run invoked the orphan `-mv` script, the ancient VCF would carry <222 sites with a sample-dependent site set and lost hom-ref genotypes, distorting the projection. No current committed artifact reflects this — delete the unused script.

---

## A5 — Orphan / broken scripts — **CONFIRMED**

**Reproduce** (cluster): `ancient_merge.slurm`'s glob `*.wg.vcf.gz` matches nothing (real file is `ancient_sgdp_wg.vcf.gz`); `pca_ancient.slurm` references a missing `reference/hg19.fa` and its `pca_snps` output is used nowhere.

**Verdict: CONFIRMED.** Both are cleanup/deletion candidates.

**Downstream consequences (verified 2026-07-23):**
- **[NONE] Neither dead script touched any result.** `ls data | grep -iE 'ancient_wholegenome|pca_snps'` → nothing. The whole-genome projection that reached Fig 7 (`data/ancient.projected.sgdp.sscore`, WG-scale counts e.g. Chagyrskaya8 ALLELE_CT 1,660,220) came from the live `ancient_wg.slurm`, not the dead merge; the WG-PCA axes came from `modern_pca.slurm` (`data/sgdp.wg.pca.eigenvec` = 15 moderns), not `pca_ancient.slurm`. No `.Rmd` references any dead-script output (`grep` of `analysis/` = 0 hits).
- **[LATENT — note] The one useful thing lost:** `pca_ancient.slurm` contains the correct `chr`-name reheader logic that would fix Denisova 3 (A1) — but being dead code it was never wired in. (Denisova 3's under-recovery is caused by A1 itself, not by this script's deadness.)

---

## A6 — website prose / link / license / reproducibility — **CONFIRMED (reader-facing)**

Consequences confined to the published workflowr site (they did **not** propagate into the thesis, which is correct):
- **[DEMONSTRATED] Wrong, self-contradicting panel size.** `analysis/introduction.Rmd:284` (and `docs/introduction.html`) tell readers the panel is **"395 SNPs"**; the thesis says **222** (Fig 8, and pp.5/20/22) and the bar chart directly beneath the sentence plots ~226 unique SNPs. `data/snps.txt` = 222. (Origin of 395: the raw `data/skin_pigmentation.tsv` has 396 rs-prefixed rows / 226 unique rsIDs — 395 is a stale raw-association count, not the analysis panel.) "395" appears nowhere in the thesis.
- **[DEMONSTRATED] Broken "View genetic PCAs" link.** `analysis/index.Rmd:25` links to `analysis.html`, a stale orphan build artifact with no source `.Rmd`; the live page is `pca.html` (per `_site.yml` navbar). Serves outdated content today; 404s on a clean rebuild.
- **[DEMONSTRATED] Unsupported license grant.** `LICENSE` is **0 bytes**, yet `analysis/license.Rmd` (and `docs/license.html`) assert MIT and point readers to "the `LICENSE` file". The repo carries no actual license text. (`CITATION.cff` does exist, 418 B, so that reference is fine.)
- **[DEMONSTRATED] The committed site is not reproducible.** `.gitignore:48` excludes all `*.csv`, and the derived CSVs are only ever written to hardcoded `/Users/lilyheald/…` paths outside the repo (`cleaning.Rmd:12/25/43`, `process_links.R:2-3`). So `git ls-files` shows **zero** tracked CSVs, and every page reading a derived CSV errors on rebuild — `introduction.html` (`pigmentation_snps.csv`, `neo_uvi.csv`), `pca.html` (`modern_metadata.csv`), `depth.html` (`ancient_depth_clean.csv`); `cleaning.Rmd` even reads its input via a nonexistent absolute path.

---

## Depth missingness model — redundant random effect, stale prose, unseeded MC — **CONFIRMED (with corrections)**

`analysis/depth.Rmd` fits `glmer(Missing ~ factor(Chromosome) + age_scaled + (1|Coverage) + (1|Sample))`.

**Downstream consequences (verified 2026-07-23):**
- **[DEMONSTRATED — corrects the original hypothesis] Not a singular fit; a 2-group variance instead.** The rendered summary (`docs/depth.html`) shows **no** singular-fit warning. But `Coverage` is a **2-level** grouping (`groups: Sample, 13; Coverage, 2`), and its random-intercept variance (**13.01**, from just 2 groups → statistically unidentifiable) **dwarfs** the Sample variance (0.99). So the defect is a degenerate 2-tier variance component, not the collinear-with-Sample singularity first suspected. *(This corrects the earlier "Coverage is per-sample → singular fit" framing.)*
- **[DEMONSTRATED] The prose reports a different model than the page runs.** `depth.Rmd` prose says "age β=1.34 … Chromosome β=−0.02, p=0.03", but the page's `factor(Chromosome)` model yields `age_scaled = 1.360` and **20 separate** chromosome coefficients (none = −0.02, no omnibus p=0.03). The prose numbers match the *other* (numeric-Chromosome) model in the `depth_spinoff` page exactly (`Chromosome −0.019465, p=0.0277`; `age_scaled 1.3356`) — the narrative is borrowed from a model the page doesn't fit.
- **[DEMONSTRATED — thesis] chr5 is over-stated.** The thesis (p.27) lists the chromosome effect as significant for "5, 7, 9, 13, 15, 16, 22", but in the committed factor model **chr5 is p=0.094 (not significant)**; the other six are. The odds ratio (3.9×) matches `exp(1.360)=3.895`, confirming the thesis used the factor model where chr5 is marginal.
- **[LATENT] The "older samples miss more" result rests on n=13.** `Number of obs: 2886, groups: Sample, 13` (= 13×222) — one of the 14 samples in Fig 5 is silently absent from the model; the 2-tier Coverage effect absorbs most between-group variance; and `Missing` is scored at off-target hg38 coordinates (the build bug). The age→missingness *direction* is stable (1.36 factor / 1.34 numeric) so the qualitative headline survives, but the exact OR and its p<0.001 are fragile at 13 units.
- **[NONE — corrects the workbook] The unseeded Monte Carlo has no effect on the figure.** Although `depth.Rmd` has no explicit `set.seed`, `_workflowr.yml` sets `seed: 20251106` and workflowr injects it before knitting (the "Seed: set.seed(20251106)" banner is in `docs/depth.html`), and no chunk before the Monte Carlo consumes RNG — so Fig 6 is reproducible as built (and with n_sim=1000 the MC standard error is ~±0.01 anyway). *(This corrects the workbook note that the figure "changes each render".)*

---

## `subset_sgdp` region-string bug + 1-based/0-based coordinate split — **CONFIRMED (latent — no reached-result impact shown)**

From `pipeline_workbook.md`: `subset_sgdp.slurm` writes `CHR:from-to` region *strings* then feeds them to `bcftools view -R FILE` (which parses only tab-delimited `CHROM/POS` or BED); separately `sgdp.snps.pos` is used 1-based in one script but converted to 0-based BED in another.

**Downstream consequences (verified 2026-07-23):**
- **[NONE, on the reported results] The reported WG PCA is healthy.** A `CHR:from-to` regions file passed to `-R` would read each line as a nonexistent contig → ~0 records → an empty panel and no PCA. But `data/sgdp.wg.pca.eigenvec` has 15 well-spread rows and `eigenval` declines monotonically (2.296 → 0.951) — a real structure — so the region-string bug did **not** produce the panel behind Fig 7.
- **[NONE] No fatal coordinate offset on the reported path.** The ancient WG projection matches millions of sites by `chr:pos` ID (high-coverage ALLELE_CT ~1.66M); a systematic 1-bp shift would drive matched sites to ~0 and collapse every sample — not observed. Collapse occurs only for genuinely empty samples (missing-coverage-driven, not offset-driven).
- **[LATENT] Unresolved branch-identity question.** The committed WG eigenvec has exactly **15 rows**, matching the 15-sample Approach-B branch (`sgdp_merge/`, where the buggy `subset_sgdp.slurm` lives) rather than the 279-sample Approach A. If the Fig 7 panel actually came from `subset_sgdp`'s output, the region-string bug determined its site content — yet the PCA is healthy, implying either `bcftools` tolerated the strings or a corrected subset ran. **Cannot be resolved from committed files** (no WG panel VCF or SLURM log is committed). Cluster check: `bcftools view -H sgdp_wholegenome.snps.vcf.gz | wc -l` vs `wc -l snps/sgdp.bim`, plus file timestamps to identify the true PCA input.
- **[NONE] No effect on the depth arm or Fig 8.** The depth step reads the 222-SNP pigmentation BED (every `*_depth.txt` has 222 rows), not the WG regions file; and `subset_sgdp`'s pigmentation branch uses a properly tab-delimited BED, so the region-string bug never touched the pigmentation panel (Fig 8's degeneracy is the build bug).

---

## Summary

| ID | Claim | Verdict | Worst demonstrated downstream consequence |
|---|---|---|---|
| ⓵ / A2 build | hg38 panel vs hg19 data → wrong coordinates | **CONFIRMED** | Rank-1 pigmentation PCA; 221/222 SNPs dead; Fig 8 + abstract conclusions are one-SNP artifacts |
| projection collapse | `--score` mean-imputation + rank-1 panel | **CONFIRMED** | All 15 archaics identical in Fig 8; "cluster with Africans" rests on one collapsed point |
| A1 | Denisova 3 chr-naming mismatch | **CONFIRMED** | A 30× genome recovers at 0.5×/69-of-222; misplaced in Figs 5 & 7 vs its own Table 3 class |
| A3 | `--ploidy 1` haploid autosomal calling | **CONFIRMED** | Haploid archaics scored on a diploid basis; WG-PCA conclusion nonetheless survives |
| A4 | `-mv` drops non-variant sites | **DOWNGRADED** | **None** — committed output has all 222 sites (ALLELE_CT=444) |
| A5 | Orphan/broken scripts | **CONFIRMED** | **None** — no committed artifact or figure traces to them |
| A6 | Website prose/link/license/reproducibility | **CONFIRMED** | "395 SNPs" mislabel; empty LICENSE; site cannot rebuild (missing CSVs) |
| depth model | Redundant RE, stale prose, unseeded MC | **CONFIRMED** | Coverage variance from 2 groups; prose/thesis over-state chr5; MC is actually seeded |
| subset/coord | `-R` region-string + 1/0-based split | **CONFIRMED (latent)** | No shown impact on reported results; branch identity unresolved without the cluster |
