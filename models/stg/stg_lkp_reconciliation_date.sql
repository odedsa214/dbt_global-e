WITH MerchantReconciliationOrderStatuses AS (
SELECT DISTINCT MerchantId, ReconciliationDateStatusId
FROM (
SELECT rg.MerchantId, mf.ReconciliationDateStatusId
  FROM datalake.GLOBALE_DBO.MerchantReportGroups rg
  INNER JOIN datalake.GLOBALE_DBO.MERCHANTFEES mf ON rg.ReportGroupId = mf.ReportGroupId
  UNION ALL
  SELECT mf.MerchantId, mf.ReconciliationDateStatusId
  FROM datalake.GLOBALE_DBO.MERCHANTFEES mf
  WHERE mf.ReportGroupId IS NULL
  and mf.MerchantId not in (select rg.MerchantId FROM datalake.GLOBALE_DBO.MerchantReportGroups rg
	INNER JOIN datalake.GLOBALE_DBO.MerchantFees mf
	ON rg.ReportGroupId = MF.ReportGroupId)
))
,
RawOrders AS(
SELECT O.OrderId,
       O.MerchantId,
       pt.PaymentMethodId,
       odd.DateReceivedByGlobalE AS DateReceivedByGlobalE,
       NULLIF(odd.ActualShippedByMerchant, '1900-01-01') AS ActualShippedByMerchant,
       NULLIF(odd.ActualReceivedinHub, '1900-01-01') AS ActualReceivedinHub,
       NULLIF(odd.ActualDispatchedtocustomer, '1900-01-01') AS ActualDispatchedtocustomer,
       NULLIF(odd.ActualDeliveredtocustomer, '1900-01-01') AS ActualDeliveredtocustomer,
       COALESCE(BSP.BespokeIndicator, 0) AS BespokeIndicator
FROM datalake.GLOBALE_DBO.Orders O
INNER JOIN datalake.GLOBALE_DBO.ORDERDELIVERYDETAILS odd ON O.OrderId = odd.OrderId AND odd.ParcelId IS NULL
INNER JOIN datalake.GLOBALE_DBO.PaymentTransactions pt ON pt.PaymentTransactionId = O.ActivePaymentTransactionId
LEFT JOIN LATERAL( 
  SELECT MAX(1) AS BespokeIndicator
  FROM datalake.GLOBALE_DBO.ORDERPRODUCTS OP
  WHERE OP.OrderId = O.OrderId
  AND OP.IsBackOrdered = 1
) BSP 
WHERE (
    O.OrderStatusId NOT IN (3, 9, 20, 2, 5, 19)
    OR ((O.OrderStatusId = 2)
    AND odd.ActualReceivedInHub < O.DateStatusLastUpdated))
 AND NOT EXISTS (
     SELECT 1 FROM analytics.STG.STG_LKP_ReconciliationDate RD WHERE RD.OrderId = O.OrderId
 ))


SELECT OrderId,
       CASE
           WHEN s.ReconciliationDateStatusId = 16 THEN COALESCE(RO.ActualReceivedinHub, RO.ActualDispatchedtocustomer, RO.ActualDeliveredtocustomer)
           WHEN s.ReconciliationDateStatusId IN (14, 15) THEN COALESCE(RO.ActualShippedByMerchant, RO.ActualReceivedinHub, RO.ActualDispatchedtocustomer,RO.ActualDeliveredtocustomer)
           WHEN s.ReconciliationDateStatusId = 6 THEN RO.DateReceivedByGlobalE
           WHEN s.ReconciliationDateStatusId = 18 THEN COALESCE(RO.ActualDispatchedtocustomer, RO.ActualDeliveredtocustomer)
           WHEN s.ReconciliationDateStatusId = 29 THEN RO.ActualDeliveredtocustomer
       END AS ReconciliationDate,
       CURRENT_TIMESTAMP() AS DWHDateInserted,
       'RegularOrders' AS SourceType
FROM RawOrders RO
INNER JOIN MerchantReconciliationOrderStatuses S ON S.MerchantId = RO.MerchantId
WHERE RO.PaymentMethodId <> 47
AND NOT (RO.MerchantId = 336 AND BespokeIndicator = 1)
AND ReconciliationDate IS NOT NULL
UNION ALL
SELECT RO.OrderId,
       RO.ActualDeliveredToCustomer AS ReconciliationDate,
       CURRENT_TIMESTAMP() AS DWHDateInserted,
       'COD' AS SourceType
FROM RawOrders RO
WHERE RO.PaymentMethodId = 47
AND RO.ActualDeliveredToCustomer IS NOT NULL
UNION ALL
SELECT RO.OrderId,
       RO.DateReceivedByGlobalE AS ReconciliationDate,
       CURRENT_TIMESTAMP() AS DWHDateInserted,
       'Bespoke' AS SourceType
FROM RawOrders RO
WHERE RO.MerchantId = 336
AND BespokeIndicator = 1
AND RO.DateReceivedByGlobalE IS NOT NULL