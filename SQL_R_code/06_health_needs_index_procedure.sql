/* This is version 0.1.1 of the workflow to pull the data together for 
creating a health needs index 

Last run on 13 Jan 2026
Full years: 2018-2025

@author: Anna Head
@email: anna.head2@liverpool.ac.uk

@author: Lohavani Sevverl
@email: lohavani.Sevverl@liverpool.ac.uk

@date: 2026-03-25

VERSION 0.1.1 IN DEVELOPMENT

*/

/*For creating a household-level low-income flag, using diagnosis 
of conditions (COPD, asthma, CVD, CMD) as a predictor
For COPD, asthma, CVD - at least 1 GP record of the condition <=2018 used as diagnosis
For CMD - using at least 1 GP record of the condition <=2018 PLUS a CMD prescription in 2018 as diagnosis 
*/




/* Utilisation that goes into the health needs index 
Emergency admissions for CVD all ages 1.14936232 
Emergency admissions for resp conditions all ages 1.14099571 
Emergency admissions for injuries age 60+ 1.22366723 
Prescribed medications for participants with a CMD 1.02359888
Resp prescriptions for participants with history of resp conditions all ages 1.02442886 1.02184866 - 
GP contacts for participants with a history of asthma or COPD 1.01926847 - restricted these to GP contacts for asthma/COPD
*/

-- Bringing together uprn level variables -- Bringing together uprn level variables 
drop table if EXISTS #uprn_tmp
select 
acorn.Pseudo_UPRN as acorn_pseudo_UPRN, 
uprn.Address_From_Month as uprn_Address_From_Month, 
mpi.gp_LSOA2011 as gp_LSOA2011,
mpi.acorn_LSOA2011 as acorn_LSOA2011,
mpi.LCR_flag,
acorn.der_Care_Home_Residence_Flag as acorn_CareHomeFlag,
acorn.caci_Acorn_Household_Type, -- don't know where the lookup for this is 
acorn.der_Total_Household_Population as acorn_total_household_population,
acorn.der_Living_Alone_Flag as acorn_living_alone_flag,
acorn.der_Living_with_People_Under18_Flag as acorn_living_with_under_18_flag,
acorn.der_Living_with_People_Over64_Flag as acorn_living_with_over_64_flag,
acorn.EPC_Current_Energy_Rating
into #uprn_tmp
from [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026] as mpi
left join Client_SystemP.UPRN_Acorn as acorn
on mpi.Pseudo_NHS_Number = acorn.Pseudo_NHS_Number
left join Client_SystemP.UPRN_Res_Linkage as uprn
on mpi.Pseudo_NHS_Number = uprn.Pseudo_Number

--select top 10 * from #uprn_tmp

