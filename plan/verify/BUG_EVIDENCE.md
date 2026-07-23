# PAINT — Bug evidence log

Every issue in [`../plan.md`](../plan.md) §3.A, with the **exact commands to reproduce it** and the **actual output** observed on 2026-07-22. Verdicts are honest: one claim (A4) did **not** hold up and is downgraded here.

- **Local** commands run against the committed repo (`paint-workflowr/data/`).
- **Cluster** commands run over SSH against `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` (`B` below). They need the authenticated ControlMaster socket up (`ssh -O check greatlakes` → `Master running`); UMich requires Kerberos+Duo, so establish it once interactively.
- Runnable version of every command: [`verify_bugs.sh`](verify_bugs.sh).

```
B=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data
```

---

## ⓵ The root cause behind A2 (and it also hits the depth arm): hg38 panel vs hg19 data — **CONFIRMED**

**Claim.** The 222-SNP pigmentation panel is on **GRCh38/hg38**, but the reference genome and all sequence data (SGDP + archaic) are on **GRCh37/hg19**. So every pigmentation-SNP measurement is taken at the wrong coordinates.

**Reproduce — the panel is hg38** (local; rs1426654/SLC24A5 is hg38 15:48134288, hg19 15:48426484):
```bash
grep -E "48134288|48426484" data/snps.txt          # committed 222-SNP panel
# spot-check more canonical SNPs are all hg38:
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

**Consequence 1 — SGDP is monomorphic at the hg38 positions** (cluster; afreq built by `pig_pca.slurm`):
```bash
ssh greatlakes "awk 'NR>1{n++; if(\$5+0==0)z++} END{print \"sites=\"n\"  ALT_FREQ==0: \"z}' \
  $B/pca/pigmentation/pigmentation_snps_freq.afreq"
ssh greatlakes "head -3 $B/pca/pigmentation/pigmentation_snps_freq.afreq"
```
```
sites=222  ALT_FREQ==0: 221
#CHROM  ID           REF  ALT  ALT_FREQS  OBS_CT
6       6:396322     A    .    0          30      ← observed (OBS_CT=30) but no ALT allele
6       6:19996578   C    .    0          30
```
The sites are *observed* (all 15 diploid SGDP samples, OBS_CT=30) yet carry **no alternate allele** — impossible for genuinely variable pigmentation SNPs (SLC24A5, HERC2, …) across globally diverse humans, but exactly what you get reading hg38 coordinates against an hg19 genome. The lone polymorphic site (`15 rs76285708 T C 0.0667`) is the *only* thing PC1 has to work with.

**Consequence 2 — the depth arm measures the wrong loci too** (local):
```bash
grep -E "^15[[:space:]]+48134288" data/vindija33_depth.txt
```
```
15   48134288   19     ← depth 19 at the hg38 SLC24A5 coordinate, on an hg19 BAM
```
Real coverage, but ~292 kb from the true hg19 SLC24A5 SNP (48426484). So the per-SNP depth/missingness values (thesis Fig 5) are at shifted positions. *(Aggregate conclusions like "older samples miss more" may partly survive, since missingness tracks a sample's overall coverage; the per-locus / "pigmentation loci" framing does not.)*

**Verdict: CONFIRMED.** This is the single biggest issue and the reason [B2 (normalize to hg38)](../plan.md) is a correctness fix. Fix = put panel and data on the same build (lift data → hg38, or the panel → hg19), then re-run.

---

## A1 · Denisova 3 chromosome-naming mismatch — **CONFIRMED**

**Claim.** Denisova 3's BAM uses `chr`-prefixed contigs while every other sample, the reference, and the panels use bare names, so its extraction fails and it looks empty.

**Reproduce** (cluster):
```bash
ssh greatlakes "module load Bioinformatics samtools/1.21;
  echo D3:; samtools view -H $B/results/filtered/filtered_Denisova3.bam | grep '^@SQ' | head -2;
  echo VI33:; samtools view -H $B/results/filtered/filtered_vindija33.bam | grep '^@SQ' | head -2;
  echo BED:; head -1 $B/snps/snps.bed; head -1 $B/snps/snps.chr.bed"
