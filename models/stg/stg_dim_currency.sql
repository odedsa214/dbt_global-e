
WITH
mrr_currencies as (
                SELECT  CurrencyId
                        ,CurrencyCode
                        ,CurrencyName
                        ,CurrencySymbol
                FROM datalake.globale_dbo.currencies
                
),


derived_column as (
                select CurrencyId as Currency_Id,
                        CurrencyCode as Currency_Code,
                        NULL::TIMESTAMP as LEGACY_INSERT_DATE,
                        NULL::TIMESTAMP as LEGACY_UPDATE_DATE,
                        sysdate() as dw_insert_date,
                        sysdate() as dw_update_date,
                        iff(currencyid=0,-1,0) as ri_ind, 
                        CurrencySymbol,
                        CurrencyName
                        
                from mrr_currencies

)

select *
from derived_column