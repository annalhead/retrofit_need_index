/* This is version 0.1.0 of the workflow to create tables for
the PHIRST evaluation of quarterly healthcare use. 
Heavily adapted from RVD's asthma workflow code 

This workflow is for GP prescription data 


Last run on 13 Jan 2026
Full years: 2018-2025

********************INCOMPLETE***********************************
@author: Anna Head
@email: ahead@liverpool.ac.uk

@author: Roberto Villegas-Diaz
@email: r.villegas-diaz@liverpool.ac.uk

@author: Hannah Burnett
@email: hannah.burnett@liverpool.ac.uk

@author: Anna Head
@email: anna.head2@liverpool.ac.uk

@author: Antonio Ross-Perez
@email: antonio.ross@ed.ac.uk

@author: Rukun Khalaf
@email: r.khalaf@liverpool.ac.uk

@author: Lohavani Sevverl
@email: lohavani.Sevverl@liverpool.ac.uk


@date: 2026-01-01

VERSION 0.1.0 IN DEVELOPMENT

*/



-------------------------------------------------------------------------------
---------------------------------- Patients of interest -----------------------
-------------------------------------------------------------------------------
/* code for this is in phirst-mpi-v0.1.0 file  */


-------------------------------------------------------------------------------
---------------------------------- Asthma Medications -------------------------
-------------------------------------------------------------------------------
/* Made an error importing the BNF code lists for asthma & copd - didn't include 
the condition names. the top 26 are asthma */

select 
[bnf_ref].*,
codes.term
into #asthma_medications 
from (
    select 
    bnf_code,
    SUBSTRING(bnf_code, 1, 9) as bnf_code_short,
    presentation_pack_level,
    vmp_vmpp_amp_ampp, -- this includes 'virtual' and 'actual'? 
    bnf_name, 
    snomed_code
    from [Client_SystemP_RW].[HUP_REF_BNF_SNOMED_CT_Mapping_202407]
) as bnf_ref
inner join (select top 26
    code COLLATE SQL_Latin1_General_CP1_CS_AS as code,
    term
    from [Client_SystemP_RW].[HUP_code_lists_opencode_meds])  as codes
on bnf_ref.bnf_code_short = codes.code

DECLARE @MedicationDate_Start DATETIME  = '2017-12-31 23:59:59'; 
DECLARE @MedicationDate_End DATETIME  = '2026-01-01 00:00:00';

DROP TABLE IF EXISTS #asthma_gp_med;
SELECT 
MPI.Pseudo_NHS_Number,
    PK_GP_Medications_ID AS [FK_GP_Medications_ID],
    -- GP_Medications_ID,
    GP.FK_Patient_ID,
    FK_Reference_SnomedCT_ID,
    CAST(MedicationDate AS DATE) AS MedicationDate,
    SuppliedCode,
    -- MedicationDescription,
    -- Units,
    -- LastIssueDate,
    RepeatMedicationFlag,
    -- CAST(MedicationStartDate AS DATE) AS MedicationStartDate,
    CAST(MedicationEndDate AS DATE) AS MedicationEndDate,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO #asthma_gp_med  /* Name of the new table */
FROM [Client_SystemP].[GP_Medications] AS [GP]
LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
ON [GP].[FK_Patient_ID] = [MPI].[FK_Patient_ID]
Left join [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma_min] AS [diag]
on [MPI].[Pseudo_NHS_Number] = [diag].Pseudo_NHS_Number
WHERE [SuppliedCode] IN ( 
    SELECT distinct snomed_code  FROM #asthma_medications
)
AND [MedicationDate] > @MedicationDate_Start AND [MedicationDate] < @MedicationDate_End
AND [GP].[FK_Patient_ID] <> -1
AND [MPI].[Pseudo_NHS_Number] IN (select distinct Pseudo_NHS_Number from [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma_min]) -- only want medications for people who have asthma
AND [GP].MedicationDate >= [diag].Date_First_Diag -- only keep those that happen on or after first asthma event code 
ORDER BY [MedicationDate];




