# Health-sensitive housing retrofit need index

This repository accompanies the manuscript **“A health-sensitive housing
retrofit need index for English neighbourhoods”** and its supplementary
material. It contains the public data, R code, and derived outputs used to
describe housing retrofit need across English Lower-layer Super Output Areas
(LSOAs).

The analysis compares:

- a **conventional index**, combining housing energy inefficiency and income
  deprivation; and
- an **enhanced (health-sensitive) index**, which additionally incorporates
  population health vulnerability.

The enhanced index was originally constructed in an approved secure
environment because condition-specific emergency-admission data are
safeguarded. Those confidential inputs are not included here. Instead, the
public workflow starts from a declassified LSOA-level index that excludes the
confidential columns, then reproduces the mapping, statistical summaries,
sensitivity analyses, and publication figures.

## Repository contents

| Path | Contents |
|---|---|
| [`open_data/`](open_data/) | Small public inputs retained in the repository, including the manually downloaded Nomis energy-efficiency extract and the declassified index hand-off file. See the [data guide](open_data/README.md). |
| [`scripts/`](scripts/) | Main R Markdown analysis and the sourced publication-plot script. See the [script guide](scripts/README.md). |
| [`outputs/`](outputs/) | Derived tables, maps, sensitivity plots, heat maps, and Sankey diagrams used in or supporting the manuscript and supplement. See the [output guide](outputs/README.md). |
| `housing_retrofits_final.Rproj` | RStudio project file; opening it sets the repository root as the working project. |
| `.gitignore` | Excludes R/RStudio session files and large public source files that the analysis downloads when required. |
| `.Rhistory` and `.Rproj.user/` | Local R/RStudio session metadata. These are ignored by Git and are not part of the publication repository. |

## Public reproduction workflow

1. Clone or download the repository and open
   `housing_retrofits_final.Rproj` in RStudio.
2. Confirm that the three files listed in the
   [`open_data` guide](open_data/README.md) are present.
3. Ensure that the R packages named in the setup section of the main R
   Markdown file are installed. Internet access is required for the public
   IMD, lookup, and boundary downloads.
4. Knit `scripts/housing_retofit_needs_index_v4.Rmd`, or render it from the
   repository root with:

   ```r
   rmarkdown::render(
     "scripts/housing_retofit_needs_index_v4.Rmd",
     knit_root_dir = normalizePath(".")
   )
   ```

The default data mode is `public`. In that mode, chunks requiring safeguarded
data are skipped and `open_data/housing_retrofit_need_index_lsoa_v3.csv` is
read as the hand-off point for all subsequent processing. The R Markdown file
then writes derived files to `outputs/` and sources
`scripts/create_retrofit_index_publication_plots_v2.R` to create the final
correlation and decile-transition graphics. A public run consumes, but does not
recreate, the declassified index; the matching copy in `outputs/` is an
archived public-safe product of the safeguarded build.

The repository does not currently contain an `renv` lockfile, so exact R
package versions are not pinned. Recording a lockfile or session information
with the archival release would further strengthen computational
reproducibility.

## Safeguarded rebuild

The full index-construction code is retained for methodological transparency,
but it is not runnable from the public repository alone. Authorised users in
the secure environment may set `HOUSING_RETROFIT_DATA_MODE=safeguarded` and
provide the secure directories named in the script. Safeguarded emergency
admissions, modelled population files, secure paths, and any outputs retaining
confidential columns must never be committed to this repository.

## Manuscript and supplementary material
The associated documents:
- `JECH_revised_manuscript_health_sensitive_retrofit_index.docx` contains
  the main article, including the national index methods, geographic results,
  local-authority variation, sensitivity analyses, and policy implications.
- `JECH_supplementary_material_enhanced_retrofit_index.docx` contains the
  extended methods, data-source and weighting tables, additional figures, and
  supplementary results.

Source datasets remain subject to the terms of their original publishers.
