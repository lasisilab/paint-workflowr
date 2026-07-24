# output/ — small, synced results

Generated results that are small enough to **track in git and sync** between the
cluster, GitHub, and laptops: PCA coordinates (`*.eigenvec`, `*.eigenval`),
projection scores (`*.sscore`), QC tables (`qc/*.tsv`), and figures (`figures/*.png`).

This is the "results go straight into the repo" half of the layout. The heavy inputs
and intermediates that produce them live in the gitignored `resources/` and `scratch/`
on the cluster and never sync. The `.gitignore` safety net also blocks large binary
genomic formats (`*.bam`, `*.bcf`, `*.vcf.gz`, plink `*.bed/.bim/.fam`, `*.allele`,
`*.afreq`, …), so keep only compact text/plots here.

- `pca_wg/` — genome-wide ancient-vs-modern PCA coordinates
- `pca_panel/` — pigmentation-panel PCA coordinates
- `qc/` — per-sample QC summary tables
- `figures/` — rendered figures referenced by the site / plan
