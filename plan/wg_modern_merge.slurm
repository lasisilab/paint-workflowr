#!/bin/bash
# =====================================================================================
# SEPIA — complete the MODERN SGDP reference merge (prerequisite for the genome-wide
# "where does everyone cluster" sanity PCA).
#
# WHY: pca/modern/sgdp.wg holds only 15 individuals, but 166 per-sample SGDP BCFs sit
# in sgdp/subsets/ (Lily's merge was left incomplete — see merge_continue.slurm). 15
# samples cannot define global structure. This finishes the merge Lily's
# sgdp_merge_pca.slurm intended (it globs *_sgdp.bcf), LD-prunes, and runs a
# projection-ready PCA (allele weights + allele freqs) so the pseudo-haploid archaics
# can later be PROJECTED onto it.
#
# Writes ONLY to $B/rebuild/wg_pca/ — nothing of Lily's is modified. Submit with:
#     sbatch plan/wg_modern_merge.slurm
# then read rebuild/wg_pca/modern_merge_<jobid>.log
# =====================================================================================
#SBATCH --job-name=sepia_modern_merge
#SBATCH --account=tlasisi0
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/rebuild/wg_pca/modern_merge_%j.log
set -uo pipefail

B=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data
SUB="$B/sgdp/subsets"          # 166 per-sample SGDP BCFs (*_sgdp.bcf)
W="$B/rebuild/wg_pca"          # fresh workspace
mkdir -p "$W"; cd "$W"

echo "===== SEPIA modern SGDP merge ====="; date; echo "workspace: $W"

# ---- toolchain (ARC modules; conda fallback) ---------------------------------------
module load Bioinformatics >/dev/null 2>&1 || true
module load bcftools/1.21   >/dev/null 2>&1 || module load bcftools >/dev/null 2>&1 || true
module load plink/2.0       >/dev/null 2>&1 || module load plink2   >/dev/null 2>&1 || true
PLINK2="$(command -v plink2 || command -v plink)"
echo "--- tools ---"; for t in bcftools plink2; do printf "%s: " "$t"; command -v "$t" || echo "(see PLINK2=$PLINK2)"; done
[ -n "$PLINK2" ] || { echo "!! plink2 not found"; exit 2; }

# ---- 1. gather the 166 per-sample SGDP BCFs ----------------------------------------
ls "$SUB"/*_sgdp.bcf > sgdp_bcf.list 2>/dev/null
N=$(wc -l < sgdp_bcf.list)
echo "===== 1. merge $N modern SGDP per-sample BCFs ====="
[ "$N" -ge 100 ] || { echo "!! only $N BCFs found (<100); aborting so we don't rebuild a partial ref"; exit 3; }

# ---- 2. merge (missing stays missing; do NOT use -0 which would fabricate 0/0) ------
bcftools merge -l sgdp_bcf.list --threads 8 -Ob -o merged_sgdp.bcf
bcftools index -f merged_sgdp.bcf
echo "  merged samples: $(bcftools query -l merged_sgdp.bcf | wc -l)"
echo "  merged sites  : $(bcftools index -n merged_sgdp.bcf)"

# ---- 3. BCF -> PLINK; set variant IDs to chr:pos:ref:alt (stable cross-dataset key) -
echo "===== 3. convert to PLINK (chr:pos:ref:alt IDs) ====="
"$PLINK2" --bcf merged_sgdp.bcf \
  --set-all-var-ids '@:#:$r:$a' --new-id-max-allele-len 100 missing \
  --max-alleles 2 --snps-only \
  --make-bed --out sgdp166
echo "  sgdp166 samples: $(wc -l < sgdp166.fam)   variants: $(wc -l < sgdp166.bim)"

# ---- 4. LD prune (same params as Lily's sgdp_merge_pca.slurm) -----------------------
echo "===== 4. LD prune (200 25 0.4) ====="
"$PLINK2" --bfile sgdp166 --indep-pairwise 200 25 0.4 --out sgdp166_prune
echo "  prune.in variants: $(wc -l < sgdp166_prune.prune.in 2>/dev/null || echo 0)"

# ---- 5. projection-ready PCA: allele weights + allele freqs -------------------------
echo "===== 5. PCA (10 PCs, allele-wts) + allele freqs ====="
"$PLINK2" --bfile sgdp166 --extract sgdp166_prune.prune.in \
  --freq --pca 10 allele-wts --threads 8 --out sgdp166_pca
echo "  eigenvec samples: $(tail -n +2 sgdp166_pca.eigenvec 2>/dev/null | wc -l)"
echo "  --- eigenvalues (want a clear PC1/PC2 gap, not a flat tail) ---"
cat sgdp166_pca.eigenval 2>/dev/null

echo "===== modern merge done ====="; date
echo "NEXT: reheader+intersect ancient_sgdp_wg -> project onto sgdp166_pca (no-mean-imputation),"
echo "      per-sample call-rate QC, then the ancient+modern cluster figure."
