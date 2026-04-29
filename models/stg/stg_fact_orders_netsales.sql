WITH Discounts AS 
(
    SELECT  
        OD.OrderId,
        SUM(OriginalDiscountValue / (1 + (LocalVATRate / 100))) AS TotalOriginalDiscountValueExVAT
    FROM shared_prod_datalake.GLOBALE_DBO.OrderDiscounts OD
    INNER JOIN {{ ref ('orders_pop') }} P ON P.OrderId = OD.OrderId 
    WHERE DiscountTypeId = 1 /* Cart discount*/
        AND DiscountSourceId != 5 /* Amend*/
    GROUP BY OD.OrderId
),
GrossProducts AS 
(
    SELECT  
        OP.OrderId,
        SUM(OriginalSalePriceBeforeGlobalEDiscount * OrderedQuantity / (1 + (LocalVATRate / 100))) AS GrossItemPriceExVAT
    FROM shared_prod_datalake.GLOBALE_DBO.OrderProducts OP
    INNER JOIN {{ ref ('orders_pop') }} P ON P.OrderId = OP.OrderId 
    GROUP BY OP.OrderId
)

SELECT  
    GP.OrderId,
    GrossItemPriceExVAT - COALESCE(TotalOriginalDiscountValueExVAT, 0) AS NetSales
FROM GrossProducts GP
LEFT JOIN Discounts D ON GP.OrderId = D.OrderId