SELECT  
    O.OrderId,
    COALESCE(products.TotalProducts, 0) 
    + COALESCE(OED.DutiesPaid, 0) 
    + COALESCE(O.TotalEndCustomerShippingPrice, 0) AS EndCustomerTotalOrderPrice
FROM shared_prod_datalake.GLOBALE_DBO.Orders O
INNER JOIN {{ ref ('orders_pop')}} P ON P.OrderId = O.OrderId
INNER JOIN shared_prod_datalake.GLOBALE_DBO.ORDEREXTRADETAILS OED ON O.OrderId = OED.OrderId 
INNER JOIN LATERAL (
    SELECT 
        SUM(OrderedQuantity * UnitSalePriceForDuties) AS TotalProducts
    FROM shared_prod_datalake.GLOBALE_DBO.OrderProducts OP 
    WHERE OP.orderid = O.orderid
    GROUP BY OP.OrderId
) products