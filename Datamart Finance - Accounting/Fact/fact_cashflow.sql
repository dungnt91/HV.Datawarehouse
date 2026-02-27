-- WITH ship AS (
--   SELECT
--     PaymentId,
--     SUM(COALESCE(TotalPayment, 0) + COALESCE(ShippingCodFee, 0) + COALESCE(ShippingCodFeeVAT, 0)) AS ShippingTotal
--   FROM `hv-data.hvnet_products_dwh.od_orders_payments_multiple_platforms_items`
--   GROUP BY PaymentId
-- ),

WITH o AS (
  SELECT
    pi.PaymentId,

    fo.country_id,
    fo.country_code,
    fo.bu_id,
    fo.bu_name,
    fo.order_type,

    -- Amount theo đúng 3 nhánh SQL Server
    CASE
      WHEN COALESCE(p.PaymentShippingId, 0) > 0
           AND p.DeliveryPartnerId <> 7
      THEN
        SUM(
              COALESCE(pi.TotalPayment, 0)
            - COALESCE(pi.FeeDiscount, 0)
            - COALESCE(pi.FeeOrther, 0)
            + COALESCE(pi.FeeFloor, 0)
            - COALESCE(pi.PlatformServiceFee, 0)
            - COALESCE(pi.PlatformTransactionFee, 0)
            - COALESCE(pi.PlatformAffiliateCommissionFee, 0)
            - COALESCE(pi.PlatformOtherFee, 0)
            - COALESCE(pi.ExternalMarketingOtherFee, 0)
        )
        - MAX(COALESCE(p.TotalPriceCancelled, 0))
        -- - MAX(COALESCE(ship.ShippingTotal, 0))
        - MAX(COALESCE(p.OtherIncome, 0))

      WHEN COALESCE(p.PaymentShippingId, 0) = 0
           AND p.DeliveryPartnerId <> 7
      THEN
        SUM(
              COALESCE(pi.TotalPayment, 0)
            - COALESCE(pi.ShipPriceRealPayment, 0)
            - COALESCE(pi.FeeDiscount, 0)
            - COALESCE(pi.FeeOrther, 0)
            + COALESCE(pi.FeeFloor, 0)
            - COALESCE(pi.PlatformServiceFee, 0)
            - COALESCE(pi.PlatformTransactionFee, 0)
            - COALESCE(pi.PlatformAffiliateCommissionFee, 0)
            - COALESCE(pi.PlatformOtherFee, 0)
            - COALESCE(pi.ExternalMarketingOtherFee, 0)
        )
        - MAX(COALESCE(p.TotalPriceCancelled, 0))
        - MAX(COALESCE(p.OtherIncome, 0))

      ELSE
        SUM(
              COALESCE(pi.TotalPaymentPayment, 0)
            - COALESCE(pi.FeeDiscount, 0)
            - COALESCE(pi.FeeOrther, 0)
            - COALESCE(pi.ShipPriceRealPayment, 0)
            - COALESCE(pi.ShippingFeeReturn, 0)
            + COALESCE(pi.FeeFloor, 0)
            - COALESCE(pi.PlatformServiceFee, 0)
            - COALESCE(pi.PlatformTransactionFee, 0)
            - COALESCE(pi.PlatformAffiliateCommissionFee, 0)
            - COALESCE(pi.PlatformOtherFee, 0)
            - COALESCE(pi.ExternalMarketingOtherFee, 0)
        )
        - MAX(COALESCE(p.TotalPriceCancelled, 0))
    END AS amount,

    e.base_fx_rate

  FROM `hv-data.hvnet_products_dwh.a_orders_payments_items` pi
  LEFT JOIN `hv-data.hvnet_products_dwh.a_orders_payments` p
    ON pi.PaymentId = p.Id
  -- LEFT JOIN ship
  --   ON ship.PaymentId = p.PaymentShippingId
  LEFT JOIN `hv-data.a_dwh.FactOrder` fo
    ON pi.OrderId = fo.order_id
  LEFT JOIN `hv-data.a_dwh.DimExchangeRate` e
    ON fo.project_id = e.project_id
   AND fo.created_order = e.exchange_date

  WHERE fo.bu_id IS NOT NULL
    AND fo.country_id IS NOT NULL
    AND p.StatusValue = 2
    AND pi.StatusValue = 2

  GROUP BY
    pi.PaymentId,
    fo.country_id,
    fo.country_code,
    fo.bu_id,
    fo.bu_name,
    fo.order_type,
    e.base_fx_rate,
    p.PaymentShippingId,
    p.DeliveryPartnerId
)

SELECT
  'portal_phieuthanhtoan' AS source_system,

  o.country_id,
  o.country_code,

  o.bu_id,
  o.bu_name,

  NULL AS sub_bu_id,
  NULL AS sub_bu_name,

  NULL AS bank_account_id,
  NULL AS bank_account_number,
  NULL AS bank_account_name,

  p.Id AS source_reference_id,

  c.category_id,
  c.cashflow_category,
  c.cashflow_subcategory,
  c.cashflow_item,
  c.transaction_type,

  p.PaymentDate AS transaction_date,
  p.PaymentNote AS note,

  o.amount AS amount,

  CASE o.country_code
    WHEN 'ML' THEN 'MYR'
    WHEN 'PH' THEN 'PHP'
    WHEN 'TH' THEN 'THB'
    WHEN 'ID' THEN 'IDR'
    WHEN 'CAM' THEN 'USD'
    WHEN 'LAO' THEN 'LAK'
    WHEN 'USA' THEN 'USD'
    WHEN 'CA' THEN 'CAD'
    WHEN 'VN' THEN 'VND'
    ELSE 'UNKNOWN'
  END AS currency,

  o.base_fx_rate AS exchange_rate_to_vnd

FROM `hv-data.hvnet_products_dwh.a_orders_payments` p
LEFT JOIN o
  ON p.Id = o.PaymentId
LEFT JOIN `hv-data.lark_dwh.lark_base_dim_cashflow_categories` c
  ON c.category_id = CASE WHEN o.order_type = 2 THEN 2 ELSE 3 END
WHERE p.PaymentDate >= '2026-01-01'
  AND p.StatusValue = 2
  AND p.PaymentType <> 2;
