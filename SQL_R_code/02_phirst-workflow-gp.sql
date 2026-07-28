/* This is version 0.1.0 of the workflow to create tables for
the PHIRST evaluation of quarterly primary secondary care & medication use. 
Heavily adapted from RVD's asthma workflow code 
Last run on 13 Jan 2026
Full years: 2018-2025

********************INCOMPLETE***********************************


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

@date: 2026-01-13

VERSION 0.1.0 IN DEVELOPMENT

*/



-------------------------------------------------------------------------------
---------------------------------- Patients of interest -----------------------
-------------------------------------------------------------------------------
/* code for this is in phirst-mpi-v0.1.0 file  */

-------------------------------------------------------------------------------
---------------------------------- Codes of interest  -------------------------
-------------------------------------------------------------------------------
/* Primary care data is coded using snomet_ct. Not all code lists were devleoped 
in this format so have to match these using the reference coding lookups
*/



/* Stored in [Client_SystemP_RW].[HUP_code_lists_asthma_primary_care] 
The asthma codelists were extracted from the following references:

- Luke Daines, Ann Morgan, Mome Mukherjee, Mohammad Al Sallakh, 
Eimear O'Rourke, Jennifer K Quint. PH782 / 2206 - Asthma Primary care. 
Phenotype Library [Online]. 04 August 2022. Available from: 
http://phenotypes.healthdatagateway.org/phenotypes/PH782/version/2206/detail/. 
[Accessed 11 March 2025]

- Luke Daines, Ann Morgan, Mome Mukherjee, Mohammad Al Sallakh, 
Eimear O'Rourke, Jennifer K Quint. PH783 / 2207 - Asthma Secondary care. 
Phenotype Library [Online]. 04 August 2022. Available from: 
http://phenotypes.healthdatagateway.org/phenotypes/PH783/version/2207/detail/. 
[Accessed 11 March 2025]

- Eleanor L Axson, Jennifer K Quint. PH12 / 24 - Asthma. 
Phenotype Library [Online]. 06 October 2021. Available from: 
http://phenotypes.healthdatagateway.org/phenotypes/PH12/version/24/detail/. 
[Accessed 11 March 2025]
*/

--------
-- HDR UK codes: CVD, CMD, COPD
--------

-- linking up the HDR UK codes to the reference table

-- Matching by either code or by description and then will use all distinct snomed codes 
drop table if exists #tmp
drop table if exists #tmp_codes_all
select 
[HDRUK_refset].*,
[lookup].[Reference_Coding_ID],
[lookup].[MainCode], 
[lookup].[CodingType],
[lookup].[SnomedCT_ConceptID],
[lookup].[ICD10Code],
[lookup].[FullDescription]
into #tmp_codes_all
from [Client_SystemP_RW].[HUP_code_lists_hdruk] as [HDRUK_refset]
inner join [Client_SystemP].[Reference_Coding] as [lookup] 
on  [lookup].[MainCode] COLLATE SQL_Latin1_General_CP1_CS_AS = [HDRUK_refset].[code] COLLATE SQL_Latin1_General_CP1_CS_AS
where [HDRUK_refset].[coding_system] NOT LIKE 'ICD%' -- remove ICD codes as these are secondary care
and [HDRUK_refset].[coding_system] not like 'BNF%' -- remove BNF codes as these are for medications
UNION
select 
[HDRUK_refset].*,
[lookup].[Reference_Coding_ID],
[lookup].[MainCode], 
[lookup].[CodingType],
[lookup].[SnomedCT_ConceptID],
[lookup].[ICD10Code],
[lookup].[FullDescription]
from [Client_SystemP_RW].[HUP_code_lists_hdruk] as [HDRUK_refset]
inner join [Client_SystemP].[Reference_Coding] as [lookup] 
on  [lookup].[FullDescription] COLLATE SQL_Latin1_General_CP1_CS_AS = [HDRUK_refset].[description] COLLATE SQL_Latin1_General_CP1_CS_AS
where [HDRUK_refset].[coding_system] NOT LIKE 'ICD%' -- remove ICD codes as these are secondary care
and [HDRUK_refset].[coding_system] not like 'BNF%' -- remove BNF codes as these are for medications


