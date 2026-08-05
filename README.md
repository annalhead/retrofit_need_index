# Health-sensitive housing retrofit need index

This repository accompanies the manuscript **“A health-sensitive housing
retrofit need index for English neighbourhoods”** and its supplementary
material. It contains the public data, R code, and derived outputs used to
investigate housing retrofit need across English Lower-layer Super Output Areas
(LSOAs), as well as validation using a household-level index for the Cheshire & 
Merseyside region.

The analysis compares:

- a **conventional index**, combining housing energy inefficiency and income
  deprivation; and
- an **enhanced (health-sensitive) index**, which additionally incorporates
  population health vulnerability.

This repository contains two sub-directories:
1. Neighbourhood_index: this is the main analysis in the paper. It creates a national neighbourhood-level housing retrofit index for England, using neighbourhood-level (LSOA) data
  ![Alt "Enhanced index and difference map"](https://github.com/annalhead/retrofit_need_index/blob/main/Neighbourhood_index/outputs/lsoa_need_relv_indx2_maps_v4_fshr.png)

  ![Alt LSOA and LA decile transition heatmaps](https://github.com/annalhead/retrofit_need_index/blob/main/Neighbourhood_index/outputs/enhanced_decile_composition_heatmaps_national_combined_v2.png)
  
2. Household_index: this is for validation. It creates a household-level housing retrofit index for Cheshire & Merseyside, using household-level data, aggregated back to neighbourhood-level
  ![Alt "Neighbourhood and household comparison"](https://github.com/annalhead/retrofit_need_index/blob/main/Household_index/Outputs/neighbourhood_v_household_bivar.png)
