# Household_retrofit_need_index

This repository contains the code lists and analysis code for a household-level index of health-sensitive retrofit need for Cheshire & Merseyside. 

In brief, the regional household-level index was constructed for Cheshire and Merseyside ICB using pseudonymised primary and secondary health care data within a secure data environment. Individuals registered with participating general practices in 2025 and not opted out of data sharing were grouped into households using pseudonymised UPRNs. The latest recorded residential address was used for linkage to EPC and area deprivation data. 

Low energy efficiency was defined as an EPC rating of D-G. Where EPC information was missing, a low-efficiency flag was imputed using a fixed-effects ordinary least squares model with area-level low energy efficiency and income deprivation predictors. As household income was unavailable in routine health data, an income deprivation flag was imputed from LSOA income deprivation rates and household age composition. 

Household health vulnerability was defined using healthcare use indicators for cardiovascular, respiratory and common mental health conditions, and injuries/falls among older adults. Additional vulnerability weights were applied where households contained at least one child aged under 14 years or one adult aged over 64 years. Household scores were aggregated to LSOA level and re-centred to the regional mean to enable comparison with the national neighbourhood-level enhanced index.
