SELECT 
	OrderId,
	case when IsReplacementOrder ilike 'No' then 
	(
		(TotalProductsPrice - TotalCartDiscountsPrice) 
		+ 
		(TotalShippingPrice) 
		+ 
		(DutiesPaid + MerchantDTSubsidy) 
		+ 
		(SameDayDispatchCost)
	)
	else
	(
	    (TotalShippingPrice)
		+ 
		(DutiesPaid + MerchantDTSubsidy/*InitialAvalaraSalesTax*/) 
		+ 
		(SameDayDispatchCost)
	)
	END AS GMV
FROM 
	(
	SELECT 
		 O.OrderId
		,coalesce(TotalProductsPrice 			,0) AS   TotalProductsPrice 
		,coalesce(TotalCartDiscountsPrice		,0) AS   TotalCartDiscountsPrice
		,coalesce(TotalShippingPrice			,0) AS   TotalShippingPrice
		,coalesce(TotalShippingDiscountsPrice	,0) AS   TotalShippingDiscountsPrice
		,coalesce(DutiesPaid					,0) AS   DutiesPaid
		,coalesce(MerchantDTSubsidy			,0) AS   MerchantDTSubsidy
		,coalesce(SameDayDispatchCost			,0) AS   SameDayDispatchCost
		,CASE WHEN O.OriginalOrderId IS NOT NULL THEN 'Yes' ELSE 'No' END As IsReplacementOrder
	FROM {{ref ('orders_pop')}} P 
	INNER JOIN shared_prod_datalake.GLOBALE_DBO.Orders O ON O.OrderId = P.OrderId
    INNER JOIN shared_prod_datalake.GLOBALE_DBO.ORDEREXTRADETAILS OED ON OED.OrderId = P.OrderId
	INNER JOIN  {{ref ('stg_fact_orders_basetable')}}  BT ON BT.OrderId = P.OrderId
)T