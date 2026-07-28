# Household-level health-sensitive retrofit need index for Cheshire and Merseyside 
#' @author: Anna Head
#' @email: anna.head2@liverpool.ac.uk
#' 
#' @author: Lohavani Sevverl
#' @email: lohavani.Sevverl@liverpool.ac.uk
#' 
#' @date: 2026-04-27
#' 
#' 
#' */
  

# This script creates a household-level health-sensitive retrofit need index 
# for Cheshire and Merseyside ICB

# This script takes as input: cleaned yearly data from 2018-2025 for households
# in Cheshire & Merseyside from GP events, GP prescription, A&E emergency admissions, 
# and Acorn UPRN tables (unique property reference number) 
# Data are aggregated to household/UPRN level (i.e. each household has 1 row per year)

# Binary columns were derived at household level for:
# - Child under 14 in the household: "gp_under14_flag"
# - Adult over 64 in the household: "gp_over64_flag"
# - Primary care CVD diagnosis: "cvd_diagnosis" 
# - Primary care COPD diagnosis:"copd_diagnosis", 
# - Primary care asthma diagnosis:"asthma_diagnosis", 
# - Primary care respiratory diagnosis (COPD or asthma): "resp_gp"
# - Primary care CMD medication prescribed:"cmd_medication" 
# - Primary care respiratory medication prescribed:"resp_medication" 
# - Emergency admissions for CVD: "cvd_apce", 
# - Emergency admissions for respiratory conditions: "resp_apce", 
# - Emergency admissions for falls or injuries: "injuries_apce", 

# Also calculated at household level:
# - number of people in the household: "persons"
# - number of children under 14 in the household: "child_N"
# - number of adults over 64 in the household: "old_N"

# The Acorn UPRN tables were used for:
# - energy performance certificate rating (EPC): "EPC_Current_Energy_Rating"
# - LSOA: "acorn_LSOA2011" - used for linkage to IMD for income 
#         deprivation score "imd_inc_score"

# # SETUP ----

# # replace with your details
# server <- "xxx" # server name
# db <- "xxx" # database name
# driver <- "xxx" # driver name
# user_name <- "xxx" # user name
# open_input_dir <- "xxx" # open input data directory
# secure_outputs_dir <- "xxx" # output directory 


library(DBI)
library(odbc)
library(data.table)
library(fixest)
library(broom)
library(dplyr)
# 
# CONNECTION ----
conn <- DBI::dbConnect(odbc::odbc(),
                       UID = user_name,
                       Driver= driver,
                       Server = server,
                       Database = db,
                       Authentication = "ActiveDirectoryInteractive")


# Set-up
years <- c(2018:2025) # Years of interest 
set.seed(42) # Fixing a seed for replicability


# Chesire & Merseyside LSOAs
lsoa_lookup_tbl <- fread(paset0(open_input_dir, "LSOA_2011_to_LSOA_2021_to_LAD_2022_lookup_EW_V2.csv"))
# Available from https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2011-to-lsoa-2021-to-local-authority-district-2022-exact-fit-lookup-for-ew-v3/about 

# create subset for the NHS Cheshire and Merseyside ICB
c_m_lsoa <- lsoa_lookup_tbl[LAD22NM %in% c("Cheshire East", "Cheshire West and Chester", "Halton", "Knowsley", "Liverpool", "Sefton","St. Helens","Warrington", "Wirral"  ),
                            LSOA11CD]

# create subset for Liverpool City Region local authorites
liv_lsoa <- lsoa_lookup_tbl[LAD22NM %in% c("Halton", "Knowsley", "Liverpool", "Sefton","St. Helens", "Wirral"  ),
                            LSOA11CD]


