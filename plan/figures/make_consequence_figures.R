#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# PAINT — "consequence" figures for the before/after record of the build fix.
#
# WHY THIS EXISTS
#   The genome-build mismatch (bug A2), the projection collapse, and the
#   Denisova-3 chr-naming bug (A1) each leave a visible fingerprint in the
#   COMMITTED (pre-fix) outputs. This script renders those fingerprints so we
#   have an honest BEFORE baseline. After the fix (B2), re-run this SAME script
#   pointing --state after at the corrected outputs to produce the AFTER panels
#   and do a like-for-like comparison.
#
# USAGE
#   Rscript plan/figures/make_consequence_figures.R              # state = before
#   Rscript plan/figures/make_consequence_figures.R after        # after the fix
#   (run from the repo root; reads data/, writes plan/figures/)
#
# INPUTS (all committed): data/*_depth.txt, data/ancient.projected.pig.sscore,
#   data/ancient.projected.sgdp.sscore, data/pigmentation.pca.eigenval,
#   data/sgdp.wg.pca.eigenval
# OUTPUTS: plan/figures/<state>_coverage.png, _projection.png, _scree.png
# ---------------------------------------------------------------------------

suppressMessages({library(data.table); library(ggplot2)})

args  <- commandArgs(trailingOnly = TRUE)
state <- if (length(args) >= 1) args[1] else "before"
outdir <- "plan/figures"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
tag <- toupper(state)

# Declared coverage tier (thesis Table 3: five "high-coverage" archaic genomes)
high_cov <- c("vindija33","Chagyrskaya8","den5","den25","Denisova3")
# Species-group rule (thesis: Denisova 3 & 25 = Denisovan; Denisova 11 = hybrid;
# Denisova 5 and all others = Neanderthal)
grp <- function(id) fifelse(grepl("Denisova3$|Denisova25|den25", id), "Denisovan",
                     fifelse(grepl("Denisova11|denny", id),          "Hybrid (Den. 11)",
                                                                     "Neanderthal"))
pretty_name <- c(vindija33="Vindija 33.19", Chagyrskaya8="Chagyrskaya 8",
  den5="Denisova 5", den25="Denisova 25", Denisova3="Denisova 3", denny="Denisova 11",
  goyet="Goyet", lesCottes="Les Cottes", mez1="Mezmaiskaya 1", mez2="Mezmaiskaya 2",
  spy="Spy", hst="Hohlenstein-Stadel", Sclad="Scladina", vindija87="Vindija 87",
  Sid1253="El Sidron")

theme_paint <- theme_bw(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA),
        strip.background = element_rect(fill = "grey92", colour = NA),
        legend.position = "top")

## ---- FIGURE A: per-sample coverage over the 222-SNP panel --------------------
depth_files <- list.files("data", pattern = "_depth\\.txt$", full.names = TRUE)
cov <- rbindlist(lapply(depth_files, function(f) {
  s <- sub("_depth\\.txt$", "", basename(f))
  d <- tryCatch(fread(f, header = FALSE), error = function(e) NULL)
  if (is.null(d) || ncol(d) < 3) return(NULL)
  data.table(sample = s, mean_depth = mean(d[[3]]),
             covered = sum(d[[3]] > 0), n = nrow(d))
}))
cov[, tier := fifelse(sample %in% high_cov, "declared high-coverage", "low / medium")]
cov[, label := fifelse(sample %in% names(pretty_name), pretty_name[sample], sample)]
cov[, label := factor(label, levels = label[order(mean_depth)])]

figA <- ggplot(cov, aes(mean_depth, label, colour = tier)) +
  geom_segment(aes(x = 0, xend = mean_depth, yend = label), linewidth = 0.5) +
  geom_point(size = 3) +
  geom_text(aes(label = sprintf("%.1fx  (%d/%d)", mean_depth, covered, n)),
            hjust = -0.15, size = 3, colour = "grey25") +
  scale_colour_manual(values = c("declared high-coverage" = "#1E5A54",
                                 "low / medium" = "#B0B0B0"), name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.35))) +
  labs(title = sprintf("[%s] Realised coverage over the 222-SNP pigmentation panel", tag),
       subtitle = "Mean depth (and covered/222) per archaic sample. A declared high-coverage genome sitting with the low group is the A1 fingerprint.",
       x = "Mean depth over panel positions", y = NULL) +
  theme_paint
