SELECT 
    BT.OrderId,
    COALESCE(WYOL.IsWYOL, WE.IsWYOL, SPP.IsWYOL, 
             CASE WHEN BT.OriginalTotalShippingPrice = 0 
             OR SM.ShippingServiceName = 'Merchant Own Carriage' THEN 1 
             ELSE 0 END) AS IsWYOL
FROM {{ ref('orders_pop') }}  P
INNER JOIN shared_prod_datalake.GLOBALE_DBO.Orders BT ON BT.OrderId = P.OrderId
LEFT JOIN shared_prod_analytics.STG.STG_MGMT_WYOL WYOL ON WYOL.OrderId = BT.OrderId  /*source for that table needed to found*/
INNER JOIN {{ ref('stg_dim_shippingmethods') }} SM ON BT.ShippingMethodId = SM.ShippingMethodId
LEFT JOIN shared_prod_analytics.STG.STG_MGMT_WYOLExcludedShippingMethodIds WE ON WE.ShippingMethodId = SM.ShippingMethodId /*source for that table needed to found*/
LEFT JOIN  (
    SELECT DISTINCT SPP."GE Order#" AS OrderId
    ,0 AS IsWYOL
    FROM shared_prod_datalake.GLOBALE_REPORTS.RECONCILIATIONREPORTEXECUTION_SHIPPINGPERPARCEL SPP
    INNER JOIN shared_prod_datalake.GLOBALE_REPORTS.RECONCILIATIONREPORTEXECUTIONLOG LL 
    ON SPP.ReconciliationReportExecutionGUID = LL.ReconciliationReportExecutionGUID
    WHERE LL.IsDeleted = 0
        AND COALESCE(SPP."Shipping Cost-Actual Shipping Weight-ExVatExMarkUp", 0) > 0 /*Shipping Cost-Actual Shipping Weight-ExVatExMarkUp*/
) SPP on spp.OrderId=BT.OrderId
