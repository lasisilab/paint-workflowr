# SEPIA — cluster inventory

A snapshot of everything on the cluster, so the compute side is accounted for in the repo. **Not published to the website** (this is a `.md`; the Pages workflow only serves `plan/*.html`) because it lists internal cluster paths.

- **Location:** `/nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data` on the University of Michigan **Great Lakes** HPC system (Turbo storage).
- **Size:** ~110 GB. **Snapshot date:** 2026-07-22.
- **Access:** SSH to `greatlakes` (needs a UMich Kerberos password + Duo two-factor; no key-only login). Reuse an authenticated session via a ControlMaster socket, then `ssh greatlakes "<cmd>"`. Scratch working area: `/scratch/tlasisi_root/tlasisi0/lheald/`. SLURM account `tlasisi0`.
- **Reference genome:** `reference/hs37d5.fa` = **GRCh37 / hg19** (this is the build all the sequence data is on — see the build-mismatch bug A2 in `plan.md`). A `hg19.fa` is referenced by one script but is **absent**.
- **To refresh this inventory:** `ssh greatlakes "du -sh /nfs/turbo/lsa-tlasisi1/lheald_thesis/aDNA_data/*/"` etc. Keep cluster commands **text-only** (`ls`, `du`, `grep`, `samtools view -H`, `bcftools view -H`) — never `cat`/`head` a `.bcf`/`.bam` (binary → scrambles the terminal).

## Directory layout (by size)

| Directory | Size | Contents |
|---|---:|---|
| `sgdp/subsets/` | 102 GB | 326 per-sample SGDP (modern reference) BCF subsets — two SNP-panel subsets per sample. The bulk of the store. |
| `ancient_wholegenome/` | 4.5 GB | Merged archaic genotype calls at the whole-genome SNP panel (`ancient_sgdp_wg.bcf` / `.vcf.gz`). |
| `pca/` | 1.8 GB | `modern/` (SGDP whole-genome PLINK files + PCA eigen-outputs) and `pigmentation/` (pigmentation-panel PLINK + PCA + an `ancient/` subdir with the ancient pigmentation calls). |
| `reference/` | 1.4 GB | `hs37d5.fa` (+ `.fai`) — the GRCh37/hg19 reference. |
| `snps/` | 928 MB | SNP-panel definitions: `snps.bed` (bare-named), `snps.chr.bed` (chr-prefixed), `sgdp.snps.pos`, `sgdp.bim`. |
| `results/` | 5.7 MB | `depth/` — 15 `*_depth.txt` per-sample depth tables (one, `Sid1253`, is empty); `filtered/` — 15 panel-filtered BAMs. |
| `sgdp_merge/` | 112 KB | Alternate SGDP merge scripts (`vcf_wget`, `vcf_merge`, `merge_continue`). |
| `work/` | 64 KB | `bamlist.txt` and scratch bits. |
| (root) | — | ~15 `*.slurm` scripts + `wget_commands.txt` (558 lines = 279 SGDP samples × 2). |

## The pipeline (~19 SLURM jobs), by stage
1. **Acquire archaic BAMs** — `sort_wget.slurm`, `phased_get.slurm` (download 15 archaic genomes from MPI-EVA & EBI/ENA; merge per-chromosome, sort, index).
2. **Depth & filtering** — `snp_subset.slurm` (`samtools depth -a -b snps.bed` → per-sample depth tables; `samtools view -L` → panel-filtered BAMs).
3. **Ancient genotype calling** — `ancient_wg.slurm` (whole-genome panel, per chromosome; note the `--ploidy 1` bug A3); `pig_call_miss.slurm` (pigmentation panel, keeps all sites — the one used); `pigmentation_ancient_call.slurm` (pigmentation panel, variants-only — unused; bug A4).
4. **Acquire & subset SGDP** — `sgdp_subset_array.slurm` (279-task array: download each modern VCF, subset to both panels); alternates `get_simons.slurm`, `sgdp_merge/vcf_wget.slurm`.
5. **Merge + modern PCA** — `sgdp_merge_pca.slurm` / `sgdp_merge_panel.slurm` (merge subsets → PLINK → LD-prune → PCA with allele weights); `modern_pca.slurm`; `pig_pca.slurm` (pigmentation PCA); `subset_sgdp.slurm`.
6. **Project archaics onto modern PCA** — `analysis/pca_proj.py` & `analysis/pig_pca_proj.py` in the repo (plink2 `--score`); `pca_ancient.slurm` on the cluster is dead code referencing the missing `hg19.fa` (bug A5).

**Tools:** `bcftools`, `samtools`, `plink`/`plink2`, `tabix`, `eigensoft`, `wget`.

## Archaic samples (15 BAMs; 14 analyzed)
`Chagyrskaya8`, `Denisova3`, `den11` (Denisova 11 / "Denny"), `den25` (Denisova 25), `den5` (Denisova 5), `goyet`, `hst` (Hohlenstein-Stadel), `lesCottes`, `mez1` (Mezmaiskaya 1), `mez2` (Mezmaiskaya 2), `scladina`, `Sid1253` (El Sidrón — depth file empty, not analyzed), `spy`, `vindija33` (Vindija 33.19), `vindija87` (Vindija 87).
Note: `Denisova3`'s BAM uses `chr`-prefixed contigs while all others (and the reference) are bare-named — see bug A1.

## Key derived products (expensive to regenerate → back these up, item C3)
- `ancient_wholegenome/ancient_sgdp_wg.bcf` / `.vcf.gz` — the merged archaic genotype call set at the whole-genome SNP panel.
- `sgdp/merged_sgdp_panel.bcf`, `sgdp/merged_snps_panel.bcf` — the merged modern SGDP reference panels.
- `pca/modern/sgdp.wg.pca.*`, `pca/pigmentation/pigmentation_snps_pca.*` — the PCA eigen-outputs (these are what got copied into the repo's `data/`).
- `results/depth/*_depth.txt` — the per-sample depth tables (also copied into the repo's `data/`).

The raw archaic BAMs are re-downloadable from MPI-EVA (`ftp.eva.mpg.de/neandertal`) and EBI/ENA, so they're lower priority to preserve than the derived products above.
