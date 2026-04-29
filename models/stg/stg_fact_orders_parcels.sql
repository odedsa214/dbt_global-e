
SELECT
    O.OrderId,
    CASE WHEN COUNT(PP.ParcelId) = 0 THEN 1 ELSE COUNT(PP.ParcelId) END AS ParcelsCount
FROM {{ ref ('orders_pop')}}  P
INNER JOIN shared_prod_datalake.GLOBALE_DBO.Orders O ON O.OrderId = P.OrderId
LEFT JOIN datalake.globale_dbo.V_Active_Parcels PP ON O.OrderId = PP.OrderId
GROUP BY O.OrderId