-- CVD
drop table if exists #cvdcodes

select 
SnomedCT_ConceptID collate SQL_Latin1_General_CP1_CS_AS as SnomedCT_ConceptID,
[description], 
condition = 'gp_cvd'
into #cvdcodes
from (select 
*, 
ROW_NUMBER() over (PARTITION by SnomedCT_ConceptID order by SnomedCT_ConceptID) as RowNbr
from #tmp_codes_all
where (phenotype_name like 'CCU0%' OR 
phenotype_name = 'Coronary Heart Disease (CHD)') 
AND SnomedCT_ConceptID is not null
AND FullDescription is not null
and concept_name not like '%Prescriptions%')
sub 
where RowNbr = 1



-- COPD codes -- need to check how many match
select 
SnomedCT_ConceptID collate SQL_Latin1_General_CP1_CS_AS as SnomedCT_ConceptID,
[description], 
condition = 'gp_copd'
into #copdcodes
from (select 
*, 
ROW_NUMBER() over (PARTITION by SnomedCT_ConceptID order by SnomedCT_ConceptID) as RowNbr
from #tmp_codes_all
where phenotype_name like '%COPD%' 
AND phenotype_name like '%Primary%' 
AND SnomedCT_ConceptID is not null
AND FullDescription is not null
and concept_name not like '%Prescriptions%')
sub 
where RowNbr = 1


-- CMD codes: 
select 
SnomedCT_ConceptID collate SQL_Latin1_General_CP1_CS_AS as SnomedCT_ConceptID,
[description], 
condition = 'gp_cmd'
into #cmdcodes
from (select 
*, 
ROW_NUMBER() over (PARTITION by SnomedCT_ConceptID order by SnomedCT_ConceptID) as RowNbr
from #tmp_codes_all
where phenotype_name in ('Depression', 'Anxiety')
AND SnomedCT_ConceptID is not null
AND FullDescription is not null
and concept_name not like '%Prescriptions%')
sub 
where RowNbr = 1


--------
-- Falls
--------
/* Stored in [Client_SystemP_RW].[HUP_code_lists_refset_falls] 
Come from: 

*/
-- Looking at Falls look up code: all of these match on snomeds
/*
select 
[refset].*,
[ref].[Term],
[ref].[PK_Reference_SnomedCT_ID]
from [Client_SystemP_RW].[HUP_code_lists_refset_falls] as [refset]
left join [Client_SystemP].[Reference_SnomedCT] as [ref] 
on  [ref].[ConceptID] = [refset].[code] 
*/


-- Combined codelist table for saving as csv
select * 
into #gpcodes
from #cvdcodes
UNION
select * 
from #copdcodes
UNION
select
SnomedCT_ConceptID collate SQL_Latin1_General_CP1_CS_AS as SnomedCT_ConceptID,
[description], 
condition = 'gp_cmd' 
from #cmdcodes
UNION 
    SELECT
    SnomedCT_ConceptID collate SQL_Latin1_General_CP1_CS_AS as SnomedCT_ConceptID,
    [Description] collate SQL_Latin1_General_CP1_CS_AS AS [description], 
     condition = 'gp_asthma'
    FROM [Client_SystemP].[Reference_Coding] AS [Ref]
    LEFT JOIN (select MainCode COLLATE SQL_Latin1_General_CP1_CS_AS AS MainCode, Description 
    FROM [Client_SystemP_RW].[HUP_code_lists_asthma_primary_care] where CodingType = 'ReadCodeV2') as [list]
    on  Ref.[MainCode] =  list.[MainCode]
    WHERE 
        Ref.[MainCode] IN (
            SELECT MainCode COLLATE SQL_Latin1_General_CP1_CS_AS -- Case sensitive
            FROM [Client_SystemP_RW].[HUP_code_lists_asthma_primary_care]
        )
        AND Ref.CodingType = 'ReadCodeV2'
        AND DELETED = 'N'
        AND SnomedCT_ConceptID is not null
        AND FullDescription is not null