-------------------------------------------------------------------------------
---------------------------------- COPD Medications -------------------------
-------------------------------------------------------------------------------
/*made a mistake importing resp bnf codes, all of these can be used for copd
except for 0301011V0 which is asthma only */
select 
[bnf_ref].*,
codes.term
into #copd_medications 
from (
    select 
    bnf_code,
    SUBSTRING(bnf_code, 1, 9) as bnf_code_short,
    presentation_pack_level,
    vmp_vmpp_amp_ampp,
    bnf_name, 
    snomed_code
    from [Client_SystemP_RW].[HUP_REF_BNF_SNOMED_CT_Mapping_202407]
) as bnf_ref
inner join (select distinct
    code COLLATE SQL_Latin1_General_CP1_CS_AS as code,
    term
    from [Client_SystemP_RW].[HUP_code_lists_opencode_meds]
    where code <> '0301011V0'
    group by code, term )  as codes
on bnf_ref.bnf_code_short = codes.code


--DECLARE @MedicationDate_Start DATETIME  = '2017-12-31 23:59:59'; 
--DECLARE @MedicationDate_End DATETIME  = '2026-01-01 00:00:00';

DROP TABLE IF EXISTS #copd_gp_med;
SELECT 
MPI.Pseudo_NHS_Number,
    PK_GP_Medications_ID AS [FK_GP_Medications_ID],
    -- GP_Medications_ID,
    GP.FK_Patient_ID,
    FK_Reference_SnomedCT_ID,
    CAST(MedicationDate AS DATE) AS MedicationDate,
    SuppliedCode,
    -- MedicationDescription,
    -- Units,
    -- LastIssueDate,
    RepeatMedicationFlag,
    -- CAST(MedicationStartDate AS DATE) AS MedicationStartDate,
    CAST(MedicationEndDate AS DATE) AS MedicationEndDate,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO #copd_gp_med  /* Name of the new table */
FROM [Client_SystemP].[GP_Medications] AS [GP]
LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
ON [GP].[FK_Patient_ID] = [MPI].[FK_Patient_ID]
Left join [Client_SystemP_RW].[HUP_AH_phirst_gp_copd_min] AS [diag]
on [MPI].[Pseudo_NHS_Number] = [diag].Pseudo_NHS_Number
WHERE [SuppliedCode] IN ( 
    SELECT distinct snomed_code  FROM #copd_medications
)
AND [MedicationDate] > @MedicationDate_Start AND [MedicationDate] < @MedicationDate_End
AND [GP].[FK_Patient_ID] <> -1
AND [MPI].[Pseudo_NHS_Number] IN (select distinct Pseudo_NHS_Number from [Client_SystemP_RW].[HUP_AH_phirst_gp_copd_min]) -- only want medications for people who have copd
AND [GP].MedicationDate >= [diag].Date_First_Diag -- only keep those that happen on or after first copd event code 
ORDER BY [MedicationDate];

-------------------------------------------------------------------------------
---------------------------------- CVD Medications -------------------------
-------------------------------------------------------------------------------
select 
[bnf_ref].*,
codes.description
into #cvd_medications 
from (
    select 
    bnf_code,
    --SUBSTRING(bnf_code, 1, 9) as bnf_code_short,
    presentation_pack_level,
    vmp_vmpp_amp_ampp, -- this includes 'virtual' and 'actual'? 
    bnf_name, 
    snomed_code
    from [Client_SystemP_RW].[HUP_REF_BNF_SNOMED_CT_Mapping_202407]
) as bnf_ref
inner join (select 
code COLLATE SQL_Latin1_General_CP1_CS_AS as code,
[description]
    from Client_SystemP_RW.HUP_code_lists_hdruk
where coding_system = 'BNF codes' AND concept_name <> 'Type 2 diabetes mellitus (T2DM)')  as codes
on bnf_ref.bnf_code = codes.code

