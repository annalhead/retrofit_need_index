/* This is version 0.1.0 of the workflow to create tables for
the PHIRST evaluation of quarterly healthcare use. 
Heavily adapted from RVD's asthma workflow code 

This workflow is for Emergency Care (A&E) data - ECDS dataset 
We have used A&E attendances between 6am-midnight as a proxy
for non-alcohol related emergency attendances 

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
---------------------------------- ECDS ---------------------------------------
-------------------------------------------------------------------------------
-- Extracting ECDS events within a specified time - this is the Emergency Care Dataset 
/* restrict these to not happening at night (midnight to 6am) as a proxy for excluding
alcohol related admissions */

DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = '2026-01-01';
DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_ecds];
SELECT 
    [ECDS_MPI].*
INTO [Client_SystemP_RW].[HUP_AH_phirst_ecds] /* Name of the new table */
FROM (
    SELECT 
        ECDS.*,
        MPI.Deceased,
        MPI.Dob,
        MPI.DeathDate
    FROM (
        SELECT 
         CAST(Arrival_Date AS DATE) AS Arrival_Date,
         EC_Chief_Complaint_SNOMED_CT, 
         CMv2_Pseudo_Number AS Pseudo_NHS_Number
        FROM [Client_SystemP].[vw_SUS_Faster_ECDS] AS ECDS
        WHERE 
            (EC_Chief_Complaint_SNOMED_CT IS NOT NULL) AND
                (Arrival_Date BETWEEN @StartDate AND @EndDate) AND
                Arrival_Time >= Cast('06:00:00' as time) /* want to 
                exclude admissions between midnight and 6am as a proxy for alcohol related A&E attendances*/
    ) AS ECDS
    LEFT JOIN [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS MPI
    ON ECDS.Pseudo_NHS_Number = MPI.Pseudo_NHS_Number
) AS ECDS_MPI
where  [Arrival_Date] >=  CAST(Dob + '-01' AS DATE) -- only keep those on/after dob
AND ([Arrival_Date] <= [DeathDate] OR DeathDate is NULL) -- only keep those on/before date of death 
;


-------------------------------------------------------------------------------
---------------------------------- Compiling tables ----------------------------
-------------------------------------------------------------------------------
-- Compiling long table for A&E attendances 
-- Count per person per year per quarter number of unique days have an A&E attendance
-- This code is not efficient at all! I think it could be made into two functions


-- This could be 1 function?
--DECLARE @StartDate DATE = '2018-01-01';
--DECLARE @EndDate DATE = '2026-01-01';
DROP TABLE IF EXISTS #ecds_quarter_ind_tmp 
select
Pseudo_NHS_Number,
age,
Sex,
acorn_LSOA2011,
year,
quarter,
count (*) as row_count
into #ecds_quarter_ind_tmp
from(select  
event.Pseudo_NHS_Number,
Sex, 
acorn_LSOA2011,
imd_dec,
floor(Datediff(Day,  Cast(Dob + '-15' AS DATE), Cast(Arrival_Date as date)) /365.25) as age,
Arrival_Date,
year,
quarter
from (
    SELECT 
Pseudo_NHS_Number,
Arrival_Date,
CAST(YEAR(Arrival_Date) AS VARCHAR) as year,
CAST(DATEPART(QUARTER, Arrival_Date) AS VARCHAR) as quarter
from ( -- this bit of code keeps only unique days per individual
    select 
*, 
ROW_NUMBER() over (PARTITION by Pseudo_NHS_Number, Arrival_Date order by Arrival_Date) as RowNbr
from [Client_SystemP_RW].[HUP_AH_phirst_ecds] 
)
sub
where RowNbr = 1
) as [event]
left join [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] AS [MPI] 
on event.Pseudo_NHS_Number = MPI.Pseudo_NHS_Number
where Arrival_Date  >= @StartDate
AND Arrival_Date  < @EndDate
) as tmp
where Pseudo_NHS_Number is not null
GROUP BY Pseudo_NHS_Number, 
year,
quarter,
age,
Sex,
acorn_LSOA2011
ORDER BY Pseudo_NHS_Number, year, quarter, age;

-- Use this to make an aggregate table by year, quarter, sex, age-group & LSOA
-- This could be another function?
DROP TABLE IF EXISTS [Client_SystemP_RW].[HUP_AH_phirst_ecds_quarter] 
select
    year, 
    quarter, 
    acorn_LSOA2011 as LSOA2011,
    Sex,
    age_group,
    outcome = 'ae_attendances',
    N = sum(row_count)
    into [Client_SystemP_RW].[HUP_AH_phirst_ecds_quarter] 
from (select *,
case when age < 15 then '0-14'
    when age between 15 and 19 then '15-19'
    when age between 20 and 34 then '20-34'
    when age between 35 and 49 then '35-49'
    when age between 50 and 64 then '50-64'
    when age between 65 and 74 then '65-74'
    when age >= 75 then '75+'
    END as age_group
     from #ecds_quarter_ind_tmp) as emad
group by year, quarter,  acorn_LSOA2011, Sex, age_group
order by year, quarter, acorn_LSOA2011, Sex, age_group;



