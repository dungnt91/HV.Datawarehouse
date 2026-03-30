WITH Params AS (
  SELECT DATE '2025-10-01' AS FromDate
),

Orders AS (
  SELECT
      order_id,
      created_order,
      delivery_success_date,
      payment_confirmed_date,
      stock_in_void_date,
      return_processed_date,
      country_id,
      bu_id,
      project_id,
      status_id,
      order_type,
      net_amount,
      total_cogs,
      other_income_refund,
      marketplace_return_fee,
      marketplace_service_fee,
      marketplace_transaction_fee,
      marketplace_admin_fee,
      marketplace_affiliate_fee,
      marketplace_shipping_fee,
      marketplace_tax_fee,
      marketplace_other_fee,
      shipment_shipping_fee,
      shipment_return_fee,
      shipment_cod_fee,
      shipment_cod_vat_amount,
      external_marketing_other_fee
  FROM `hv-data.a_dwh.FactOrder` o
),

Dates AS (
  SELECT
    o.order_id,
    NULLIF(DATE(o.created_order), DATE '1900-01-01') AS CreatedOrder,
    CASE
      WHEN NULLIF(DATE(o.delivery_success_date), DATE '1900-01-01') IS NULL
       AND NULLIF(DATE(o.payment_confirmed_date),        DATE '1900-01-01') IS NOT NULL
      THEN NULLIF(DATE(o.payment_confirmed_date),        DATE '1900-01-01')
      ELSE NULLIF(DATE(o.delivery_success_date), DATE '1900-01-01')
    END AS success_delivery_date
  FROM Orders o
),

Rates AS (
   SELECT
    o.order_id,
    COALESCE(ex.base_fx_rate, 1) AS rate
  FROM Orders o
  JOIN Dates d ON d.order_id = o.order_id
  LEFT JOIN `hv-data.a_dwh.DimExchangeRate`  ex
    ON ex.project_id = o.project_id
   AND CAST(ex.exchange_key AS STRING) = FORMAT_DATE('%Y%m%d', d.CreatedOrder)
),

