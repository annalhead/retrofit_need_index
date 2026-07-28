/* This is version 0.1.0 of the workflow to create tables for
the PHIRST evaluation of quarterly healthcare use. 
Heavily adapted from RVD's asthma workflow code 

This workflow is for Admitted Patient Care data (APC)
Using APCE (APC episodes) table to identify the first diagnosis
within a spell. 

For falls, extracting any first episode with a fall recorded 
For injuries from falls, using any diagnosis within the first episode of a spell 
where the primary diagnosis is from a traumatic injury (based on Rodgers et al report)

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
---------------------------------- APC ----------------------------------------
-------------------------------------------------------------------------------
-- Extracting APCE events within a specified time - this is admitted patient care
-- Extracted emergency admitted care based on admission method as 'Emergency Admission'
-- Extracting only episodes where 'episode_number' = 1 - first episode in a spell 
/* 
21	Emergency Admission	A & E or dental casualty department of the health care provider
21	Emergency Admission	Emergency Department or dental casualty department of the health care provider
22	Emergency Admission	GP: after a request for immediate admission has been made direct to a hospital provider (i.e. not through a Bed Bureau) by a General Practitioner or deputy
22	Emergency Admission	GP: after a request for immediate admission has been made direct to a hospital provider by a General Practitioner or deputy
23	Emergency Admission	Bed bureau
24	Emergency Admission	Consultant clinic of this or another health care provider
25	Emergency Admission	Domiciliary visit by Consultant
28	Emergency Admission	Other means, including admitted from the A & E department of another provider where they had not been admitted (been replaced by 2A-D)
2A  Emergency Care Department of another provider where patient not admitted 
2B  Emergency Admission; transfer of an admitted patient from another hospital provide in an emergnecy
2C  Emergency Admission: Baby born at home as intended
2D  Emergency Admission: Other emergency admission 


For falls, extracting any first episode with a fall recorded 
For all other conditions, only extracting primary diagnoses from the 1st episode
For injuries - Primary diagnosis has to be S0-00 /T00-65/T71 + any diagnosis of falls (based on Rodgers et al report)

*/


DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = '2026-01-01';
DROP TABLE IF EXISTS #apce_tmp;
SELECT 
    [APCE_MPI].*
INTO #apce_tmp -- don't need to keep this table 
FROM (
    SELECT 
        APCE.*,
        MPI.Deceased,
        MPI.Dob,
        MPI.DeathDate
    FROM (SELECT 
            Der_Pseudo_NHS_Number AS Pseudo_NHS_Number,
            APCS_Ident,
            Admission_Date,
            Episode_Start_Date,
            Der_Primary_Diagnosis_Code,
            Der_Diagnosis_All
        FROM [Client_SystemP].[vw_SUS_Faster_APCE] AS APCE
        WHERE 
            (Der_Primary_Diagnosis_Code IS NOT NULL) AND
                (APCE.Admission_Date BETWEEN @StartDate AND @EndDate) AND 
                Admission_Method IN ('21','22','23','24','25','28', '2A', '2B', '2C', '2D')
                AND Episode_Number = 1
    ) AS APCE
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS MPI
    ON APCE.Pseudo_NHS_Number = MPI.Pseudo_NHS_Number
) AS APCE_MPI
where  [Episode_Start_Date] >=  CAST(Dob + '-01' AS DATE) -- only keep those on/after dob
AND ([Episode_Start_Date] <= [DeathDate] OR [Deathdate] is NULL); -- only keep those on/before date of death 


