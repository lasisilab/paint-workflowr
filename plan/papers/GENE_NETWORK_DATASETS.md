# Gene-network datasets inventory — `tinalasisi/pigmentation-gene-network`

**Purpose.** SEPIA item **B1** prep: catalog every dataset the public repo
`tinalasisi/pigmentation-gene-network` provides, so we can plan folding its richer, gene-level
pigmentation data into SEPIA (the "bigger goal" beyond Lily's 222-SNP panel).

**Provenance of this inventory.** Cloned `https://github.com/tinalasisi/pigmentation-gene-network`
at commit `7618746` (2026-07-13). Every count, column, DOI, and build below was read directly from
the repo's committed `DATA_SOURCES.md` and by inspecting each file's header + rows. Where a figure
below differs from `DATA_SOURCES.md`, the file-actual value is given and the difference noted. Nothing
here is inferred beyond what was read; missing items are called out as missing.

---

## Build reality (read this first — it is not "all hg38")

`DATA_SOURCES.md` and SEPIA `plan.md` §5 both describe the repo as "hg38." That is true for the two
pieces SEPIA most cares about, but **not uniform** across the repo:

- **hg38 (GRCh38):** the GWAS Catalog pull (`pos_hg38` column, 1,065/1,072 rows populated) and the
  assembled gene network's gene coordinates (MyGene `genomic_pos`, default GRCh38). These are the
  datasets SEPIA calls the "four hg38 gene-network datasets."
- **hg19 (GRCh37):** the per-paper SNP extractions carry `coord_build = GRCh37/hg19` and `pos_hg19`
  columns — Martin 2017, Kim 2024, the discordance/case-study loci, and the merged `nb4` base's
  curated-paper rows. In `nb4_unified_association_base.csv` the two builds sit **side by side**:
  1,072 rows tagged `GRCh38 (pos_hg38 … GWAS Catalog)` and 105 curated-paper rows mostly
  `GRCh37/hg19 (b37)`.
- **build-agnostic:** HIrisPlex-S, Bajpai, Baxter, Raghunath, and the D'Arcy tables are keyed by
  **rsID or gene symbol only** — no genomic coordinates at all (except the assembled network's gene
  `chr`), so "build" does not apply until coordinates are attached.

**Implication for SEPIA's B2 bridge:** rsID is the only field common to all SNP-level sources, which
is exactly why the B2 plan keys the hg19↔hg38 map on rsID. Coordinate columns in these files cannot be
trusted to be hg38 without checking the per-file `coord_build` tag.

---

## Source index (what the repo provides)

| # | Dataset | Level | File(s) read | Rows | rsIDs / genes | Build |
|---|---------|-------|--------------|------|---------------|-------|
| 1 | **GWAS Catalog** pigmentation (deduplicated) | **SNP** | `data/external/gwas_catalog/pigmentation_gwas_catalog.csv` | 1,072 | 1,072 unique rsIDs | hg38 |
| 1b | **GWAS Catalog** pigmentation (granular, per-association) | **SNP** | `data/external/gwas_catalog/gwas_pigmentation_associations.csv` | 723 | 472 unique rsIDs · 723 gene–SNP assoc | (rsID + gene) |
| 2 | **Bajpai 2023** genome-wide CRISPR screen hits | **gene** | `data/processed/bajpai2023_crispr_hits.csv` | 169 | 169 genes (Symbol+Ensembl) | n/a |
| 3 | **Baxter 2018/19** curated cross-species gene list | **gene** | `data/processed/baxter2018_650_pigmentation_genes.csv` | 659 | 635 w/ human symbol | n/a |
| 4 | **HIrisPlex-S** (Chaitanya 2018) forensic markers | **SNP** | `data/processed/hirisplexs2018_markers.csv` | 36 | 36 rsIDs → 16 genes | rsID only |
| 5 | **Raghunath 2015** melanogenesis backbone | **gene/network** | `data/processed/raghunath_nodes_typed.csv` + `..._edges_typed_signed.csv` | 265 nodes / 429 edges | 265 nodes (genes+metabolites) | n/a |
| 6 | **D'Arcy 2023** OMIM disease genes (Table S1) | **gene** | `data/processed/darcy2023_S1_disease_genes.csv` | 278 | 243 unique genes | n/a |
| 6b | **D'Arcy 2023** STRING PPI network (Tables S4/S5) | **gene/network** | `darcy2023_S4_string_edges.csv` / `_S5_string_nodes.csv` | 4,668 edges / 452 nodes | 452 genes | n/a |
| 6c | **D'Arcy 2023** mass-spec expression (Table S6) + sys/GO (S2) | **gene** | `darcy2023_S6_massspec_expression.csv` / `_S2_sysgo_annotation.csv` | 4,232 / 243 | 4,232 / 243 genes | n/a |
| 7 | **Assembled gene network** (Notebook 2 output) | **gene/network** | `data/processed/gene_network_nodes.csv` + `_edges.csv` | 168 nodes / 309 edges | 168 genes (entrez/ensembl/chr) | hg38 (gene coords) |
| — | **Additional SNP extractions** (Martin, Kim, discordance/case studies) | **SNP** | see "Additional SNP-level sources" below | — | — | **hg19** |

The five SEPIA §5 "four datasets + prediction panel" map to rows above: **GWAS Catalog** (1/1b),
**CRISPR** = Bajpai (2), **cross-species** = Baxter (3), **melanogenesis network** = Raghunath (5),
**PPI expansion** = D'Arcy (6/6b/6c), **prediction panel** = HIrisPlex-S (4).

---

## Per-dataset detail

### 1 · GWAS Catalog — pigmentation associations  (SNP-level, hg38)
- **What:** NHGRI-EBI GWAS Catalog lead SNPs for pigmentation (skin/eye/hair + photo-response),
  pulled over 10 frozen EFO/OBA/MONDO trait roots with child traits.
- **Provenance:** live pull, download endpoint `https://www.ebi.ac.uk/gwas/api/search/downloads`,
  `queried_utc = 2026-07-12T14:46:57Z`; script `scripts/gwas_catalog.py v1.0`. Catalog citation
  **Sollis 2023**; EMBL-EBI terms (reuse with attribution) + per-row study PubMed IDs. Independently
  cross-checked via the human-genetics MCP connector.
- **File / format:** `pigmentation_gwas_catalog.csv`, **27 columns** including
  `rsid, chr, pos_hg38, risk_allele, direction_raw, risk_freq, or_beta, pvalue, mapped_gene,
  reported_gene, pubmed, study_accession, ancestry, initial/replication ancestry+N, queried_utc`.
  **Build GRCh38/hg38** (`pos_hg38`; 1,065 of 1,072 rows populated — 7 rsIDs unmapped).
- **Counts:** 1,072 rows = **1,072 unique rsIDs**. Payoff loci per `DATA_SOURCES.md`:
  MC1R 16 assoc · OCA2 67 · HERC2 65. p-values kept as **strings** (underflow-safe); no p-filter at pull.
- **1b (granular sibling):** `gwas_pigmentation_associations.csv` — 723 rows,
  columns `efo_id, trait, gene, snp_id, pvalue`; **472 unique rsIDs**. This is the per-gene / per-association
  table (supports the ≥2-association replication filter → 83 replicated genes); the deduplicated 1,072 table
  cannot give per-gene counts.

### 2 · Bajpai 2023 — genome-wide CRISPR screen  (gene-level)
- **What:** 169 genes whose CRISPR perturbation changed melanin content in a genome-wide screen
  (Table S1, "Low SSC FACS enriched genes"), called at **q < 0.10** (reproduces the paper).
- **Provenance:** DOI **10.1126/science.ade6289** · PMC10901463 · *Science* 381(6658):eade6289.
  Table S1 is a supplementary file of the **CC BY 4.0** PMC deposit (redistributable w/ attribution).
- **File / format:** `bajpai2023_crispr_hits.csv`, 13 columns —
  `GeneID(Ensembl), Symbol, GeneInfo, Localization, Process, Function, Combined_casTLE_Effect,
  Combined_casTLE_Score, Minimum/Maximum_Effect_Estimate, p_value, q_value, direction_note`.
- **Counts:** **169 gene rows**, no rsIDs (verified 0 rsID matches). All effects positive →
  uniform direction *perturbation reduces pigmentation*. TYR/SLC45A2/OCA2 are hits; MC1R/HERC2 are not.

### 3 · Baxter 2018/19 — curated cross-species gene list  (gene-level)
- **What:** curated pigmentation genes with mouse/zebrafish orthologs (Supporting Table S7,
  "650 Pigmentation Genes").
- **Provenance:** DOI **10.1111/pcmr.12743** · PMID 30339321 · PMC10413850 · *Pigment Cell Melanoma Res*.
  Raw Table S7 is **NOT redistributed** (Wiley subscription VOR, no open-license copy; git-ignored);
  only the derived CSV is committed. Cite Baxter + OMIM/MGI/ZFIN/GO.
- **File / format:** `baxter2018_650_pigmentation_genes.csv`, 12 columns —
  `Gene stable ID, Human gene symbol, Mouse gene symbol, Zebrafish gene symbol, Orthologs across species,
  Pigment phenotype location, GO, OMIM, MGI, ZFIN, PubMed, Species with phenotype`.
- **Counts:** **659 rows**; **635 carry a human gene symbol** (the project's "Baxter 635"). Membership
  list only — no direction, no effect size, no rsIDs. OCA2, MC1R present; **HERC2 absent**.

### 4 · HIrisPlex-S — Chaitanya 2018 forensic prediction markers  (SNP-level)  ★
- **What:** the forensic skin/hair/eye-color prediction marker set.
- **Provenance:** DOI **10.1016/j.fsigen.2018.04.004** · *FSI:Genetics* 35:123–135; skin-model
  coefficients from **Walsh 2017** (*Hum Genet* 136:847); web tool hirisplex.erasmusmc.nl. rsIDs are
  factual; model free to use via the Erasmus MC tool. Elsevier subscription for the PDF text.
  Extraction notebook `notebooks/01c_extract_hirisplex_markers.ipynb`; raw transcription
  `data/raw/hirisplexs2018/hirisplexs2018_markers_raw_transcribed.csv`.
- **File / format:** `hirisplexs2018_markers.csv`, 3 columns — `gene, rsid, in_novel_17plex_skin`.
- **Counts:** **36 markers = 36 unique rsIDs → 16 genes.** `DATA_SOURCES.md` documents this as 36/41
  (full 41 needs Table 1 transcription; one OCR fix `rs228479`→`rs2228479`, one dup dropped).
- **The 16 genes:** ANKRD11, ASIP, BNC2, DEF8, HERC2, IRF4, KITLG, MC1R, OCA2, PIGU, RALY, SLC24A4,
  SLC24A5, SLC45A2, TYR, TYRP1.
- **MC1R red-hair set — complete (8 markers present):** rs1805007, rs1805008, rs1805006, rs11547464,
  rs885479, rs2228479, rs1110400, rs3212355.
- **Blue-eye markers — present:** HERC2 **rs12913832** ✓ and OCA2 **rs1800407** ✓ (also OCA2 rs1800414,
  rs1470608, rs1545397, rs12441727; HERC2 rs2238289/rs6497292/rs1129038/rs1667394/rs1667395).
- Companion `hirisplexs2018_population_provenance.json` documents the model training populations
  (eye ~97% European, hair ~85% European, skin most diverse) — relevant to SEPIA's European-training
  caveat for archaic prediction. **Numeric prediction weights are NOT in this repo** (must be pulled
  from Walsh 2017 / the web tool) — matches SEPIA plan's "optional fetch" note.

### 5 · Raghunath 2015 — directed melanogenesis backbone  (gene/network)
- **What:** the mechanistic directed/signed melanogenesis network; the backbone everything else annotates.
- **Provenance:** *BMC Res Notes* 2015, Additional Files 1–5 (CC BY 4.0; raw MOESM1–5 committed in
  `data/raw/raghunath2015/`). Prior in-lab SEPIA work.
- **Files / format:** `raghunath_nodes_typed.csv` (cols `node, base, node_type, type_source, compartment,
  state, dual_compartment`) + `raghunath_edges_typed_signed.csv` (cols `source, target, verb,
  interaction_norm, sign, reference`).
- **Counts:** **265 nodes / 429 signed directed edges.** Nodes are a mix of genes/proteins **and
  metabolites** (e.g. `4HNE_kerat`, `ACTH_kerat`) with compartment tags — **not** a clean gene list.
  No rsIDs. OCA2 present; HERC2 absent; MC1R present in both keratinocyte and melanocyte compartments.

### 6 · D'Arcy 2023 — OMIM disease genes + STRING PPI + mass-spec  (gene/network)
- **Provenance:** DOI **10.3390/bioengineering10010013** · PMC9854651 · PMID 36671585 ·
  *Bioengineering* 10(1):13. **CC BY 4.0**, six supplementary tables committed at
  `data/raw/darcy2023/Table S1–S6 …FINAL.xlsx`; derived CSVs in `data/processed/darcy2023_S*.csv`
  (each with a `.meta.json`).
- **Table S1 — disease genes:** `darcy2023_S1_disease_genes.csv`, cols `gene, disease_name, inheritance,
  phenotype_mim, phenotype_class, pigmentation_phenotype, source, citation, citation_source`.
  **278 rows / 243 unique genes** (`DATA_SOURCES.md` calls it the "243-gene OMIM disease-gene table" —
  the extra rows are multiple disease entries per gene; S2 sys/GO annotation confirms 243 unique genes).
- **Tables S4/S5 — STRING PPI:** `darcy2023_S4_string_edges.csv` (**4,668 edges**, cols
  `node1, node2, combined_score, citation, citation_source`) + `darcy2023_S5_string_nodes.csv`
  (**452 nodes**, cols incl. `gene_string, process_1..3, main_location, disease_gene_flag/class,
  in_a375, in_fm55`). STRING `combined_score`, **undirected/unsigned association — not mechanistic**.
  (`DATA_SOURCES.md` states "451-node/4668-edge"; file has 452 node rows.)
- **Table S6 — mass-spec:** `darcy2023_S6_massspec_expression.csv`, **4,232 genes**, A375/FM55 melanoma
  LFQ expression. **Table S2 — sys/GO:** 243 genes annotated.
- No rsIDs anywhere in the D'Arcy tables.

### 7 · Assembled gene network — Notebook 2 output  (gene/network, hg38 gene coords)
- `data/processed/gene_network_nodes.csv` (**168 nodes**, cols `gene, entrez, ensembl, chr, node_class,
  citation, citation_source`) + `gene_network_edges.csv` (**309 edges**, cols `source, target, sign,
  edge_class, via, citation, citation_source`). Gene identity via MyGene/UniProt (GRCh38 `chr`),
  release-gated so every node+edge carries a resolvable citation. No rsIDs. This is the repo's own
  integrated backbone (Raghunath + database enrichment); downstream NB5 layers Bajpai/Baxter/D'Arcy onto it.

### Additional SNP-level sources (present, hg19 — beyond the SEPIA §5 five)
These are extra rsID-bearing tables the repo also ships. They are **hg19/GRCh37** and are relevant to
SEPIA only if the panel is extended beyond the §5 set:
- `EXTRACT_Martin2017_loci.csv` — KhoeSan (San/Nama) skin-pigmentation GWAS, 51 rows / **49 unique
  lead rsIDs**, `pos_hg19`, San/W-African/N-European allele freqs. DOI 10.1016/j.cell.2017.11.015.
- `EXTRACT_Kim2024_loci_v2.csv` — East-Asian skin-color GWAS, 26 rows / **26 rsIDs**,
  `coord_build = GRCh37/hg19`. DOI 10.1038/s41467-024-49031-4.
- `discordance_loci.csv` — 105 rows / **75 unique rsIDs** (eye-color discordance case studies), hg19.
- `data/case_records/EXTRACT_*_records.csv` (13 papers) + `data/processed/EXTRACT_*_loci_v2.csv`
  (15 papers) — per-individual validation case-study genotype records (Norton TYRP1, Morgan MC1R,
  Yang OCA2, etc.). SNP/genotype-level, hg19, small.
- `nb4_unified_association_base.csv` — the **merged SNP base**: 1,177 rows / **1,103 unique rsIDs**
  = 1,072 GWAS-Catalog-dedup (hg38) + 105 curated-paper rows (mostly hg19), with `rsid`, `rsid_primary`,
  `pos_hg38`, `coord_build`, `gene_label`, `pvalue`, `population`, and cross-membership flags. This is
  the single most convenient union table if SEPIA wants "all pigmentation rsIDs the repo knows about."

---

## Integration into SEPIA

SEPIA's plan (`plan.md` B1/B3/B6) already splits sources into **SNP-level** (feed the directional
polygenic score B3 + panel PCA) vs **gene-level** (gene-region PCA B4-ii, layered coverage B1,
functional interpretation B7). This inventory confirms and quantifies that split.

### A. rsID SNP-lists → fold into the hg19↔hg38 panel map (B2), extend the panel (B1/B3)
These have rsIDs, so B2's `rsID ↔ hg19 ↔ hg38` map can resolve them and we can pull archaic/SGDP
genotypes at each locus and report on hg38:

| Source | rsIDs | In SEPIA 222-panel already | **New to the panel** | Note |
|--------|------:|---------------------------:|---------------------:|------|
| **GWAS Catalog dedup** | 1,072 | 212 | **~860** | Panel is essentially a subset of this pull; carries `or_beta`/`direction_raw` for B3 signs |
| **HIrisPlex-S** | 36 | 15 | **21** | Adds the MC1R red-hair extras (rs1110400, rs2228479, rs3212355), OCA2 (rs1470608/rs1545397/rs12441727), TYR rs1393350, TYRP1 rs683, KITLG rs12821256, etc. |
| Martin 2017 (KhoeSan) | 49 | 15 | ~34 | hg19 already — but African-ancestry axis; optional |
| Kim 2024 (East Asian) | 26 | 1 | ~25 | hg19; almost entirely novel to the panel |
| GWAS granular assoc | 472 | 43 | — | per-gene replication counts, not new loci |

**Overlap method / caveat:** SEPIA's 222 panel positions (`data/snps.txt`, hg38) map cleanly to 222
rsIDs via `data/skin_pigmentation.tsv` (the panel's GWAS-Catalog source table, 226 unique rsIDs).
Overlap counts above are rsID-set intersections against those 222 (identical whether measured against
the 222-mapped set or the 226-rsID source table, ±1). So:

- **The GWAS Catalog pull is a strict superset of the current panel** (212/222 present) and roughly
  **quadruples** the pigmentation SNP count (→ ~1,072). The 10 panel rsIDs not found are likely
  non-pigmentation/near-miss trait rows dropped by the repo's trait-root filter — worth a spot check
  before swapping the panel source.
- **HIrisPlex-S contributes 21 forensically-validated markers not in the panel**, including the
  well-characterized MC1R red-hair and HERC2/OCA2 blue-eye variants SEPIA's Q9 concordance check
  (`plan.md` B7) explicitly wants. This is the highest-value small addition.
- Martin/Kim add non-European ancestry axes but are **hg19** — they still route through the same rsID
  bridge, so no extra machinery; include only if the phenotype scope broadens.

**Build handling:** fold these in by **rsID**, not by coordinate. Only the GWAS Catalog rows are
natively hg38; HIrisPlex-S is rsID-only and Martin/Kim are hg19. B2's dual-coordinate dbSNP re-pull
(keyed by rsID) is exactly the right mechanism, and `nb4_unified_association_base.csv` is a ready-made
union to seed the map (it already stores `rsid`+`pos_hg38`+`coord_build` per row).

### B. Gene-level → B6 (genes-vs-SNPs) / B4-ii (gene-region PCA) / B7 (functional)
No per-SNP genotype; used as **gene-region sets** (take each gene's Ensembl start/end, use all variants
inside) or for network/functional interpretation — never in the +1/−1 directional score:

- **Bajpai 169** CRISPR hits — gene set + `Combined_casTLE_Effect` weight, uniform reduces-pigmentation sign.
- **Baxter 635** curated genes — membership only.
- **Raghunath 265-node / 429-edge** signed directed backbone — mechanism/direction context (nodes include
  metabolites; filter to gene nodes before coordinate lookup).
- **D'Arcy** 243 disease genes + 452-node/4,668-edge STRING PPI (association, not mechanistic) + 4,232-gene
  mass-spec — disease-gene overlay + PPI-shell expansion for B7.
- **Assembled gene network** (168 nodes, GRCh38 `chr`) — the repo's integrated backbone, already citation-gated.

These need gene coordinates from Ensembl/BioMart on the matched build (SEPIA plan B4-ii/B6 already
specify this); the repo supplies **symbols/Ensembl IDs**, not coordinates (except the 168-node assembled
network's `chr`), so a coordinate join is required regardless.

### C. What is NOT in the repo (do not assume)
- **HIrisPlex-S numeric prediction weights** — absent; pull from Walsh 2017 / Erasmus MC tool if
  quantitative color probabilities are needed (SEPIA already flags this as optional for archaics).
- **Per-SNP genotypes / allele-frequency panels for archaics** — not here; that is SEPIA's own data.
- **Kim 2024 / Zhang 2018 full summary stats** — only reference/derived extracts; full stats are
  publisher/dbGaP-gated.
- Coordinates for the gene-level sources — symbols only.