select * from #gpcodes


-------------------------------------------------------------------------------
---------------------------------- GP_Events for asthma -----------------------
-------------------------------------------------------------------------------
--- This is very slow... 
DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = '2026-01-01';

DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma];
SELECT 
    [GP].*,
    [RefCo].[FullDescription] as description,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma]  /* Name of the new table */
FROM (
    SELECT 
        [P].[Pseudo_NHS_Number],
        [GP].[PK_GP_Events_ID] AS [FK_GP_Events_ID],
        [GP].[FK_Patient_ID],
        [GP].[FK_Patient_Link_ID],
        [GP].[FK_Reference_Coding_ID], -- what is this?
        [GP].[FK_Reference_SnomedCT_ID],
        CAST([GP].[EventDate] AS DATE) AS [EventDate],
        --[GP].[Episodicity], -- this isn't well recorded
        [GP].[SuppliedCode],
        CAST([MPI].[DeathDate] AS DATE) AS [DeathDate]
    FROM [Client_SystemP].[GP_Events] AS [GP]
    LEFT JOIN (
        SELECT *
        FROM [Client_SystemP].[Patient]
     ) AS [P]
    ON [GP].[FK_Patient_ID] = [P].[PK_Patient_ID]
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
    ON [P].[Pseudo_NHS_Number] = [MPI].[Pseudo_NHS_Number]
--   WHERE [EventDate] > @StartDate AND [EventDate] < @EndDate -- start with all of them so can have min date 
   WHERE  [EventDate] < @EndDate 
    AND [GP].[Deleted] = 'N'
    AND [GP].[FK_Reference_Coding_ID] <> -1
    AND [GP].[FK_Patient_ID] <> -1
    AND [MPI].[Dob] IS NOT NULL
    AND ([GP].[EventDate] <= [MPI].[DeathDate] OR [MPI].[DeathDate] IS NULL) -- don't want any records after deathdate 
    AND [GP].[EventDate] >= Cast([MPI].[Dob] + '-01' AS DATE) -- don't want any before birthdate
) AS GP
INNER JOIN (
    SELECT
        [PK_Reference_Coding_ID], /* to link with [Client_SystemP].[Reference_Coding] */
        [MainCode], /* to link with [Client_SystemP_RW].[HUP_code_lists_asthma_primary_care] */
        SnomedCT_ConceptID AS ConceptID,
        FullDescription
    FROM [Client_SystemP].[Reference_Coding]
    WHERE 
        [MainCode] IN (
            SELECT MainCode COLLATE SQL_Latin1_General_CP1_CS_AS  -- Case sensitive
            FROM [Client_SystemP_RW].[HUP_code_lists_asthma_primary_care]
        )
        AND CodingType = 'ReadCodeV2'
        AND DELETED = 'N'
) AS RefCo
ON [GP].[FK_Reference_Coding_ID] = [RefCo].[PK_Reference_Coding_ID]
ORDER BY [EventDate];




-- Will also want the first ever record, for matching with prescriptions
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma_min]
SELECT Pseudo_NHS_Number,
        CAST(MIN(EventDate) AS DATE) AS [Date_First_Diag]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma_min]
FROM [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma]
GROUP BY Pseudo_NHS_Number


-- Deleting the events that happen outside of the study period - this is to minimise the data 
--DECLARE @StartDate DATE = '2018-01-01';
delete from [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma] 
where EventDate < @StartDate

 

