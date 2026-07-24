#!/bin/bash
# =====================================================================================
# SEPIA — complete the MODERN SGDP reference merge (prerequisite for the genome-wide
# "where does everyone cluster" sanity PCA).
#
# WHY: Lily's pca/modern/sgdp.wg holds only 15 individuals, but 166 per-sample SGDP
# BCFs sit in her sgdp/subsets/ (her merge was left incomplete — see merge_continue.slurm).
# 15 samples cannot define global structure. This finishes that merge, LD-prunes, and
# runs a projection-ready PCA (allele weights + allele freqs) so the pseudo-haploid
# archaics can later be PROJECTED onto it.
#
# LAYOUT (repo-is-workdir): run from the SEPIA cluster checkout. Big outputs go to the
# gitignored resources/ + scratch/; only the small PCA coords go to output/ (tracked,
# synced). Lily's folder is READ once (SRC) and never modified. Submit from the checkout:
#     cd /nfs/turbo/lsa-tlasisi1/sepia && sbatch code/wg_modern_merge.slurm
# =====================================================================================
#SBATCH --job-name=sepia_modern_merge
#SBATCH --account=tlasisi0
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/nfs/turbo/lsa-tlasisi1/sepia/scratch/sepia_modern_merge_%j.log
set -uo pipefail

REPO="${SEPIA_REPO:-/nfs/turbo/lsa-tlasisi1/sepia}"        # the cluster checkout (this repo)
GENOMES="${SEPIA_GENOMES:-/nfs/turbo/lsa-tlasisi1/genomes}" # SHARED lab genomes (reusable across projects)
SRC=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data        # Lily's data — READ once to seed SEPIA
SUB="$SRC/sgdp/subsets"                                     # 166 per-sample SGDP BCFs (*_sgdp.bcf)
RES="$GENOMES/SGDP"                                         # completed modern SGDP reference (shared, reusable)
SCR="$REPO/scratch/modern_merge"                            # big intermediates (gitignored)
OUT="$REPO/output/pca_wg"                                   # small synced results (tracked, in repo)
mkdir -p "$RES" "$SCR" "$OUT"; cd "$SCR"

echo "===== SEPIA modern SGDP merge ====="; date; echo "scratch: $SCR   shared-ref: $RES   output: $OUT"

# ---- toolchain (ARC modules; conda fallback) ---------------------------------------
module load Bioinformatics >/dev/null 2>&1 || true
module load bcftools/1.21   >/dev/null 2>&1 || module load bcftools >/dev/null 2>&1 || true
module load plink/2.0       >/dev/null 2>&1 || module load plink2   >/dev/null 2>&1 || true
PLINK2="$(command -v plink2 || command -v plink)"
echo "--- tools ---"; for t in bcftools plink2; do printf "%s: " "$t"; command -v "$t" || echo "(see PLINK2=$PLINK2)"; done
[ -n "$PLINK2" ] || { echo "!! plink2 not found"; exit 2; }

