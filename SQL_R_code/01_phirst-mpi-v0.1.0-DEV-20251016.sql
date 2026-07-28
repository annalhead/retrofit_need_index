/* This is version 0.1.0 of the workflow to create tables for
the PHIRST evaluation of quarterly primary secondary care & medication use. 
Heavily adapted from RVD's MPI workflow code 

Last run on 13 Jan 2026
Full years: 2018-2025

********************INCOMPLETE**********************************

@author: Roberto Villegas-Diaz
@email: r.villegas-diaz@liverpool.ac.uk

@author: Anna Head
@email: anna.head2@liverpool.ac.uk

@author: Lohavani Sevverl
@email: lohavani.Sevverl@liverpool.ac.uk


@date: 2026-01-13

VERSION 0.1.0 IN DEVELOPMENT

*/



-------------------------------------------------------------------------------
---------------------------------- Patients of interest -----------------------
-------------------------------------------------------------------------------
/* Selecting patients in C&M  who did not die before the start
of the study period, with a flag  for LCR */
drop table if exists [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026]
drop table if exists #tmp_mpi

DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = '2026-01-01'; 
SELECT 
        P.Pseudo_NHS_Number,
        P.PK_Patient_ID AS FK_Patient_ID,
        MAX(
            CASE
                WHEN left(GPPracticeCode, 1) = 'V' THEN '0'
                ELSE left(GPPracticeCode, 6)
            END
        ) AS GP_PracticeCode, -- Vs were only duplicates on practices
        GP_CCG_CODE,
        GP_CCG_Name,
        -- P.X_CCG_OF_REGISTRATION, -- this is the same as gp_ccg_code 
        P.X_CCG_OF_RESIDENCE AS Residence_CCG_code,
        Case 
            when acorn.der_ONS_LSOA2011 IN (select distinct lsoa11cd -- using acorn as this is what using for the Uprn households
            from [Client_SystemP_RW].[GW_REF_LSOA2011_TO_LSOA2021_TO_LAD2022] 
            where lsoa11nm like 'Liverpool%' or  lsoa11nm like 'Knowsley%' OR lsoa11nm like 'Halton%' OR
            lsoa11nm like 'Sefton%' or lsoa11nm like 'St. Helens%' or lsoa11nm like 'Wirral%' ) THEN 'Y' 
            ELSE 'N' 
        END AS LCR_flag, 
        Dob,
        Sex,
        EthnicGroup,
        EthnicSubGroup,
        LSOA_Code as gp_LSOA2011,
        acorn.der_ONS_LSOA2011 as acorn_LSOA2011,
        imd_dec,
        PL.Deceased,
        Cast(DeathDate AS DATE) AS DeathDate,
        CASE
            WHEN U.Pseudo_Number IS NULL THEN 'N'
            ELSE 'Y'
        END AS UPRNMatch,
        CASE
            WHEN acorn.Pseudo_NHS_Number IS NULL THEN 'N'
            ELSE 'Y'
        END AS acornMatch,
        acorn.Pseudo_UPRN  as Pseudo_UPRN_acorn,-- using the national uprn 
        U.Pseudo_UPRN  as Pseudo_UPRN_uprn -- adding the uprn_res linkage one here just in case
        into #tmp_mpi
    FROM 
        Client_SystemP.Patient AS P
        LEFT JOIN Client_SystemP.Patient_Link AS PL ON P.FK_Patient_Link_ID = PL.PK_Patient_Link_ID -- mapping extra patient info
        LEFT JOIN Client_SystemP_RW.JWRefEthnicLookUp AS E ON PL.NHS_EthnicCategory = E.EthnicCode -- mapping ethnicity codes
        LEFT JOIN Client_SystemP_RW.OB_MPI_ref_practices AS RP ON P.GPPracticeCode = RP.GP_Code -- Map practice to CCG codes
        LEFT OUTER JOIN [Client_SystemP].[UPRN_Res_Linkage] AS U ON P.Pseudo_NHS_Number = U.Pseudo_Number 
        LEFT OUTER JOIN [Client_SystemP].[UPRN_Acorn] AS acorn ON P.Pseudo_NHS_Number = acorn.Pseudo_NHS_Number 
        left join [Client_SystemP_RW].[GW_REF_IMD_2019] as [imd] on  [LSOA_Code] = [lsoa11cd]
        --left join [Client_SystemP_RW].[GW_REF_OA21_LSOA21_MSOA21_LAD25] as [lsoa_ref] on  [LSOA_Code] = [lsoa21cd]
        Where GPPracticeCode <> 'ZZZZ'
        AND	FK_Reference_Tenancy_ID = '2' -- this is standard registration at a gp practice 
        AND P.Pseudo_NHS_Number IS NOT NULL -- need to have a pseudo nhs number 
        AND (DeathDate >= @StartDate OR DeathDate is NULL) -- removing people who died before start of study 
        And CAST(Dob + '-01' AS DATE) < @EndDate -- don't want people born after end of study
        GROUP BY 
        P.Pseudo_NHS_Number,
        P.PK_Patient_ID,
        acorn.Pseudo_UPRN,
        U.Pseudo_UPRN,
        Dob,
        GP_CCG_CODE,
        GP_CCG_Name,
        -- P.X_CCG_OF_REGISTRATION, -- this is the same as gp_ccg_code 
        P.X_CCG_OF_RESIDENCE,
        Sex,
        EthnicGroup,
        EthnicSubGroup,
        imd_dec,
        Deceased,
        LSOA_Code,
        acorn.der_ONS_LSOA2011,
        DeathDate,
        CASE
            WHEN U.Pseudo_Number IS NULL THEN 'N'
            ELSE 'Y'END,
            CASE
            WHEN acorn.Pseudo_NHS_Number IS NULL THEN 'N'
            ELSE 'Y'
        END;

/* For some reason there are some duplicates with multiple PK_Patient_IDs for the same Pseudo_NHS_Numbers. 
But all the other information for these individuals is the same. So removing these 
2,728,520 unique NHS numbers on 13 Jan 2026*/ 
select count (distinct Pseudo_NHS_Number) from #tmp_mpi
select count (*) from #tmp_mpi -- 2,735,485

select 
Pseudo_NHS_Number,
FK_Patient_ID,
GP_PracticeCode,
        GP_CCG_CODE,
        GP_CCG_Name,
        Residence_CCG_code,
        LCR_flag,
        Dob,
        Sex,
        EthnicGroup,
        EthnicSubGroup,
        gp_LSOA2011,
        acorn_LSOA2011,
        imd_dec,
        Deceased,
        DeathDate,
        UPRNMatch,
        acornMatch,
        Pseudo_UPRN_acorn,
        Pseudo_UPRN_uprn -- probably don't want this 
into [Client_SystemP_RW].[HUP_AH_phirst_mpi_Jan2026]
from(
select 
*, 
ROW_NUMBER() over (PARTITION by Pseudo_NHS_Number order by Pseudo_NHS_Number) as RowNbr
from #tmp_mpi)
sub
where RowNbr = 1

-------------------------------------------------------------------------------