-------------------------------------------------------------------------------
---------------------------------- GP_Events for COPD -------------------------
-------------------------------------------------------------------------------
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';

DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_gp_copd] ;
SELECT 
    [GP].*,
    [RefCo].[description],
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_copd]  /* Name of the new table */
FROM (
    SELECT 
    [P].[Pseudo_NHS_Number],
        [GP].[PK_GP_Events_ID] AS [FK_GP_Events_ID],
        [GP].[FK_Patient_ID],
        [GP].[FK_Patient_Link_ID],
        [GP].[FK_Reference_Coding_ID], -- what is this?
        [GP].[FK_Reference_SnomedCT_ID],
        CAST([GP].[EventDate] AS DATE) AS [EventDate],
        --[GP].[Episodicity], -- this isn't well recorded
        [GP].[SuppliedCode],
        CAST([MPI].[DeathDate] AS DATE) AS [DeathDate]
    FROM [Client_SystemP].[GP_Events] AS [GP]
    LEFT JOIN (
        SELECT *
        FROM [Client_SystemP].[Patient]
     ) AS [P]
    ON [GP].[FK_Patient_ID] = [P].[PK_Patient_ID]
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
    ON [P].[Pseudo_NHS_Number] = [MPI].[Pseudo_NHS_Number]
--   WHERE [EventDate] > @StartDate AND [EventDate] < @EndDate -- start with all of them so can have min date 
   WHERE  [EventDate] < @EndDate 
    AND [GP].[Deleted] = 'N'
    AND [GP].[FK_Reference_Coding_ID] <> -1
    AND [GP].[FK_Patient_ID] <> -1
    AND [MPI].[Dob] IS NOT NULL
    AND ([GP].[EventDate] <= [MPI].[DeathDate] OR [MPI].[DeathDate] IS NULL) -- don't want any records after deathdate 
    AND [GP].[EventDate] >= Cast([MPI].[Dob] + '-01' AS DATE) -- don't want any before birthdate
    /*AND [MPI].[CodingOptOutFlag] <> 'Y' -- no longer need these flags 
    AND [MPI].[OptedOutType2Flag] <> 'Y'*/
) AS GP
INNER JOIN (
    SELECT * 
    FROM #copdcodes
) AS RefCo
ON [GP].[SuppliedCode] COLLATE SQL_Latin1_General_CP1_CS_AS  = [RefCo].[SnomedCT_ConceptID] COLLATE SQL_Latin1_General_CP1_CS_AS 
ORDER BY [EventDate];


-- Will also want the first ever record, for matching with prescriptions
drop table if EXISTS [Client_SystemP_RW].[HUP_AH_phirst_gp_copd_min]  
SELECT  [Pseudo_NHS_Number],
        CAST(MIN(EventDate) AS DATE) AS [Date_First_Diag]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_copd_min]  
FROM [Client_SystemP_RW].[HUP_AH_phirst_gp_copd] 
GROUP BY  [Pseudo_NHS_Number]


-- Deleting the events that happen outside of the study period - this is to minimise the data 
--DECLARE @StartDate DATE = '2018-01-01';
delete from [Client_SystemP_RW].[HUP_AH_phirst_gp_copd]  
where EventDate < @StartDate



-------------------------------------------------------------------------------
---------------------------------- GP_Events for CVD -----------------------
-------------------------------------------------------------------------------
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';

DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd];
SELECT 
    [GP].*,
    [RefCo].[description],
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd]  /* Name of the new table */
FROM (
    SELECT 
        [P].[Pseudo_NHS_Number],
        [GP].[PK_GP_Events_ID] AS [FK_GP_Events_ID],
        [GP].[FK_Patient_ID],
        [GP].[FK_Patient_Link_ID],
        [GP].[FK_Reference_Coding_ID], -- what is this?
        [GP].[FK_Reference_SnomedCT_ID],
        CAST([GP].[EventDate] AS DATE) AS [EventDate],
        --[GP].[Episodicity], -- this isn't well recorded
        [GP].[SuppliedCode],
        CAST([MPI].[DeathDate] AS DATE) AS [DeathDate]
    FROM [Client_SystemP].[GP_Events] AS [GP]
    LEFT JOIN (
        SELECT *
        FROM [Client_SystemP].[Patient]
     ) AS [P]
    ON [GP].[FK_Patient_ID] = [P].[PK_Patient_ID]
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
    ON [P].[Pseudo_NHS_Number] = [MPI].[Pseudo_NHS_Number]
--   WHERE [EventDate] > @StartDate AND [EventDate] < @EndDate -- start with all of them so can have min date 
   WHERE  [EventDate] < @EndDate 
    AND [GP].[Deleted] = 'N'
    AND [GP].[FK_Reference_Coding_ID] <> -1
    AND [GP].[FK_Patient_ID] <> -1
    AND [MPI].[Dob] IS NOT NULL
    AND ([GP].[EventDate] <= [MPI].[DeathDate] OR [MPI].[DeathDate] IS NULL) -- don't want any records after deathdate 
    AND [GP].[EventDate] >= Cast([MPI].[Dob] + '-01' AS DATE) -- don't want any before birthdate
    /*AND [MPI].[CodingOptOutFlag] <> 'Y' -- no longer need these flags 
    AND [MPI].[OptedOutType2Flag] <> 'Y'*/
) AS GP
INNER JOIN (
    SELECT * 
    FROM #cvdcodes
) AS RefCo
ON [GP].[SuppliedCode] COLLATE SQL_Latin1_General_CP1_CS_AS  = [RefCo].[SnomedCT_ConceptID] COLLATE SQL_Latin1_General_CP1_CS_AS 
ORDER BY [EventDate];



-- Will also want the first ever record, for matching with prescriptions
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd_min]
SELECT Pseudo_NHS_Number,
        CAST(MIN(EventDate) AS DATE) AS [Date_First_Diag]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd_min]
FROM [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd]
GROUP BY Pseudo_NHS_Number

-- Deleting the events that happen outside of the study period - this is to minimise the data 
--DECLARE @StartDate DATE = '2018-01-01';
delete from [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd] 
where EventDate < @StartDate


-------------------------------------------------------------------------------
---------------------------------- GP_Events for CMD -----------------------
-------------------------------------------------------------------------------
-- DECLARE @StartDate DATE = '2018-01-01';
-- DECLARE @EndDate DATE = '2026-01-01';
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd]
SELECT 
    [GP].*,
    [RefCo].[description],
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
    into [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd]
FROM (
    SELECT
    [P].[Pseudo_NHS_Number],
        [GP].[PK_GP_Events_ID] AS [FK_GP_Events_ID],
        [GP].[FK_Patient_ID],
        [GP].[FK_Patient_Link_ID],
        [GP].[FK_Reference_Coding_ID], -- what is this?
        [GP].[FK_Reference_SnomedCT_ID],
        CAST([GP].[EventDate] AS DATE) AS [EventDate],
        --[GP].[Episodicity], -- this isn't well recorded
        [GP].[SuppliedCode],
        CAST([MPI].[DeathDate] AS DATE) AS [DeathDate]
    FROM [Client_SystemP].[GP_Events] AS [GP]
    LEFT JOIN (
        SELECT *
        FROM [Client_SystemP].[Patient]
     ) AS [P]
    ON [GP].[FK_Patient_ID] = [P].[PK_Patient_ID]
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
    ON [P].[Pseudo_NHS_Number] = [MPI].[Pseudo_NHS_Number]
--   WHERE [EventDate] > @StartDate AND [EventDate] < @EndDate -- start with all of them so can have min date 
   WHERE  [EventDate] < @EndDate 
    AND [GP].[Deleted] = 'N'
    AND [GP].[FK_Reference_Coding_ID] <> -1
    AND [GP].[FK_Patient_ID] <> -1
    AND [MPI].[Dob] IS NOT NULL
    AND (Cast([GP].[EventDate] as date ) <= cast([MPI].[DeathDate] as date) OR [MPI].[DeathDate] IS NULL)-- don't want any records after deathdate 
    AND Cast([GP].[EventDate] as date )>=  Cast([MPI].[Dob] + '-01' AS DATE)-- Don't want any from before date of birth
    /*AND [MPI].[CodingOptOutFlag] <> 'Y' -- no longer need these flags 
    AND [MPI].[OptedOutType2Flag] <> 'Y'*/
) AS GP
INNER JOIN (
    SELECT * 
    FROM #cmdcodes
) AS RefCo
ON [GP].[SuppliedCode] COLLATE SQL_Latin1_General_CP1_CS_AS  = [RefCo].[SnomedCT_ConceptID] COLLATE SQL_Latin1_General_CP1_CS_AS 
ORDER BY [EventDate];

