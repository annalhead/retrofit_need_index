The main output for this piece of work is a household-level health-sensitive retrofit need index, aggregated to LSOA-level from Cheshire & Merseyside ICB for 2025.
This index comprises three domains calculated at household-level:
1. Health vulnerability
2. Age-group vulnerability
3. Retrofit programme eligibility: low income and low EPC 

Household health vulnerability was defined using healthcare use indicators for cardiovascular, respiratory and common mental health conditions, and injuries/falls among older adults. Additional vulnerability weights were applied where households contained at least one child aged under 14 years or one adult aged over 64 years. The housing retrofit need index was calculated at the household-level by multiplying eligibility (EPC rating D or below and low income household) with the health vulnerability index. 

2 sensitivity analysis versions were also produced: 
1. rni_sa1: RNI sensitivity analysis 1 - not including low income (imputed) household as a criteria
2. rni_sa2: RNI sensitivity analysis 2: not including imputed EPC. Excluding household with missing EPC. 

Household scores were aggregated to LSOA level and re-centred to the regional mean to enable comparison with the national neighbourhood-level enhanced index. 
A value of 1 indicates an average level of need within the region; <1 is lower than average need; >1 is greater than average need.  

Variables: 
- year: year 
- acorn_LSOA2011: 2011 LSOA code 
- rni: primary index. Health-sensitive retrofit need index. Centered so that 1 = average need in the region. 
- rni_N: Number of households included in the main index 
- rni_sa1: RNI sensitivity analysis 1 - not including low income (imputed) household as a criteria
- rni_sa1_N: Number of households included in the Sensitivity Analysis 1 index (not including the low income domain)
- rni_sa2: RNI sensitivity analysis 2: not including imputed EPC. Excluding household with missing EPC. 
- rni_sa2_N: Number of households included in the Sensitivity Analysis 2 index (excluding households with missing EPC rating)
- rni_health_vuln: Health and vulnerability domain index. Centered so that 1 = average need in the region.
- rni_health: Health domain index. Centered so that 1 = average need in the region.
- rni_big_pc: Percentage of households in the LSOA with a retrofit need index > 1 (i.e. greater than average need)  
- rni_big_sa1_pc: Percentage of households in the LSOA with a SA1 retrofit need index > 1 (i.e. greater than average need)   
- rni_big_sa2_pc: Percentage of households in the LSOA with a SA2 retrofit need index > 1 (i.e. greater than average need)  
- lowEPC_pc: Percentage of households with low EPC 
- poverty_pc: Percentage of households with low income 
- eligibility_pc: Percentage of households eligible for retrofit (low income and low EPC)
- eligibility_sa1_pc: Percentage of households eligible for retrofit in SA1 (low EPC)
- eligibility_sa2_pc: Percentage of households eligible for retrofit in SA2 (excluding imputed EPC)
- imd_dec: IMD decile [1 = most deprived] 
- imd_inc_score: IMD income deprivation score

