# Derived outputs

This folder contains the public, derived tables and graphics produced by
`scripts/housing_retofit_needs_index_v4.Rmd` and its sourced plotting script.
No safeguarded row-level data or condition-specific emergency-admission
columns should appear here.

`LSOA` means Lower-layer Super Output Area and `LA`/`LAD` means local authority
district. The conventional index combines energy inefficiency and income
deprivation; the enhanced index additionally includes health vulnerability.

## Index and statistical tables

| File | Description |
|---|---|
| `housing_retrofit_need_index_lsoa_v3.csv` | Public LSOA-level index for 32,844 English neighbourhoods. This archived declassified output comes from a safeguarded rebuild and mirrors the stable hand-off copy in `open_data/`; it is not regenerated in default public mode. |
| `housing_retrofit_need_index_LA_v3b.csv` | Descriptive statistics for the enhanced relative index across the 314 local authorities represented in the analysis, including mean, standard deviation, interquartile range, range, skewness, kurtosis, and observation counts. |
| `oneway_anova_df_v3.csv` | Tidy export of the robust one-way ANOVA comparing neighbourhood enhanced-index values across local authorities; the Isles of Scilly is excluded because it has only one LSOA observation. |
| `pairwise_t_test_of_need_index_LA_v3.csv` | Statistically significant local-authority pairwise comparisons of neighbourhood enhanced-index values after Holm adjustment. |
| `rtft_indx_imd_corr_df.csv` | Pearson correlations and p-values for the enhanced retrofit index against IMD and related indicators. It is an intermediate input to the publication correlation plot. |
| `rtrft_lsoa11_lad_v4.csv` | Analysis-ready LSOA table with index values, local-authority summaries, English regions, and conventional/enhanced deciles at LSOA and LA levels. It is the main input to the heat-map, Sankey, and transition-summary script. |
| `retrofit_decile_change_breakdown_by_region_v2.csv` | Publication-ready national and regional counts/percentages of LSOAs and local authorities changing decile, including units newly entering the highest-need enhanced decile. |

## Maps and sensitivity figures from the main R Markdown file

| File | Description | Manuscript role |
|---|---|---|
| `indtr_map_dmains_v4_fshr.png` | Side-by-side national maps of the energy inefficiency, income deprivation, and health-vulnerability domains. | Main Figure 1. |
| `lsoa_need_relv_indx1_maps_v4_fshr.png` | National comparison of conventional and enhanced relative indices, drawn on separate classification scales. | Supplementary Figure S1. |
| `lsoa_need_relv_indx2_maps_v4_fshr.png` | Enhanced relative-index map paired with the change from conventional to enhanced index. | Main Figure 2. |
| `rtrft_lsoa11_lad_bxplt_v3a.png` | Distribution of LSOA enhanced relative-index values within each local authority. | Main Figure 3. |
| `rtrft_lsoa11_lad_bxplt_dcl_v4.png` | Boxplots focused on local authorities in the highest- and lowest-need deciles. | Supporting local-authority sensitivity output. |
| `sntvty_indx_hlth_vuln_plt_v3.png` | Cleveland-style comparison of conventional and enhanced values/ranks for the 100 highest-need neighbourhoods. | Supplementary Figure S2. |

## Publication plot pairs

Each item below exists as both `.png` and `.pdf` with the same filename stem.
PNG files are high-resolution raster versions for document insertion; PDF
files are vector versions for publication and editing.

| Filename stem (`.png` and `.pdf`) | Description | Manuscript role |
|---|---|---|
| `retrofit_index_correlations_v2` | Bar chart of the magnitude and direction of correlations between the enhanced index and IMD-related measures. | Supplementary Figure S5. |
| `retrofit_decile_transitions_local_authorities_v2` | National Sankey diagram of local-authority movement from conventional to enhanced deciles. | Supporting national transition output. |
| `retrofit_decile_transitions_lsoas_v2` | National Sankey diagram of LSOA movement from conventional to enhanced deciles. | Supplementary Figure S3. |
| `retrofit_decile_transitions_local_authorities_by_region_v2` | Regional facets of local-authority decile transitions. | Supplementary Figure S4. |
| `retrofit_decile_transitions_lsoas_by_region_v2` | Regional facets of LSOA decile transitions. | Supporting regional transition output. |
| `enhanced_decile_composition_heatmap_local_authorities_v2` | National heat map showing which conventional deciles compose each enhanced local-authority decile. | Component of the national comparison. |
| `enhanced_decile_composition_heatmap_lsoas_v2` | National heat map showing which conventional deciles compose each enhanced LSOA decile. | Component of the national comparison. |
| `enhanced_decile_composition_heatmaps_national_combined_v2` | Combined national LSOA and local-authority decile-composition heat maps. | Main Figure 4. |
| `enhanced_decile_composition_heatmap_local_authorities_by_region_v2` | Regional facets of enhanced local-authority decile composition. | Supporting regional comparison output. |
| `enhanced_decile_composition_heatmap_lsoas_by_region_v2` | Regional facets of enhanced LSOA decile composition. | Main Figure 5. |
| `retrofit_decile_transitions_national_combined_v2` | Combined national LSOA and local-authority Sankey diagrams. | Supporting combined transition output. |

Main Figure 6 and the household-level regional comparison described in the
manuscript rely on a separate safeguarded regional analysis and are not
generated by the public scripts in this repository.

## Regeneration notes

The contents of this folder are derived and may be overwritten when the main R
Markdown file is rendered. The two plotting intermediates
`rtft_indx_imd_corr_df.csv` and `rtrft_lsoa11_lad_v4.csv` must exist before the
secondary publication-plot script is sourced. Differences in R package,
font-rendering, or geospatial-library versions may cause small visual changes
without changing the underlying results.