-- Will also want the first ever record, for matching with prescriptions
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd_min] 
SELECT Pseudo_NHS_Number,
        CAST(MIN(EventDate) AS DATE) AS [Date_First_Diag]
INTO [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd_min]
FROM [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd]
GROUP BY Pseudo_NHS_Number

-- Deleting the events that happen outside of the study period - this is to minimise the data 
-- building in a 1 year buffer for medication for cmd 
--DECLARE @StartDate DATE = '2017-01-01';
delete from [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd]
where EventDate < @StartDate

-------------------------------------------------------------------------------
---------------------------------- GP_Events for falls -----------------------
-------------------------------------------------------------------------------
-- Extracting falls from GP events
drop table if EXISTS [Client_SystemP_RW].[HUP_AH_phirst_gp_falls]
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';
SELECT 
    [GP].*,
    [RefCo].[term] as description,
    CAST(GETDATE() AS DATE) AS [ExtractionDate]
    into [Client_SystemP_RW].[HUP_AH_phirst_gp_falls]
    from ( 
        SELECT    [P].[Pseudo_NHS_Number],
        [GP].[PK_GP_Events_ID] AS [FK_GP_Events_ID],
        [GP].[FK_Patient_ID],
        [GP].[FK_Patient_Link_ID],
        [GP].[FK_Reference_Coding_ID], -- what is this?
        [GP].[FK_Reference_SnomedCT_ID],
        CAST([GP].[EventDate] AS DATE) AS [EventDate],
        --[GP].[Episodicity], -- this isn't well recorded
        [GP].[SuppliedCode],
        CAST([MPI].[DeathDate] AS DATE) AS [DeathDate]
    FROM [Client_SystemP].[GP_Events] AS [GP]
    LEFT JOIN (
        SELECT *
        FROM [Client_SystemP].[Patient]
     ) AS [P]
    ON [GP].[FK_Patient_ID] = [P].[PK_Patient_ID]
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI]
    ON [P].[Pseudo_NHS_Number] = [MPI].[Pseudo_NHS_Number]
--   WHERE 
   WHERE  [EventDate] < @EndDate 
    AND [GP].[Deleted] = 'N'
    AND [GP].[FK_Reference_Coding_ID] <> -1
    AND [GP].[FK_Patient_ID] <> -1
    AND [MPI].[Dob] IS NOT NULL
    AND [EventDate] > @StartDate AND [EventDate] < @EndDate 
    AND (Cast([GP].[EventDate] as date ) <= cast([MPI].[DeathDate] as date) OR [MPI].[DeathDate] is null)-- don't want any records after deathdate 
    AND Cast([GP].[EventDate] as date )>=  Cast([MPI].[Dob] + '-01' AS DATE)-- Don't want any from before date of birth
    /*AND [MPI].[CodingOptOutFlag] <> 'Y' -- no longer need these flags 
    AND [MPI].[OptedOutType2Flag] <> 'Y'*/
) AS GP
INNER JOIN (
    select * 
    from [Client_SystemP_RW].[HUP_code_lists_refset_falls] 
    where [include] = 1)  AS RefCo
