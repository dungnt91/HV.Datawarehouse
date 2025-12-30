WITH Params AS (
  SELECT DATE '2025-10-01' AS FromDate
),

Orders AS (
  SELECT
      Id,
      CreatedOrder,
      success_delivery_date,
      PaymentDate,
      CancelledStockinDate,
      ReturnDateKey,
      CountryId,
      BuId,
      ProjectId,
      StatusValue,
      OrderType,
      Amount,
      TotalCost,
      ReturnDiscount,
      PlatformServiceFee,
      PlatformTransactionFee,
      PlatformFee,
      PlatformAffiliateCommissionFee,
      PlatformShippingFee,
      PlatformTaxFee,
      PlatformOtherFee,
      ShippingFee,
      ShippingFeeReturn,
      ShippingCodFee,
      ShippingCodFeeVAT
  FROM `hv-data.hvnet_products_dwh.od_orders` o
  WHERE IsDeleted = FALSE
    AND NOT EXISTS (
      SELECT 1
      FROM `hv-data.hvnet_products_dwh.Od_OrdersDeleted_od_orders_deleted` d
      WHERE d.OrderId = o.Id
    )
),

Dates AS (
  SELECT
    o.Id,
    NULLIF(DATE(o.CreatedOrder), DATE '1900-01-01') AS CreatedOrder,
    CASE
      WHEN NULLIF(DATE(o.success_delivery_date), DATE '1900-01-01') IS NULL
       AND NULLIF(DATE(o.PaymentDate),        DATE '1900-01-01') IS NOT NULL
      THEN NULLIF(DATE(o.PaymentDate),        DATE '1900-01-01')
      ELSE NULLIF(DATE(o.success_delivery_date), DATE '1900-01-01')
    END AS success_delivery_date
  FROM Orders o
),

