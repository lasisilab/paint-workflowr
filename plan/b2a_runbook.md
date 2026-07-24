# B2a runbook — put the pigmentation panel on hg19 (the fast, lossless build fix)

**Goal.** Fix the root bug (A2) the cheap way: the sequence data is already on **hg19**, so move the **222-SNP pigmentation panel** from hg38 → hg19 (instead of migrating 110 GB of data). In the same pass, fix Denisova 3's contig naming (**A1**) and the projection collapse (add `no-mean-imputation`, the **Q5** fix), then re-run the pigmentation arm — depth, PCA, projection — and regenerate the **after** figures for the before/after comparison. This validates the entire pigmentation story on the build the data already uses, at trivial compute.

> Scope note: B2a is the **integrity fix + before/after**. The heavier **B2b** (migrate the data up to hg38) is a *separate* later job, needed only when we bring in the four hg38 datasets (B1/B3/B4). B2a does **not** require B2b.

---

## 1. What I need from you

### 1.1 Cluster access (the one real dependency)
Everything heavy runs on Great Lakes. I do **not** need — and will not accept — your UMich password or Duo code. The safe mechanism (the one that worked earlier this session):

- **You** open an authenticated session in a terminal I can reach: `ssh greatlakes` (UMich Kerberos + Duo). That creates a reusable **ControlMaster socket**; while it's open I can run the commands/SLURM jobs below through it, and you stay in control of the credentials.
- **Or**, if you'd rather not share a live session: I hand you the finished SLURM script (below) and the exact commands, **you** submit them, and paste back the small text outputs (eigenvalues, QC counts, depth summaries). That's enough for me to verify and to build the after-figures.

Either way works. Tell me which you prefer.

### 1.2 Confirm these cluster parameters (fill in / correct)
These are not secrets — you can just confirm or edit this table and I'll bake them into the script.

| Parameter | Value I'll assume | Confirm / correct |
|---|---|---|
| SLURM account | `tlasisi0` | ? |
| Partition | `standard` | ? |
| Working dir (`$B`) | `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` | ? |
| Scratch | `/scratch/tlasisi_root/tlasisi0/lheald` | ? |
| Reference (hg19) | `$B/reference/hs37d5.fa` | ? |
| Archaic BAMs | `$B/results/sorted/*_sorted.bam` (+ Denisova 3) | ? |
| SGDP reference to use | the **15-sample** merged VCF `$B/sgdp_merge/sgdp_merged.vcf.gz` (matches the thesis's committed PCA) | ? |
| Modules | `Bioinformatics samtools/1.21 bcftools`, `plink/2.0`, `UCSC-utilities` (for `liftOver`) | ? |
| Internet on login node | yes (to fetch the UCSC chain file once) | ? |

### 1.3 Two small decisions (I have defaults; override if you like)
- **Lift method.** Default: `liftOver` the 222 coordinates with the UCSC `hg38ToHg19` chain (offline once the chain is downloaded), **and** cross-check a sample by rsID against dbSNP. *(Alternative: re-pull every hg19 coord by rsID from dbSNP and store both builds — more robust but needs dbSNP access. Recommended as a follow-up, not a blocker.)*
- **Depth quality filter.** The original `samtools depth` used **no** `-q/-Q` filter. Default for B2a: run it **both** ways — raw (to match the thesis exactly for a clean before/after) **and** with `-q 30 -Q 30` (the correct definition) — and report the difference. Override if you want only one.

### 1.4 Not required from you
No datasets. The hg19 BAMs, the panel, and the SGDP data are all already on the cluster; the UCSC chain file and any dbSNP lookups are public. Lily/Yemko don't need to produce anything for B2a. (The A1 "was Denisova 3 naming accidental?" and A3 "was `--ploidy 1` intentional?" questions are courtesy confirmations for the write-up — they do **not** block B2a, and A3 doesn't even touch the pigmentation arm.)

---

## 2. Compute resources

**B2a is light.** Every step is restricted to the 222 panel positions — there is no whole-genome operation. A single modest batch job covers the whole thing:

```bash
#!/bin/bash
#SBATCH --job-name=sepia_b2a
#SBATCH --account=tlasisi0
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=b2a_%j.log
```

| Resource | Ask | Why |
|---|---|---|
| Cores | 8 (most steps use 1–4) | `bcftools`/`plink2` threading on the SGDP subset |
| Memory | 32 GB (generous) | peak is the SGDP subset/merge + plink; realistically < 8 GB |
| Walltime | 2 h (generous) | most steps run in seconds–minutes; the SGDP subset is the only I/O-bound one |
| Scratch/disk | ~5 GB | panel VCFs + per-sample intermediates (the big BAMs already exist) |
| GPU / large-mem node | none | nothing here needs them |