ON cast([GP].[SuppliedCode] AS nvarchar)  = cast([RefCo].[Code] as nvarchar) 
ORDER BY [EventDate];





-------------------------------------------------------------------------------
---------------------------------- Compiling tables ----------------------------
-------------------------------------------------------------------------------

-- Combining all the gp data together 
drop table if exists #tmp
select 
Pseudo_NHS_Number, 
FK_GP_Events_ID,
FK_Patient_ID,
FK_Patient_Link_ID, 
FK_Reference_Coding_ID,
FK_Reference_SnomedCT_ID,
EventDate, 
SuppliedCode, 
DeathDate, 
[description] collate SQL_Latin1_General_CP1_CS_AS as description, 
ExtractionDate,
outcome = 'asthma_gp'    
into #tmp 
from [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma]
union all 
select *,
outcome = 'copd_gp'  
--into #tmp 
from [Client_SystemP_RW].[HUP_AH_phirst_gp_copd]
union all 
select *,
outcome = 'cvd_gp'  
from [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd]
union all 
select *,
outcome = 'cmd_gp'  
from [Client_SystemP_RW].[HUP_AH_phirst_gp_cmd]
union all 
select *,
outcome = 'falls_gp'  
from [Client_SystemP_RW].[HUP_AH_phirst_gp_falls]

-- Count per person per year per quarter number of unique days have an X record
-- Long table 
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';
DROP TABLE IF EXISTS #gp_dev_quart 
select 
Pseudo_NHS_Number,
age,
Sex,
acorn_LSOA2011,
year,
quarter,
outcome, 
count (*) as row_count
into #gp_dev_quart 
from(
    select  
event.Pseudo_NHS_Number,
Sex,
acorn_LSOA2011,
imd_dec,
floor(Datediff(Day,  Cast(Dob + '-15' AS DATE), Cast(EventDate as date)) /365.25) as age,
Eventdate,
year,
quarter,
outcome
from (
    SELECT 
Pseudo_NHS_Number,
EventDate,
outcome,
CAST(YEAR(EventDate) AS VARCHAR) as year,
CAST(DATEPART(QUARTER, EventDate) AS VARCHAR) as quarter
from ( -- this bit of code keeps only unique days per individual
    select 
*, 
ROW_NUMBER() over (PARTITION by Pseudo_NHS_Number, outcome, EventDate order by Pseudo_NHS_Number) as RowNbr
from #tmp
)
sub
where RowNbr = 1
) as [event]
left join [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI] 
on event.Pseudo_NHS_Number = MPI.Pseudo_NHS_Number
where EventDate  >= @StartDate
AND EventDate  < @EndDate) as tmp
GROUP BY Pseudo_NHS_Number, 
 year,
quarter,
age,
Sex,
acorn_LSOA2011,
outcome
ORDER BY Pseudo_NHS_Number, year, quarter, age, outcome;




drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_gp_quarter] 
select 
    year, 
    quarter, 
    acorn_LSOA2011 as LSOA2011,
    Sex,
    age_group,
    outcome,
    N = sum(row_count)
    into [Client_SystemP_RW].[HUP_AH_phirst_gp_quarter] 
from (select *,
case when age < 15 then '0-14'
    when age between 15 and 19 then '15-19'
    when age between 20 and 34 then '20-34'
    when age between 35 and 49 then '35-49'
    when age between 50 and 64 then '50-64'
    when age between 65 and 74 then '65-74'
    when age >= 75 then '75+'
    END as age_group
     from #gp_dev_quart ) as gp
group by year, quarter, acorn_LSOA2011, Sex, age_group, outcome
order by year, quarter, acorn_LSOA2011, Sex, age_group, outcome;