Rates AS (
  SELECT
    o.Id,
    COALESCE(ex.exchange_rate, 1) AS rate
  FROM Orders o
  JOIN Dates d ON d.Id = o.Id
  LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` ex
    ON ex.ProjectId = o.ProjectId
   AND CAST(ex.DateKey AS STRING) = FORMAT_DATE('%Y%m%d', d.CreatedOrder)
),

StatusLogic AS (
  SELECT
    o.Id,
    o.StatusValue,
    CASE
      WHEN CAST(o.StatusValue AS STRING) NOT IN ('5','7') THEN ''
      ELSE
        CASE
          WHEN d.success_delivery_date IS NOT NULL AND o.CancelledStockinDate IS NOT NULL THEN 'Hoàn'
          ELSE 'Hủy'
        END
    END AS order_status,
    CASE CAST(o.StatusValue AS STRING)
      WHEN '1' THEN 'Mới'
      WHEN '2' THEN 'Đang gói hàng'
      WHEN '3' THEN 'Đang giao hàng'
      WHEN '4' THEN 'Giao thành công'
      WHEN '5' THEN 'Hủy chưa trả hàng'
      WHEN '7' THEN 'Hủy đã trả hàng'
      ELSE 'Không xác định'
    END AS StatusValueText
  FROM Orders o
  JOIN Dates d ON o.Id = d.Id
),

/* =========================
   1) BaseData: số liệu theo CreatedOrder
      - Cost CHỈ cho status 1,2,3,4
      - KHÔNG join LostParcel ở đây
   ========================= */
BaseData AS (
  SELECT
    c.CountryCode AS thitruong,
    bu.name AS bu_phongban,
    o.OrderType,
    IF(o.OrderType = 2, 'Sàn TMĐT', 'Kênh bán hàng khác') AS OrderTypeLabel,

    CASE
      WHEN s.order_status IN ('Hủy', 'Hoàn') THEN s.order_status
      ELSE s.StatusValueText
    END AS status,

    FORMAT_DATE('%Y-%m', d.CreatedOrder) AS thang,

    CAST(
      IF(c.CountryCode = 'VN',
         SUM(o.Amount * r.rate) / 1.08,
         SUM(o.Amount * r.rate)
      ) AS INT64
    ) AS Amount,

    -- ✅ Cost chỉ dành cho đơn 1,2,3,4 (giá vốn hàng bán)
    CAST(
      CASE
        WHEN CAST(o.StatusValue AS STRING) IN ('1','2','3','4')
        THEN SUM(o.TotalCost * r.rate)
        ELSE NULL
      END AS INT64
    ) AS Cost,

    CAST(SUM(o.ReturnDiscount * r.rate) AS INT64) AS ReturnDiscount,
    CAST(SUM(o.PlatformServiceFee * r.rate) AS INT64) AS PlatformServiceFee,
    CAST(SUM(o.PlatformTransactionFee * r.rate) AS INT64) AS PlatformTransactionFee,
    CAST(SUM(o.PlatformFee * r.rate) AS INT64) AS PlatformFee,
    CAST(SUM(o.PlatformAffiliateCommissionFee * r.rate) AS INT64) AS PlatformAffiliateCommissionFee,
    CAST(SUM(o.PlatformShippingFee * r.rate) AS INT64) AS PlatformShippingFee,
    CAST(SUM(o.PlatformTaxFee * r.rate) AS INT64) AS PlatformTaxFee,
    CAST(SUM(o.PlatformOtherFee * r.rate) AS INT64) AS PlatformOtherFee,
    CAST(SUM((o.ShippingFee + o.ShippingCodFee + o.ShippingCodFeeVAT) * r.rate) AS INT64) AS TotalShippingFee,
    CAST(SUM(o.ShippingFeeReturn * r.rate) AS INT64) AS ShippingFeeReturn
  FROM Orders o
  JOIN Dates d ON o.Id = d.Id
  JOIN Rates r ON o.Id = r.Id
  JOIN StatusLogic s ON o.Id = s.Id
  JOIN `hv-data.hvnet_products_dwh.us_countries` c ON c.CountryId = o.CountryId
  JOIN `hv-data.hvnet_products_dwh.us_bussiness_units` bu ON bu.Id = o.BuId
  WHERE d.CreatedOrder >= (SELECT FromDate FROM Params)
    AND o.BuId IN (4,5,7,10,11,12,13,29,30,32,36,37)
  GROUP BY thitruong, bu_phongban, o.OrderType, OrderTypeLabel, status, thang, o.StatusValue
),

/* =========================
   2) LostParcel: nguồn riêng
      - CHỈ StatusValue = 7
      - tháng theo ReturnDateKey (chuẩn)
   ========================= */
LostParcelAgg AS (
  SELECT
    ctr.CountryCode AS thitruong,
    bu.name         AS bu_phongban,
    ord.OrderType,
    IF(ord.OrderType = 2, 'Sàn TMĐT', 'Kênh bán hàng khác') AS OrderTypeLabel,

    -- ✅ LostParcel là tiền huỷ hàng/hết hạn -> bạn muốn gom vào dự phòng DN
    'Hủy' AS status,

    FORMAT_DATE('%Y-%m', SAFE.PARSE_DATE('%Y%m%d', CAST(ord.ReturnDateKey AS STRING))) AS thang,

    CAST(SUM(ord.TotalCost * COALESCE(ce.exchange_rate, 1)) AS INT64) AS LostParcelCost,
    CAST(COUNT(DISTINCT ord.Id) AS INT64) AS LostParcelOrders
  FROM Orders ord
  JOIN Params p ON TRUE
  LEFT JOIN `hv-data.hvnet_products_dwh.us_bussiness_units` bu
    ON bu.Id = ord.BuId
  LEFT JOIN `hv-data.hvnet_products_dwh.us_countries` ctr
    ON ctr.CountryId = ord.CountryId
  LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` ce
    ON ce.ProjectId = ord.ProjectId
   AND ce.DateKey   = ord.ReturnDateKey
  WHERE SAFE.PARSE_DATE('%Y%m%d', CAST(ord.ReturnDateKey AS STRING)) >= p.FromDate
    AND CAST(ord.StatusValue AS STRING) = '7'
    AND ord.BuId IN (4,5,7,10,11,12,13,29,30,32,36,37,14,23,26)
    AND EXISTS (
      SELECT 1
      FROM `hv-data.hvnet_products_dwh.wh_warehouses_stocks` w
      WHERE w.ProjectId     = ord.ProjectId
        AND w.InventoryId   = ord.Id
        AND w.InventoryType = 'LostParcel'
    )
  GROUP BY thitruong, bu_phongban, ord.OrderType, OrderTypeLabel, status, thang
),

/* =========================
   3) Unpivot 2 nguồn rồi UNION ALL
   ========================= */