If the SGDP genotypes must be re-subset from the 279 per-sample VCFs instead of the merged 15-sample VCF, make it a small `--array=1-279%20` job (each task is tiny, region-restricted) — still light, just more tasks. For the controlled before/after I recommend the **15-sample** merged VCF, which is a single fast subset.

**Bottom line:** you don't need to reserve anything special — one standard node, ~8 cores, ~32 GB, ~2 h, is comfortably more than enough.

---

## 3. Step-by-step

`$B` = working dir (§1.2). Run from `$B` on a compute node unless noted.

### Step 0 — Setup & provenance baseline (Q1 slice, Q10a)
```bash
module load Bioinformatics samtools/1.21 bcftools
module load plink/2.0
# record versions (Q10a)
samtools --version | head -1;  bcftools --version | head -1;  plink2 --version
# locate & characterise the panel BED that fed the original run (Q1)
ls -l /home/lheald/gwas_loci/snps.bed && head -3 /home/lheald/gwas_loci/snps.bed
```

### Step 1 — Lift the panel hg38 → hg19 (the fix)
Build the hg38 BED from the committed panel, add the `chr` prefix UCSC needs, lift, then strip `chr` back to the bare naming the data uses.
```bash
# 1a. hg38 BED from data/snps.txt  (format 'chr:pos::' -> chr, pos-1, pos, chr:pos)
#     (copy data/snps.txt to the cluster, or regenerate from the repo)
awk -F: 'NR>1{printf "chr%s\t%d\t%d\t%s:%s\n",$1,$2-1,$2,$1,$2}' snps.txt > panel.hg38.bed

# 1b. fetch the chain once (login node) and lift
wget -nc https://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/hg38ToHg19.over.chain.gz
liftOver panel.hg38.bed hg38ToHg19.over.chain.gz panel.hg19.chr.bed panel.unmapped.bed

# 1c. strip 'chr' -> bare names (match hs37d5 / the BAMs); make a clean 3-col + id BED
sed 's/^chr//' panel.hg19.chr.bed | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$4}' > snps.hg19.bed

echo "mapped: $(wc -l < snps.hg19.bed) / 222   unmapped: $(grep -vc '^#' panel.unmapped.bed)"
```
**Q2 gate — tracer SNP must now be hg19:**
```bash
# SLC24A5 rs1426654: hg19 = 15:48426484, hg38 = 15:48134288
grep -P '^15\t4842648' snps.hg19.bed && echo "OK: SLC24A5 on hg19" || echo "FAIL: tracer not on hg19"
```
Also spot-check ~5 rsIDs by cross-referencing `data/skin_pigmentation.tsv` (rsID ↔ coordinate) against dbSNP hg19 if internet is available.

### Step 2 — Fix Denisova 3 contig naming (A1)
Reheader once, upstream, so both depth and calling use bare names.
```bash
D3=$B/results/sorted/Denisova3_sorted.bam
samtools view -H "$D3" | sed -E 's/SN:chr([0-9XYMT]+)/SN:\1/' > d3.hdr.sam
samtools reheader d3.hdr.sam "$D3" > $B/results/sorted/Denisova3_sorted.rehdr.bam
samtools index $B/results/sorted/Denisova3_sorted.rehdr.bam
# sanity: header now bare
samtools view -H $B/results/sorted/Denisova3_sorted.rehdr.bam | grep -m2 '^@SQ'
```

### Step 3 — Re-extract panel depth on hg19 (all 15 archaics)
```bash
mkdir -p depth_hg19
for bam in $B/results/sorted/*_sorted*.bam; do
  s=$(basename "$bam" | sed 's/_sorted.*//')
  samtools depth -a -b snps.hg19.bed          "$bam" > depth_hg19/${s}.raw.txt      # matches thesis
  samtools depth -a -b snps.hg19.bed -q30 -Q30 "$bam" > depth_hg19/${s}.q30.txt     # correct definition
done
# quick per-sample summary (mean depth, covered/222)
for f in depth_hg19/*.q30.txt; do
  awk -v s="$f" '{n++;sum+=$3;if($3>0)c++} END{printf "%s\t%.2f\t%d/%d\n",s,sum/n,c,n}' "$f"
done
```
**Q6 gate:** Denisova 3 should now be in the high-coverage band (≫0.5×) alongside Vindija 33.19 / Chagyrskaya 8.

