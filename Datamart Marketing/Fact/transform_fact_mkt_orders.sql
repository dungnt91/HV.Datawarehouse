DECLARE FromDate DATE DEFAULT DATE '2025-10-01';

WITH Orders AS (
  SELECT *
  FROM hv-data.hvnet_products_dwh.od_orders o
  WHERE IsDeleted = FALSE
    AND NOT EXISTS (
      SELECT 1
      FROM hv-data.hvnet_products_dwh.Od_OrdersDeleted_od_orders_deleted d
      WHERE d.OrderId = o.Id
    )
),

Rates AS (
  SELECT
    o.Id,
    ex.exchange_rate AS rate
  FROM Orders o
  LEFT JOIN hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange ex
    ON ex.ProjectId = o.ProjectId
   AND ex.DateKey = CAST(FORMAT_DATE('%Y%m%d', DATE(o.CreatedOrder)) AS INT64)
),

StatusLogic AS (
  SELECT
    o.Id,
    CASE
      WHEN o.StatusValue = 4
       AND NULLIF(DATE(o.PaymentDate), DATE '1900-01-01') IS NOT NULL
       AND NULLIF(
            COALESCE(DATE(o.success_delivery_date), DATE(o.PaymentDate)),
            DATE '1900-01-01'
           ) IS NOT NULL
        THEN -8

      WHEN o.StatusValue = 4
       AND NULLIF(
            COALESCE(DATE(o.success_delivery_date), DATE(o.PaymentDate)),
            DATE '1900-01-01'
           ) IS NOT NULL
       AND NULLIF(DATE(o.PaymentDate), DATE '1900-01-01') IS NULL
        THEN -7

      WHEN o.StatusValue NOT IN (5,7)
        THEN o.StatusValue

      WHEN NULLIF(
            COALESCE(DATE(o.success_delivery_date), DATE(o.PaymentDate)),
            DATE '1900-01-01'
           ) IS NOT NULL
       AND o.CancelledStockinDate IS NOT NULL
        THEN -5

      ELSE -2
    END AS status
  FROM Orders o
),

ChannelMaster AS (
  SELECT
    DataValue AS ChannelId,
    DataText  AS Channel,
    DataType
  FROM hv-data.hvnet_products_dwh.Od_MasterData
  WHERE DataType IN ('OrdersSource', 'Ecommerce')
),

Ecommerce AS (
  SELECT o.Id, cm.Channel
  FROM Orders o
  LEFT JOIN ChannelMaster cm
    ON cm.DataType = 'Ecommerce'
   AND cm.Channel = o.EcommerceType
  WHERE o.OrderType = 2
),

OrdersSource AS (
  SELECT o.Id, cm.Channel
  FROM Orders o
  LEFT JOIN ChannelMaster cm
    ON cm.DataType = 'OrdersSource'
   AND cm.ChannelId = o.SourceId
  WHERE o.OrderType <> 2
),

ChannelFinal AS (
  SELECT * FROM Ecommerce
  UNION ALL
  SELECT * FROM OrdersSource
),

BaseData AS (
  SELECT
    ctry.CountryCode AS thitruong,
    bu.name AS bu_phongban,
    t.Management_Employee AS Agent,

    CASE
      WHEN o.OrderType = 2 THEN
        CASE WHEN cf.Channel = 'TikTok Shop' THEN cf.Channel ELSE 'TMĐT' END
      ELSE cf.Channel
    END AS Channel,

    CASE WHEN o.OrderType = 2 THEN 'Sàn TMĐT' ELSE 'Kênh bán hàng khác' END AS OrderTypeLabel,

    s.status,
    FORMAT_DATE('%Y-%m', DATE(o.CreatedOrder)) AS thang,

    CAST(SUM(
      CASE
        WHEN ctry.CountryCode = 'VN'
          THEN o.Amount * r.rate / 1.08
        ELSE o.Amount * r.rate
      END
    ) AS INT64) AS Amount,

    CAST(SUM(o.ReturnDiscount * r.rate) AS INT64) AS ReturnDiscount,
    CAST(SUM(o.TotalCost * r.rate) AS INT64) AS cogs,
    COUNT(o.OrderCode) AS Order_number,
    CAST(SUM(o.PlatformFeeTotal * r.rate) AS INT64) AS PlatformFeeTotal,

    CAST(SUM(
      (o.ShippingFee + o.ShippingCodFee + o.ShippingCodFeeVAT) * r.rate
    ) AS INT64) AS TotalShippingFee,

    CAST(SUM(o.ShippingFeeReturn * r.rate) AS INT64) AS ShippingFeeReturn,
    CAST(SUM(o.TotalQuantity) AS INT64) AS Quantity,
    CAST(SUM(o.TotalGiftQuantity) AS INT64) AS GiftQuantity

  FROM Orders o
  LEFT JOIN Rates r         ON o.Id = r.Id
  LEFT JOIN StatusLogic s   ON o.Id = s.Id
  LEFT JOIN ChannelFinal cf ON o.Id = cf.Id
  LEFT JOIN hv-data.hvnet_products_dwh.us_countries ctry ON ctry.CountryId = o.CountryId
  LEFT JOIN hv-data.hvnet_products_dwh.us_bussiness_units bu ON bu.Id = o.BuId
  LEFT JOIN hv-data.hvnet_products_dwh.us_projects_teams t ON t.Id = o.TeamId

  WHERE o.BuId IN (4,5,7,10,11,12,13,29,30,32,36,37)
    AND DATE(o.CreatedOrder) >= FromDate

  GROUP BY
    thitruong, bu_phongban, Agent, Channel,
    OrderTypeLabel, s.status, thang
)

SELECT * FROM BaseData