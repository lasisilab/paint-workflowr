# code/ — SEPIA cluster pipeline

Version-controlled pipeline scripts (SLURM/bash/etc.) run from the SEPIA cluster
checkout (`/nfs/turbo/lsa-tlasisi1/sepia`). They read reusable inputs from the
gitignored `resources/`, write big intermediates to the gitignored `scratch/`, and
write small results to the tracked `output/` (which syncs via git).

- `wg_modern_merge.slurm` — completes the 166-sample modern SGDP reference merge →
  LD-prune → projection-ready PCA (allele weights + freqs). Reference lands in
  `resources/sgdp/`, PCA coords in `output/pca_wg/`. Prereq for the genome-wide
  ancient-vs-modern sanity PCA. Submit: `cd /nfs/turbo/lsa-tlasisi1/sepia && sbatch code/wg_modern_merge.slurm`

Legacy R helpers for the website (`pca_proj.py`, `pig_pca_proj.py`, `process_links.R`,
`sgdp_subset_array.slurm`) remain under `analysis/` next to the Quarto pages that use them.