AllMetrics AS (
  SELECT
    thitruong, bu_phongban, OrderTypeLabel, status, thang,
    Metric, Value
  FROM BaseData
  UNPIVOT (
    Value FOR Metric IN (
      Amount,
      Cost,
      ReturnDiscount,
      PlatformServiceFee,
      PlatformTransactionFee,
      PlatformFee,
      PlatformAffiliateCommissionFee,
      PlatformShippingFee,
      PlatformTaxFee,
      PlatformOtherFee,
      TotalShippingFee,
      ShippingFeeReturn
    )
  )

  UNION ALL

  SELECT
    thitruong, bu_phongban, OrderTypeLabel, status, thang,
    Metric, Value
  FROM LostParcelAgg
  UNPIVOT (
    Value FOR Metric IN (LostParcelCost, LostParcelOrders)
  )
)

SELECT
  thitruong,
  bu_phongban,
  OrderTypeLabel,
  status,
  thang,
  Metric,
  Value AS amount,

  -- ============== CHI TIẾT ==============
  CASE
    WHEN Metric = 'Amount' THEN OrderTypeLabel
    WHEN Metric = 'ReturnDiscount' THEN 'Hoàn từ sàn/đơn vị vận chuyển'

    WHEN Metric = 'Cost' THEN 'Giá vốn'

    WHEN Metric = 'LostParcelCost' THEN 'Tiền huỷ hàng/hết hạn'

    WHEN Metric = 'PlatformServiceFee' THEN 'Phí dịch vụ'
    WHEN Metric = 'PlatformTransactionFee' THEN 'Phí thanh toán'
    WHEN Metric = 'PlatformFee' THEN 'Phí quản lý sàn'
    WHEN Metric = 'PlatformAffiliateCommissionFee' THEN 'Affiliate/Hoa hồng giới thiệu'
    WHEN Metric = 'PlatformShippingFee' THEN 'Phí vận chuyển của sàn'
    WHEN Metric = 'PlatformTaxFee' THEN 'Phí thuế sàn'
    WHEN Metric = 'PlatformOtherFee' THEN 'Phí sàn & marketing sàn khác'
    WHEN Metric = 'TotalShippingFee' THEN 'Phí vận chuyển đến khách'
    WHEN Metric = 'ShippingFeeReturn' THEN 'Chi phí hoàn hàng'
  END AS chitiet,

  -- ============== NHÓM ==============
  CASE
    WHEN Metric = 'Amount' AND status = 'Hoàn' THEN 'Đơn hàng hoàn'
    WHEN Metric = 'Amount' AND status = 'Hủy' THEN 'Đơn hàng huỷ'
    WHEN Metric = 'Amount' THEN OrderTypeLabel

    WHEN Metric = 'Cost' THEN OrderTypeLabel

    WHEN Metric IN ('LostParcelCost') THEN 'Chi phí huỷ hàng/hết hạn'

    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee')
    THEN 'Phí sàn & marketing sàn'

    WHEN Metric IN ('TotalShippingFee','ShippingFeeReturn')
    THEN 'Chi phí Logistics đến KH'

    WHEN Metric = 'ReturnDiscount'
    THEN 'Hoàn từ sàn/đơn vị vận chuyển'
  END AS nhom,

  -- ============== DANH MỤC ==============
  CASE
    WHEN Metric = 'Amount' AND status = 'Giao thành công' THEN 'Doanh thu từ BH trực tiếp'
    WHEN Metric = 'Amount' AND status IN ('Mới','Đang gói hàng','Đang giao hàng') THEN 'Doanh số đang xử lý'
    WHEN Metric = 'Amount' AND status IN ('Hoàn','Hủy') THEN 'Các khoản giảm trừ'
    WHEN Metric = 'ReturnDiscount' THEN 'THU NHẬP KHÁC'

    WHEN Metric = 'LostParcelCost' THEN 'PHÍ DỰ PHÒNG DN'

    WHEN Metric = 'Cost' THEN 'GIÁ VỐN HÀNG BÁN'

    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee',
                    'TotalShippingFee','ShippingFeeReturn')
         AND status IN ('Hoàn','Hủy')
    THEN 'PHÍ DỰ PHÒNG DN'
    ELSE 'CP BÁN HÀNG'
  END AS danhmuc,

  -- ============== MỤC ==============
  CASE
    WHEN Metric IN ('Amount','ReturnDiscount') THEN 'Doanh số'
    ELSE 'Chi phí'
  END AS muc

FROM AllMetrics
ORDER BY thitruong, bu_phongban, thang, Metric;