-- Selecting the correct codes 
DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_apce_conditions]
select [APCE].*, 
[lookup].[description],
[lookup].[concept_name],
[lookup].[phenotype_name]
into [Client_SystemP_RW].[HUP_AH_phirst_apce_conditions]
from [#apce_tmp] as APCE
inner join [Client_SystemP_RW].[HUP_code_lists_hdruk] as lookup
-- Where the lookup code is 3 digits - any code within that chapter 
on SUBSTRING(Der_Primary_Diagnosis_Code, 1, 3)  COLLATE SQL_Latin1_General_CP1_CS_AS = code COLLATE SQL_Latin1_General_CP1_CS_AS
where code is not NULL 
and coding_system = 'ICD10 codes'
union
select [APCE].*, 
[lookup].[description],
[lookup].[concept_name],
[lookup].[phenotype_name]
from [#apce_tmp] as apce
inner join Client_SystemP_RW.HUP_code_lists_hdruk as lookup
-- Where the lookup code is >3 digits - exact match. Removing the . in the lookup codes 
on Der_Primary_Diagnosis_Code  = replace(code, '.', '') COLLATE SQL_Latin1_General_CP1_CS_AS
where code is not NULL
and coding_system = 'ICD10 codes'
-- Adding in falls 
-- Matching ICD10 3 digit codes from Archer et al 2022
union 
select [APCE].*, 
description = 'Fall',
concept_name = 'Fall',
phenotype_name = 'Fall'
from [#apce_tmp] as apce
WHERE (Der_Diagnosis_All like '%W010%' --the final zero denotes falls at home (excluded residential institutes)
OR Der_Diagnosis_All like '%W050%'
OR Der_Diagnosis_All like '%W060%'
OR Der_Diagnosis_All like '%W070%'
OR Der_Diagnosis_All like '%W080%'
OR Der_Diagnosis_All like '%W100%'
OR Der_Diagnosis_All like '%W180%'
OR Der_Diagnosis_All like '%W190%')
union -- adding in falls specifically with injuries 
select [APCE].*, 
description = 'Injury',
concept_name = 'Injury',
phenotype_name = 'Injury'
from [#apce_tmp] as apce
WHERE (Der_Primary_Diagnosis_Code like 'S%' OR 
Der_Primary_Diagnosis_Code like 'T0%' OR 
Der_Primary_Diagnosis_Code like 'T1%' OR 
Der_Primary_Diagnosis_Code like 'T2%' OR 
Der_Primary_Diagnosis_Code like 'T3%' OR 
Der_Primary_Diagnosis_Code like 'T4%' OR 
Der_Primary_Diagnosis_Code like 'T5%' OR 
Der_Primary_Diagnosis_Code like 'T60%' OR 
Der_Primary_Diagnosis_Code like 'T61%' OR 
Der_Primary_Diagnosis_Code like 'T62%' OR 
Der_Primary_Diagnosis_Code like 'T63%' OR 
Der_Primary_Diagnosis_Code like 'T64%' OR 
Der_Primary_Diagnosis_Code like 'T65%' OR 
Der_Primary_Diagnosis_Code like 'T71%' ) AND
(Der_Diagnosis_All like '%W010%' --the final zero denotes falls at home (excluded residential institutes)
OR Der_Diagnosis_All like '%W050%'
OR Der_Diagnosis_All like '%W060%'
OR Der_Diagnosis_All like '%W070%'
OR Der_Diagnosis_All like '%W080%'
OR Der_Diagnosis_All like '%W100%'
OR Der_Diagnosis_All like '%W180%'
OR Der_Diagnosis_All like '%W190%')


-- Adding in the outcome names I want 
ALTER TABLE [Client_SystemP_RW].[HUP_AH_phirst_apce_conditions]
    ADD [outcome] as (case   when phenotype_name like 'Asthma%' then 'asthma_apce'
when  phenotype_name like '%COPD%' then 'copd_apce'
when phenotype_name like 'CCU%' or phenotype_name like 'Coronary%' then 'cvd_apce'
when phenotype_name in ('Depression', 'Anxiety') then 'cmd_apce'
when  phenotype_name = 'Fall' then 'falls_apce'
when  phenotype_name = 'Injury' then 'injuries_apce'
end 
    )



-- Compiling long table for emergency admissions by condition 
-- Count per person per year per quarter number of unique days have a condition record
-- Long table 
drop table if exists  #apce_dev_quart
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
into #apce_dev_quart
from (
select 
event.*,
Sex,
acorn_LSOA2011,
floor(Datediff(Day,  Cast(Dob + '-15' AS DATE), Cast(Episode_Start_Date as date)) /365.25) as age
from( select *,
CAST(YEAR(Episode_Start_Date) AS VARCHAR) as year,
CAST(DATEPART(QUARTER, Episode_Start_Date) AS VARCHAR) as quarter
from(
select 
Pseudo_NHS_Number,
outcome, 
CAST(Episode_Start_Date AS DATE) as Episode_Start_Date , 
ROW_NUMBER() over (PARTITION by Pseudo_NHS_Number, outcome, Episode_Start_Date order by Pseudo_NHS_Number) as RowNbr
from [Client_SystemP_RW].[HUP_AH_phirst_apce_conditions]
)
sub
where RowNbr = 1
) as [event]
left join [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] as mpi
on event.Pseudo_NHS_Number = mpi.Pseudo_NHS_Number
where Episode_Start_Date  >= @StartDate
AND Episode_Start_Date  < @EndDate) as tmp
GROUP BY Pseudo_NHS_Number, 
outcome,
age,
Sex,
acorn_LSOA2011,
 year,
quarter
ORDER BY Pseudo_NHS_Number, outcome, age, year, quarter;


-- Can then use this to make a summary table of number of days visits by 
-- condition, year, quarter, and LSOA 

drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_apce_quarter] 
select 
    year, 
    quarter, 
    Sex,
    acorn_LSOA2011 as LSOA2011,
    age_group,
    outcome,
    N = sum(row_count)
    into [Client_SystemP_RW].[HUP_AH_phirst_apce_quarter] 
from (select *,
case when age < 15 then '0-14'
    when age between 15 and 19 then '15-19'
    when age between 20 and 34 then '20-34'
    when age between 35 and 49 then '35-49'
    when age between 50 and 64 then '50-64'
    when age between 65 and 74 then '65-74'
    when age >= 75 then '75+'
    END as age_group
     from #apce_dev_quart ) as APCE
group by year, quarter, acorn_LSOA2011, Sex, age_group, outcome
order by year, quarter, acorn_LSOA2011, Sex, age_group, outcome;