# Loop for creating the index 
for ( year in years){
res <- dbSendQuery(conn, paste0("SELECT * FROM Database", year ,"summary_uprn")) # replace with database name 
dt <- dbFetch(res)
# View(dt)
setDT(dt)
names(dt)
dt <- dt[!is.na(uprn)  & #keeping only those with a UPRN present 
           acorn_LSOA2011 %in% c_m_lsoa ]# keeping only c&m local authorities

# Creating flags for vulnerable age-groups 
dt[, `:=` (child_u14 = ifelse(gp_under14_flag == "Y", 1, 0 ),
           old_o64 = ifelse(gp_over64_flag == "Y", 1, 0 ),
           year = year)]

conds <- c("child_u14", "old_o64", "cvd_diagnosis", "copd_diagnosis", 
           "asthma_diagnosis", "cmd_medication" )


# Percentage of vulnerable age-groups in households 
 dt[, `:=` (pct_child = ( child_N) / persons,  
            pct_old = old_N / persons)]
 
vuln <- c("pct_child", "pct_old" )

# creating poverty flag using fixed effects OLS regression 
# based on imd_inc_score and percentage of people in household who are vulnerable
dt[, c(paste0("mean_", vuln)) := lapply(.SD, mean), by = .(acorn_LSOA2011), .SDcols = vuln]
var <- c("acorn_LSOA2011", "imd_inc_score" , paste0("mean_", vuln)) 
lsoa_temp <- unique(dt[, ..var])
lsoa_temp[, c(vuln) := .SD, .SDcols = paste0("mean_", vuln)]
f2 <- as.formula(paste0("log(imd_inc_score)~", paste0(vuln, collapse = "+")))
m2 <- feols(f2, data = lsoa_temp)
param2 <- as.data.table(tidy(m2))[, .(term, estimate)]
param2[, estimate := exp(estimate)]

# use estimates to generate relative risk of poverty 
dt[, rr := 1]
for (i in vuln) {
  dt[get(i) != 0, rr := rr*get(i)*param2[term == i]$estimate]
}
dt[, adj_pov := imd_inc_score * rr]
dt[adj_pov > 1, adj_pov := 1] # Capping adj_pov at 1 as max value for rbinom

#readjust back to lsoa mean for poverty levels
dt[, adj_pov := adj_pov * (imd_inc_score / mean(adj_pov)), by = .(acorn_LSOA2011)]
dt[adj_pov > 1, adj_pov := 1] # Capping adj_pov at 1 as max value for rbinom

#impute poverty flag using binomial distribution
dt[!is.na(adj_pov), poverty := rbinom (.N, size = 1, prob = adj_pov), by = acorn_LSOA2011 ]
table(dt$poverty, useNA = "ifany")
dt[, c(paste0("mean_", vuln), "rr", "adj_pov") := NULL]



# Imputing low EPC flag where EPC rating missing 
dt[EPC_Current_Energy_Rating != "NA", lowEPC := 
     ifelse(EPC_Current_Energy_Rating %in% c("D", "E", "F", "G"), 1, 0)]

#Imputing based on IMD_income score and low EPC rating in the area 
conds3 <- c("imd_inc_score", "lowEPC")

dt[, c(paste0("mean_", conds3)) :=lapply(.SD, mean, na.rm = T),
   by = .(acorn_LSOA2011),
   .SDcols = conds3]
var <- c("acorn_LSOA2011", "EPC_Current_Energy_Rating" , paste0("mean_", conds3)) 
lsoa_temp <- unique(dt[, ..var])
lsoa_temp[, c(conds3) := .SD, .SDcols = paste0("mean_", conds3)]
f1 <- as.formula(paste0("log(mean_lowEPC)~", paste0(conds3, collapse = "+")))
m1 <- feols(f1, data = lsoa_temp)
param <- as.data.table(tidy(m1))[, .(term, estimate)]
param[, estimate := exp(estimate)]

# use estimates to generate relative risk of low EPC where EPC missing 
dt[, rr := 1]
for (i in conds3) {
  dt[get(i) != 0, rr := rr*get(i)*param[term == i]$estimate]
}
dt[is.na(lowEPC), adj_EPC := mean_lowEPC * rr]
dt[adj_EPC > 1, adj_EPC := 1] # Capping adj_EPC at 1 

#readjust back to lsoa mean
dt[, adj_EPC := adj_EPC * (mean_lowEPC / mean(adj_EPC, na.rm = T)), by = .(acorn_LSOA2011)]
dt[adj_EPC > 1, adj_EPC := 1] # Capping adj_EPC at 1 

#impute low EPC flag using binomial distribution 

dt[!is.na(adj_EPC) & is.na(lowEPC), lowEPC := rbinom (.N, size = 1, prob = adj_EPC), by = acorn_LSOA2011]
table(dt$lowEPC, useNA = "ifany")

dt[, c(paste0("mean_", conds3), "rr", "adj_EPC") := NULL]

# Applying weights for vulnerable age groups, poverty, lowEPC, and healthcare use
conds2 <- c("old_o64", "child_u14", "poverty", "lowEPC", "cvd_apce", "resp_apce", "injuries_apce", "cmd_medication", "resp_medication",  "resp_gp" )

# keeping a separate table of these without weights for later 
tmp <- dt[, lapply(.SD, mean, na.rm = T), .SDcols = conds2, keyby=  .(acorn_LSOA2011)]
setnames(tmp, conds2, paste0("lsoa_", conds2) )

# Healthcare Weights from Rodgers et al. 2018
# Emergency admissions for CVD all ages 1.14936232 
# Emergency admissions for resp conditions all ages 1.14099571 
# Emergency admissions for injuries age 60+ 1.22366723 
# Prescribed medications for participants with a CMD 1.02359888 
# Resp prescriptions for participants with history of resp conditions all ages 1.02442886 
# GP contacts for participants with a history of asthma or COPD 1.01926847
wts <- c(1.2, 1.2, 1, 1 ,1.14936232, 1.14099571, 1.22366723, 1.02359888, 1.02442886, 1.01926847)
wts <- data.table(wts, conds2)
for (i in conds2){
  dt[, (i) := get(i)*wts[conds2 == i, wts]]
}

# Additive health vulnerability 
dt[
   , `:=` (
           rni_health_vuln_add =  old_o64+child_u14+cvd_apce+resp_apce+injuries_apce+cmd_medication+resp_medication+resp_gp)][
             rni_health_vuln_add == 0 , rni_health_vuln_add := 1 # so that people with no health need but retrofit eligibility have a need of 1
           ] 

# Multiplicative health vulnerability 
# setting 0 values to 1 so that work when multiplying health weights, and so that people with no health need but retrofit eligibility have a need of 1
for (i in conds2[!conds2 %in% c("poverty", "lowEPC")]){
  set(dt, NULL, i, ifelse(dt[[i]] == 0L, 1L, dt[[i]]))}

# rni_health is healthcare weights multiplied
# rni_health_vuln is healthcare & vulnerability weights multiplied
# rni_vuln is vulnerability weights multiplied 
dt[
   , `:=` (rni_health_vuln =  old_o64*child_u14*
             cvd_apce*resp_apce*injuries_apce*cmd_medication*resp_medication*resp_gp,
           rni_health =  
             cvd_apce*resp_apce*injuries_apce*cmd_medication*resp_medication*resp_gp,
           rni_vuln =  old_o64*child_u14)]

#Main eligibility is poverty AND lowEPC
dt[, eligibility := poverty * lowEPC] 
dt[, eligibility_sa1 := lowEPC] # SA1 is lowEPC only for eligibility 
dt[EPC_Current_Energy_Rating != "NA" & # SA2 is as main eligibility, but without imputed low EPC
     EPC_Current_Energy_Rating != "INVALID!", eligibility_sa2 := poverty * lowEPC]

# Centering to the mean value 
demean <- function(x){
  x = x/mean(x, na.rm = T)
}
dt[,rni_health_vuln_demean := demean(rni_health_vuln)]
dt[,rni_health_demean := demean(rni_health)]
dt[,rni_vuln_demean := demean(rni_vuln)]
dt[, rni := rni_health_vuln_demean *poverty*lowEPC ]
dt[,rni_health_vuln_add_demean := demean(rni_health_vuln_add)]
dt[, rni_add := rni_health_vuln_add_demean *poverty*lowEPC ]


# RNI sensitivity analysis 1: not including poverty as a criteria
dt[, rni_sa1 := lowEPC*rni_health_vuln_demean ] 
# RNI sensitivity analysis 2: not including imputed EPC 
dt[EPC_Current_Energy_Rating != "NA" &
     EPC_Current_Energy_Rating != "INVALID!", 
   rni_sa2 := poverty*lowEPC*rni_health_vuln_demean ] 


# Flag for inclusion in each version of index (for disclosure checking)
dt[,   valid_rni := ifelse(is.na(rni), 0, 1)]
dt[,   valid_rni_sa1 := ifelse(is.na(rni_sa1), 0, 1)]
dt[,   valid_rni_sa2 := ifelse(is.na(rni_sa2), 0, 1)]


# # For visualisations, data checking: 
# hist(dt$rni, breaks = 20)
# hist(dt$rni_add, breaks = 20)
# summary(dt[, .(rni, rni_add)])
# plot(dt$rni, dt$rni_add)
# summary(lm(rni ~ rni_add, data = dt))
# dt[eligibility == 1, .N, keyby = rni_health_vuln_demean > 1]

fwrite(dt, paste0("P:/HUP/phirst-housing-retrofit/Secure_data/uprn_rni_", year, ".csv"))

# Creating summaries at LSOA level for extraction - mean at LSOA level, 
# then re-centering to the weighted mean of LSOA level values so that 1 is the
# average need across LSOAs, weighted to LSOA number of households 
lsoa_sum <- dt[, .(
                   rni_N = sum(valid_rni),
                   rni = mean(rni),
                   rni_min = min(rni), 
                   rni_q25 = quantile(rni, 0.25), 
                   rni_q50 = quantile(rni, 0.50), 
                   rni_q75 = quantile(rni, 0.75), 
                   rni_max = max(rni), 
                   rni_big_N = sum(rni > 1  ), # number of households with greater than average health need AND eligible
                   rni_add = mean(rni_add),
                   health_vuln_need = mean(rni_health_vuln_demean, na.rm =T),
                   rni_hv_min = min(health_vuln_need), 
                   rni_hv_q25 = quantile(health_vuln_need, 0.25), 
                   rni_hv_q50 = quantile(health_vuln_need, 0.50), 
                   rni_hv_q75 = quantile(health_vuln_need, 0.75), 
                   rni_hv_max = max(health_vuln_need), 
                   health_need = mean(rni_health_demean, na.rm =T),
                   vuln_need = mean(rni_vuln_demean, na.rm =T),
                   eligibility_pc = mean(eligibility, na.rm =T), 
                   eligibility_sa1_pc = mean(eligibility_sa1, na.rm =T), 
                   eligibility_sa2_pc = mean(eligibility_sa2, na.rm =T), 
                   eligibility_N = sum(eligibility, na.rm =T), 
                   eligibility_sa1_N = sum(eligibility_sa1, na.rm =T), 
                   eligibility_sa2_N = sum(eligibility_sa2, na.rm =T), 
                   lowEPC_N = sum(lowEPC, na.rm =T), 
                   poverty_N = sum(poverty, na.rm =T), 
                   lowEPC_pc = mean(lowEPC, na.rm =T), 
                   poverty_pc = mean(poverty, na.rm =T), 
                   rni_sa1_N = sum(valid_rni_sa1, na.rm =T),
                   rni_sa1 = mean(rni_sa1, na.rm =T),
                   rni_sa1_big_N = sum(rni_sa1 > 1 ,na.rm =T ), # number of households with greater than average health need AND eligible
                   rni_sa2_N = sum(valid_rni_sa2, na.rm = T),
                   rni_sa2 = mean(rni_sa2, na.rm = T),
                   rni_sa2_big_N = sum(rni_sa2 > 1 , na.rm = T )), # number of households with greater than average health need AND eligible
               keyby = .(acorn_LSOA2011, imd_dec, imd_inc_score)][ , `:=` (year = year)]

lsoa_demean <- function(x, y){
  x = x/weighted.mean(x, w = y, na.rm = T)
}
lsoa_sum[, rni_demean := lsoa_demean(rni, rni_N)]
lsoa_sum[, rni_h_demean := lsoa_demean(health_need, rni_N)]
lsoa_sum[, rni_hv_demean := lsoa_demean(health_vuln_need, rni_N)]

# # For visualisations, data checking: 
# hist(lsoa_sum$lsoa_rni, breaks = 20)
# hist(lsoa_sum$lsoa_rni_add, breaks = 20)
# summary(lsoa_sum[, .(lsoa_rni, lsoa_rni_add)])
# plot(lsoa_sum$lsoa_rni, lsoa_sum$lsoa_rni_add)
# summary(lm(lsoa_rni ~ lsoa_rni_add, data = lsoa_sum))

fwrite(lsoa_sum, paste0(secure_outputs_dir, "/lsoa_rni_raw_", year, ".csv"))
}



