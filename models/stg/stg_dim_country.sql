
{{ config(materialized='table') }}

WITH
mrr_countries as (

    select *
    from datalake.globale_dbo.countries          

                ),

lookup_and_derived_regions as (

  select mc.*,
    COALESCE(sc.geographicalregion, 'Unknown') AS GeographicalRegion,
    COALESCE(sc.businessregion, 'Unknown') AS BusinessRegion,
    COALESCE(sc.europeanunion, 'Unknown') AS IsEuropeanUnion
    from mrr_countries as mc
    left join {{ ref('stg_mgmt_countryregionmapping') }}  as sc
    on mc.countryname = sc.CountryName

     ),

derived_regions_countries as (

    select *,
           iff(CountryId = 0,-1,0) as ri_ind,
           sysdate() as dw_insert_date,
           sysdate() as dw_update_date
    from lookup_and_derived_regions
    
    ),

    google_analytics_countries as (
    select 
            C.CountryId as Country_Id,
            C.CountryName as Country_Name,
            C.CountryCode as Country_Code,
            C.CountryCode3 as Country_Code_3,
            C.DefaultCurrencyId as Default_Currency_Id,
            C.dw_insert_date,
            C.dw_update_date,
            C.ri_ind,
            C.GeographicalRegion,
            C.BusinessRegion,
            C.IsEuropeanUnion,
            GC.countryname as GoogleAnalyticsCountryName,
            C.IsEU,
            C.TaxCalculationRuleId
    from derived_regions_countries C
    left join {{ ref('STG_MGMT_GoogleCountries') }}  GC
    ON C.CountryId =GC.CountryId
    )

select *
from google_analytics_countries