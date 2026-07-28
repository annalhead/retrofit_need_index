When run sequentially, these files prepare the raw data for compilation into a index describing health-sensitive retrofit need. 

1. 01_phirst-mpi.sql: identifies the cohort from the patient table
2. 02_phirst-workflow-gp.sql: cleans the GP event data
3. 03_phirst-workflow-med.sql: cleans the GP medication data
4. 04_phirst-workflow-ecds.sql: cleans the emergency care data [currently not used]
5. 05_phirst-workflow-apce.sql: cleans the admitted patient care data (secondary care data)
6. 06_health_needs_index_procedure.sql: creates annual summaries at household level
7. 07_household_rni_clean.R: creates the index at household-level and then aggregates at LSOA level for export 