--DECLARE @MedicationDate_Start DATETIME  = '2017-12-31 23:59:59'; 
--DECLARE @MedicationDate_End DATETIME  = '2026-01-01 00:00:00';

DROP TABLE IF EXISTS #cvd_gp_med;
SELECT 
MPI.Pseudo_NHS_Number,
    PK_GP_Medications_ID AS [FK_GP_Medications_ID],
    -- GP_Medications_ID,
    GP.FK_Patient_ID,
    FK_Reference_SnomedCT_ID,
    CAST(MedicationDate AS DATE) AS MedicationDate,
    SuppliedCode,
    -- MedicationDescription,
    -- Units,
    -- LastIssueDate,
    RepeatMedicationFlag,
    -- CAST(MedicationStartDate AS DATE) AS MedicationStartDate,
    CAST(MedicationEndDate AS DATE) AS MedicationEndDate,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO #cvd_gp_med  /* Name of the new table */
FROM [Client_SystemP].[GP_Medications] AS [GP]
LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
ON [GP].[FK_Patient_ID] = [MPI].[FK_Patient_ID]
Left join [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd_min] AS [diag]
on [MPI].[Pseudo_NHS_Number] = [diag].Pseudo_NHS_Number
WHERE [SuppliedCode] IN ( 
    SELECT distinct snomed_code  FROM #cvd_medications
)
AND [MedicationDate] > @MedicationDate_Start AND [MedicationDate] < @MedicationDate_End
AND [GP].[FK_Patient_ID] <> -1
AND [MPI].[Pseudo_NHS_Number] IN (select distinct Pseudo_NHS_Number from [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd_min]) -- only want medications for people who have cvd
AND [GP].MedicationDate >= [diag].Date_First_Diag -- only keep those that happen on or after first cvd event code 
ORDER BY [MedicationDate];

-------------------------------------------------------------------------------
---------------------------------- CMD Medications ---------------------------
-------------------------------------------------------------------------------
-- Using Roberto's GW mapping of medications to snomed for these 
--[Client_SystemP_RW].[GW_depression_anxiety_drug_treatment_snomedct]


--DECLARE @MedicationDate_Start DATETIME  = '2017-12-31 23:59:59'; 
--DECLARE @MedicationDate_End DATETIME  = '2026-01-01 00:00:00';

DROP TABLE IF EXISTS #cmd_gp_med;
SELECT 
MPI.Pseudo_NHS_Number,
    PK_GP_Medications_ID AS [FK_GP_Medications_ID],
    -- GP_Medications_ID,
    GP.FK_Patient_ID,
    FK_Reference_SnomedCT_ID,
    CAST(MedicationDate AS DATE) AS MedicationDate,
    SuppliedCode,
    -- MedicationDescription,
    -- Units,
    -- LastIssueDate,
    RepeatMedicationFlag,
    -- CAST(MedicationStartDate AS DATE) AS MedicationStartDate,
    CAST(MedicationEndDate AS DATE) AS MedicationEndDate,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO #cmd_gp_med  /* Name of the new table */
FROM [Client_SystemP].[GP_Medications] AS [GP]
LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
ON [GP].[FK_Patient_ID] = [MPI].[FK_Patient_ID]
Left join [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd_min] AS [diag]
on [MPI].[Pseudo_NHS_Number] = [diag].Pseudo_NHS_Number
WHERE [SuppliedCode] IN ( 
    SELECT distinct ConceptID  FROM [Client_SystemP_RW].[HUP_cmd_drug_snomedct]
)
AND [MedicationDate] > @MedicationDate_Start AND [MedicationDate] < @MedicationDate_End
AND [GP].[FK_Patient_ID] <> -1
AND [MPI].[Pseudo_NHS_Number] IN (select distinct Pseudo_NHS_Number from [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd_min]) -- only want medications for people who have cmd
AND [GP].MedicationDate >= [diag].Date_First_Diag -- only keep those that happen on or after first cmd event code 
ORDER BY [MedicationDate];