# ---- 1. validate + index each subset BCF; drop truncated/unreadable ones -----------
# (one download can be truncated — no BGZF EOF / missing .csi — and would abort the
#  whole merge. Test each, index if needed, and exclude the unusable ones by name.)
echo "===== 1. validate + index the per-sample SGDP BCFs ====="
: > sgdp_bcf.list; : > sgdp_bcf.dropped
for f in "$SUB"/*_sgdp.bcf; do
  if bcftools view -h "$f" >/dev/null 2>&1; then
    [ -f "$f.csi" ] || bcftools index -f "$f" 2>/dev/null
    if [ -f "$f.csi" ]; then echo "$f" >> sgdp_bcf.list; else echo "$f (no index)" >> sgdp_bcf.dropped; fi
  else
    echo "$f (truncated/unreadable)" >> sgdp_bcf.dropped
  fi
done
N=$(wc -l < sgdp_bcf.list); ND=$(wc -l < sgdp_bcf.dropped)
echo "  usable: $N   dropped: $ND"
[ "$ND" -gt 0 ] && { echo "  --- dropped (excluded from the reference) ---"; cat sgdp_bcf.dropped; }
[ "$N" -ge 100 ] || { echo "!! only $N usable BCFs (<100); aborting"; exit 3; }

# ---- 2. thin each sample by STREAMING (parallel), then merge the small results ------
# The subsets are all-sites at ~34.4M SGDP positions. Two traps we avoid:
#   (a) merging all 34M x159 -> a ~5B-genotype VCF, slow to write;
#   (b) `merge -R <1.4M scattered regions>` -> an index SEEK per region x159 files, which
#       is death on NFS (~800 rec/min observed). `-T` STREAMS each file once (sequential
#       reads, NFS-friendly) and keeps the target sites. We do that per-sample IN PARALLEL
#       (one linear pass per file, 16 at a time), then merge the tiny per-sample results.
echo "===== 2. thin (stream, parallel) then merge $N samples ====="
awk 'NR%25==0{print $1"\t"$2}' "$SRC/snps/sgdp.snps.pos" > thin.regions   # ~1.4M sites (plain -T targets)
echo "  thin target positions: $(wc -l < thin.regions)  (of 34.4M)"
mkdir -p thinned
i=0
while read -r f; do
  b=$(basename "$f" .bcf)
  ( bcftools view -T thin.regions "$f" -Ob -o "thinned/$b.bcf" 2>/dev/null && bcftools index -f "thinned/$b.bcf" 2>/dev/null ) &
  i=$((i+1)); [ $((i % 16)) -eq 0 ] && wait
done < sgdp_bcf.list
wait
ls thinned/*.bcf > thinned.list 2>/dev/null
echo "  per-sample thinned files: $(wc -l < thinned.list)"
bcftools merge -l thinned.list --threads 16 -Oz -o merged_sgdp.vcf.gz   # small files, no seeks
bcftools index -t -f merged_sgdp.vcf.gz
NS=$(bcftools query -l merged_sgdp.vcf.gz | wc -l)
echo "  merged samples: $NS   sites: $(bcftools index -n merged_sgdp.vcf.gz)"
[ "$NS" -ge 100 ] || { echo "!! merge produced $NS samples (<100); aborting"; exit 4; }

# ---- 3. VCF -> PLINK; set variant IDs to chr:pos:ref:alt (stable cross-dataset key) -
echo "===== 3. convert to PLINK (chr:pos:ref:alt IDs) ====="
"$PLINK2" --vcf merged_sgdp.vcf.gz \
  --set-all-var-ids '@:#:$r:$a' --new-id-max-allele-len 100 missing \
  --max-alleles 2 --snps-only \
  --make-bed --out sgdp166
[ -f sgdp166.fam ] || { echo "!! plink --make-bed failed"; exit 5; }
echo "  sgdp166 samples: $(wc -l < sgdp166.fam)   variants: $(wc -l < sgdp166.bim)"

# ---- 4. LD prune (same params as Lily's sgdp_merge_pca.slurm) -----------------------
echo "===== 4. LD prune (200 25 0.4) ====="
"$PLINK2" --bfile sgdp166 --indep-pairwise 200 25 0.4 --out sgdp166_prune
echo "  prune.in variants: $(wc -l < sgdp166_prune.prune.in 2>/dev/null || echo 0)"

# ---- 5. PCA (10 PCs) + allele freqs -------------------------------------------------
# NB: no 'allele-wts' modifier — unsupported in this plink2 (v2.00a2LM, 2019). That's
# only needed to PROJECT the archaics (Sanity check 2); the modern-only PCA here needs
# just the eigenvec/eigenval. Projection weights will be produced then (newer plink2 or
# smartpca lsqproject).
echo "===== 5. PCA (10 PCs) + freqs ====="
"$PLINK2" --bfile sgdp166 --extract sgdp166_prune.prune.in --freq --out sgdp166_freq
"$PLINK2" --bfile sgdp166 --extract sgdp166_prune.prune.in --pca 10 --threads 8 --out sgdp166_pca
[ -f sgdp166_pca.eigenvec ] || { echo "!! PCA failed"; exit 6; }
echo "  eigenvec samples: $(tail -n +2 sgdp166_pca.eigenvec | wc -l)"
echo "  --- eigenvalues (want a clear PC1/PC2 gap, not a flat tail) ---"; cat sgdp166_pca.eigenval

# ---- 6. place outputs: reusable reference -> shared genomes ; coords -> output/ -----
cp -f sgdp166.bed sgdp166.bim sgdp166.fam sgdp166_freq.afreq "$RES/" 2>/dev/null || true
cp -f sgdp166_pca.eigenvec sgdp166_pca.eigenval "$OUT/" 2>/dev/null || true
echo "  reference -> $RES ; PCA coords -> $OUT (tracked)"

echo "===== modern merge done ====="; date
echo "NEXT: render sanity_sgdp_pca.qmd from output/pca_wg; then Sanity check 2 (project archaics)."
