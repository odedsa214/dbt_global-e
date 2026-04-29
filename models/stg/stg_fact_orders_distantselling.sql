SELECT 
  OrderId,
  MAX(CASE WHEN CountrySettingsTrue = 1 AND MerchantCountrySettingsTrue = 1 AND FromEuToEU = 1 THEN 1 
  ELSE 0 END) AS DistantSellingIndicator
FROM (
  SELECT
    O.OrderId,
    CASE 
    WHEN CountrySettings.SettingValue = 'true' 
    AND CountrySettings.ChgType <> 'D' THEN 1 
    ELSE 0 END AS CountrySettingsTrue,
    CASE 
    WHEN MerchantCountrySettings.SettingValue <> 'false' 
    AND MerchantCountrySettings.ChgType <> 'D' THEN 1 ELSE 0 END AS MerchantCountrySettingsTrue,
    CASE WHEN SourceCountry.IsEU = 1 AND DestCountry.IsEU = 1 THEN 1 ELSE 0 END AS FromEuToEU
  FROM
   shared_prod_datalake.GLOBALE_DBO.ORDERS O
  INNER JOIN {{ ref ('orders_pop') }} P ON P.OrderId = O.OrderId
  INNER JOIN shared_prod_datalake.GLOBALE_DBO.Countries DestCountry ON DestCountry.CountryId = O.ShipCountryId
  INNER JOIN shared_prod_datalake.GLOBALE_DBO.MerchantGlobalEBillingDetails MBD ON MBD.MerchantId = O.MerchantId
  INNER JOIN shared_prod_datalake.GLOBALE_DBO.GlobalEBillingDetails GBD ON GBD.GlobalEBillingDetailId = MBD.GlobalEBillingDetailId
  INNER JOIN shared_prod_datalake.GLOBALE_DBO.Countries SourceCountry ON SourceCountry.CountryId = GBD.CountryId
  LEFT JOIN LATERAL (
    SELECT
      MAX_BY(CTC.SettingValue, CTC.ChgDateCreated) AS SettingValue,
      MAX_BY(CTC.ChgType, CTC.ChgDateCreated) AS ChgType
    FROM
      shared_prod_datalake.GLOBALE_changes.CountryToCountrySettingsChanges CTC
    WHERE
      CTC.TargetCountryId = O.ShipCountryId
      AND CTC.SourceCountryId = O.SourceCountryId
      AND CTC.SettingName = 'UseCountryVAT'
      AND CTC.ChgDateCreated <= O.DateCreated
  ) CountrySettings 
  LEFT JOIN LATERAL (
    SELECT
      MAX_BY(MCTC.SettingValue, MCTC.ChgDateCreated) AS SettingValue,
      MAX_BY(MCTC.ChgType, MCTC.ChgDateCreated) AS ChgType
    FROM
      shared_prod_datalake.GLOBALE_changes.MerchantCountryToCountrySettingsChanges MCTC
    WHERE
      MCTC.MerchantId = O.MerchantId
      AND MCTC.TargetCountryId = O.ShipCountryId
      AND MCTC.SourceCountryId = O.SourceCountryId
      AND MCTC.SettingName = 'UseCountryVAT'
      AND MCTC.ChgDateCreated <= O.DateCreated
  ) MerchantCountrySettings 
) T
group by OrderId