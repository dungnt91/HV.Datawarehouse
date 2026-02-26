 SELECT
    'lark_global_2026' AS source_system,

    NULL                            AS country_id,
    CAST(thi_truong__bc AS STRING)  AS country_code,    

    NULL                            AS bu_id,
    CAST(bu_phong_ban AS STRING)    AS bu_name,

    NULL                            AS sub_bu_id,
    CAST(bo_phan AS STRING)         AS sub_bu_name,

    NULL                                          AS bank_account_id,
    CAST(ten_ngan_hang AS STRING)                 AS bank_name,
    CAST(so_tai_khoan_ngan_hang AS STRING)        AS back_account_number,
    CAST(ten_tai_khoan AS STRING)                 AS bank_account_name,

    CAST(l.record_id AS STRING)                     AS source_reference_id,

    c.category_id,
    c.cashflow_category,
    c.cashflow_subcategory,
    c.cashflow_item,
    c.transaction_type,

    DATE(TIMESTAMP_MILLIS(ngay_thanh_toan))       AS transaction_date,
    CAST(noi_dung_thu__chi AS STRING)             AS note,
    SAFE_CAST(so_tien__tien_ban_dia AS NUMERIC)   AS amount,

    CAST(don_vi_tien_te AS STRING)                AS currency,
    SAFE_CAST(ti_gia AS NUMERIC)                  AS exchange_rate_to_vnd

  FROM `hv-data.lark_dwh.lark_base_money_global` l
    LEFT JOIN `hv-data.lark_dwh.lark_base_dim_cashflow_categories` c    ON l.loai_chi = c.spending_name 
  WHERE trang_thai = 'Đã hoàn thành'
    AND loai_phieu = 'Phiếu chi'

