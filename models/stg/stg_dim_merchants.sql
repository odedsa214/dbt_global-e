
WITH Merchants AS(
SELECT 
    M.MerchantId,
    IFNULL(M.DEALID, 0) AS DEALID,
    COALESCE(LKP.MerchantNameForQV, RM.ReplatformedMerchant, M.MerchantNameForReports, M.MerchantName) AS Merchant,
    COALESCE(M.MerchantNameForReports, M.MerchantName) AS MerchantDBName,
    M.MerchantName,
    M.MerchantNameForReports,
    LKP.MerchantNameForQV,
    RM.ReplatformedMerchant,
    NVL(LKP.ShouldBeInQV, 1) AS ShouldBeInQV,
    M.CalendarId,
    M.IsActive,
    M.MerchantCurrencyId AS MerchantCurrencyId,
    Curr.CurrencyCode AS MerchantCurrencyCode,
    M.CountryId AS MerchantCountryId,
    C.CountryName AS MerchantCountry,
    IFF(MT.MerchantTypeId = 3, 'NCE',  MT.MerchantTypeName) AS "Pro/Enterprise",
    OMT.MerchantTypeName AS "Original Merchant Type",
    MC.MerchantTypeIdChgDate,
    M.APIPlatformTypeId,
    API_P.MerchantPlatformName AS APIPlatformType,
    M.BrowsingPlatformTypeId,
    Browsing_P.MerchantPlatformName AS BrowsingPlatformType,
    CASE 
        WHEN RTRIM(API_P.MerchantPlatformName, ' ') ilike 'Visual Soft' THEN 'Visual Soft'
        WHEN RTRIM(API_P.MerchantPlatformName, ' ') ilike 'BigCommerce' THEN 'BigCommerce' 
        WHEN RTRIM(M.MerchantName, ' ') ilike 'Frankies Bikinis' THEN 'NRI'
        WHEN RTRIM(M.MerchantName, ' ') ilike any ('John Hardy', 'Faherty Brand LLC','A Pea in the Pod','BCBGMAXAZRIA','Motherhood Maternity') THEN 'Akari Enterprises'
        WHEN RTRIM(M.MerchantName, ' ') ilike 'Vincero Watches' THEN 'Ruby Hass' 
        WHEN RTRIM(M.MerchantName, ' ') ilike any ('Funko UK Ltd','SKIMS','Lightbox Jewelry','Balance Athletica','KITH','KITH EU'
                                  ,'ReDone','ReDone EU','Stussy','Vera Bradley','Easilocks','Lunya') THEN 'Shopify'
        WHEN RTRIM(M.MerchantNameForReports, ' ') ilike 'Value Retail' THEN 'Moddo'
        WHEN RTRIM(M.MerchantName, ' ') ilike any ('Clove and Hallow', 'Wren and Glory') THEN 'Disruptive Digital Agencys'
        ELSE 'NA'
    END AS Partner,
    NVL(V.VerticalName, 'NA') AS Vertical,
    NVL(BT.BusinessTypeName, 'NA') AS TypeOfBusiness,
    COALESCE(IFF(BU.BusinessUnitName= 'Undefined', NULL, BU.BusinessUnitName), UnknownBU.BusinessUnitName, 'NA') AS BusinessUnit,
    IFF(NVL(M.IsLuxury,0) = 0, 'No', 'Yes') AS IsLuxury,
    CURRENT_TIMESTAMP() AS DWHInsertDate,
    'GlobalE'::VARCHAR(16777216) AS MerchantSource,
    RM.ReplatformDate::timestamp as ReplatformDate,
    RM.IsReplatformed::boolean as IsReplatformed,
    MCC.MCC_Code,
	MCC.MCC_Category,
    M.SITEURL,
    MASC.IsBorderfreeMerchantFlag
FROM DATALAKE.globale_dbo.Merchants M
INNER JOIN DATALAKE.globale_dbo.Countries C ON M.CountryId = C.CountryId
INNER JOIN DATALAKE.globale_dbo.Currencies Curr ON Curr.CurrencyId = M.MerchantCurrencyId
INNER JOIN DATALAKE.globale_dbo.MerchantTypes MT ON MT.MerchantTypeId = M.MerchantTypeId 
LEFT JOIN DATALAKE.globale_dbo.MerchantTypes OMT ON OMT.MerchantTypeId = M.OriginalMerchantTypeId 
LEFT JOIN DATALAKE.globale_dbo.MerchantPlatforms API_P ON API_P.MerchantPlatformId = M.APIPlatformTypeId
LEFT JOIN DATALAKE.globale_dbo.MerchantPlatforms Browsing_P ON Browsing_P.MerchantPlatformId = M.BrowsingPlatformTypeId
LEFT JOIN DATALAKE.globale_dbo.Verticals V ON M.MerchantVerticalID = V.VerticalId
LEFT JOIN DATALAKE.globale_dbo.BusinessTypes BT ON M.MerchantBusinessTypeID = BT.BusinessTypeId
LEFT JOIN DATALAKE.globale_dbo.BusinessUnits BU ON M.BusinessUnitId = BU.BusinessUnitId
LEFT JOIN ANALYTICS.STG.STG_LKP_Merchants LKP ON LKP.MerchantId = M.MerchantId 
LEFT JOIN
(
    SELECT
        pgmsd.MerchantId ,
        MAX(mcc.MCC_Category) AS MCC_Category ,
        MAX(mcc.MCC_Code) AS MCC_Code
    FROM DATALAKE.globale_dbo.PaymentGatewayMerchantSoftDescriptors pgmsd 
    INNER JOIN DATALAKE.globale_dbo.MerchantCategoryCodes mcc 
    on pgmsd.MCC =mcc.MCC_Code
    WHERE pgmsd.PaymentGatewayId = 2 /*AdyenAPI*/
    GROUP BY MerchantId
) MCC 
ON MCC.MerchantId=M.MerchantId
LEFT JOIN LATERAL (
    SELECT 
        MIN_BY(MC.ChgDateCreated,ChgId) AS MerchantTypeIdChgDate
        FROM (
                select
                merchantid,
                MerchantTypeID,
                ChgId,
                ChgDateCreated,
                case
                    when OriginalMerchantTypeId is null then
                    case 
                        when ROW_NUMBER() OVER (PARTITION BY MerchantID ORDER BY ChgDateCreated asc)=1 then MerchantTypeID
                        else LAG(MerchantTypeID,1,0) OVER (PARTITION BY MerchantID ORDER BY ChgId, merchantid) end
                        else OriginalMerchantTypeId 
                    end as OriginalMerchantTypeId
                from DATALAKE.globale_changes.MerchantsChanges
                where MerchantTypeId is not null
                ) MC
        WHERE MC.MerchantTypeId <> MC.OriginalMerchantTypeId
        AND M.MerchantId = MC.MerchantId
        AND M.MerchantTypeId = MC.MerchantTypeId
        AND M.OriginalMerchantTypeId = MC.OriginalMerchantTypeId

) MC
LEFT JOIN(
    SELECT 
    CU.CountryId
    ,
        CASE 
            WHEN CU.IsEurope = 1 THEN 'EMEA'
            WHEN CU.CountryName IN ('United States','Canada') THEN 'North America'
            WHEN CU.CountryName = 'Japan' THEN 'Japan'
            WHEN CU.CountryName = 'Australia' THEN 'APAC'
            WHEN CU.CountryName = 'Israel' THEN 'Israel'
        END AS BusinessUnitName
    FROM DATALAKE.globale_dbo.Countries CU 
) UnknownBU ON UnknownBU.CountryId = C.CountryId
LEFT JOIN  (
    SELECT  
        DISTINCT 
            MAS.MerchantId,
            MIN(COALESCE(LKP.MerchantNameForQV, MR.MerchantName, MR.MerchantNameForReports)) AS ReplatformedMerchant,
            MIN(CAST(MASC.DATEUPDATED AS DATE)) AS ReplatformDate,
            1 AS IsReplatformed
    FROM DATALAKE.GLOBALE_DBO.MERCHANTAPPSETTINGS MAS 
    INNER JOIN DATALAKE.globale_changes.MerchantAppSettingsChanges MASC 
        ON MAS.MERCHANTID = MASC.MERCHANTID  and MASC.appsettingname = 'ReplatformedMerchant'
    LEFT JOIN ANALYTICS.STG.STG_LKP_Merchants LKP 
        ON LKP.MerchantId = CAST(MAS.AppSettingValue AS BIGINT)
    LEFT JOIN DATALAKE.globale_dbo.Merchants MR 
        ON MR.MerchantId = CAST(MAS.AppSettingValue AS BIGINT)
    WHERE 1=1
        AND MAS.AppSettingName = 'ReplatformedMerchant' 
        AND TRY_CAST(MAS.AppSettingValue AS BIGINT) IS NOT NULL
        AND TRY_CAST(MAS.MerchantId AS BIGINT) IS NOT NULL
    GROUP BY MAS.MerchantId
) RM on RM.MerchantId=M.MerchantId
LEFT JOIN  (
    select 
	MerchantId,
	max(CASE WHEN lower(AppSettingName) = 'showglobalemailagreement' AND lower(AppSettingValue) = 'true' THEN 1 ELSE 0 END) AS IsBorderfreeMerchantFlag
	FROM DATALAKE.globale_dbo.MerchantAppSettings
    where lower(AppSettingName) IN ('showglobalemailagreement', 'borderfreelogininCheckout')
    group by all
) MASC ON MASC.MerchantId = M.MerchantId
),
MerchantOrderDates AS(
SELECT 
    UPPER(M.Merchant) as Merchant,
    MIN(O.OrderDate)::date AS MerchantGoLiveDate,
    MAX(O.OrderDate)::date AS MerchantLastOrderDate
FROM ANALYTICS.STG.STG_Fact_Orders O 
INNER JOIN Merchants M ON O.MerchantId = M.MerchantId
WHERE O.IsApprovedOrder = 'Yes'
GROUP BY UPPER(M.Merchant)
),
COMM_GROUP AS
(
    SELECT IFNULL(DEALID, 0) AS DEALID, 
           MIN_BY(MERCHANTNAME, MERCHANTID) AS COM_GROUP
    FROM DATALAKE.GLOBALE_DBO.MERCHANTS
    GROUP BY ALL
)