-- Compiling long table for all prescriptions together
drop table if exists #tmp_med
select *,
outcome = 'asthma_medication'
into #tmp_med
from #asthma_gp_med
union all 
select *,
outcome = 'copd_medication'
from #copd_gp_med
union all 
select *,
outcome = 'cvd_medication'
from #cvd_gp_med
union all 
select *,
outcome = 'cmd_medication'
from #cmd_gp_med


select distinct outcome from #tmp_med

-- Compiling long table for X prescriptions 
-- Counting total items of prescription X on distinct days, on or after first X code
-- Annualy - for needs index
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_meds_annual_ind] 
DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = '2026-01-01';
select
Pseudo_NHS_Number,
Sex,
acorn_LSOA2011,
year,
outcome, 
count (*) as row_count
into [Client_SystemP_RW].[HUP_AH_phirst_meds_annual_ind] 
from (
select 
event.*,
Sex,
acorn_LSOA2011
from( select *,
CAST(YEAR(MedicationDate) AS VARCHAR) as year
from #tmp_med
) as [event]
left join [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] as mpi
on event.Pseudo_NHS_Number = mpi.Pseudo_NHS_Number
where MedicationDate  >= @StartDate
AND MedicationDate  < @EndDate) as tmp
GROUP BY Pseudo_NHS_Number, 
Sex, 
acorn_LSOA2011, 
outcome,
 year
ORDER BY Pseudo_NHS_Number, year, outcome;


-- Quarterly 
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';
select
Pseudo_NHS_Number,
age,
Sex,
acorn_LSOA2011,
year,
quarter,
outcome, 
count (*) as row_count
into #meds_dev_quart
from (
select 
event.*,
Sex,
acorn_LSOA2011,
floor(Datediff(Day,  Cast(Dob + '-15' AS DATE), Cast(MedicationDate as date)) /365.25) as age
from( select *,
CAST(YEAR(MedicationDate) AS VARCHAR) as year,
CAST(DATEPART(QUARTER, MedicationDate) AS VARCHAR) as quarter
from #tmp_med
) as [event]
left join [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] as mpi
on event.Pseudo_NHS_Number = mpi.Pseudo_NHS_Number
where MedicationDate  >= @StartDate
AND MedicationDate  < @EndDate) as tmp
GROUP BY Pseudo_NHS_Number, 
age,
Sex, 
acorn_LSOA2011, 
outcome,
 year,
quarter
ORDER BY Pseudo_NHS_Number, year, quarter, age, outcome;


-- Make this into an aggregate table
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_med_quarter] 
select 
    year, 
    quarter, 
    acorn_LSOA2011 as LSOA2011,
    Sex,
    age_group,
    outcome,
    N = sum(row_count)
    into [Client_SystemP_RW].[HUP_AH_phirst_med_quarter] 
from (select *,
case when age < 15 then '0-14'
    when age between 15 and 19 then '15-19'
    when age between 20 and 34 then '20-34'
    when age between 35 and 49 then '35-49'
    when age between 50 and 64 then '50-64'
    when age between 65 and 74 then '65-74'
    when age >= 75 then '75+'
    END as age_group
     from #meds_dev_quart ) as meds
group by year, quarter, acorn_LSOA2011, Sex, age_group, outcome
order by year, quarter, acorn_LSOA2011, Sex, age_group, outcome;



-- For saving table of codes as a csv
Select 
bnf_code,
snomed_code, 
bnf_name as [description],
condition = 'med_asthma'
into #medicationcodes
from #asthma_medications
UNION
Select 
bnf_code,
snomed_code, 
bnf_name,
condition = 'med_copd'
from #copd_medications
UNION
Select 
bnf_code,
snomed_code, 
bnf_name as [description],
condition = 'med_cvd'
from #cvd_medications
UNION
SELECT
bnf_code = 'NA', 
ConceptID as snomed_code, 
Description as [description], 
condition = 'med_cmd'
from [Client_SystemP_RW].[HUP_cmd_drug_snomedct]
select * from  #asthma_medications

select * from #medicationcodes

