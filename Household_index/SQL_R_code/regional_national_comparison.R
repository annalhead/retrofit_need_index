# This script compares the national area-level open source index with the Cheshire & Merseyside household-level index at LSOA level 

library(data.table)
library(dplyr)


c_m <- fread("outputs/CIPHA index/2026-05-12/LSOA_rni_2025.csv")
national <- fread("outputs_v3/core_outputs/housing_retrofit_need_index_lsoa_v3.csv")


c_m[national, on = c("acorn_LSOA2011" = "LSOA11CD")
      , `:=` (rtrft_need_indx = i.rtrft_need_indx,
              rtrft_need_indx_mini = i.rtrft_need_indx_mini,
              hlth_vlnblty_dmain = i.hlth_vlnblty_dmain
              )]

summary(lm(rtrft_need_indx ~ rni, data = c_m)) #Adj R2 = 0.8344
summary(lm(rtrft_need_indx ~ rni, data = c_m[year == 2025 & rni_N >100])) #Adj R2 = 0.8344
c_m[year == 2025, plot(rtrft_need_indx, rni)]


# EPC as only eligibility criteria - not well correlated
summary(lm(rtrft_need_indx ~ rni_sa1, data = c_m[year == 2025 & rni_N >100])) #Adj R2 = 0.002719
c_m[year == 2025, plot(rtrft_need_indx, rni_sa1)]

# No missing EPC
summary(lm(rtrft_need_indx ~ rni_sa2, data = c_m[year == 2025& rni_N >100])) #Adj R2 = 0.8072
c_m[year == 2025, plot(rtrft_need_indx, rni_sa2)]


# Bivariate plot
library(biscale)
library(ggplot2)
library(sf)
c_m[, `:=` (national_thirds = ntile(rtrft_need_indx, 3),
                    regional_thirds = ntile(rni, 3)) ]
c_m <- bi_class(c_m, x = rtrft_need_indx, y =  rni, style = "quantile", dim = 3)

lsoa_11_sf <-
  read_sf("open_data/LSOA_2011_Boundaries_Super_Generalised_Clipped_BSC_EW_V4_2637602833960592029/LSOA_2011_EW_BSC_V4.shp") 

lsoa_la <- fread("open_data/LSOA_(2011)_to_LSOA_(2021)_to_Local_Authority_District_(2022)_Best_Fit_Lookup_for_EW_(V2).csv")
lcr_lsoa <- lsoa_la[LAD22NM %in% c("Halton", "Knowsley", "Liverpool", "Sefton", "St. Helens","Wirral" ), unique(LSOA11CD)]

setDT(lsoa_11_sf)

c_m[lsoa_11_sf, on = c("acorn_LSOA2011" = "LSOA11CD"), `:=` (geometry = i.geometry, LSOA11NM = i.LSOA11NM)]

c_m <- c_m[acorn_LSOA2011 %in% lcr_lsoa]
c_m[lsoa_la, on = c("acorn_LSOA2011" = "LSOA11CD"), `:=` (LSOA11NM = i.LSOA11NM, LAD22NM = i.LAD22NM)]


# 
map <- 
  ggplot() +
  geom_sf(data = c_m[rni_N >= 100],
          aes(geometry = geometry  ,
              fill = bi_class, colour = bi_class), show.legend = F )+
  bi_scale_fill(pal = "GrPink", dim =3) +
  bi_scale_color(pal = "GrPink", dim =3) +
 # labs(title = "Comparison of neighbourhood- \nand household-level indices") +
  bi_theme() + coord_sf(xlim = c(300000,360000), ylim = c(375000, 420000)) +
  theme(panel.background = element_blank())


legend <- bi_legend("GrPink",
                    dim = 3,
                    xlab = "Neighbourhood: Greater need",
                    ylab = "Household: Greater need",
                    size = 6)

library(cowplot)
finalPlot <- ggdraw() +
  draw_plot(map, 0,0,1,1) +
  draw_plot(legend, 0.1,0.1,.2,.2)
finalPlot 
ggsave("outputs/neighbourhood_v_household_bivar.png",
       dpi = 900,
       width = 12,
       height = 8)

ggsave("outputs/neighbourhood_v_household_bivar.svg",
       dpi = 900,
       width = 12,
       height = 8)


# Comparing the deciles of the two indices 
c_m[, household_decile := ntile(rni, 10)]
c_m[, neighbourhood_decile := ntile(rtrft_need_indx, 10)]
c_m[, .N, keyby = household_decile == neighbourhood_decile] # 391/989 LSOAs in same decile in both 
c_m[, .N, keyby = abs(household_decile - neighbourhood_decile)] # 804/989 LSOAs no more than 1 decile different 

