# SGDP sample metadata — provenance

`sgdp_metadata.tsv` maps each Simons Genome Diversity Project (SGDP) sample, keyed
by its Illumina/library ID (the `IID` used in our genotype files, e.g.
`LP6005441-DNA_D05`, `SS6004477`), to its population, continental region, country,
and sampling coordinates. It exists to colour SGDP PCA plots by geographic origin.

## Source

- **Paper:** Mallick S, Li H, Lipson M, et al. "The Simons Genome Diversity Project:
  300 genomes from 142 diverse populations." *Nature* 538, 201–206 (2016).
  DOI: [10.1038/nature18964](https://doi.org/10.1038/nature18964)
- **File:** `SGDP_metadata.279public.21signedLetter.44Fan.samples.txt`
- **Download URL:**
  `https://sharehost.hms.harvard.edu/genetics/reich_lab/sgdp/SGDP_metadata.279public.21signedLetter.44Fan.samples.txt`
  (David Reich Lab, Harvard Medical School — the canonical public SGDP release host)
- **Access date:** 2026-07-23
- **Downloaded size:** 54,485 bytes; 344 sample rows + 1 header row.

Note on TLS: `sharehost.hms.harvard.edu` serves a valid certificate
(`CN=*.hms.harvard.edu`, issuer `InCommon RSA OV SSL CA 3`, President and Fellows of
Harvard College) but the InCommon intermediate CA is missing from the default macOS
trust store, so `curl`/`WebFetch` fail chain verification. The server identity was
confirmed out-of-band via `openssl s_client` before downloading with `curl -k`.

## Column mapping (original → this file)

The upstream file is tab-separated with a `#`-prefixed header. Columns used:

| this file    | upstream column        | notes                                             |
|--------------|------------------------|---------------------------------------------------|
| `IID`        | `Illumina_ID` (col 2)  | matches our genotype sample IDs exactly           |
| `sgdp_id`    | `SGDP_ID` (col 5)      | e.g. `B_Han-3`; human-readable panel label        |
| `population` | `Population_ID` (col 6)| e.g. `Han`, `Yoruba`, `French`                    |
| `region`     | `Region` (col 7)       | continental group (see values below)              |
| `country`    | `Country` (col 8)      |                                                   |
| `latitude`   | `Latitude` (col 12)    | decimal degrees                                   |
| `longitude`  | `Longitude` (col 13)   | decimal degrees                                   |
| `embargo`    | `Embargo` (col 15)     | genotype-access category (see caveat)             |

Upstream columns not carried over: `Sequencing_Panel`, `Sample_ID`,
`Sample_ID(Aliases)`, `Town`, `Contributor`, `Gender`, `DNA_Source`, and the
`SGDP-lite category` column.

`region` takes exactly these 7 values (counts over all 344 rows): Africa (93),
WestEurasia (75), SouthAsia (49), EastAsia (47), America (28), CentralAsiaSiberia
(27), Oceania (25).

## Verification

- The `Illumina_ID` column format matches our genotype IDs (`LP…-DNA_…` and `SS…`).
- All 15 sample IDs currently present in `data/sgdp.wg.pca.eigenvec` were found in
  the metadata (15/15), each resolving to a sensible, distinct global population
  (e.g. Han/EastAsia, Yoruba/Africa, French/WestEurasia, Papuan/Oceania,
  Tlingit/CentralAsiaSiberia). No IDs were guessed or fabricated.
- `Illumina_ID` values are unique (no duplicate keys); all rows have 16 fields; all
  15 of our samples have non-empty latitude/longitude.

## Caveats

- **Coverage of the full 166:** `sanity_sgdp_pca.qmd` rebuilds the reference from all
  166 SGDP individuals, but only the 15-sample `sgdp.wg.pca.eigenvec` was available
  in-repo at write time, so only those 15 were positively confirmed. The other 151
  are expected to be a subset of these 344 rows and will left-join by `IID`; if any
  future `sgdp166_pca.eigenvec` IID is absent here, it will show as `NA` — re-check
  against this file rather than assuming a match.
- **`embargo` is about genotype-data access, not the metadata.** This table itself is
  public. The column marks each sample's genotype release tier: `FullyPublic` (279),
  `SignedLetterNoDelay` (21), `SignedLetterDelay` (44 "Fan" samples). All 15 of our
  current samples are `FullyPublic`.
- The upstream file contains a few non-ASCII bytes (accented town/contributor names);
  these live only in columns we did not carry over, so `sgdp_metadata.tsv` is ASCII.