ggsave(file.path(outdir, paste0(state, "_coverage.png")), figA,
       width = 8.5, height = 5.2, dpi = 150, bg = "white")

## ---- FIGURE B: ancient PCA projections, pigmentation vs whole-genome ---------
read_sscore <- function(f, panel) {
  d <- fread(f)                       # quoted CSV; fread handles it
  setnames(d, gsub('[#"]', '', names(d)))
  data.table(panel = panel, IID = d$IID, PC1 = d$PC1_AVG, PC2 = d$PC2_AVG)
}
proj <- rbind(
  read_sscore("data/ancient.projected.pig.sscore",  "Pigmentation panel (222 SNPs)"),
  read_sscore("data/ancient.projected.sgdp.sscore", "Whole-genome panel")
)
proj[, group := grp(IID)]
proj[, panel := factor(panel, levels = c("Pigmentation panel (222 SNPs)", "Whole-genome panel"))]
# annotate the overplot in any panel where all points share one coordinate
collapse_note <- proj[, .(uniq = uniqueN(round(PC1, 6)), PC1 = PC1[1], PC2 = PC2[1],
                          n = .N), by = panel][uniq == 1]

figB <- ggplot(proj, aes(PC1, PC2, colour = group)) +
  geom_point(size = 3, alpha = 0.8) +
  facet_wrap(~panel, scales = "free") +
  scale_colour_manual(values = c("Denisovan" = "#A5433A", "Hybrid (Den. 11)" = "#8F6410",
                                 "Neanderthal" = "#1E5A54"), name = NULL) +
  labs(title = sprintf("[%s] Archaic samples projected onto the modern PCA", tag),
       subtitle = "Each point is one archaic individual. Left: all 15 collapse to a single coordinate (projection + build bug). Right: whole-genome projection is spread.",
       x = "PC1", y = "PC2") +
  theme_paint
if (nrow(collapse_note)) {
  figB <- figB + geom_text(data = collapse_note,
    aes(x = PC1, y = PC2, label = sprintf("all %d archaics\noverplotted here", n)),
    colour = "grey20", size = 3, vjust = -1.1, inherit.aes = FALSE)
}
ggsave(file.path(outdir, paste0(state, "_projection.png")), figB,
       width = 9.5, height = 5, dpi = 150, bg = "white")

## ---- FIGURE C: eigenvalue spectra (scree), pigmentation vs whole-genome ------
read_eig <- function(f, panel) {
  v <- fread(f, header = FALSE)[[1]]
  data.table(panel = panel, PC = seq_along(v), eigenvalue = v)
}
scree <- rbind(
  read_eig("data/pigmentation.pca.eigenval", "Pigmentation panel (222 SNPs)"),
  read_eig("data/sgdp.wg.pca.eigenval",      "Whole-genome panel")
)
scree[, panel := factor(panel, levels = c("Pigmentation panel (222 SNPs)", "Whole-genome panel"))]
scree[, eig_plot := pmax(eigenvalue, 1e-6)]   # so ~0 bars are visibly flat, not log-blown

figC <- ggplot(scree, aes(factor(PC), eig_plot, fill = panel)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  facet_wrap(~panel, scales = "free_y") +
  scale_fill_manual(values = c("Pigmentation panel (222 SNPs)" = "#A5433A",
                               "Whole-genome panel" = "#1E5A54")) +
  labs(title = sprintf("[%s] PCA eigenvalue spectrum (scree)", tag),
       subtitle = "Pigmentation panel is rank-1 (only PC1 > 0; PC2-10 ~ 3e-18) vs the healthy declining whole-genome spectrum.",
       x = "Principal component", y = "Eigenvalue") +
  theme_paint
ggsave(file.path(outdir, paste0(state, "_scree.png")), figC,
       width = 9, height = 4.4, dpi = 150, bg = "white")

cat(sprintf("Wrote %s_coverage.png, %s_projection.png, %s_scree.png to %s/\n",
            state, state, state, outdir))