```
```
D3:    @SQ  SN:chrM ...   @SQ  SN:chr1  LN:249250621     ← chr-prefixed (only sample that is)
VI33:  @SQ  SN:1 ...      @SQ  SN:2                       ← bare
BED:   6  19996577 ... (snps.bed, bare)   chr6  19996577 ... (snps.chr.bed, chr)
reference hs37d5.fa header: ">1 ... GRCh37"              ← bare
```
Denisova 3's mean depth over the panel is **0.5 / 222 SNPs covered = 69** vs Vindija 33.19's **30.7 / 222** (computed from `data/*_depth.txt`), and it sits in the sparse group of thesis Fig 5 despite being a high-coverage genome.

**Verdict: CONFIRMED.** Independent of the build issue above (this is why D3 *specifically* is empty). Fix = harmonize contig names / use the `chr`-aware reheader path already in `pca_ancient.slurm`, then re-run.

---

## A3 · Whole-genome ancient calling is haploid (`--ploidy 1`) on autosomes — **CONFIRMED**

**Reproduce** (cluster):
```bash
ssh greatlakes "grep -nE 'ploidy|CHRS=' $B/ancient_wg.slurm;
  module load Bioinformatics bcftools;
  bcftools view -H -r 1 $B/ancient_wholegenome/ancient_sgdp_wg.vcf.gz | head -3 | cut -f1,2,4,5,10-12"
```
```
64: CHRS=( {1..22} X Y )      ← autosomes included
83:     --ploidy 1 \
1  846808  C  T  0:0,255:27,0   .:0,0:0,0   0:0,67:2,0     ← GT is a single allele (haploid), never 0/1
```

**Verdict: CONFIRMED.** Autosomes are called haploid, so heterozygotes are never emitted. Confirm intent; for diploid autosomal genotypes this should not be `--ploidy 1`.

---

## A4 · "`bcftools call -mv` drops non-variant sites" — **DOWNGRADED (not an active bug)**

**Claim (as originally flagged).** The ancient pigmentation caller uses `-mv` (variants-only), dropping non-variant sites → ascertainment bias.

**Reproduce** (cluster):
```bash
ssh greatlakes "grep -nA1 'bcftools call' $B/pigmentation_ancient_call.slurm $B/pig_call_miss.slurm;
  module load Bioinformatics bcftools;
  bcftools view -H $B/pca/pigmentation/ancient/ancient_pigmentation.vcf.gz | wc -l"
```
```
pigmentation_ancient_call.slurm:  bcftools call -mv     ← variants-only
pig_call_miss.slurm:              bcftools call -c      ← keeps all sites ("low coverage mode")
records in ancient_pigmentation.vcf.gz: 222             ← FULL panel, nothing dropped
```

**Verdict: NOT AN ACTIVE BUG.** The committed output has all **222** sites, so the keep-all (`-c`) script is evidently the one used; the `-mv` script exists but did not produce the output. This is a **cleanup/clarity** item (two competing scripts — delete the unused one), not a defect in the data. *My earlier "ascertainment bias" framing was wrong for the committed output — corrected here.*

---

## A5 · Orphan / broken scripts — **CONFIRMED**

**Reproduce** (cluster):
```bash
ssh greatlakes "ls $B/ancient_wholegenome/*.wg.vcf.gz;      # ancient_merge.slurm's glob
  ls $B/ancient_wholegenome/*_wg.vcf.gz;                     # what actually exists
  ls $B/reference/;                                          # what pca_ancient.slurm needs
  grep -n hg19.fa $B/pca_ancient.slurm;
  grep -ln pca_snps $B/*.slurm"
```
```
ls: cannot access '.../ancient_wholegenome/*.wg.vcf.gz': No such file or directory   ← glob matches nothing
.../ancient_wholegenome/ancient_sgdp_wg.vcf.gz                                        ← real file is _wg, not .wg
reference/: hs37d5.fa  hs37d5.fa.fai                                                  ← no hg19.fa
pca_ancient.slurm:19: REF=".../reference/hg19.fa"                                     ← references a missing file
pca_ancient.slurm  (only match for pca_snps)                                          ← output used nowhere → dead code
```

**Verdict: CONFIRMED.** `ancient_merge.slurm`'s merge glob matches nothing (output is `ancient_sgdp_wg.vcf.gz`, suffix `_wg.vcf.gz`). `pca_ancient.slurm` references a missing `hg19.fa` (so it can't run) and its `pca_snps` output is referenced nowhere. Both are cleanup/deletion candidates.

---

## Summary

| ID | Claim | Verdict |
|---|---|---|
| ⓵ build | hg38 panel vs hg19 data → wrong coordinates (root cause of A2; also hits depth arm) | **CONFIRMED** |
| A1 | Denisova 3 chr-naming mismatch | **CONFIRMED** |
| A2 | Pigmentation PCA degenerate / rank-1 / identical projections | **CONFIRMED** (caused by ⓵) |
| A3 | `--ploidy 1` haploid autosomal calling | **CONFIRMED** |
| A4 | `-mv` drops non-variant sites | **DOWNGRADED** — output has all 222 sites; cleanup only |
| A5 | Orphan/broken scripts (`ancient_merge` glob; `pca_ancient` missing ref + dead output) | **CONFIRMED** |