### Step 4 — SGDP moderns at the hg19 panel + reference PCA (with allele weights)
```bash
mkdir -p pca_hg19 && cd pca_hg19
# 4a. subset the 15-sample SGDP merged VCF to the hg19 panel
bcftools view -R ../snps.hg19.bed -m2 -M2 -v snps -Oz \
  -o sgdp.pig.hg19.vcf.gz $B/sgdp_merge/sgdp_merged.vcf.gz
tabix -p vcf sgdp.pig.hg19.vcf.gz
# 4b. PLINK: make-pgen, deterministic IDs, dedup, biallelic
plink2 --vcf sgdp.pig.hg19.vcf.gz --set-all-var-ids '@:#:$r:$a' \
  --rm-dup force-first --max-alleles 2 --make-pgen --out sgdp.pig.hg19
# 4c. reference allele freqs + PCA with per-allele weights (the projection basis)
plink2 --pfile sgdp.pig.hg19 --freq --out sgdp.pig.hg19.freq
plink2 --pfile sgdp.pig.hg19 --read-freq sgdp.pig.hg19.freq.afreq \
  --pca 10 allele-wts --out sgdp.pig.hg19.pca
```
**Q4 gate (allele/REF sanity):** for each retained SNP, assert the reference base equals the panel/VCF REF (`samtools faidx $B/reference/hs37d5.fa <chr:pos>`), count ref/alt swaps and palindromes.
**Q5 gate (non-degeneracy):** `cat sgdp.pig.hg19.pca.eigenval` should now show **several** non-zero eigenvalues (not one), i.e. the panel is polymorphic on the correct coordinates.

### Step 5 — Call archaic genotypes at the hg19 panel + project (Q5 fix)
```bash
# 5a. keep-all diploid calls at the hg19 panel across the 15 archaic BAMs
#     (use the reheadered Denisova 3 from Step 2)
BAMS=$(ls $B/results/sorted/*_sorted*.bam | grep -v 'Denisova3_sorted.bam'; echo $B/results/sorted/Denisova3_sorted.rehdr.bam)
bcftools mpileup -f $B/reference/hs37d5.fa -R ../snps.hg19.bed -q30 -Q30 -Ou $BAMS \
  | bcftools call -c -Oz -o ancient.pig.hg19.vcf.gz
plink2 --vcf ancient.pig.hg19.vcf.gz --set-all-var-ids '@:#:$r:$a' \
  --rm-dup force-first --max-alleles 2 --make-bed --out ancient.pig.hg19
# 5b. PROJECT with no-mean-imputation (THE Q5 fix) + variance-standardize
plink2 --bfile ancient.pig.hg19 --read-freq sgdp.pig.hg19.freq.afreq \
  --score sgdp.pig.hg19.pca.eigenvec.allele 2 5 header-read no-mean-imputation \
          ignore-dup-ids list-variants --score-col-nums 6-15 --variance-standardize \
  --out ancient.pig.hg19.projected
```
**Q5 gate (projection spread):** `ancient.pig.hg19.projected.sscore` PC1 must now vary across samples (`sd(PC1) > 0`, not one repeated value).

### Step 6 — QC summary (the gates, one place)
Emit a small table: tracer build (Q2), mapped/unmapped panel SNPs, REF-base mismatches + palindromes (Q4), eigenvalue spectrum (Q5), per-sample covered/222 with Denisova 3 flagged (Q6). This is the acceptance evidence that B2a worked.

### Step 7 — After-figures + commit
Pull the corrected outputs to the laptop into `data/after/` (or overwrite with a git branch), then:
```bash
# rename to the names the figure script expects, or point it at data/after/
Rscript plan/figures/make_consequence_figures.R after
```
Commit `plan/figures/after_*.png` and add them beside the `before_*.png` in the HTML's Before/after section. Done: a real before → after comparison for coverage, projection, and scree.

---

## 4. Acceptance criteria (B2a is "done" when all pass)
- [ ] **Q2** — tracer rs1426654 resolves to hg19 `15:48426484`; naming consistent; lint exits 0.
- [ ] **Q4** — 0 REF-base mismatches on retained SNPs; palindromes flagged; funnel reported.
- [ ] **Q5** — pigmentation eigenvalues are multi-dimensional (not rank-1); projected archaic PC1 has non-zero spread; `no-mean-imputation` present.
- [ ] **Q6** — Denisova 3 recovers in the high-coverage band (not 0.5×).
- [ ] **after-figures** rendered and visibly different from `before_*.png` (coverage: Denisova 3 up; projection: archaics spread; scree: multiple components).

## 5. What B2a does NOT cover (tracked elsewhere)
- The four hg38 datasets / gene-level PCA / directional score → need **B2b** (data → hg38) first; see `plan.md` §4 B2 / Phase 4.
- Whole-genome positive control (Q3), sample identity/sex/contamination (Q7), damage (Q8) → Phases 2–3, independent of B2a.
