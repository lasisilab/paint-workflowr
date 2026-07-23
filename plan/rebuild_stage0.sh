#!/bin/bash
# =====================================================================================
# PAINT rebuild — STAGE 0 (setup + acquire high-cov VCFs + lift panel + verify SGDP)
# Run as ONE SLURM batch job so it does NOT hammer the login node:
#     sbatch plan/rebuild_stage0.sh
# Then read paint_stage0_<jobid>.log.  Nothing existing is overwritten — all output
# goes to a NEW  $B/rebuild/  workspace.
#
# This is a ready-to-submit DRAFT: paths/URLs are the verified ones from
# papers/REFERENCES.md + PIPELINE_QC_BY_PAPER.md, but we validate on first run and
# fix any specifics live. Heavy compute (ANGSD/mapDamage) is Stage 2/4, not here.
# =====================================================================================
#SBATCH --job-name=paint_stage0
#SBATCH --account=tlasisi0
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=paint_stage0_%j.log
set -uo pipefail

# ---- config (confirm) --------------------------------------------------------------
B=/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data
WORK="$B/rebuild"                       # clean workspace; nothing else is touched
REF="$B/reference/hs37d5.fa"            # hg19/GRCh37 (bare contigs)
SGDP_BIM="$B/pca/modern/sgdp.wg.bim"    # modern ref (hg19, rsID-keyed) — for lift + verify
PANEL_BED="$B/snps/snps.chr.bed"        # 222/395-SNP panel (hg38, rsID in col4)
mkdir -p "$WORK"/{vcf,panel,logs}
cd "$WORK"

echo "===== PAINT Stage 0  =====";  date;  echo "workspace: $WORK"

# ---- toolchain (conda; ANGSD/PCAngsd/mapDamage come in Stage 2/4) -------------------
source /home/tlasisi/tlasisi/miniconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate align 2>/dev/null || conda activate base 2>/dev/null || true
echo "--- tools ---"; for t in bcftools samtools tabix awk curl; do printf "%s: " "$t"; command -v "$t" || echo MISSING; done

# ---- internet check (compute nodes may lack egress) --------------------------------
NET=1; curl -sfI https://cdna.eva.mpg.de/ >/dev/null 2>&1 || NET=0
if [ "$NET" = 0 ]; then
  echo "!! No internet from this node. Run the DOWNLOAD section on a login/data-transfer"
  echo "!! node (e.g. ssh gl-xfer), then re-submit for the lint sections. Continuing with"
  echo "!! the offline sections (panel lift by rsID, SGDP verify) only."
fi

# =====================================================================================
# 1. Download the Tier-1 high-coverage snpAD VCFs + FilterBed masks   (needs internet)
#    Denisova 3 here = the A1 "fix": its true ~30x calls, bare-named hg19, no reheader.
# =====================================================================================
if [ "$NET" = 1 ]; then
  echo "===== 1. download high-coverage snpAD VCFs ====="
  VBASE=http://cdna.eva.mpg.de/neandertal/Vindija/VCF          # Altai, Vindija33.19, Denisova, Mez1
  FBASE=http://cdna.eva.mpg.de/neandertal/Vindija/FilterBed
  for g in Denisova Vindija33.19 Altai Mez1; do                # Denisova = Denisova 3
    mkdir -p "vcf/$g" "panel/$g"
    for c in $(seq 1 22) X; do
      f="chr${c}_mq25_mapab100.vcf.gz"
      curl -sfL "$VBASE/$g/$f"     -o "vcf/$g/$f"     && curl -sfL "$VBASE/$g/$f.tbi" -o "vcf/$g/$f.tbi" \
        || echo "MISS $g/$f (confirm URL)"
    done
  done
  # Chagyrskaya 8 + Denisova 25 are separate releases (own masks):
  echo "  Chagyrskaya: ftp.eva.mpg.de/neandertal/Chagyrskaya/VCF/  (chrN.noRB.vcf.gz) + FilterBed/"
  echo "  Denisova 25: cdna.eva.mpg.de/denisova/Den25/VCF/         (preprint; may be gated) + FilterBed/"
  # (left explicit rather than auto-pulled since their per-chr filenames differ; confirm then add)
  echo "downloaded VCF dirs:"; du -sh vcf/* 2>/dev/null
fi

# =====================================================================================
# 2. Lift the pigmentation panel hg38 -> hg19, primarily BY rsID (no chain needed):
#    the modern ref sgdp.wg.bim is hg19 and keyed by rsID, so we read hg19 coords straight
#    out of it. (liftOver of the residual rsIDs not in SGDP is a follow-up.)  Q2 gate.
# =====================================================================================
echo "===== 2. panel -> hg19 by rsID ====="
awk '{split($4,a,"-"); print a[1]}' "$PANEL_BED" | sort -u > panel/panel_rsids.txt
echo "  panel rsIDs: $(wc -l < panel/panel_rsids.txt)"
# join rsID -> hg19 coord/alleles from sgdp.wg.bim  (bim: chr id cM pos a1 a2)
awk 'NR==FNR{p[$1]=1;next} ($2 in p){print $1"\t"($4-1)"\t"$4"\t"$2"\t"$5"\t"$6}' \
    panel/panel_rsids.txt "$SGDP_BIM" | sort -k1,1 -k2,2n > panel/panel.hg19.bed
echo "  panel SNPs placed on hg19 (present in SGDP): $(wc -l < panel/panel.hg19.bed)"
# Q2 tracer: SLC24A5 rs1426654 must be hg19 15:48426484 ; HERC2 rs12913832 -> 15:28365618
echo "  --- Q2 tracer check ---"
awk '$4=="rs1426654"||$4=="rs12913832"{print "   "$4" -> "$1":"$3}' panel/panel.hg19.bed
grep -q $'\t48426484\t' <(awk '{print $1"\t"$3}' panel/panel.hg19.bed) \
  && echo "   OK: SLC24A5 on hg19 (48426484)" || echo "   CHECK: SLC24A5 hg19 coord not found"

# =====================================================================================
# 3. Verify SGDP reference is hg19 + confirm panel alleles (Q2 build + Q4 allele lint)
# =====================================================================================
echo "===== 3. verify SGDP (hg19) ====="
awk '$1==15 && ($4==48426484||$4==28365618){print "   FOUND hg19 tracer: "$2" "$1":"$4}' "$SGDP_BIM"
awk '$1==15 && ($4==48134288||$4==28120472){print "   WARN hg38 coord present: "$2" "$1":"$4}' "$SGDP_BIM"
echo "  sgdp.wg samples: $(wc -l < ${SGDP_BIM%.bim}.fam)   sites: $(wc -l < $SGDP_BIM)"

echo "===== Stage 0 done ====="; date
echo "NEXT: Stage 1 targeted re-acquisition of Les Cottes / Denisova 11 / Goyet (panel regions),"
echo "      then Stage 2 QC (mapDamage, coverage, het-vs-depth) — see plan/rebuild_from_raw.md."
