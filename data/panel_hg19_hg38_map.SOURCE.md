# panel_hg19_hg38_map.tsv — source & method

Verified rsID ↔ GRCh37 (hg19) ↔ GRCh38 (hg38) coordinate map for the 222-SNP
pigmentation panel. This is the core deliverable of SEPIA item **B2a** (the build
fix) and the coordinate/allele substrate for **Q4** (allele harmonization).

## Access date
2026-07-24

## Inputs (panel identity only — NOT used for authoritative coordinates)
- `data/snps.txt` — the panel: 222 rows, each a `chrom:pos::` locus. No rsIDs.
- `data/skin_pigmentation.tsv` — pigmentation-SNP annotation table (GWAS-Catalog
  export). Columns used: `riskAllele` (rsID is the `rs\d+` prefix, e.g.
  `rs9350204-C` → `rs1426654`), `mappedGenes` (gene), `locations` (`chrom:pos`).

### How the panel was keyed to rsIDs
`snps.txt` carries no rsIDs, so each panel position was joined to `skin_pigmentation.tsv`
by coordinate. The join is exact under the rule **`snps.txt pos = TSV locations + 1`**
(the TSV `locations` column is 0-based/BED-style; snps.txt added 1). All 222 panel
positions matched a TSV rsID under this rule; 0 unmatched.

## Authoritative coordinate/allele source
Coordinates and alleles were **not** taken from either input file (both are
unreliable — see "Build bug" below). Each rsID was resolved against a public API:

- **Ensembl REST** (primary), batch POST endpoint `/variation/human`:
  - GRCh38: `https://rest.ensembl.org/variation/human` (`ids` list, JSON)
  - GRCh37: `https://grch37.rest.ensembl.org/variation/human` (`ids` list, JSON)
  - For each variant, the primary-assembly mapping (`seq_region_name` ∈ 1–22,X,Y,MT;
    scaffold/patch mappings discarded) supplies `start` (1-based pos) and
    `allele_string` (`REF/ALT1/ALT2…`, forward strand of the assembly).
- **NCBI dbSNP RefSNP API** (`https://api.ncbi.nlm.nih.gov/variation/v0/refsnp/<id>`)
  was used as an independent cross-check on the tracer discrepancy (see below).

Merged rsIDs were detected because Ensembl returns a merged variant under its
**current** rsID; the queried (old) id appears in that variant's `synonyms`. The
map records the current rsID in `rsid` and the panel's original id in `panel_rsid`.

## Columns
| column | meaning |
|---|---|
| `rsid` | current authoritative rsID (Ensembl/dbSNP; = merge target where applicable) |
| `chrom` | chromosome (Ensembl primary assembly) |
| `pos_hg38` | GRCh38 position, 1-based (Ensembl `start`) |
| `pos_hg19` | GRCh37 position, 1-based (Ensembl GRCh37 `start`) |
| `ref_hg38` / `alt_hg38` | GRCh38 reference / alternate allele(s) (comma-joined), forward strand |
| `ref_hg19` / `alt_hg19` | GRCh37 reference / alternate allele(s) (comma-joined), forward strand |
| `gene` | mapped gene(s) from the panel table (`skin_pigmentation.tsv`) |
| `strand_ambiguous` | TRUE iff the site is a biallelic SNV whose two alleles are complementary (A/T or C/G) — the palindromic SNPs Q4 must treat with care |
| `panel_pos_hg38` | the raw `snps.txt` position (off-by-one high — see below) |
| `panel_rsid` | rsID as joined from the panel table (differs from `rsid` when merged) |
| `status` | `resolved`, `resolved_merged`, or `unresolved` |
| `notes` | merge/co-location/multiallelic/mapping caveats |

## Tracer verification
| tracer | build | expected (task) | resolved (Ensembl) | match |
|---|---|---|---|---|
| rs1426654 (SLC24A5) | hg38 | 15:48134288 | 15:**48134287** | ✗ (off by 1) |
| rs1426654 (SLC24A5) | hg19 | 15:48426484 | 15:48426484 | ✓ |
| rs12913832 (HERC2) | hg38 | 15:28120472 | 15:28120472 | ✓ |
| rs12913832 (HERC2) | hg19 | 15:28365618 | 15:28365618 | ✓ |

