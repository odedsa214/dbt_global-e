SELECT
    SS.ShippingServiceId,
    SM.ShippingMethodId,
    SM.IsActive,
    SM.ShippingMethodName,
    SM.ShippingRateCardTypeID,
    SM.ShippingMethodDescription,
    SM.IsLocal,
    SM.CurrencyId,
    SM.CountryId,
    SMT.ShippingMethodTypeId,
    SMT.ShippingMethodTypeName,
    SMTG.ShippingMethodTypeGroupId,
    SMTG.ShippingMethodTypeGroupName,
    SS.ShippingServiceName,
    /*Using POSITION instead of PATINDEX to check if substring appears in ShippingServiceName*/
    CASE
        WHEN SS.ShippingServiceName ilike '%DHL%' THEN 'DHL'
        WHEN SS.ShippingServiceName ilike '%DPD%' THEN 'DPD'
        WHEN SS.ShippingServiceName ilike '%Asendia%' THEN 'Asendia'
        WHEN SS.ShippingServiceName ilike '%Temando%' THEN 'Temando'
        WHEN SS.ShippingServiceName ilike '%FedE%' THEN 'FedEx'
        ELSE SS.ShippingServiceName
    END AS ShippingServiceNameUnified,
    SSG.GroupName AS ShippingServiceGroup,
    SSG.ShippingServiceGroupID,
    CASE
        WHEN COALESCE(VolumeWeightDenominator, 0) = 0 THEN 'Dead'
        ELSE 'Volumetric'
    END AS OrderShippingType,
    null as SHIPPINGMETHODSOURCE,
    null as BFSHIPPINGMETHODID,
    SM.ShippingMethodAPITypeId as SHIPPING_METHOD_API_TYPE_ID
FROM datalake.GLOBALE_DBO.ShippingMethods SM
INNER JOIN datalake.GLOBALE_DBO.ShippingMethodTypes SMT ON SM.ShippingMethodTypeId = SMT.ShippingMethodTypeId
INNER JOIN datalake.GLOBALE_DBO.ShippingMethodTypeGroups SMTG ON SMT.ShippingMethodTypeGroupId = SMTG.ShippingMethodTypeGroupId
INNER JOIN datalake.GLOBALE_DBO.ShippingServices SS ON SS.ShippingServiceId = SM.ShippingServiceId 
INNER JOIN datalake.GLOBALE_DBO.GroupShippingServices GSS ON GSS.ShippingServiceID = SS.ShippingServiceId
INNER JOIN datalake.GLOBALE_DBO.ShippingServiceGroups SSG ON SSG.ShippingServiceGroupID = GSS.ShippingServiceGroupID