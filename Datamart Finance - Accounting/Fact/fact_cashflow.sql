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

FROM `hv-data.hvnet_products_dwh.od_orders_payments` p

LEFT JOIN (
    SELECT
        pi.PaymentId,
        o.country_id,
        o.country_code,
        o.bu_id,
        o.bu_name,
        o.order_type,

        SUM(
              COALESCE(pi.TotalPaymentPayment, 0)
            - COALESCE(pi.ShipPriceRealPayment, 0)
            - COALESCE(pi.PlatformServiceFee, 0)
            - COALESCE(pi.PlatformTransactionFee, 0)
            - COALESCE(pi.PlatformAffiliateCommissionFee, 0)
            - COALESCE(pi.PlatformOtherFee, 0)
            - COALESCE(pi.ExternalMarketingOtherFee, 0)
        ) AS amount,

        e.base_fx_rate

    FROM `hv-data.hvnet_products_dwh.od_orders_payments_items` pi

    LEFT JOIN `hv-data.a_dwh.FactOrder` o
        ON pi.OrderId = o.order_id

    LEFT JOIN `hv-data.a_dwh.DimExchangeRate` e
        ON o.project_id = e.project_id
       AND o.created_order = e.exchange_date

    WHERE o.bu_id IS NOT NULL
      AND o.country_id IS NOT NULL

    GROUP BY
        pi.PaymentId,
        o.country_id,
        o.country_code,
        o.bu_id,
        o.bu_name,
        o.order_type,
        e.base_fx_rate

) o
ON p.Id = o.PaymentId

LEFT JOIN `hv-data.lark_dwh.lark_base_dim_cashflow_categories` c
ON c.category_id =
    CASE
        WHEN o.order_type = 2 THEN 2
        ELSE 3
    END

WHERE p.PaymentDate >= '2026-01-01'
AND p.StatusValue = 2
AND p.PaymentType <> 2