GO
CREATE OR ALTER PROCEDURE [Client_SystemP_RW].compile_yearly 
    @year INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @mpi_table NVARCHAR(40)
    DECLARE @uprn_table NVARCHAR(40)
    DECLARE @hup_uprn_table NVARCHAR(100)
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @year_str NVARCHAR(40)

    SET @year_str = CAST(@year AS NVARCHAR(10))
    SET @mpi_table = N'##mpi_' + @year_str;
    SET @uprn_table = N'##mp_uprn' + @year_str;
    SET @hup_uprn_table = N'[Client_SystemP_RW].[HUP_AH_phirst_' + @year_str + 'summary_uprn]';

    SET @SQL = N'drop table if EXISTS ' + @mpi_table + N';';
    EXEC sp_executesql @SQL;

    SET @SQL = N'select  p.*, 
    case when copd.copd = ''1'' then 1 else 0 end as ''copd_diagnosis'',
    case when asthma.asthma = ''1''  then 1 else 0 end as ''asthma_diagnosis'',
    case when cvd.cvd = ''1'' then 1 else 0 end as ''cvd_diagnosis'',
    case when apce.outcome = ''cvd_apce'' then 1 else 0 end as ''cvd_apce'',
    case when apce.outcome in ( ''copd_apce'', ''asthma_copd'' )then 1 else 0 end as ''resp_apce'', 
    case when apce.outcome = ''injuries_apce'' and age >= 60 then 1 else 0 end as ''injuries_apce'',  
    case when med.outcome in ( ''copd_medication'', ''asthma_medication'' )then 1 else 0 end as ''resp_medication'', 
    case when med.outcome = ''cmd_medication'' then 1 else 0 end as ''cmd_medication'', -- also using this for diagnosis 
    case when gp.row_count > 0  then 1 else 0 end as ''resp_gp'' 
    into ' + @mpi_table +
    ' from (select *,
    floor(Datediff(Day,  Cast(Dob + ''-15'' AS DATE), Cast(''' + @year_str + N'-07-01'' as date)) /365.25) as age
    from
    [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026]
    where (year(DeathDate) >= @year OR DeathDate is null)
    and year(Cast(Dob + ''-15'' AS DATE)) <= @year) as p
    left join -- diagnosed copd
    (select Pseudo_NHS_Number, copd = 1 from [Client_SystemP_RW].[HUP_AH_phirst_gp_copd_min] where year(Date_First_Diag) <= @year ) as copd
    on p.Pseudo_NHS_Number = copd.Pseudo_NHS_Number
    left join -- diagnosed asthma
    (select Pseudo_NHS_Number, asthma = 1 from [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma_min] where year(Date_First_Diag) <= @year ) as asthma
    on p.Pseudo_NHS_Number = asthma.Pseudo_NHS_Number
    left join -- diagnosed cvd
    (select Pseudo_NHS_Number, cvd = 1 from [Client_SystemP_RW].[HUP_AH_phirst_gp_cvd_min] where year(Date_First_Diag) <= @year ) as cvd
    on p.Pseudo_NHS_Number = cvd.Pseudo_NHS_Number
    left  join ( -- emergency admissions
        select  Pseudo_NHS_Number, 
        year(Episode_Start_Date) as year, 
        outcome
    from [Client_SystemP_RW].[HUP_AH_phirst_apce_conditions]
    where outcome in (''cvd_apce'', ''copd_apce'', ''asthma_apce'', ''injuries_apce'')
    and year(Episode_Start_Date) = @year
    group by 
    Pseudo_NHS_Number, 
    year(Episode_Start_Date), 
    outcome) as apce
    on p.Pseudo_NHS_Number = apce.Pseudo_NHS_Number
    left join ( -- medications 
        select * from  [Client_SystemP_RW].[HUP_AH_phirst_meds_annual_ind]
    where year = @year and 
    outcome in (''copd_medication'', ''asthma_medication'', ''cmd_medication'')) as med
    on p.Pseudo_NHS_Number = med.Pseudo_NHS_Number
    left join ( -- GP appointment for people with asthma/copd - this is for asthma/copd only 
        select Pseudo_NHS_Number, 
    year(EventDate) as year,
    count (*) as row_count
    from  [Client_SystemP_RW].[HUP_AH_phirst_gp_asthma] 
    where year(EventDate) = @year group by 
    Pseudo_NHS_Number, 
    year(EventDate)) as gp
    on p.Pseudo_NHS_Number = gp.Pseudo_NHS_Number' + N';';

    PRINT @SQL;
    
    EXEC sp_executesql
    @SQL,
    N'@year INT',
    @year;

    -- collating the health metrics at uprn level
    SET @SQL = N'drop table if EXISTS ' + @uprn_table + N';';
    EXEC sp_executesql @SQL;



    SET @SQL = N'select 
    Pseudo_UPRN_acorn,
    count (*) as persons,
    max(cvd_diagnosis) as cvd_diagnosis, 
    max(copd_diagnosis) as copd_diagnosis, 
    max(asthma_diagnosis) as asthma_diagnosis, 
    max(cvd_apce) as cvd_apce, 
    max(resp_apce) as resp_apce, 
    max(injuries_apce) as injuries_apce, 
    max(cmd_medication) as cmd_medication,
    max(resp_medication) as resp_medication,
    max(resp_gp) as resp_gp,
    min(age) as min_age,
    count (case when age < 18 then 1 else null end) as child_N, 
    count (case when age > 64 then 1 else null end) as old_N, 
    case when min(age) < 18 then ''Y'' else ''N'' end as ''gp_under18_flag'', 
    case when min(age) < 16 then ''Y'' else ''N'' end as ''gp_under16_flag'', 
    case when min(age) < 14 then ''Y'' else ''N'' end as ''gp_under14_flag'', 
    max(age) as max_age,
    case when max(age) >= 65 then ''Y'' else ''N''  end as ''gp_over64_flag''
    into ' + @uprn_table +
    ' from ' + @mpi_table + ' as mpi
    group by Pseudo_UPRN_acorn' + N';';

    EXEC sp_executesql @SQL;

    /* -- checking uprns are in LCR
    select *  from #mpi_2018 
    where acorn_LSOA2011 not in (select distinct lsoa11cd
    from [Client_SystemP_RW].[GW_REF_LSOA2011_TO_LSOA2021_TO_LAD2022]
    where lsoa11nm like 'Liverpool%' or  lsoa11nm like 'Knowsley%' OR lsoa11nm like 'Halton%' OR
    lsoa11nm like 'Sefton%' or lsoa11nm like 'St. Helens%' or lsoa11nm like 'Wirral%' )
    */

    -- Making the uprn-level table for 2018 
    SET @SQL = N'drop table if EXISTS ' + @hup_uprn_table + N';';
    
    EXEC sp_executesql @SQL;
    
    SET @SQL = N'select 
    acorn_pseudo_UPRN as uprn,
    gp_LSOA2011,
    acorn_LSOA2011, 
    LCR_flag,
    imd_dec, 
    inc_score as imd_inc_score,
    acorn_total_household_population, 
    persons,
    acorn_CareHomeFlag,
    acorn_living_alone_flag,
    acorn_living_with_under_18_flag,
    child_N, 
    old_N, 
    gp_under18_flag,
    gp_under16_flag,
    gp_under14_flag,
    acorn_living_with_over_64_flag, 
    gp_over64_flag,
    EPC_Current_Energy_Rating,
    cvd_diagnosis,
    copd_diagnosis,
    asthma_diagnosis,
    cvd_apce,
    resp_apce,
    injuries_apce, 
    cmd_medication,
    resp_medication,
    resp_gp
    into ' + @hup_uprn_table + '
    from ' + @uprn_table + ' as tmp
    left join  ( -- this bit of code keeps only unique days per individual
        select * from (select 
    *, 
    ROW_NUMBER() over (PARTITION by acorn_pseudo_UPRN order by acorn_pseudo_UPRN) as RowNbr
    from #uprn_tmp
    where acorn_pseudo_UPRN is not null
    )
    sub
    where RowNbr = 1
    )  as uprn
    on tmp.Pseudo_UPRN_acorn = uprn.acorn_pseudo_UPRN
    left join [Client_SystemP_RW].[GW_REF_IMD_2019]  as imd
    on uprn.acorn_LSOA2011 = imd.lsoa11cd' + N';';

    EXEC sp_executesql @SQL;

    -- to test for correct output
    -- SET @SQL = N'SELECT sum(old_N) FROM ' + @hup_uprn_table + N';';
    -- EXEC sp_executesql @SQL;

END
GO
-- end of procedure

-- looping through the years and calling procedure

DECLARE @year int = 2018
WHILE @year <= 2025
BEGIN
    EXEC [Client_SystemP_RW].compile_yearly @year;
    SET @year = @year + 1
END
