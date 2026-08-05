# Open-data inputs

This folder contains the small, non-confidential inputs that must travel with
the publication repository. The main analysis runs from the repository root
and defaults to `HOUSING_RETROFIT_DATA_MODE=public`.

## Files in this folder

| File | Description and role |
|---|---|
| `housing_energy_efficiency_nomis.csv` | Manually queried Nomis export for **Energy efficiency of housing, 2024**, downloaded on 2 October 2025. It contains dwelling counts and percentages by EPC bands A–G for 2021 LSOAs in England and Wales. The R Markdown file reads this repository copy with `skip = 5`, cleans the export headings, and calculates the number and percentage of dwellings rated band D or worse. This is the active energy-efficiency input; it is not downloaded automatically. |
| `housing_retrofit_need_index_lsoa_v3.csv` | Declassified hand-off dataset for 32,844 English LSOAs. It contains geographic identifiers, public component indicators, conventional and enhanced index values, standardised/relative scores, and ranks. The public workflow imports this file after skipping the safeguarded construction chunks. |
| `disease_wts_use.xlsx` | Author-prepared workbook (`disease_wts` sheet) containing the health-condition weights used to construct the health-vulnerability domain, based on the health-impact estimates described in the manuscript and Rodgers et al. (2018). It is retained for method transparency and is read only during an authorised safeguarded rebuild. |

The declassified index deliberately excludes the condition-specific
emergency-admission columns `asthma.p_rate`, `respiratory.p_rate`,
`cvd.p_rate`, and `burns_falls_65_ova.p_rate`. It is also written to
`outputs/housing_retrofit_need_index_lsoa_v3.csv` when the safeguarded index is
rebuilt; the `open_data` copy is the stable public input.

### Main index column groups

- `LSOA*` and `LAD*`: 2011/2021 LSOA and 2020 local-authority identifiers and
  names.
- `income_score_rate`, `MentalHealth.p_rate`, `copd_asthma.p_rate`, and
  `epc_lss_eql_d_*`: public component indicators.
- `hlth_vlnblty_dmain`: combined health-vulnerability domain.
- `rtrft_need_indx*`: enhanced health-sensitive index values, relative scores,
  z-scores, and ranks.
- `rtrft_need_indx_mini*`: conventional index equivalents, excluding the
  health-vulnerability domain.

## Public data retrieved at run time

The following larger or publisher-maintained resources are read directly from
their online sources and should not be duplicated in this folder:

| Input | Use | Source |
|---|---|---|
| English Indices of Deprivation 2019, File 5 | Income deprivation and comparison correlations; public and safeguarded modes | [GOV.UK Excel download](https://assets.publishing.service.gov.uk/media/5d8b3b51ed915d036a455aa6/File_5_-_IoD2019_Scores.xlsx) |
| LSOA 2011 boundaries and LAD 2011 boundaries | National maps; public and safeguarded modes | [ONS Open Geography LSOA GeoJSON](https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/f23b8af6504640558a5100dfcd19a7ee/geojson?layers=0) and [LAD GeoJSON](https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/ad7f01a8ae73441b95444080c78caa17/geojson?layers=0) |
| LSOA 2011-to-region lookup | Regional summaries and plots; public and safeguarded modes | [ONS Open Geography CSV](https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/c1e13af610c84ec59f086502e8ebe4f7/csv?layers=0) |
| LSOA 2011-to-2021/LAD 2022 and LSOA 2011-to-Ward/LAD 2020 lookups | Geography harmonisation during the safeguarded rebuild | [ONS 2011–2021 lookup](https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/b684a0dbf786473f9563ec0616da2f8b/csv?layers=0) and [ONS LAD 2020 lookup](https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/31dfd51115194a6bbe0bf4a26019f884/csv?layers=0) |
| QOF asthma, COPD, and mental-health prevalence | Health-vulnerability construction during the safeguarded rebuild | [Asthma](https://pldr.org/download/e6nzv/ng1/QOF_4_03_Asthma_LSOA.csv), [COPD](https://pldr.org/download/23q1e/2tm/QOF_4_04_COPD_LSOA.csv), and [mental health](https://pldr.org/download/ex3od/j5c/QOF_4_15_MentalHealth_LSOA.csv) PLDR extracts |

The Nomis file in this directory was obtained through the publisher’s manual
[query interface](https://www.nomisweb.co.uk/query/construct/submit.asp?menuopt=201&subcomp=).
Its small size and the manual query steps are the reasons it is stored in the
repository rather than fetched at run time.

## Safeguarded inputs not included

The following inputs are used only inside the approved secure environment and
must never be committed:

- emergency-admission indicator files matching
  `PLDR_v5_2_*_APC_all_byLSOA.csv` and `*v5_2_49_APC_age5_byLSOA*`, supplied
  through `EMERGENCY_ADMISSIONS_ROOT`; and
- modelled LSOA population files matching `LSOA_65plus_mod_*.csv`, supplied
  through `LSOA_POPULATION_ROOT`.

The environment-variable approach keeps secure filesystem paths and protected
data out of the public code and repository.
