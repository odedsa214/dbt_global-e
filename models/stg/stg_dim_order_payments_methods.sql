/* STG_Dim_Order_Payments_Methods */


with
mrr_paymentmethods as (
                select * 
                from datalake.globale_dbo.paymentmethods
 
        ),



lookup_payments as (
    select  mp.*, 
            p.PaymentMethodTypeName
    
    from mrr_paymentmethods mp
    left join datalake.globale_dbo.paymentmethodtypes as p
    on mp.paymentmethodtypeid = p.paymentmethodtypeid
),



derived_column as (
        select
            * exclude PaymentMethodName,
            iff(paymentmethodtypeid = 0,true,false) as ri_ind,
            sysdate() as dw_insert_date,
            sysdate() as dw_update_date,
            case
                when PaymentMethodId in (53, 54, 55, 91) then concat(PaymentMethodName, ' - ',DisplayToCustomerName)
                else PaymentMethodName
            end AS PaymentMethodName

           
        from lookup_payments

    )


select 
    PaymentMethodId as Payment_Method_Id,
    PaymentMethodName as Payment_Method_Name,
    PaymentMethodTypeId as Payment_Method_Type_Id,
    PaymentMethodTypeName as Payment_Method_Type_Name,
    CASE WHEN PaymentMethodId IN (50, 135,124,139,9008) THEN 'Wallet' ELSE CASE when PaymentMethodTypeName ilike 'Credit Card' then 'Card' else 'Alternative' END END as Payment_Method_Type_Calc,
    IsAutoCapture as Is_Auto_Capture,
    PerformHedging as Perform_Hedging,
    ServesAsUndefined as Serves_As_Undefined,
    DefaultCurrencyId as Default_Currency_Id,
    RI_IND as RI_IND,
    Dw_Insert_Date as Dw_Insert_Date,
    Dw_Update_Date as Dw_Update_Date,
    null as PAYMENTMETHODSOURCE,
    null as FLOWPAYMENTMETHODID,
    null as BFPAYMENTMETHODID
from derived_column

UNION ALL
SELECT 
    -1                as Payment_Method_Id,
    'Shop Pay'        as Payment_Method_Name,
    -1                as Payment_Method_Type_Id,
    'Alternative'     as Payment_Method_Type_Name,
    'Wallet'          as Payment_Method_Type_Calc,
    FALSE             as Is_Auto_Capture,
    FALSE             as Perform_Hedging,
    FALSE             as Serves_As_Undefined,
    0                 as Default_Currency_Id,
    TRUE              as RI_IND,
    CURRENT_TIMESTAMP as Dw_Insert_Date,
    CURRENT_TIMESTAMP as Dw_Update_Date,
    null              as PAYMENTMETHODSOURCE,
    null              as FLOWPAYMENTMETHODID,
    null              as BFPAYMENTMETHODID