**rs12913832 verifies exactly in both builds. rs1426654 hg19 verifies. The one
mismatch — rs1426654 hg38 — is a 1-bp discrepancy where the authoritative sources,
not the pipeline, disagree with the tracer target:**

- Ensembl GRCh38 reports 48134287. NCBI dbSNP RefSNP reports SPDI
  `NC_000015.10:48134286` (0-based) = **48134287** (1-based). Two independent public
  authorities agree at 48134287.
- The tracer's target (48134288) equals the value in `snps.txt` for this locus, i.e.
  it inherited the systematic **+1 build bug** (below) that B2a exists to fix.
- The other tracer's hg38 target (rs12913832 = 28120472) equals the *correct* Ensembl
  value, so the two tracer hg38 targets are internally inconsistent about which source
  they trust.

Because the pipeline is corroborated by a second independent authority and the
discrepancy is fully explained by the known input bug, the map records the
authoritative 48134287; this discrepancy is surfaced here rather than silently
passed. All resolved coordinates come from the public databases; none were
fabricated or lifted-over by hand.

## Build bug this map fixes (B2a)
Across **all 222** panel loci, `snps.txt pos − Ensembl GRCh38 pos = +1` (uniform,
no exceptions; chromosome matches 100%). The panel's hg38 coordinates are
systematically one base too high (1-based vs 0-based off-by-one introduced when
`snps.txt` was built from the 0-based TSV `locations`). `pos_hg38` in this map is the
corrected, authoritative coordinate; `panel_pos_hg38` preserves the original buggy
value for traceability.

## Resolution summary
- **Panel SNPs: 222**
- **Resolved cleanly: 222 / 222** (100%)
- **Unresolved: 0** (no panel position was left without an authoritative variant)
- **Merged rsIDs (panel id → current id): 9** rows (`status = resolved_merged`):
  rs200426972→rs3071601, rs397854007→rs35629645, rs869190367→rs35995546,
  rs370724688→rs146410588, rs752243327→rs528795462, rs367554063→rs79064946,
  rs200118663→rs70964426, rs1184030188→rs367752652, rs397977468→rs11429237.
- **Strand-ambiguous (palindromic A/T or C/G): 11** — rs2524069, rs6497263,
  rs11636073, rs568405296, rs62052172, rs6429197, rs10080040, rs73077127,
  rs4644350, rs10160510, rs4355331. **Q4 must resolve strand for these before
  allele harmonization.**

## Caveats for Q4
- **Multiallelic sites (126 rows, noted `multiallelic`):** `alt_hg38`/`alt_hg19`
  list Ensembl's full observed allele set at the locus, which can exceed the
  panel's two genotyped alleles (e.g. rs1426654 = A/G/T, rs12913832 = A/C/G). The
  `strand_ambiguous` flag is computed under the strict biallelic definition, so
  multiallelic sites are flagged FALSE; Q4 should re-check strand ambiguity for any
  multiallelic site against the panel's actual genotyped alleles.
- **Allele consistency across builds:** for all 222 rows the GRCh38 and GRCh37
  `allele_string`s are identical (no cross-build strand flip), simplifying Q4.
- **3 co-located indel/repeat loci** (noted `co-located panel candidate(s)`): the
  TSV listed two rsIDs at the same locus; the dbSNP variant at that coordinate is an
  insertion/deletion or short repeat, not a SNV:
  - 15:28032794 → **rs34369918** (poly-A indel, OCA2); co-located: rs755407864
    (the only truly withdrawn/unresolvable id, absorbed by rs34369918).
  - 15:28041323 → **rs3071601** (poly-A indel, OCA2); both panel candidates
    (rs200426972, rs202126943) merge into rs3071601.
  - 5:33944491 → **rs1214023646** (small indel, SLC45A2/RXFP3); co-located:
    rs1491276502 → rs869097159 (AG-repeat). rs1214023646 chosen (resolves directly).

## Reproduction
1. Join `snps.txt` positions to `skin_pigmentation.tsv` rsIDs via `pos = locations + 1`.
2. Batch-POST the rsID set to the two Ensembl REST servers above (GRCh38, GRCh37).
3. Take each variant's primary-chromosome mapping; follow merges via `synonyms`.
4. Emit one row per panel position; flag biallelic palindromes; preserve panel origin.