## Looking at index over time 
files <- list.files(path = paste0(secure_outputs_dir), pattern = "lsoa", full.names = T)
lsoa <- rbindlist(lapply(files, fread), fill = T)

lsoa[acorn_LSOA2011  %in% c_m_lsoa, uniqueN(acorn_LSOA2011)] #1562 LSOAs


lsoa[,uniqueN(acorn_LSOA2011)] # 4950
lsoa[acorn_LSOA2011  %in% c_m_lsoa , uniqueN(acorn_LSOA2011) ] #1562
lsoa_cm <- lsoa[acorn_LSOA2011  %in% c_m_lsoa & rni_N > 9 , ]
lsoa_cm[,uniqueN(acorn_LSOA2011)]  #1562

lsoa_cm[, rni_big_pc := rni_big_N / rni_N ]
lsoa_cm[, rni_big_sa1_pc := rni_sa1_big_N  / rni_sa1_N     ]
lsoa_cm[, rni_big_sa2_pc := rni_sa2_big_N  / rni_sa2_N     ]
lsoa_cm[, c("eligibility_N", "eligibility_sa1_N", "eligibility_sa2_N", "poverty_N", 
            "lowEPC_N", "rni_big_N", "rni_sa1_big_N", "rni_sa2_big_N") := NULL]

