#!/usr/bin/env bash
# Reproduce every issue in plan.md §3.A. See BUG_EVIDENCE.md for expected output + verdicts.
#
# Usage:
#   cd sepia && bash plan/verify/verify_bugs.sh
#
# LOCAL checks run against committed repo data. CLUSTER checks need the authenticated
# ControlMaster socket up:  ssh -O check greatlakes   ->  "Master running"
# (UMich Great Lakes = Kerberos password + Duo; establish the socket once interactively.)
#
# NOTE: all cluster inspection is text-only (grep / ls / samtools view -H / bcftools view -H).
# Never cat/head a .bcf/.bam/.vcf.gz directly — that dumps binary and scrambles the terminal.

set -uo pipefail
B=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

hr(){ printf '\n========== %s ==========\n' "$1"; }

hr "ROOT CAUSE: panel is hg38, data is hg19 (LOCAL: panel build)"
echo "rs1426654/SLC24A5  hg38=15:48134288  hg19=15:48426484"
grep -E "48134288|48426484" data/snps.txt || true
for p in 6:396322 16:89919710 15:28120473 5:33951589; do
  grep -q "^${p}:" data/snps.txt && echo "$p present (hg38)"; done

hr "ROOT CAUSE (CLUSTER: reference build + SGDP monomorphism)"
ssh greatlakes "head -1 $B/reference/hs37d5.fa;
  awk 'NR>1{n++; if(\$5+0==0)z++} END{print \"pigmentation panel sites=\"n\"  ALT_FREQ==0: \"z}' \
    $B/pca/pigmentation/pigmentation_snps_freq.afreq"

hr "ROOT CAUSE (LOCAL: depth arm measures the hg38 coordinate)"
grep -E "^15[[:space:]]+48134288" data/vindija33_depth.txt || true

hr "A2: pigmentation PCA is rank-1; whole-genome PCA (same samples) is full-rank"
echo "-- pigmentation eigenvalues --"; cat data/pigmentation.pca.eigenval
echo "-- whole-genome eigenvalues (control) --"; cat data/sgdp.wg.pca.eigenval
echo "-- 221/222 SNPs have no minor allele + zero loadings --"
awk 'NR>1{n++; if($4=="."||$4=="")m++} END{print "rows="n" NONMAJ_missing="m}' data/pigmentation_snps_pca.eigenvec.var
echo "-- => all ancient samples project to identical pigmentation coords --"
head -4 data/ancient.projected.pig.sscore | cut -c1-90

hr "A1: Denisova 3 is the only chr-prefixed BAM"
ssh greatlakes "module load Bioinformatics samtools/1.21 >/dev/null 2>&1;
  echo D3:;   samtools view -H $B/results/filtered/filtered_Denisova3.bam | grep '^@SQ' | head -2;
  echo VI33:; samtools view -H $B/results/filtered/filtered_vindija33.bam | grep '^@SQ' | head -2"

hr "A3: --ploidy 1 on autosomes; genotypes are haploid"
ssh greatlakes "grep -nE 'ploidy|CHRS=' $B/ancient_wg.slurm;
  module load Bioinformatics bcftools >/dev/null 2>&1;
  bcftools view -H -r 1 $B/ancient_wholegenome/ancient_sgdp_wg.vcf.gz | head -3 | cut -f1,2,4,5,10-12"

hr "A4: two callers; the committed output has all 222 sites (NOT an active bug)"
ssh greatlakes "grep -nA1 'bcftools call' $B/pigmentation_ancient_call.slurm $B/pig_call_miss.slurm;
  module load Bioinformatics bcftools >/dev/null 2>&1;
  printf 'records in ancient_pigmentation.vcf.gz (panel=222): ';
  bcftools view -H $B/pca/pigmentation/ancient/ancient_pigmentation.vcf.gz | wc -l"

hr "A5: orphan glob + missing reference + dead output"
ssh greatlakes "ls $B/ancient_wholegenome/*.wg.vcf.gz 2>&1 | head -1;
  ls $B/ancient_wholegenome/*_wg.vcf.gz 2>&1 | head -1;
  ls $B/reference/;
  grep -n hg19.fa $B/pca_ancient.slurm;
  echo 'pca_snps used in:'; grep -ln pca_snps $B/*.slurm"

hr "DONE — compare against BUG_EVIDENCE.md"