StatusLogic AS (
  SELECT
    o.order_id,
    o.status_id,
    CASE
      WHEN CAST(o.status_id AS STRING) NOT IN ('5','7') THEN ''
      ELSE
        CASE
          WHEN d.success_delivery_date IS NOT NULL AND o.stock_in_void_date IS NOT NULL THEN 'Hoàn'
          ELSE 'Hủy'
        END
    END AS order_status,
    CASE CAST(o.status_id AS STRING)
      WHEN '1' THEN 'Mới'
      WHEN '2' THEN 'Đang gói hàng'
      WHEN '3' THEN 'Đang giao hàng'
      WHEN '4' THEN 'Giao thành công'
      WHEN '5' THEN 'Hủy chưa trả hàng'
      WHEN '7' THEN 'Hủy đã trả hàng'
      ELSE 'Không xác định'
    END AS StatusValueText
  FROM Orders o
  JOIN Dates d ON o.order_id = d.order_id
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
    o.order_type,
    IF(o.order_type = 2, 'Sàn TMĐT', 'Kênh bán hàng khác') AS OrderTypeLabel,

    CASE
      WHEN s.order_status IN ('Hủy', 'Hoàn') THEN s.order_status
      ELSE s.StatusValueText
    END AS status,

    FORMAT_DATE('%Y-%m', d.CreatedOrder) AS thang,
    d.CreatedOrder AS ngay,

    COUNT(o.order_id) AS CountOrders,

    CAST(
      IF(c.CountryCode = 'VN',
         SUM(o.net_amount * r.rate) / 1.08,
         SUM(o.net_amount * r.rate)
      ) AS INT64
    ) AS GrossAmount,

    CAST(
      CASE WHEN s.StatusValueText IN ('Hủy chưa trả hàng','Hủy đã trả hàng')
      THEN 
        (IF(c.CountryCode = 'VN',
          SUM(o.net_amount * r.rate) / 1.08,
          SUM(o.net_amount * r.rate)
        ))
      ELSE 0 END AS INT64
    ) AS Deductions,

    CAST(
      CASE WHEN s.StatusValueText IN ('Mới','Đang gói hàng','Đang giao hàng','Giao thành công')
      THEN 
        (IF(c.CountryCode = 'VN',
          SUM(o.net_amount * r.rate) / 1.08,
          SUM(o.net_amount * r.rate)
        ))
      ELSE 0 END AS INT64
    ) AS NetAmount,

    -- ✅ Cost chỉ dành cho đơn 1,2,3,4 (giá vốn hàng bán)
    CAST(
      CASE
        WHEN CAST(o.status_id AS STRING) IN ('1','2','3','4')
        THEN SUM(o.total_cogs * r.rate)
        ELSE NULL
      END AS INT64
    ) AS Cost,

    CAST(SUM(o.other_income_refund * r.rate) AS INT64) AS ReturnDiscount,
    CAST(SUM(o.marketplace_service_fee * r.rate) AS INT64) AS PlatformServiceFee,
    CAST(SUM(o.marketplace_transaction_fee
 * r.rate) AS INT64) AS PlatformTransactionFee,
    CAST(SUM(o.marketplace_admin_fee * r.rate) AS INT64) AS PlatformFee,
    CAST(SUM(o.marketplace_affiliate_fee * r.rate) AS INT64) AS PlatformAffiliateCommissionFee,
    CAST(SUM((o.marketplace_shipping_fee + o.marketplace_return_fee) * r.rate) AS INT64) AS PlatformShippingFee,
    CAST(SUM(o.marketplace_tax_fee * r.rate) AS INT64) AS PlatformTaxFee,
    CAST(SUM(o.marketplace_other_fee * r.rate) AS INT64) AS PlatformOtherFee,
    CAST(SUM((o.shipment_shipping_fee + o.shipment_cod_fee + o.shipment_cod_vat_amount) * r.rate) AS INT64) AS TotalShippingFee,
    CAST(SUM(o.shipment_return_fee * r.rate) AS INT64) AS ShippingFeeReturn,
    CAST(SUM(o.external_marketing_other_fee * r.rate) AS INT64) AS ExternalMarketingOtherFee
  FROM Orders o
  JOIN Dates d ON o.order_id = d.order_id
  JOIN Rates r ON o.order_id = r.order_id
  JOIN StatusLogic s ON o.order_id = s.order_id
  JOIN `hv-data.hvnet_products_dwh.us_countries` c ON c.CountryId = o.country_id
  JOIN `hv-data.hvnet_products_dwh.us_bussiness_units` bu ON bu.Id = o.bu_id
  WHERE d.CreatedOrder >= (SELECT FromDate FROM Params)
    AND o.bu_id IN (4,5,7,10,11,12,13,29,30,32,36,37)
  GROUP BY thitruong, bu_phongban, o.order_type, OrderTypeLabel, status, thang, ngay, o.status_id, s.StatusValueText
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
    ord.order_type,
    IF(ord.order_type = 2, 'Sàn TMĐT', 'Kênh bán hàng khác') AS OrderTypeLabel,

    -- LostParcel là tiền huỷ hàng/hết hạn -> bạn muốn gom vào dự phòng DN
    'Hủy' AS status,

    FORMAT_DATE('%Y-%m', ord.return_processed_date) AS thang,
    ord.return_processed_date AS ngay,

    CAST(SUM(ord.total_cogs * COALESCE(ce.exchange_rate, 1)) AS INT64) AS LostParcelCost
  FROM Orders ord
  JOIN Params p ON TRUE
  LEFT JOIN `hv-data.hvnet_products_dwh.us_bussiness_units` bu
    ON bu.Id = ord.bu_id
  LEFT JOIN `hv-data.hvnet_products_dwh.us_countries` ctr
    ON ctr.CountryId = ord.country_id
  LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` ce
    ON ce.ProjectId = ord.project_id
   AND SAFE.PARSE_DATE('%Y%m%d', CAST(ce.DateKey AS STRING))   = ord.return_processed_date
  WHERE ord.return_processed_date >= p.FromDate
    AND CAST(ord.status_id AS STRING) = '7'
    AND ord.bu_id IN (4,5,7,10,11,12,13,29,30,32,36,37,14,23,26)
    AND EXISTS (
      SELECT 1
      FROM `hv-data.hvnet_products_dwh.wh_warehouses_stocks` w
      WHERE w.ProjectId     = ord.project_id
        AND w.InventoryId   = ord.order_id
        AND w.InventoryType = 'LostParcel'
    )
  GROUP BY thitruong, bu_phongban, ord.order_type, OrderTypeLabel, status, thang, ngay
),

/* =========================
   3) Unpivot 2 nguồn rồi UNION ALL
   ========================= */
AllMetrics AS (
  SELECT
    thitruong, bu_phongban, OrderTypeLabel, status, thang, ngay,
    Metric, Value
  FROM BaseData
  UNPIVOT (
    Value FOR Metric IN (
      CountOrders,
      GrossAmount,
      NetAmount,
      Deductions,
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
      ShippingFeeReturn,
      ExternalMarketingOtherFee
    )
  )

  UNION ALL

  SELECT
    thitruong, bu_phongban, OrderTypeLabel, status, thang, ngay,
    Metric, Value
  FROM LostParcelAgg
  UNPIVOT (
    Value FOR Metric IN (LostParcelCost)
  )
)

SELECT
  thitruong,
  bu_phongban,
  OrderTypeLabel,
  status,
  thang,
  ngay,
  Metric,
  Value AS amount,

  -- ============== CHI TIẾT ==============
  CASE
    WHEN Metric IN ('CountOrders','GrossAmount','Cost','NetAmount','Deductions') THEN OrderTypeLabel
    WHEN Metric = 'ReturnDiscount' THEN 'Hoàn từ sàn/đơn vị vận chuyển'

    WHEN Metric = 'LostParcelCost' THEN 'Tiền hàng hủy/hết hạn'

    WHEN Metric = 'PlatformServiceFee' THEN 'Phí dịch vụ'
    WHEN Metric = 'PlatformTransactionFee' THEN 'Phí thanh toán'
    WHEN Metric = 'PlatformFee' THEN 'Phí quản lý sàn'
    WHEN Metric = 'PlatformAffiliateCommissionFee' THEN 'Affiliate/Hoa hồng giới thiệu'
    WHEN Metric = 'PlatformShippingFee' THEN 'Phí vận chuyển của sàn'
    WHEN Metric = 'PlatformTaxFee' THEN 'Phí thuế sàn'
    WHEN Metric = 'PlatformOtherFee' THEN 'Phí sàn & marketing sàn khác'
    WHEN Metric = 'TotalShippingFee' THEN 'Phí vận chuyển đến khách hàng'
    WHEN Metric = 'ShippingFeeReturn' THEN 'Chi phí hoàn hàng'
    WHEN Metric = 'ExternalMarketingOtherFee' THEN 'Chi phí marketing ngoài sàn khác'
  END AS chitiet,

  -- ============== NHÓM ==============
  CASE
    WHEN Metric = 'CountOrders' THEN 'Số lượng đơn hàng'
    
    WHEN Metric = 'GrossAmount' THEN 'Doanh số đến từ việc bán hàng'

    WHEN Metric = 'Deductions' AND status = 'Hoàn' THEN 'Đơn hàng hoàn'
    WHEN Metric = 'Deductions' AND status = 'Hủy' THEN 'Đơn hàng huỷ'

    WHEN Metric = 'NetAmount' AND status = 'Giao thành công' THEN 'Doanh thu từ bán hàng trực tiếp'
    WHEN Metric = 'NetAmount' AND status IN ('Mới','Đang gói hàng','Đang giao hàng') THEN 'Doanh thu đang xử lý'

    WHEN Metric = 'ReturnDiscount' THEN 'Thu nhập khác'

    WHEN Metric = 'Cost' THEN 'Giá vốn hàng bán'

    WHEN Metric IN ('LostParcelCost') THEN 'Chi phí hủy hàng/hết hạn'

    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee')
    THEN 'Phí sàn & marketing sàn'

    WHEN Metric IN ('TotalShippingFee','ShippingFeeReturn')
    THEN 'Chi phí Logistics đến Khách hàng'

    WHEN Metric IN ('ExternalMarketingOtherFee')
    THEN 'Chi phí marketing ngoài sàn'

  END AS nhom,

  -- ============== DANH MỤC ==============
  CASE
    WHEN Metric = 'CountOrders' THEN 'ĐƠN HÀNG'
    WHEN Metric = 'GrossAmount' THEN 'DOANH SỐ'
    WHEN Metric = 'Deductions' THEN 'GIẢM TRỪ'
    WHEN Metric IN ('NetAmount','ReturnDiscount') THEN 'DOANH THU'

    WHEN Metric = 'LostParcelCost' THEN 'PHÍ DỰ PHÒNG DN'

    WHEN Metric = 'Cost' THEN 'GIÁ VỐN HÀNG BÁN'

    WHEN Metric IN ('PlatformServiceFee','PlatformTransactionFee','PlatformFee',
                    'PlatformAffiliateCommissionFee','PlatformShippingFee',
                    'PlatformTaxFee','PlatformOtherFee',
                    'TotalShippingFee','ShippingFeeReturn','ExternalMarketingOtherFee')
         AND status IN ('Hoàn','Hủy')
    THEN 'PHÍ DỰ PHÒNG DN'
    ELSE 'CP BÁN HÀNG'
  END AS danhmuc

FROM AllMetrics
WHERE Value <> 0
ORDER BY thitruong, bu_phongban, thang, Metric
