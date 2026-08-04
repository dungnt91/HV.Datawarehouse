-- CREATE OR REPLACE TABLE `hv-data.hv_fin.fin_orders` AS

/*
================================================================================
  BÁO CÁO DOANH THU & CHI PHÍ ĐƠN HÀNG
  Mục tiêu : Cung cấp dữ liệu P&L theo ngày, thị trường, BU, sub_brand
  Phạm vi  : Đơn hàng từ ngày from_date trở đi (cả portal lẫn pancake_pos)
  Tác giả  : Lê Xuân Quỳnh - IT Business Analyst - Phòng Công nghệ
  Lưu ý   : Mọi số tiền đã quy đổi sang VND theo tỷ giá tại ngày tạo đơn.
             Riêng VN chia thêm 1.08 để loại VAT khỏi doanh số.
================================================================================
*/

WITH cfg AS (
  SELECT
    DATE '2025-10-01'                              AS from_date,
    [4,5,7,10,11,12,13,29,30,32,36,37]            AS valid_bu_ids,
    [4,5,7,10,11,12,13,29,30,32,36,37,14,23,26]   AS lost_parcel_bu_ids
),

metric_label_lookup AS (
  SELECT metric, status_condition, use_order_type_as_chitiet, chitiet, nhom, danhmuc
  FROM UNNEST([
    STRUCT('CountOrders'                    AS metric, 'any'           AS status_condition, TRUE  AS use_order_type_as_chitiet, ''                                  AS chitiet, 'Số lượng đơn hàng'                   AS nhom, 'ĐƠN HÀNG'          AS danhmuc),
    STRUCT('GrossAmount'                    , 'any'           , TRUE  , ''                                  , 'Doanh số đến từ việc bán hàng'       , 'DOANH SỐ'          ),
    STRUCT('Deductions'                     , 'returned'      , TRUE  , ''                                  , 'Đơn hàng hoàn'                       , 'GIẢM TRỪ'          ),
    STRUCT('Deductions'                     , 'cancelled'     , TRUE  , ''                                  , 'Đơn hàng huỷ'                        , 'GIẢM TRỪ'          ),
    STRUCT('DiscountAmount'                 , 'any'     , TRUE  , ''                                  , 'Khoản chiết khấu thương mại'         , 'GIẢM TRỪ'          ),
    STRUCT('NetAmount'                      , 'delivered'     , TRUE  , ''                                  , 'Doanh thu từ bán hàng trực tiếp'     , 'DOANH THU'         ),
    STRUCT('NetAmount'                      , 'pending'       , TRUE  , ''                                  , 'Doanh thu đang xử lý'                , 'DOANH THU'         ),
    STRUCT('ReturnDiscount'                 , 'any'           , FALSE , 'Hoàn từ sàn/đơn vị vận chuyển'    , 'Thu nhập khác'                       , 'DOANH THU'         ),
    STRUCT('Cost'                           , 'any'           , TRUE  , ''                                  , 'Giá vốn hàng bán'                    , 'GIÁ VỐN HÀNG BÁN' ),
    STRUCT('LostParcelCost'                 , 'any'           , FALSE , 'Tiền hàng hủy/hết hạn'            , 'Chi phí hủy hàng/hết hạn'            , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformServiceFee'             , 'active'        , FALSE , 'Phí dịch vụ'                      , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformTransactionFee'         , 'active'        , FALSE , 'Phí thanh toán'                   , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformFee'                    , 'active'        , FALSE , 'Phí quản lý sàn'                  , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformAffiliateCommissionFee' , 'active'        , FALSE , 'Affiliate/Hoa hồng giới thiệu'    , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformShippingFee'            , 'active'        , FALSE , 'Phí vận chuyển của sàn'           , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformTaxFee'                 , 'active'        , FALSE , 'Phí thuế sàn'                     , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformOtherFee'               , 'active'        , FALSE , 'Phí sàn & marketing sàn khác'     , 'Phí sàn & marketing sàn'             , 'CP BÁN HÀNG'       ),
    STRUCT('TotalShippingFee'               , 'active'        , FALSE , 'Phí vận chuyển đến khách hàng'    , 'Chi phí Logistics đến Khách hàng'    , 'CP BÁN HÀNG'       ),
    STRUCT('ShippingFeeReturn'              , 'active'        , FALSE , 'Chi phí hoàn hàng'                , 'Chi phí Logistics đến Khách hàng'    , 'CP BÁN HÀNG'       ),
    STRUCT('ExternalMarketingOtherFee'      , 'active'        , FALSE , 'Chi phí marketing ngoài sàn khác' , 'Chi phí marketing ngoài sàn'         , 'CP BÁN HÀNG'       ),
    STRUCT('PlatformServiceFee'             , 'cancelled_fee' , FALSE , 'Phí dịch vụ'                      , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformTransactionFee'         , 'cancelled_fee' , FALSE , 'Phí thanh toán'                   , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformFee'                    , 'cancelled_fee' , FALSE , 'Phí quản lý sàn'                  , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformAffiliateCommissionFee' , 'cancelled_fee' , FALSE , 'Affiliate/Hoa hồng giới thiệu'    , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformShippingFee'            , 'cancelled_fee' , FALSE , 'Phí vận chuyển của sàn'           , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformTaxFee'                 , 'cancelled_fee' , FALSE , 'Phí thuế sàn'                     , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('PlatformOtherFee'               , 'cancelled_fee' , FALSE , 'Phí sàn & marketing sàn khác'     , 'Phí sàn & marketing sàn'             , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('TotalShippingFee'               , 'cancelled_fee' , FALSE , 'Phí vận chuyển đến khách hàng'    , 'Chi phí Logistics đến Khách hàng'    , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('ShippingFeeReturn'              , 'cancelled_fee' , FALSE , 'Chi phí hoàn hàng'                , 'Chi phí Logistics đến Khách hàng'    , 'PHÍ DỰ PHÒNG DN'   ),
    STRUCT('ExternalMarketingOtherFee'      , 'cancelled_fee' , FALSE , 'Chi phí marketing ngoài sàn khác' , 'Chi phí marketing ngoài sàn'         , 'PHÍ DỰ PHÒNG DN'   )
  ])
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. SUB-BRAND CHÍNH CHO TỪNG ĐƠN PANCAKE
-- ─────────────────────────────────────────────────────────────────────────────
pancake_order_dominant_brand AS (
  SELECT
    ol.order_key,
    p.sub_brand
  FROM `hv-data.a_dwh_pancake.FactOrderLine` ol
  JOIN `hv-data.a_dwh_pancake.DimProduct`    p  ON ol.sku_id = p.sku_id
  WHERE p.sub_brand IN ('LumiABERA', "MEN'S ABERA", "Perle d'ABERA", 'DermABERA')
  GROUP BY ol.order_key, p.sub_brand
  QUALIFY
    ROW_NUMBER() OVER (
      PARTITION BY ol.order_key
      ORDER BY SUM(ol.allocation_rate) DESC
    ) = 1
),



-- ─────────────────────────────────────────────────────────────────────────────
-- 3. NGÀY CHỐT ĐƠN PANCAKE (finalized_date)
--
--    Vấn đề với confirmed_date:
--      confirmed_date trong FactOrder là ngày cập nhật gần nhất của đơn,
--      không phải ngày đơn được xác nhận lần đầu → gây sai lệch kỳ báo cáo.
--
--    Giải pháp — dùng FactOrderStatusHistory:
--      Truy vết lịch sử trạng thái, tìm ngày đầu tiên đơn đi qua
--      một trạng thái "chốt" theo thứ tự ưu tiên nghiệp vụ:
--
--      Nhóm 1 (ưu tiên cao nhất, lấy cái nào đến trước):
--        status 1  = Đã xác nhận
--        status 17 = Chờ xác nhận
--        status 11 = Chờ hàng
--
--      Nhóm 2 (fallback theo thứ tự cố định):
--        status 12 → status 2 (Đã gửi hàng) → status 3 (Đã nhận) → status 16 (Đã thu tiền)
--
--    Đơn không có finalized_date → chưa chốt → bị loại khỏi báo cáo
--    tại WHERE created_order >= from_date (vì NULL không thỏa điều kiện).
--    Đây là hành vi đúng: đơn chưa chốt không được tính doanh thu.
-- ─────────────────────────────────────────────────────────────────────────────
pancake_status_fallback AS (
  SELECT
    order_key,
    update_date,
    status_id,
    ROW_NUMBER() OVER (
      PARTITION BY order_key
      ORDER BY
        -- Nhóm 1: status chốt chính thức, ưu tiên như nhau → lấy update_date sớm nhất
        CASE status_id
          WHEN 1  THEN 1
          WHEN 17 THEN 1
          WHEN 11 THEN 1
          -- Nhóm 2: fallback theo thứ tự nghiệp vụ
          WHEN 12 THEN 2
          WHEN 2  THEN 3
          WHEN 3  THEN 4
          WHEN 16 THEN 5
          ELSE 99
        END,
        update_date ASC   -- cùng nhóm → lấy ngày sớm nhất
    ) AS rn
  FROM `hv-data.a_dwh_pancake.FactOrderStatusHistory`
  WHERE status_id IN (1, 11, 17, 12, 2, 3, 16)
),

pancake_order_finalized AS (
  SELECT
    fo.order_key,
    DATE(sf.update_date) AS finalized_date
  FROM `hv-data.a_dwh_pancake.FactOrder`  fo
  LEFT JOIN pancake_status_fallback        sf
    ON  sf.order_key = fo.order_key
    AND sf.rn = 1
  -- Loại đơn huỷ/nháp và đơn trả hàng chưa từng xác nhận
  WHERE fo.status_id NOT IN (0, 7, 11, 17)
    AND NOT (fo.status_id = 6 AND fo.confirmed_at_ts IS NULL)
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CHUẨN HOÁ ĐƠN HÀNG TỪ HAI NGUỒN
-- ─────────────────────────────────────────────────────────────────────────────
stg_orders AS (

  -- 4a. PORTAL
  SELECT
    'portal'                 AS nguondulieu,
    CAST(order_id AS STRING) AS order_id,
    created_order,
    stock_in_void_date,
    return_processed_date,
    CASE
      WHEN project_id = 39 THEN 1
      WHEN project_id = 40 THEN 11
      ELSE country_id
    END                      AS country_id,
    CASE
      WHEN project_id = 8              THEN 4
      WHEN project_id = 5              THEN 5
      ELSE bu_id
    END                      AS bu_id,
    'NULL'                   AS sub_brand,
    project_id,
    status_id,
    order_type,
    net_amount,
    0                        AS aggregate_discount,
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
    external_marketing_other_fee,
    CASE
      WHEN NULLIF(DATE(delivery_success_date), DATE '1900-01-01') IS NOT NULL THEN TRUE
      WHEN NULLIF(DATE(payment_confirmed_date), DATE '1900-01-01') IS NOT NULL THEN TRUE
      ELSE FALSE
    END AS was_delivered,
    'NULL' AS MarketId
  FROM `hv-data.a_dwh.FactOrder` o
     CROSS JOIN cfg
  WHERE NOT EXISTS (
    SELECT 1
    FROM `hv-data.hvnet_products_dwh.a_orders_deleted` del
    WHERE del.OrderId = o.order_id
  )
  AND o.created_order >= cfg.from_date
  AND o.bu_id IN UNNEST(cfg.valid_bu_ids)

  UNION ALL

  -- 4b. PANCAKE POS
  --
  
  SELECT
    CONCAT('pancake_pos_', o.shop_id) AS nguondulieu,
    CAST(o.order_key AS STRING) AS order_id,

    -- Dùng finalized_date làm ngày chốt đơn — xem giải thích ở CTE 3
    DATE(pof.finalized_date)   AS created_order,

    DATE(o.shipped_at_ts)                      AS stock_in_void_date,
    DATE(o.returned_at_ts)                     AS return_processed_date,
    m.ExternalId                              AS country_id,
    CASE o.shop_id
      WHEN 1942976467 THEN org.ExternalId
      WHEN 1942946009 THEN 11
      WHEN 1943014207 THEN 7
    END                                    AS bu_id,
    sb.sub_brand,
    0 AS project_id,
    CASE o.status_id
      WHEN 1  THEN 1  WHEN 11 THEN 1  WHEN 12 THEN 1  WHEN 17 THEN 1
      WHEN 8  THEN 2  WHEN 9  THEN 2
      WHEN 2  THEN 3
      WHEN 3  THEN 4  WHEN 16 THEN 4
      WHEN 4  THEN 5
      WHEN 5  THEN 7  WHEN 15 THEN 7
    END                                     AS status_id,
    CASE WHEN o.sales_platform IN ('TikTok', 'Shopee', 'Lazada') THEN 2 ELSE 1
    END                                     AS order_type,
    SAFE_CAST(COALESCE(total_price,0) + COALESCE(shipping_fee_customer,0) + COALESCE(surcharge_amount,0) AS FLOAT64)         AS net_amount,
    SAFE_CAST(COALESCE(total_discount,0) + COALESCE(total_items_discount,0) - COALESCE(platform_subsidy,0) AS FLOAT64)       AS aggregate_discount,
    SAFE_CAST(COALESCE(product_cogs,0) + COALESCE(gift_cogs,0) AS FLOAT64)                                                   AS total_cogs,
    0                                                                                                                        AS other_income_refund,
    0                                                                                                                        AS marketplace_return_fee,
    COALESCE(SAFE_CAST(af_service_fee AS FLOAT64), 0)                                                                        AS marketplace_service_fee,
    SAFE_CAST(COALESCE(af_payment_fee,0) + COALESCE(af_seller_transaction_fee,0) AS FLOAT64)                                 AS marketplace_transaction_fee,
    COALESCE(SAFE_CAST(af_commission_fee AS FLOAT64), 0)                                                                     AS marketplace_admin_fee,
    COALESCE(SAFE_CAST(af_affiliate_commission AS FLOAT64), 0)                                                               AS marketplace_affiliate_fee,
    COALESCE(SAFE_CAST(af_shipping_fee_amount AS FLOAT64), 0)                                                                AS marketplace_shipping_fee,
    SAFE_CAST(COALESCE(af_isr_income_tax_amount,0) + COALESCE(af_iva_vat_amount,0) + COALESCE(af_tax,0) AS FLOAT64)          AS marketplace_tax_fee,
    fee_marketplace - (
        COALESCE(SAFE_CAST(af_service_fee AS FLOAT64), 0)
      + SAFE_CAST(COALESCE(af_payment_fee,0) + COALESCE(af_seller_transaction_fee,0) AS FLOAT64)
      + COALESCE(SAFE_CAST(af_commission_fee AS FLOAT64), 0)
      + COALESCE(SAFE_CAST(af_affiliate_commission AS FLOAT64), 0)
      + COALESCE(SAFE_CAST(af_shipping_fee_amount AS FLOAT64), 0)
      + SAFE_CAST(COALESCE(af_isr_income_tax_amount,0) + COALESCE(af_iva_vat_amount,0) + COALESCE(af_tax,0) AS FLOAT64)
      + COALESCE(SAFE_CAST(af_marketplace_other_fee AS FLOAT64), 0)
    )                                                                                                                         AS marketplace_other_fee,
    COALESCE(SAFE_CAST(partner_fee AS FLOAT64), 0)                                                                           AS shipment_shipping_fee,
    0  AS shipment_return_fee,
    0  AS shipment_cod_fee,
    0  AS shipment_cod_vat_amount,
    0  AS external_marketing_other_fee,
    CASE
      WHEN NULLIF(DATE(received_at_ts),   DATE '1900-01-01') IS NOT NULL THEN TRUE
      WHEN NULLIF(DATE(reconciled_at_ts), DATE '1900-01-01') IS NOT NULL THEN TRUE
      ELSE FALSE
    END AS was_delivered,
    s.MarketId

  FROM `hv-data.a_dwh_pancake.FactOrder`          o
    LEFT JOIN pancake_order_finalized                pof ON pof.order_key        = o.order_key  --  join lấy finalized_date
    LEFT JOIN `hv-data.mdm_prod_dwh.shops`          s   ON CAST(o.shop_id AS STRING)  = s.ExternalShopId
    LEFT JOIN `hv-data.mdm_prod_dwh.markets`        m   ON s.MarketId          = m.Id
    LEFT JOIN `hv-data.a_dwh_pancake.DimEmployee`   e   ON o.marketer_id       = e.external_employee_id AND CAST(o.shop_id AS STRING) = e.shop_id
    LEFT JOIN `hv-data.mdm_prod_dwh.org_units`      org ON org.Type = 3 AND e.bu = org.Code
    LEFT JOIN pancake_order_dominant_brand           sb  ON o.order_key         = sb.order_key
  WHERE (o.status_id NOT IN (0, 6, 7)                          -- loại 0, 7, và 6 mặc định
    OR (o.status_id = 6 AND o.confirmed_at_ts IS NOT NULL))    -- nhưng giữ lại 6 nếu có confirmed_date
    AND o.shop_id IN (1942946009,1942976467,1942955945,714982840,1635973951)
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. TỶ GIÁ QUY ĐỔI
-- ─────────────────────────────────────────────────────────────────────────────
order_fx_rate AS (
  SELECT
  o.order_id,
  CASE 
    WHEN nguondulieu = 'portal' THEN COALESCE(ex.base_fx_rate, 1) 
    WHEN o.country_id = 9 THEN 1
    ELSE COALESCE(r.Rate, 1)  
  END AS fx_rate
  FROM stg_orders o
  LEFT JOIN `hv-data.a_dwh.DimExchangeRate` ex
    ON  ex.project_id  = o.project_id
    AND CAST(ex.exchange_key AS STRING) = FORMAT_DATE('%Y%m%d', o.created_order)
  LEFT JOIN `hv-data.mdm_prod_dwh.market_exchange_rate` r
    ON r.MarketId = o.MarketId
    AND r.EffectiveFrom = DATE_TRUNC(
       DATE(o.created_order),
       MONTH
     )
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. PHÂN LOẠI TRẠNG THÁI ĐƠN
-- ─────────────────────────────────────────────────────────────────────────────
order_status_classification AS (
  SELECT
    o.order_id,
    o.status_id,
    o.status_id IN (1, 2, 3, 4) AS is_active,
    o.status_id IN (5, 7)       AS is_cancelled_or_returned,
    CASE
      WHEN o.status_id IN (5, 7) AND o.was_delivered AND o.stock_in_void_date IS NOT NULL
        THEN 'Hoàn'
      WHEN o.status_id IN (5, 7) THEN 'Hủy'
      WHEN o.status_id = 1       THEN 'Mới'
      WHEN o.status_id = 2       THEN 'Đang gói hàng'
      WHEN o.status_id = 3       THEN 'Đang giao hàng'
      WHEN o.status_id = 4       THEN 'Giao thành công'
      ELSE                            'Không xác định'
    END AS display_status
  FROM stg_orders o
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. BASE METRICS
-- ─────────────────────────────────────────────────────────────────────────────
base_metrics AS (
  SELECT
    o.nguondulieu,
    c.CountryCode                                              AS market,
    bu.name                                                    AS business_unit,
    o.sub_brand,
    o.order_type,
    IF(o.order_type = 2, 'Sàn TMĐT', 'Kênh bán hàng khác')   AS order_type_label,
    sc.display_status,
    FORMAT_DATE('%Y-%m', o.created_order)                      AS month_key,
    o.created_order                                            AS order_date,
    sc.is_active,
    sc.is_cancelled_or_returned,

    COUNT(o.order_id) AS CountOrders,

    CAST(IF(c.CountryCode = 'VN',
            SUM(o.net_amount * r.fx_rate) / 1.08,
            SUM(o.net_amount * r.fx_rate))
    AS INT64) AS GrossAmount,

    CAST(CASE WHEN sc.is_cancelled_or_returned
           THEN IF(c.CountryCode = 'VN',
                   SUM(o.net_amount * r.fx_rate) / 1.08,
                   SUM(o.net_amount * r.fx_rate))
           ELSE 0 END
    AS INT64) AS Deductions,

    CAST(CASE WHEN sc.is_active
           THEN IF(c.CountryCode = 'VN',
                   SUM((o.net_amount - o.aggregate_discount) * r.fx_rate) / 1.08,
                   SUM((o.net_amount - o.aggregate_discount) * r.fx_rate))
           ELSE 0 END
    AS INT64) AS NetAmount,

    CAST(CASE WHEN sc.is_active
           THEN IF(c.CountryCode = 'VN',
                   SUM(o.aggregate_discount * r.fx_rate) / 1.08,
                   SUM(o.aggregate_discount * r.fx_rate))
           ELSE 0 END
    AS INT64) AS DiscountAmount,

    CAST(CASE WHEN sc.is_active
           THEN SUM(o.total_cogs * r.fx_rate)
           ELSE NULL END
    AS INT64) AS Cost,

    CAST(SUM(o.other_income_refund             * r.fx_rate) AS INT64) AS ReturnDiscount,
    CAST(SUM(o.marketplace_service_fee          * r.fx_rate) AS INT64) AS PlatformServiceFee,
    CAST(SUM(o.marketplace_transaction_fee      * r.fx_rate) AS INT64) AS PlatformTransactionFee,
    CAST(SUM(o.marketplace_admin_fee            * r.fx_rate) AS INT64) AS PlatformFee,
    CAST(SUM(o.marketplace_affiliate_fee        * r.fx_rate) AS INT64) AS PlatformAffiliateCommissionFee,
    CAST(SUM((o.marketplace_shipping_fee
             + o.marketplace_return_fee)         * r.fx_rate) AS INT64) AS PlatformShippingFee,
    CAST(SUM(o.marketplace_tax_fee              * r.fx_rate) AS INT64) AS PlatformTaxFee,
    CAST(SUM(o.marketplace_other_fee            * r.fx_rate) AS INT64) AS PlatformOtherFee,
    CAST(SUM((o.shipment_shipping_fee
             + o.shipment_cod_fee
             + o.shipment_cod_vat_amount)        * r.fx_rate) AS INT64) AS TotalShippingFee,
    CAST(SUM(o.shipment_return_fee              * r.fx_rate) AS INT64) AS ShippingFeeReturn,
    CAST(SUM(o.external_marketing_other_fee     * r.fx_rate) AS INT64) AS ExternalMarketingOtherFee

  FROM stg_orders                                                    o
  LEFT JOIN order_fx_rate                                            r   ON r.order_id  = o.order_id
  LEFT JOIN order_status_classification                              sc  ON sc.order_id = o.order_id
  LEFT JOIN `hv-data.hvnet_products_dwh.us_countries`               c   ON c.CountryId = o.country_id
  LEFT JOIN `hv-data.hvnet_products_dwh.us_bussiness_units`         bu  ON bu.Id       = o.bu_id

  GROUP BY
    o.nguondulieu, market, business_unit, o.sub_brand,
    o.order_type, order_type_label,
    sc.display_status,
    month_key, order_date,
    sc.is_active,
    sc.is_cancelled_or_returned
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. LOST PARCEL COST
-- ─────────────────────────────────────────────────────────────────────────────
lost_parcel_cost AS (
  SELECT
    o.nguondulieu,
    ctr.CountryCode                                            AS market,
    bu.name                                                    AS business_unit,
    'NULL'                                                     AS sub_brand,
    o.order_type,
    IF(o.order_type = 2, 'Sàn TMĐT', 'Kênh bán hàng khác')   AS order_type_label,
    'Hủy'                                                      AS display_status,
    FORMAT_DATE('%Y-%m', o.return_processed_date)              AS month_key,
    o.return_processed_date                                    AS order_date,
    CAST(SUM(o.total_cogs * COALESCE(ce.exchange_rate, 1)) AS INT64) AS LostParcelCost
  FROM stg_orders                                                            o
  CROSS JOIN cfg
  LEFT JOIN `hv-data.hvnet_products_dwh.us_bussiness_units`                 bu  ON bu.Id         = o.bu_id
  LEFT JOIN `hv-data.hvnet_products_dwh.us_countries`                       ctr ON ctr.CountryId = o.country_id
  LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` ce
    ON  ce.ProjectId = o.project_id
    AND SAFE.PARSE_DATE('%Y%m%d', CAST(ce.DateKey AS STRING)) = o.return_processed_date
  WHERE o.return_processed_date >= cfg.from_date
    AND o.status_id              = 7
    AND o.bu_id IN UNNEST(cfg.lost_parcel_bu_ids)
    AND EXISTS (
      SELECT 1
      FROM `hv-data.hvnet_products_dwh.wh_warehouses_stocks` w
      WHERE w.ProjectId    = o.project_id
        AND CAST(w.InventoryId AS STRING) = o.order_id
        AND w.InventoryType  = 'LostParcel'
    )
  GROUP BY
    o.nguondulieu, market, business_unit, o.sub_brand,
    o.order_type, order_type_label, display_status,
    month_key, order_date
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 9. UNPIVOT WIDE → LONG
-- ─────────────────────────────────────────────────────────────────────────────
all_metrics_long AS (
  SELECT
    nguondulieu, market, business_unit, sub_brand,
    order_type_label, display_status, month_key, order_date,
    metric, value
  FROM base_metrics
  UNPIVOT (
    value FOR metric IN (
      CountOrders, GrossAmount, NetAmount, Deductions, DiscountAmount, Cost,
      ReturnDiscount, PlatformServiceFee, PlatformTransactionFee, PlatformFee,
      PlatformAffiliateCommissionFee, PlatformShippingFee, PlatformTaxFee,
      PlatformOtherFee, TotalShippingFee, ShippingFeeReturn, ExternalMarketingOtherFee
    )
  )

  UNION ALL

  SELECT
    nguondulieu, market, business_unit, sub_brand,
    order_type_label, display_status, month_key, order_date,
    metric, value
  FROM lost_parcel_cost
  UNPIVOT (value FOR metric IN (LostParcelCost))
),


-- ─────────────────────────────────────────────────────────────────────────────
-- 10. GẮN STATUS_CONDITION
-- ─────────────────────────────────────────────────────────────────────────────
metrics_with_condition AS (
  SELECT
    *,
    CASE
      WHEN display_status = 'Hoàn'                                       THEN 'returned'
      WHEN display_status = 'Hủy'                                        THEN 'cancelled'
      WHEN display_status = 'Giao thành công'                            THEN 'delivered'
      WHEN display_status IN ('Mới', 'Đang gói hàng', 'Đang giao hàng') THEN 'pending'
      ELSE 'any'
    END AS row_status_condition,
    CASE
      WHEN display_status IN ('Hoàn', 'Hủy') THEN 'cancelled_fee'
      ELSE                                         'active'
    END AS fee_status_condition

  FROM all_metrics_long
)


-- ─────────────────────────────────────────────────────────────────────────────
-- 11. OUTPUT CUỐI
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
  m.nguondulieu,
  m.market           AS thitruong,
  m.business_unit    AS bu_phongban,
  'NULL'             AS sub_bu,
  m.sub_brand,
  m.order_type_label AS OrderTypeLabel,
  m.display_status   AS status,
  m.month_key        AS thang,
  m.order_date       AS ngay,
  m.metric           AS Metric,
  m.value            AS amount,
  IF(lk.use_order_type_as_chitiet, m.order_type_label, lk.chitiet) AS chitiet,
  lk.nhom,
  lk.danhmuc

FROM metrics_with_condition m
JOIN metric_label_lookup    lk
  ON  lk.metric = m.metric
  AND CASE lk.status_condition
        WHEN 'any'           THEN TRUE
        WHEN 'returned'      THEN m.row_status_condition = 'returned'
        WHEN 'cancelled'     THEN m.row_status_condition = 'cancelled'
        WHEN 'delivered'     THEN m.row_status_condition = 'delivered'
        WHEN 'pending'       THEN m.row_status_condition = 'pending'
        WHEN 'active'        THEN m.fee_status_condition = 'active'
        WHEN 'cancelled_fee' THEN m.fee_status_condition = 'cancelled_fee'
        ELSE FALSE
      END
WHERE m.value <> 0
AND m.month_key >= "2026-07"

UNION ALL

SELECT *
FROM `hv-data.hv_fin.fin_orders-2026-06`
WHERE thang <= "2026-06" AND thang >= "2026-01"
ORDER BY thitruong, bu_phongban, thang, Metric, nguondulieu
