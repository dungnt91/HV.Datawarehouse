DECLARE FromDate DATE DEFAULT DATE '2025-10-01';

WITH Orders AS (
  SELECT
      Id,
      CreatedOrder,
      success_delivery_date,
      PaymentDate,
      CancelledStockinDate,
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

    CAST(SUM(o.TotalCost * r.rate) AS INT64) AS Cost,
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
  WHERE d.CreatedOrder >= FromDate
    AND o.BuId IN (4,5,7,10,11,12,13,29,30,32,36,37)
  GROUP BY thitruong, bu_phongban, o.OrderType, OrderTypeLabel, status, thang
)

SELECT
  thitruong,
  bu_phongban,
  OrderTypeLabel,
  status,
  thang,
  Metric,
  Value AS amount,

  -- ================= CHI TIẾT =================
  CASE
    WHEN Metric = 'Amount' THEN OrderTypeLabel
    WHEN Metric = 'ReturnDiscount' THEN 'Hoàn từ sàn/đơn vị vận chuyển'

    WHEN Metric = 'Cost'
     AND status IN ('Mới', 'Đang gói hàng', 'Đang giao hàng', 'Giao thành công')
    THEN OrderTypeLabel

    WHEN Metric = 'Cost' AND status IN ('Hoàn', 'Hủy')
    THEN 'Giá vốn'

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

  -- ================= NHÓM =================
  CASE
    WHEN Metric = 'Amount' AND status = 'Hoàn' THEN 'Đơn hàng hoàn'
    WHEN Metric = 'Amount' AND status = 'Hủy' THEN 'Đơn hàng huỷ'
    WHEN Metric = 'Amount' THEN OrderTypeLabel

    WHEN Metric = 'Cost'
     AND status IN ('Mới', 'Đang gói hàng', 'Đang giao hàng', 'Giao thành công')
    THEN OrderTypeLabel

    WHEN Metric = 'Cost' AND status IN ('Hoàn', 'Hủy')
    THEN 'Chi phí huỷ hàng/hết hạn'

    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee')
    THEN 'Phí sàn & marketing sàn'

    WHEN Metric IN ('TotalShippingFee','ShippingFeeReturn')
    THEN 'Chi phí Logistics đến KH'

    WHEN Metric = 'ReturnDiscount'
    THEN 'Hoàn từ sàn/đơn vị vận chuyển'
  END AS nhom,

  -- ================= DANH MỤC =================
  CASE
    WHEN Metric = 'Amount' AND status = 'Giao thành công' THEN 'Doanh thu từ BH trực tiếp'
    WHEN Metric = 'Amount' AND status IN ('Mới','Đang gói hàng','Đang giao hàng') THEN 'Doanh số đang xử lý'
    WHEN Metric = 'Amount' AND status IN ('Hoàn','Hủy') THEN 'Các khoản giảm trừ'
    WHEN Metric = 'ReturnDiscount' THEN 'THU NHẬP KHÁC'
    WHEN Metric = 'Cost' AND status IN ('Hoàn','Hủy') THEN 'PHÍ DỰ PHÒNG DN'
    WHEN Metric = 'Cost' THEN 'GIÁ VỐN HÀNG BÁN'
    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee',
                    'TotalShippingFee','ShippingFeeReturn')
         AND status IN ('Hoàn','Hủy')
    THEN 'PHÍ DỰ PHÒNG DN'
    ELSE 'CP BÁN HÀNG'
  END AS danhmuc,

  -- ================= MỤC =================
  CASE WHEN Metric IN ('Amount','ReturnDiscount') THEN 'Doanh số' ELSE 'Chi phí' END AS muc

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
ORDER BY thitruong, bu_phongban, thang, Metric;