SELECT
    CAST(pay.id AS STRING)       AS maphieuchi,
    CAST(paytrans.id AS STRING) AS malenhchi,
    CAST(paycat.name AS STRING)         AS loaiphieu,
    org.name AS tochuc,
    CASE
        WHEN bu.name IN (
            'Vận hành chung',
            'Phòng Quản trị thương hiệu',
            'Phòng Cung ứng',
            'Phòng Nhân sự',
            'Phòng Kế toán',
            'Phòng Công nghệ',
            'Phòng Dịch vụ khách hàng',
            'Bộ phận Kho',
            'Phòng Giải pháp - Chiến lược'
        )
        THEN 'Khối Vận hành'
        ELSE 'Khối Kinh doanh'
    END AS khoi,    
    tt.name AS thitruong,
    bu.name AS phongban,
    spendcat.name AS danhmucchiphi,
    spendtype.name AS nhomchiphi,
    spend.name AS loaichiphi,
    spend.description AS motaloaicp,
    pay.amount AS tienvnd,
    pay.vat_amount AS tienvat,
    CAST(NULL AS NUMERIC) AS tienbandia,
    CAST(NULL AS NUMERIC) AS tigia,
    CAST(NULL AS STRING)  AS donvitiente,

    TIMESTAMP(pay.created_at) AS ngaylenphieu,
    TIMESTAMP(pay.payment_datetime) AS ngaythanhtoan,

    pay.note_payment AS noidungchi,
    pay.note AS noidungthanhtoan,
    nguoitaophieu.user_name AS nguoitaophieu,
    nguoiduyet.user_name AS nguoiduyetphieu,
    nguoichi.user_name AS nguoichitien,
    bank.bank_account_name AS taikhoanchi,
    bank.bank_account_number AS sotaikhoanchi,
    bank.bank_name AS tennganhangchi,
    bank.bank_short_name AS viettatnganhangchi,
    bankrecp.bank_account_name AS taikhoannhan,
    bankrecp.bank_account_number AS sotaikhoannhan,
    bankrecp.bank_name AS tennganhangnhan,
    bankrecp.bank_short_name AS viettatnganhangnhan
  FROM `hv-data.hv_money_dwh.p_payments` AS pay
  LEFT JOIN `hv-data.hv_money_dwh.p_payments_categories` AS paycat ON pay.payment_categories_id = paycat.id
  LEFT JOIN `hv-data.hv_money_dwh.s_markets` AS tt ON tt.id = pay.market_id
  LEFT JOIN `hv-data.hv_money_dwh.s_projects` AS bu ON bu.id = pay.project_id
  LEFT JOIN `hv-data.hv_money_dwh.s_teams` AS team ON team.id = pay.team_id
  LEFT JOIN `hv-data.hv_money_dwh.m_spendings` AS spend ON spend.id = pay.spending_id
  LEFT JOIN `hv-data.hv_money_dwh.m_spendings_types` AS spendtype ON spendtype.id = pay.spending_type_id
  LEFT JOIN `hv-data.hv_money_dwh.m_spending_categories` AS spendcat ON spendcat.id = pay.spending_category_id
  LEFT JOIN `hv-data.hv_money_dwh.p_payments_transactions` AS paytrans ON paytrans.payment_id = pay.id
  LEFT JOIN `hv-data.hv_money_dwh.s_users` AS nguoitaophieu ON pay.created_by = nguoitaophieu.id
  LEFT JOIN `hv-data.hv_money_dwh.s_users` AS nguoiduyet ON paytrans.updated_by = nguoiduyet.id
  LEFT JOIN `hv-data.hv_money_dwh.s_users` AS nguoichi ON paytrans.transfer_user_id = nguoichi.id
  LEFT JOIN `hv-data.hv_money_dwh.b_bank_accounts_recipients` AS bankrecp ON bankrecp.id = pay.bank_account_recipient_id
  LEFT JOIN `hv-data.hv_money_dwh.b_bank_accounts` AS bank ON bank.id = paytrans.transfer_bank_account_id
  LEFT JOIN `hv-data.hv_money_dwh.s_organizations` AS org ON org.id = pay.organization_id