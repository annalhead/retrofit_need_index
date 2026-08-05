# Defining health outcomes 

Where code lists are not in Snomed-ct format, we used the [Reference_Coding] file within the SDE to match either the code or the description.  

## Respiratory conditions  

## Asthma 

- Luke Daines, Ann Morgan, Mome Mukherjee, Mohammad Al Sallakh, Eimear O'Rourke, Jennifer K Quint. PH782 / 2206 - Asthma Primary care. Phenotype Library [Online]. 04 August 2022. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH782/version/2206/detail/. [Accessed 07 May 2024] 

- Luke Daines, Ann Morgan, Mome Mukherjee, Mohammad Al Sallakh, Eimear O'Rourke, Jennifer K Quint. PH783 / 2207 - Asthma Secondary care. Phenotype Library [Online]. 04 August 2022. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH783/version/2207/detail/. [Accessed 07 May 2024] 

- BNF codelist for Asthma medications: https://www.opencodelists.org/codelist/bristol/asthma-medications-bnf/7d1f49e6/ Coding system release: 84 (2023-02-01)Version ID: 7d1f49e6 

 

## COPD 

- Eleanor L Axson, Jennifer K Quint, Mome Mukherjee, Hannah R Whittaker, Philip W Stone, Kate McLaren. PH797 / 2221 - Chronic obstructive pulmonary disease (COPD) Primary care. Phenotype Library [Online]. 04 August 2022. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH797/version/2221/detail/. [Accessed 07 May 2024] 

- Eleanor L Axson, Jennifer K Quint, Mome Mukherjee, Hannah R Whittaker, Philip W Stone, Kate McLaren. PH798 / 2222 - Chronic obstructive pulmonary disease (COPD) Secondary care. Phenotype Library [Online]. 04 August 2022. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH798/version/2222/detail/. [Accessed 07 May 2024] 

BNF codelist for COPD medications: https://www.opencodelists.org/codelist/bristol/copd-medications-bnf/4b00637c/#full-list  Coding system release: 84 (2023-02-01) Version ID: 4b00637c 

 

NB: ‘Diagnosis’ of respiratory conditions: based only on GP records.

 

## CMD (anxiety and depression) 

- John, A., McGregor, J., Fone, D., Dunstan, F., Cornish, R.., Lyons, R A., & Lloyd, K R.. PH1113 / 2453 - Anxiety- Phenotype. Phenotype Library [Online]. 25 September 2023. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH1113/version/2453/detail/. [Accessed 07 May 2024] 

- John, A., Marchant, A. L., Fone, D. L., McGregor, J. I., Dennis, M. S., Tan, J. O. A., & Lloyd, K.. PH1114 / 2455 - Depression- Phenotype. Phenotype Library [Online]. 25 September 2023. Available from: http://phenotypes.healthdatagateway.org/phenotypes/PH1114/version/2455/detail/. [Accessed 07 May 2024] 

NB: Implementation for diagnosis & “Prescribed medications for participants with a CMD”: prescription in that calendar year + a prior GP contact with a CMD code.  

 

## CVD  

Included conditions: CHD, Stroke, TIA, Peripheral Vascular Disease, Myocardial Infarction, Atrial Fibrillation, Angina, Heart Failure: all have evidence of association with cold weather  

Fan JF, Xiao YC, Feng YF, Niu LY, Tan X, Sun JC, Leng YQ, Li WY, Wang WZ, Wang YK. A systematic review and meta-analysis of cold exposure and cardiovascular disease outcomes. Front Cardiovasc Med. 2023. doi: 10.3389/fcvm.2023.1084611. 

Identified code lists through HDR UK health data gateway: 

- CHD: George et al., 2022 https://phenotypes.healthdatagateway.org/phenotypes/PH1027/version/2263/detail/ (primary & secondary) 

- Stroke: Wood et al. 2022 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH948/version/2126/detail/  

- TIA: Allara et al., 2025 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH1862/version/4415/detail/  

- Peripheral Vascular disease: Allara et al., 2025 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH1845/version/4402/detail/  

- MI: Allara et al., 2025 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH1833/version/4394/detail/  

- AF: Allara et al., 2025 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH1871/version/4359/detail/  

- Angina: Allara et al., 2025 (BHF) https://phenotypes.healthdatagateway.org/phenotypes/PH1837/version/4350/detail/  

- HF unspecified: https://phenotypes.healthdatagateway.org/phenotypes/PH1900/version/4384/detail/ 

- HF reduced ejection fraction: https://phenotypes.healthdatagateway.org/phenotypes/PH1899/version/4383/detail/  

## Emergency admissions for injuries / falls in >60s  

Primary diagnosis has to be ICD10 code for traumatic injury: S0-00, T00-T65 or T71, with an additional diagnosis of falls: W01, W05, W06, W07, W08, W10, W18, W19 where the fourth digit is 0 (denotes occurred at home).  

- Rodgers SE, Bailey R, Johnson R, Poortinga W, Smith R, Berridge D, et al. Health impact, and economic value, of meeting housing quality standards: a retrospective longitudinal data linkage study. Public Health Res 2018;6(8). https://doi.org/10.3310/phr06080  p99 

- Archer L, Koshiaris C, Lay-Flurrie S, Snell K I E, Riley R D, Stevens R et al. Development and external validation of a risk prediction model for falls in patients with an indication for antihypertensive treatment: retrospective cohort study BMJ 2022; 379 :e070918 doi:10.1136/bmj-2022-070918  

##  Emergency Care (A&E) data - ECDS dataset [Currently not used in final index]

We used A&E attendances between 6am-midnight as a proxy for non-alcohol related emergency attendances 