fwrite(lsoa_cm, paste0(secure_outputs_dir, "LSOA_rni_v0-3-0_raw.csv"))

# 1 lsoa has much smaller numbers of houses than others and very extreme RNI values so will remove from plots 
lsoa_cm[ rni_N < 100 | rni_sa1_N <100 | rni_sa2_N <100,           ]



# Exploratory plots 

# load LSOA data
library("janitor")
library("sf")
library("dplyr")
lsoa_2011_shape <- paste0(open_input_dir, "Lower_layer_Super_Output_Areas_2011_EW_BFC_V3.geojson") |>
  sf::st_read() |>
  janitor::clean_names() |>
  dplyr::select(lsoa11cd, lsoa11nm)
# Available from https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-boundaries-ew-bfc-v3/about 

setDT(lsoa_2011_shape)
names(lsoa_2011_shape)
lsoa_cm[lsoa_2011_shape, on = c('acorn_LSOA2011' = 'lsoa11cd'), 
     `:=` (lsoa11nm = `i.lsoa11nm`, geometry = i.geometry)]

library(ggplot2)

# RNI 2025

p <- ggplot() +
  geom_sf(data = lsoa_cm[ rni_N >= 100 & year == 2025],
          aes(geometry = geometry  ,
              fill = rni_demean,
              colour = rni_demean)) +
  facet_wrap(vars(year)) + theme_void() +
  scale_fill_gradient2( midpoint = 1) +
  scale_colour_gradient2(midpoint = 1) + 
  coord_sf(xlim = c(320000,400000), ylim = c(340000, 430000))

p
# ggsave(paste0(secure_outputs_dir, "rni_2025.png"),
#                 dpi = 900,
#                 width = 11,
#                 height = 5)
# 


# Annual health vuln

p <- ggplot() +
  geom_sf(data = lsoa_cm[ rni_N >= 100],
          aes(geometry = geometry  ,
              fill = rni_hv_demean ,
              colour = rni_hv_demean )) +
  facet_wrap(vars(year)) + theme_void() +
  scale_fill_gradient2( midpoint = 1) +
  scale_colour_gradient2(midpoint = 1) + 
  coord_sf(xlim = c(320000,400000), ylim = c(340000, 430000))

p
# ggsave(paset0(secure_outputs_dir, "rni_hv_annual.png"),
#                 dpi = 900,
#                 width = 11,
#                 height = 5)
# 




