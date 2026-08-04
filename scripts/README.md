# Analysis scripts

This folder contains the executable analysis for the manuscript and
supplementary material. Run the workflow from the repository root so that the
relative `open_data/`, `scripts/`, and `outputs/` paths resolve correctly.

## Files in this folder

### `housing_retofit_needs_index_v4.Rmd`

The main R Markdown analysis. It:

- defines public and safeguarded execution modes;
- reads the repository-held Nomis energy-efficiency export;
- downloads IMD, lookup, and boundary data from publisher endpoints;
- retains, but skips in public mode, the safeguarded population, QOF,
  emergency-admission, weighting, and index-construction stages;
- imports the declassified LSOA index for the public continuation;
- produces component and index maps, local-authority summaries, ANOVA and
  pairwise comparisons, correlations, and health-sensitivity plots;
- writes intermediate and final tables to `outputs/`; and
- sources `create_retrofit_index_publication_plots_v2.R` for the final
  correlation, heat-map, and Sankey exports.

The active energy-efficiency import is:
`open_data/housing_energy_efficiency_nomis.csv`. Although a Nomis provenance
URL remains in the setup list, the analysis does not query Nomis at run time.

In the default public mode, chunks marked `eval=run_safeguarded` are skipped.
The script then reads
`open_data/housing_retrofit_need_index_lsoa_v3.csv`, which contains no
condition-specific emergency-admission columns, and continues with the public
analysis. Do not set the safeguarded mode outside the authorised environment.

### `create_retrofit_index_publication_plots_v2.R`

A secondary plotting script sourced near the end of the R Markdown workflow.
It reads the two intermediate files
`outputs/rtft_indx_imd_corr_df.csv` and
`outputs/rtrft_lsoa11_lad_v4.csv` (or a `v4a` replacement), validates their
columns, and creates:

- the enhanced-index correlation chart;
- national and regional Sankey diagrams showing movement from conventional to
  enhanced deciles;
- national and regional heat maps showing the conventional-decile composition
  of enhanced deciles; and
- the national/regional decile-change summary table.

Each publication plot is saved as a 600-dpi PNG and a vector PDF. The script
also supports `--national-heatmaps-only`, `--combined-figures-only`, and
`--breakdown-table-only` arguments, but its normal use in this repository is by
being sourced from the R Markdown file, where `outputs_dir` has already been
defined.

## Execution order

1. Start R in the repository root, preferably by opening
   `housing_retrofits_final.Rproj`.
2. Install the packages loaded in the R Markdown setup chunk. Principal
   dependencies include `rmarkdown`, `tidyverse`, `readxl`, `janitor`, `sf`,
   `tmap`, `SmartEDA`, `sjmisc`, `datawizard`, `statsExpressions`, `lares`,
   `report`, `plotly`, `ggrepel`, `paletteer`, `ggsankeyfier`, `patchwork`,
   `scales`, `ragg`, and `tictoc`.
3. Render the main file:

   ```r
   rmarkdown::render(
     "scripts/housing_retofit_needs_index_v4.Rmd",
     knit_root_dir = normalizePath(".")
   )
   ```

   The explicit knitting root is required because the analysis uses paths
   relative to the top-level project directory.

4. Review the generated files against the inventory in
   [`outputs/README.md`](../outputs/README.md).

The script creates or overwrites files in `outputs/`. Exact package versions
are not currently recorded in a lockfile, so users should retain
`sessionInfo()` with any formal reproduction run.
