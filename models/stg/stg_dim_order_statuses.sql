/* PKG_STG_Dim_Order_Statuses */


WITH 
mrr_orderstatuses as (
        SELECT 	 os.OrderStatusId as Order_Status_Id
                ,os.OrderStatusName as Order_Status_Name
                ,os.OrderStatusDisplayName as Order_Status_Display_Name
                ,os.OrderStatusDescription as Order_Status_Description
        FROM datalake.globale_dbo.orderstatuses os
        ),

derived_column as (

        select *,
                iff(Order_Status_Id = 0, 1, 0)::boolean as ri_ind,
                sysdate() as dw_insert_date,
                sysdate() as dw_update_date,
                NULL::timestamp as LEGACY_INSERT_DATE,
                NULL::timestamp as LEGACY_UPDATE_DATE
        from mrr_orderstatuses
)
select *
from derived_column