SELECT 	distinct		
     M.MERCHANTID
    ,M.DEALID
    ,M.MERCHANT
    ,M.MERCHANTDBNAME
    ,M.MERCHANTNAME
    ,M.MERCHANTNAMEFORREPORTS
    ,M.CALENDARID
    ,M.ISACTIVE
    ,M.MERCHANTCURRENCYID
    ,M.MERCHANTCURRENCYCODE
    ,M.MERCHANTCOUNTRYID
    ,M.MERCHANTCOUNTRY
    ,M."Pro/Enterprise"
    ,null::timestamp as GOLIVEDATE
    ,null as ACCOUNTMANAGER
    ,M.VERTICAL
    ,M.TYPEOFBUSINESS
    ,M.DWHINSERTDATE
    ,M.APIPLATFORMTYPEID
    ,M.APIPLATFORMTYPE
    ,M.BROWSINGPLATFORMTYPEID
    ,M.BROWSINGPLATFORMTYPE
    ,M.Partner
    ,M."Original Merchant Type"
    ,M.MERCHANTTYPEIDCHGDATE
    ,M.MERCHANTSOURCE
    ,null as FLOWMERCHANTID
    ,M.MERCHANTNAMEFORQV
    ,M.SHOULDBEINQV
    ,M.BUSINESSUNIT
    ,M.ISLUXURY
    ,M.ISREPLATFORMED
    ,M.REPLATFORMDATE
    ,null::int as BFMERCHANTID
    ,M.MCC_Code::int as MCC_Code_AdyenAPI
	,M.MCC_Category as MCC_Category_AdyenAPI
    ,MD.MERCHANTGOLIVEDATE
    ,MD.MERCHANTLASTORDERDATE
    ,M.SITEURL
    ,ifnull(M.IsBorderfreeMerchantFlag,0) as  IsBorderfreeMerchantFlag
FROM Merchants M 
    LEFT JOIN MerchantOrderDates MD ON UPPER(M.Merchant) = UPPER(MD.Merchant)
    LEFT JOIN COMM_GROUP CG ON M.DEALID = CG.DEALID