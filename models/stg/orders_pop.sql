with max_date as (
    select dateadd(day, -2, max(DWHDateUpdated))::string as max_DWHDateLastUpdated
    from analytics.stg.STG_Fact_Orders
),

orders_pop as (
    
    SELECT OrderId 
	FROM datalake.GLOBALE_DBO.Orders O
	Where O.DwhDateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date) 
	UNION
	SELECT OrderId 
	FROM datalake.GLOBALE_DBO.OrderRefunds ORF
	Where ORF.DwhDateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date)
	UNION
	SELECT DISTINCT OrderId 
	FROM datalake.GLOBALE_DBO.OrderDiscounts OD
	WHERE OD.DwhDateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date)
	UNION
	SELECT DISTINCT OrderId 
	FROM datalake.GLOBALE_DBO.OrderProducts OP
	WHERE OP.DwhDateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date)
	UNION
	SELECT DISTINCT OrderId 
	FROM  datalake.GLOBALE_DBO.ORDEREXTRADETAILS OED
	WHERE OED.DwhDateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date)
	UNION
	SELECT DISTINCT OrderId 
	FROM datalake.GLOBALE_DBO.Parcels
	WHERE DateLastUpdated >= (SELECT max_DWHDateLastUpdated FROM max_date)
	UNION
	SELECT DISTINCT OrderId 
	FROM analytics.STG.STG_LKP_ReconciliationDate RC
	WHERE RC.DWHDateInserted >= (SELECT max_DWHDateLastUpdated FROM max_date)

)

select * from orders_pop
