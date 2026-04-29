/*SELECT
    O.OrderId,
    O.OrderRecId,
    O.DateCreated,
    O.DwhDateLastUpdated,
    O.MerchantId,
    O.ShipCountryId,
    O.HubId,
    O.SOURCECOUNTRYID, 
    O.OrderStatusId,
    O.CurrencyId,
    O.ShippingMethodId,
    CASE WHEN PT.PaymentOptionTypeId = 1 THEN -1 ELSE O.PaymentMethodId END AS PaymentMethodId,
    O.EstimatedShippingWeight,
    CASE WHEN O.OriginalOrderId IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsReplacementOrder,
    CASE WHEN TotalEndCustomerShippingPrice = 0 THEN 'Yes' ELSE 'No' END AS IsFreeShipping,
    CASE WHEN O.OrderStatusId NOT IN (3 /*Canceled by Global-E*/, 9	/*Canceled by Merchant*/, 20	/*Canceled by customer*/, 2	/*Payment Declined*/, 5	/*Pending Payment*/) AND YEAR(ODD.DateReceivedByGlobalE) > 1900 THEN 'Yes' ELSE 'No' END AS IsApprovedOrder,
    O.ActivePaymentTransactionId,
    O.RiskStatusId,
    O.OrderedOriginalTotalShippingPrice,
    O.OriginalTotalShippingPrice,
    O.TransactionTotalPrice,
    /*OrderStatuses */
    OS.OrderStatusDisplayName,
    /*PaymentGateways*/
    PG.PaymentGatewayName,
    /*OrderExtraDetails */
    CASE WHEN OED.IsMobile = 1 THEN 'Mobile'
     WHEN OED.IsMobile = 0 THEN 'Desktop' 
     ELSE 'Unknown' END AS PlatformType,
    OED.IsTaxCollectedByGlobalE AS IS_TAX_COLLECTED_BY_GLOBALE,
    OED.ISB2B,
    CASE WHEN OED.ORDERPROCESSINGTYPEID = 2 THEN 1 ELSE 0 END AS IS_3B2C,
    OED.CODFeeCustomerCurrency,
    /*Secured_OrderCustomerDetails */
    OCD.HashShipEmail,
    /*MISC*/
    S.StateName AS ShipStateName,
    ST.Name as storeName, /*Original storeName */
    OCD2.ShipCity,
    OCD2.ShipZip,
    COALESCE(ODD.DateReceivedByGlobalE,TO_DATE('1900-01-01', 'YYYY-MM-DD')) AS OrderDate,
    RD.ReconciliationDate AS ReconciliationDate,
    FirstSM.ShippingMethodId AS CustomerSelectedFirstShippingMethod,
    O.ORIGINALCURRENCYID,
    M.MERCHANTCURRENCYID
FROM datalake.GLOBALE_DBO.Orders O
INNER JOIN {{ref.orders_pop}} P ON P.OrderId = O.OrderId
INNER JOIN datalake.GLOBALE_DBO.OrderStatuses OS ON O.OrderStatusId = OS.OrderStatusId
INNER JOIN datalake.GLOBALE_DBO.PaymentTransactions PT ON O.ActivePaymentTransactionId = PT.PaymentTransactionId
INNER JOIN datalake.GLOBALE_DBO.PaymentGateways PG ON PT.PaymentGatewayId = PG.PaymentGatewayId
INNER JOIN datalake.GLOBALE_DBO.ORDEREXTRADETAILS OED ON O.OrderId = OED.OrderId
INNER JOIN datalake.GLOBALE_SECURED.ORDERCUSTOMERDETAILS OCD ON O.OrderRecId = OCD.OrderRecId
INNER JOIN datalake.GLOBALE_DBO.Countries C ON O.ShipCountryId = C.CountryId
INNER JOIN datalake.GLOBALE_DBO.Merchants M ON O.MerchantId = M.MerchantId
INNER JOIN datalake.GLOBALE_DBO.Countries MC ON M.CountryId = MC.CountryId
INNER JOIN datalake.GLOBALE_DBO.States S ON O.ShipStateId = S.StateId
INNER JOIN datalake.GLOBALE_DBO.Stores ST ON O.StoreId = ST.StoreId
LEFT JOIN  datalake.GLOBALE_DBO.OrderCustomerDetails OCD2 ON OCD2.OrderRecId = O.OrderRecId
LEFT JOIN  datalake.GLOBALE_DBO.ORDERDELIVERYDETAILS ODD ON ODD.OrderId = O.OrderId AND ODD.ParcelId IS NULL
LEFT JOIN {analytics_db}.STG.STG_LKP_ReconciliationDate RD ON RD.OrderId = O.OrderId
LEFT JOIN LATERAL (
    SELECT Case When Count(par.ParcelId) = 0 then 1 else Count(par.ParcelId) end as ParcelsCount
    FROM datalake.GLOBALE_DBO.Parcels par 
    WHERE Par.OrderId = P.OrderId
    /*GROUP BY O.OrderId*/
) Parcels
LEFT JOIN LATERAL(
    /*SELECT X.ShippingMethodId
    FROM (*/
        SELECT 
        /*VO.OrderId*/
        MIN_BY(VO.ShippingMethodId,VO.DateLastUpdated) as ShippingMethodId
        /*, ROW_NUMBER() OVER (PARTITION BY VO.OrderId ORDER BY VO.[DateLastUpdated] ASC) AS Rown*/
        FROM datalake.GLOBALE_DBO.OrderShippingMethodsHistory VO
        WHERE VO.OrderId=P.OrderId 
    /*) X
    WHERE X.Rown = 1*/
) FirstSM
*/