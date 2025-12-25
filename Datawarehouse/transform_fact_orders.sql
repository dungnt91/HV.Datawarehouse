SELECT 
        ord_order.CreatedData AS CreatedData,
        ord_order.CustomerId AS CustomerKey,
        
        -- OrderSourceKey: Xác định nguồn đơn hàng
        CASE 
            WHEN ord_order.DeliveryPartnerId = 0 THEN 'STORE'
            WHEN ord_order.SourceId = 8 THEN 'HOTLINE'
            WHEN ord_order.SourceId = 1 THEN 'TIKTOK-ADS'
            WHEN ord_order.SourceId = 2 THEN 'GG-ADS'
            WHEN ord_order.SourceId = 3 THEN 'FB-ADS'
            WHEN ord_order.SourceId = 5 THEN 'ZALO-ADS'
            ELSE 'UNKNOWN'
        END AS OrderSourceKey,
 
      -- Phân biệt OrderType
       CASE 
              WHEN ord_order.OrderType = 2 THEN 'MARKETPLACE'
       ELSE 'NON-MARKETPLACE' END AS OrderType,
        
        -- MarketplaceKey: Xác định sàn TMĐT
        CASE
            WHEN ord_order.DeliveryPartnerId = 7 THEN
                CASE UPPER(TRIM(ord_order.EcommerceType))
                    WHEN 'TIKTOK SHOP'  THEN 'TIKTOK-SHOP'
                    WHEN 'SHOPEE'       THEN 'SHOPEE'
                    WHEN 'AMAZON'       THEN 'AMAZON'
                    WHEN 'LAZADA'       THEN 'LAZADA'
                    WHEN 'TIKI'         THEN 'TIKI'
                    WHEN 'SENDO'        THEN 'SENDO'
                    WHEN 'WALMART'      THEN 'WALMART'
                    ELSE 'UNKNOWN'
                END
            ELSE 'UNKNOWN'
        END AS MarketplaceKey,
        
        ord_order.DeliveryPartnerId AS ShippingProviderKey,
        ord_order.PaymentMethod AS PaymentMethodKey,
        status.StatusKey AS OrderStatusKey,
        
        ord_order.CountryId AS CountryKey,
        ord_order.BuId AS BusinessUnitKey,
        ord_order.ProjectId AS ProjectKey,
        ord_order.TeamId AS TeamKey,
        CONCAT('WH_', CAST(ord_order.ProjectId AS STRING), '_', CAST(ord_order.WarehouseId AS STRING)) AS WarehouseKey,
        
        -- ==========================================
        -- DEGENERATE DIMENSIONS
        -- ==========================================
        ord_order.Id AS OrderId,
        ord_order.OrderCode AS OrderCode,
        ord_order.EcommerceOrderId AS MarketplaceOrderId,
        ord_pre_order.SalepageId AS FormId,
        ord_order.PreOrderId AS LeadId,
        
        -- ==========================================
        -- EMPLOYEE DIMENSIONS
        -- ==========================================
        team.Management_Employee AS MarketerEmployeeId,
        ord_order.CreatedBy AS SaleEmployeeId,
        ord_order.PackingBy AS PackedByEmployeeId,
        ord_order.Takecare_User AS DeliveryIssueHandledByEmployeeId,
        
        -- ==========================================
        -- ORDER METRICS - QUANTITY
        -- ==========================================
        ord_order.TotalProductType AS TotalItemCount,
        ord_order.TotalQuantity AS TotalQuantity,
        (ord_order.TotalProductType - COALESCE(ord_order.TotalProductGiftType, 0)) AS TotalItemCountExcludeGift,
        (ord_order.TotalQuantity - COALESCE(ord_order.TotalGiftQuantity, 0)) AS TotalQuantityExcludeGift,
        ord_order.TotalProductGiftType AS TotalGiftItemCount,
        ord_order.TotalGiftQuantity AS TotalGiftQuantity,
        SAFE_DIVIDE(ord_order.NetWeight, 1000) AS TotalItemWeight,
        
        -- ==========================================
        -- ORDER METRICS - REVENUE
        -- ==========================================
        ord_order.TotalPrice AS GrossAmount,
        ord_order.Discount AS DiscountAmount,
        ord_order.ShipByCustomer AS CustomerShippingFee,
        ord_order.Amount AS NetAmount,
        
        -- VAT Measures
        ord_order.AmountBeforeVAT AS AmountBeforeVAT,
        country.vat_rate AS VATRate,
        ord_order.VATAmount AS VATAmount,
        
        -- ==========================================
        -- ORDER METRICS - COST
        -- ==========================================
        -- COGS
        ord_order.ProductCost AS ProductCost,
        ord_order.GiftCost AS GiftCost,
        ord_order.TotalCost AS TotalCOGS,
        
        -- Platform Fees
        ord_order.PlatformServiceFee AS PlatformServiceFee,
        ord_order.PlatformTransactionFee AS PlatformTransactionFee,
        ord_order.PlatformFee AS PlatformCommissionFee,
        ord_order.PlatformAffiliateCommissionFee AS PlatformAffiliateFee,
        ord_order.PlatformShippingFee AS PlatformShippingSubsidy,
        ord_order.PlatformTaxFee AS PlatformTaxFee,
        ord_order.PlatformOtherFee AS PlatformMarketingFee,
        ord_order.PlatformShippingFeeReturn AS PlatformReturnHandlingFee,
        ord_order.PlatformFeeTotal AS TotalPlatformFees,
        
        -- Shipping Costs
        ord_order.ShippingFee AS ShippingBaseFee,
        ord_order.ShippingCodFee AS ShippingCODFee,
        ord_order.ShippingCodFeeVAT AS ShippingCODFeeVAT,
        ord_order.ShippingFeeReturn AS ShippingReturnFee,
        ord_order.ShippingFeeTotal AS TotalShippingCost,
        
        -- Total Operating Cost
        (COALESCE(ord_order.TotalCost, 0) + 
         COALESCE(ord_order.PlatformFeeTotal, 0) + 
         COALESCE(ord_order.ShippingFeeTotal, 0)) AS TotalOperatingCost,
        
        -- ==========================================
        -- ORDER METRICS - PROFITABILITY
        -- ==========================================
        (ord_order.Amount - COALESCE(ord_order.TotalCost, 0)) AS GrossProfit,
        (ord_order.Amount - COALESCE(ord_order.TotalCost, 0) - 
         COALESCE(ord_order.PlatformFeeTotal, 0) - 
         COALESCE(ord_order.ShippingFeeTotal, 0)) AS NetProfit,
        SAFE_DIVIDE(
            (ord_order.Amount - COALESCE(ord_order.TotalCost, 0) - 
             COALESCE(ord_order.PlatformFeeTotal, 0) - 
             COALESCE(ord_order.ShippingFeeTotal, 0)),
            NULLIF(ord_order.Amount, 0)
        ) * 100 AS ProfitMargin,
        
        -- ==========================================
        -- ORDER METRICS - FULFILLMENT
        -- ==========================================
        DATE_DIFF(DATE(ord_order.OnDeliveryDate), DATE(ord_order.CreatedAt), DAY) AS OrderProcessingDays,
        DATE_DIFF(DATE(ord_order.success_delivery_date), DATE(ord_order.OnDeliveryDate), DAY) AS ShippingDays,
        DATE_DIFF(DATE(ord_order.success_delivery_date), DATE(ord_order.CreatedAt), DAY) AS TotalFulfillmentDays,
        
        -- ==========================================
        -- FLAGS & INDICATORS
        -- ==========================================
        CASE WHEN ord_order.CustomerOrderCount > 0 THEN TRUE ELSE FALSE END AS IsRepeatCustomer,
        ord_order.isPayment AS IsPaymentCompleted,
        CASE WHEN ord_order.PaymentMethod = 1 THEN TRUE ELSE FALSE END AS IsCODPayment,
        CASE WHEN ord_order.ReturnDateKey IS NOT NULL THEN TRUE ELSE FALSE END AS IsReturnOrder,
        CASE  WHEN ord_order.EcommerceOrderId IS NOT NULL  AND TRIM(ord_order.EcommerceOrderId) <> '' THEN TRUE  ELSE FALSE  END AS IsMarketplace,

        ord_order.IsDeleted AS IsDeleted,
        
        -- Customer Demographics
        ord_order.Gender AS CustomerGender,
        COALESCE(regVN.provName, regOS.provName)  AS CustomerProvince,
        
        -- ==========================================
        -- MARKETING & TRACKING
        -- ==========================================
        ord_pre_order.AdsSource AS TrafficSource,
        ord_pre_order.AdsMedium AS TrafficMedium,
        ord_pre_order.AdsCampaign AS CampaignId,
        ord_pre_order.AdsContent AS AdContent,
        ord_pre_order.AdsTerm AS Keyword,
        ord_pre_order.AdsFullParams AS TrackingParams,

        -- ==========================================
        -- FOREIGN KEYS TO DIMENSIONS
        -- ==========================================
        ord_order.CreatedDataKey AS OrderDateKey,
        ord_order.CreatedOrderKey AS OrderCreatedDateKey,
        CAST(FORMAT_DATE('%Y%m%d', DATE(ord_order.OnDeliveryDate)) AS INT64) AS ShipmentDateKey,
        ord_order.SuccessDeliveryDateKey AS CompletedDateKey,
        ord_order.PaymentDateKey AS PaymentDateKey,
        ord_order.ReturnDateKey AS ReturnDateKey,
        
        -- ==========================================
        -- AUDIT METADATA
        -- ==========================================
        ord_order.CreatedBy AS CreatedBy,
        ord_order.CreatedAt AS CreatedAt
        
    FROM `hvnet_products_dwh.od_orders` ord_order
    LEFT JOIN `hvnet_products_dwh.Pd_Products_od_pre_orders` ord_pre_order 
        ON ord_order.PreOrderId = ord_pre_order.Id
    LEFT JOIN `hvnet_products_dwh.us_projects` project 
        ON ord_order.ProjectId = project.Id
    LEFT JOIN `hvnet_products_dwh.us_projects_teams` team 
        ON ord_order.TeamId = team.Id
    LEFT JOIN `hvnet_products_dwh.us_countries` country 
        ON country.CountryId = ord_order.CountryId
    LEFT JOIN `hvnet_products_staging.us_bussiness_units` bussiness_unit 
        ON bussiness_unit.Id = ord_order.BuId
    LEFT JOIN `hv-data.hv_warehouse.dim_status` status 
        ON COALESCE(ord_order.StatusValue, -1) = status.StatusValue 
        AND status.Domain = 'ORDER'

    LEFT JOIN `hvnet_products_dwh.JT_Regions_jt_regions` regVN ON ord_order.CountryId = 9	AND ord_order.DistrictId = regVN.areaId
    LEFT JOIN `hvnet_products_dwh.JT_Regions_jt_regions` regOS ON ord_order.CountryId <> 9	AND ord_order.DistrictId = regOS.Id
    
    WHERE ord_order.CreatedDataKey >= 20250101
        AND NOT EXISTS (
            SELECT 1 
            FROM `hvnet_products_dwh.Od_OrdersDeleted_od_orders_deleted` AS del 
            WHERE del.OrderId = ord_order.Id
        )
        AND ord_order.IsDeleted = FALSE
        AND ord_pre_order.ProjectId NOT IN (4)

