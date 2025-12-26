SELECT 
        ord_order.CreatedData AS CreatedData,
        ord_order.CustomerId AS CustomerKey,

      -- Phân biệt OrderType
       CASE 
            WHEN ord_order.OrderType = 2 THEN 'MARKETPLACE'
            ELSE 'NON-MARKETPLACE' 
       END AS OrderType,
        
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
        
        -- ==========================================
        -- EMPLOYEE DIMENSIONS
        -- ==========================================
        team.Management_Employee AS MarketerEmployeeId,
        ord_order.CreatedBy AS SaleEmployeeId,

        -- ==========================================
        -- PRODUCT DIMENSIONS
        -- ==========================================
        ord_order_line.ProductId        AS ProductKey,
        ord_order_line.ProductName      AS ProductName,
        ord_order_line.IsProductGift    AS IsProductGift,

        -- ==========================================
        -- CURRENCY & EXCHANGE RATE
        -- ==========================================
        cur_exc.exchange_rate AS ExchangeRate,

        -- ==========================================
        -- ORDER LINE METRICS - QUANTITY
        -- ==========================================
        
        ord_order_line.UnitCost,
        ord_order_line.ProductCost,
        ord_order_line.GiftCost,
        ord_order_line.TotalCost,
        ord_order_line.UnitPrice,
        ord_order_line.TotalPrice,
        ord_order_line.ItemRatio,
        ord_order_line.ShipByCustomer,
        ord_order_line.DiscountAmount,
        ord_order_line.Amount,
        ord_order_line.PromotionCost,
        ord_order_line.ShippingFee,
        ord_order_line.ShippingCodFee,
        ord_order_line.ShippingCodFeeVAT,
        ord_order_line.ShippingFeeReturn,
        ord_order_line.ReturnDiscount,
        ord_order_line.ShippingFeeTotal,
        ord_order_line.CodDifference,
        ord_order_line.PlatformShippingFee,
        ord_order_line.PlatformShippingFeeReturn,
        ord_order_line.PlatformFee,
        ord_order_line.PlatformTaxFee,
        ord_order_line.PlatformFeeTotal,
        ord_order_line.GrossProfit,
        

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
    LEFT JOIN `hvnet_products_dwh.od_orders_items` ord_order_line 
        ON ord_order.Id = ord_order_line.OrderId
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

    LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` cur_exc 
        ON ord_order.CountryId = cur_exc.CountryId AND ord_order.ProjectId = cur_exc.ProjectId AND cur_exc.DateKey = ord_order.CreatedOrderKey
    
    WHERE ord_order.CreatedDataKey >= 20250101
        AND NOT EXISTS (
            SELECT 1 
            FROM `hvnet_products_dwh.Od_OrdersDeleted_od_orders_deleted` AS del 
            WHERE del.OrderId = ord_order.Id
        )
        AND ord_order.IsDeleted = FALSE
        AND ord_pre_order.ProjectId NOT IN (4)

