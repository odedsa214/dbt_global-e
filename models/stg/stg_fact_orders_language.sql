SELECT   
    O.OrderId,
    OED.InitialCultureCode AS InitialCheckoutLanguage,
    C.CultureProgId AS FinalCheckoutLanguage,
    CASE WHEN C.CultureProgId <> OED.InitialCultureCode THEN 1 ELSE 0 END AS FlagCheckoutLanguageChanged
FROM {{ ref ('orders_pop')}} P 
INNER JOIN shared_prod_datalake.GLOBALE_DBO.Orders O ON P.OrderId = O.OrderId	
INNER JOIN shared_prod_datalake.GLOBALE_DBO.ORDEREXTRADETAILS OED ON P.OrderId = OED.OrderId 
INNER JOIN shared_prod_datalake.GLOBALE_DBO.Cultures C ON C.CultureId = O.CultureId