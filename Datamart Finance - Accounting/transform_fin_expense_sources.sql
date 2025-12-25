WITH src_fin AS (
/* 1. Nguồn chi phí: HV. Money
- Chỉ lấy Phiếu ở trạng thái Đã hoàn thành 
- Phạm vi dữ liệu: Quỹ HV Net ĐNA (Từ tháng 10/2025), Khải Hoàn Net (Từ tháng 11/2025)
- Chỉ lấy Phiếu đề nghị chi - Loại Thanh toán 
- Các điều kiện phân loại phiếu:
  + Danh mục chi phí: Chỉ lấy CP BÁN HÀNG, QUẢN LÝ DN và PHÍ DỰ PHÒNG DN
  + Chi phí:
    . Không lấy Lương Khối Kinh doanh BU (Lương, BHXH), Lương K.VH Tổng Cty (Lương, BHXH), Lương K. VH BU (Lương, BHXH)
    . Không lấy Chế độ chính sách (Team <> Tiền cơm nhân sự)
    . Không lấy Phí thuế sàn, Phí dịch vụ, Phí vận chuyển của sàn, Affiliate/Hoa hồng giới thiệu, Phí quản lý sàn, Phí thanh toán, Chi phí Ads sàn, Chi phí Ads các kênh social, Chi phí hoàn hàng 
*/

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
  WHERE pay.status_id = 3  --Chỉ lấy Phiếu ở trạng thái Đã hoàn thành 
    AND ((DATE(pay.payment_datetime) >= '2025-10-01'AND org.id = 3 AND team.id <> 1105) --Phạm vi dữ liệu: Quỹ HV Net ĐNA (Từ tháng 10/2025), không lấy bộ phận "Tiền cơm nhân sự"
    OR (DATE(pay.payment_datetime) >= '2025-11-01' AND org.id = 5)) --Phạm vi dữ liệu: Khải Hoàn Net (Từ tháng 11/2025)
    AND pay.typeform = 1  -- Chỉ lấy Phiếu đề nghị chi - Loại Thanh toán 

    --Danh mục chi phí: Chỉ lấy CP BÁN HÀNG, QUẢN LÝ DN và PHÍ DỰ PHÒNG DN
    AND spendcat.id IN (2,3,4,17,15,16) 
    /*+ Chi phí:
    . Không lấy Lương Khối Kinh doanh BU (Lương, BHXH), Lương K.VH Tổng Cty (Lương, BHXH), Lương K. VH BU (Lương, BHXH)
    . Không lấy Chế độ chính sách (Team <> Tiền cơm nhân sự)
    . Không lấy Phí thuế sàn, Phí dịch vụ, Phí vận chuyển của sàn, Affiliate/Hoa hồng giới thiệu, Phí quản lý sàn, Phí thanh toán, Chi phí Ads sàn, Chi phí Ads các kênh social, Chi phí hoàn hàng*/
    AND spend.id NOT IN (1433,1440,1434,1436,1438,1439,1437,1482,1488,1487,1361,1357,1362,1358,1356,1359,1432,1455,1454,1458,1459,1462,1463,1257) 
),

src_global_phieu AS (
/* 2. Nguồn chi phí: Lark Approval - Global Tạo phiếu chi (Vận hành)
- Chỉ lấy Phiếu ở trạng thái Approved
- Phạm vi dữ liệu: Ngày thanh toán từ 01/10/2025
- Các điều kiện phân loại phiếu:
  + Danh mục chi phí: Chỉ lấy CP BÁN HÀNG, QUẢN LÝ DN 
  + Chi phí: Không lấy Phí vận chuyển đến khách, Lương, BHXH, Thưởng
*/

  SELECT
    CAST(record_id AS STRING) AS maphieuchi,
    CAST(NULL AS STRING)      AS malenhchi,
    CAST(NULL AS STRING)  AS loaiphieu,
    CAST(initiator_department AS STRING) AS tochuc,
        CASE
        WHEN phong_ban IN (
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
    CAST(thi_truong__bc AS STRING) AS thitruong,    
    CAST(phan_phong_ban AS STRING) AS phongban,
    CAST(danh_muc_chi_phi AS STRING) AS danhmucchiphi,
    CAST(phan_loai_chi AS STRING) AS nhomchiphi,
    CAST(loai_chi AS STRING) AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    SAFE_CAST(tien_vnd AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    SAFE_CAST(tong_chi AS NUMERIC) AS tienbandia,
    SAFE_CAST(ti_gia AS NUMERIC) AS tigia,
    CAST(don_vi_tien_te AS STRING) AS donvitiente,

    TIMESTAMP(created_time) AS ngaylenphieu,
    TIMESTAMP_MILLIS(`ngay_chuyen_tien`) AS ngaythanhtoan,

    CAST(noi_dung AS STRING) AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    IF(
      ARRAY_LENGTH(requester) > 0,
      JSON_EXTRACT_SCALAR(requester[OFFSET(0)], '$.name'),
      NULL
    ) AS requester,
    IF(
      ARRAY_LENGTH(nguoi_quan_ly) > 0,
      JSON_EXTRACT_SCALAR(nguoi_quan_ly[OFFSET(0)], '$.name'),
      NULL
    ) AS nguoiduyetphieu,

    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(NULL AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_global__tao_phieu_chi`
  WHERE status = 'Approved'
    AND TIMESTAMP_MILLIS(`ngay_chuyen_tien`) > '2025-10-01'
    AND danh_muc_chi_phi IN ('CP BÁN HÀNG','QUẢN LÝ DN')
    AND phan_loai_chi NOT IN ('Lương Khối Kinh doanh BU','Lương K. VH BU','Lương K.VH Tổng Cty')
    AND loai_chi <> 'Phí vận chuyển đến khách hàng'
),

src_global_phieu_bu AS (
/* 3. Nguồn chi phí: Lark Approval - Global Tạo phiếu chi (BU)
- Chỉ lấy Phiếu ở trạng thái Approved
- Phạm vi dữ liệu: Ngày thanh toán từ 01/10/2025
- Các điều kiện phân loại phiếu:
  + Danh mục chi phí: Chỉ lấy CP BÁN HÀNG, QUẢN LÝ DN 
  + Nhóm chi phí: Không lấy Lương Khối Kinh doanh BU, Lương K.VH Tổng Cty, Lương K. VH BU
  + Chi phí: Không lấy Phí vận chuyển đến khách, Chi phí Ads sàn
*/

    SELECT
    CAST(record_id AS STRING) AS maphieuchi,
    CAST(NULL AS STRING)      AS malenhchi,
        CAST(NULL AS STRING)  AS loaiphieu,
    CAST(initiator_department AS STRING) AS tochuc,
    CASE
        WHEN bu__bc IN (
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
    CAST(thi_truong AS STRING) AS thitruong,
    CAST(bu__bc AS STRING) AS phongban,
    CAST(danh_muc_chi_phi AS STRING) AS danhmucchiphi,
    CAST(phan_loai_chi AS STRING) AS nhomchiphi,
    CAST(loai_chi AS STRING) AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    SAFE_CAST(tien_vnd AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    SAFE_CAST(tong_chi AS NUMERIC) AS tienbandia,
    SAFE_CAST(ti_gia AS NUMERIC) AS tigia,
    CAST(don_vi_tien_te AS STRING) AS donvitiente,

    TIMESTAMP(created_time) AS ngaylenphieu,
    TIMESTAMP_MILLIS(`ngay_chuyen_tien`) AS ngaythanhtoan,

    CAST(noi_dung AS STRING) AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    IF(
      ARRAY_LENGTH(requester) > 0,
      JSON_EXTRACT_SCALAR(requester[OFFSET(0)], '$.name'),
      NULL
    ) AS requester,
    IF(
      ARRAY_LENGTH(nguoi_quan_ly) > 0,
      JSON_EXTRACT_SCALAR(nguoi_quan_ly[OFFSET(0)], '$.name'),
      NULL
    ) AS nguoiduyetphieu,

    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(NULL AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_global__tao_phieu_chi__bu`
    WHERE status = 'Approved'
    AND TIMESTAMP_MILLIS(`ngay_chuyen_tien`) > '2025-10-01'
    AND danh_muc_chi_phi IN ('CP BÁN HÀNG','QUẢN LÝ DN')
    AND phan_loai_chi NOT IN ('Lương Khối Kinh doanh BU','Lương K. VH BU','Lương K.VH Tổng Cty')
    AND loai_chi NOT IN ('Chi phí Ads sàn','Phí vận chuyển đến khách hàng')
),

src_tien_com AS (
/* 4. Nguồn chi phí: File nhập tay - Bảng Tiền cơm (Phòng Nhân sự) */
  SELECT
    CAST(NULL AS STRING) AS maphieuchi,
    CAST(NULL AS STRING) AS malenhchi,
    'Thanh toán'  AS loaiphieu,
    CAST(NULL AS STRING) AS tochuc,
    CASE
        WHEN bo_phan IN (
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
    'VN' AS thitruong,
    CAST(bo_phan AS STRING) AS phongban,
      CASE
    WHEN bo_phan IN (
      'Phòng Dịch vụ khách hàng',
      'Bộ phận Kho',
      'Bộ phận Quản trị thương hiệu ABERA',
      'Phòng Cung ứng',
      'Phòng Nhân sự',
      'Phòng Kế toán',
      'Phòng Công nghệ',
      'Phòng Giải pháp - Chiến lược'
    ) THEN 'QUẢN LÝ DN'
    ELSE 'CP BÁN HÀNG'
  END AS danhmucchiphi,

  CASE
    WHEN bo_phan IN (
      'Phòng Dịch vụ khách hàng',
      'Bộ phận Kho',
      'Bộ phận Quản trị thương hiệu ABERA'
    ) THEN 'Lương K. VH BU'
    WHEN bo_phan IN (
      'Phòng Cung ứng',
      'Phòng Nhân sự',
      'Phòng Kế toán',
      'Phòng Công nghệ',
      'Phòng Giải pháp - Chiến lược'
    ) THEN 'Lương K.VH Tổng Cty'
    ELSE 'Lương Khối Kinh doanh BU'
  END AS nhomchiphi,

  'Chế độ chính sách' AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    SAFE_CAST(tien_com AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    CAST(NULL AS NUMERIC) AS tienbandia,
    CAST(NULL AS NUMERIC) AS tigia,
    CAST(NULL AS STRING)  AS donvitiente,

    CAST(NULL AS TIMESTAMP) AS ngaylenphieu,
    TIMESTAMP(PARSE_DATE('%Y-%m', thang)) AS ngaythanhtoan,

    'Tiền cơm nhân sự' AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    CAST(NULL AS STRING) AS nguoitaophieu,
    CAST(NULL AS STRING) AS nguoiduyetphieu,
    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(NULL AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_che_do_chinh_sach__tien_com`
),

src_lark_account AS (
/* 4. Nguồn chi phí: File nhập tay - Phân bổ chi phí Lark (Phòng Kế toán) */
  SELECT
    CAST(NULL AS STRING) AS maphieuchi,
    CAST(NULL AS STRING) AS malenhchi,
        'Thanh toán'  AS loaiphieu,
    CAST(NULL AS STRING) AS tochuc,
    CASE
        WHEN bo_phan IN (
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
    CAST(thi_truong AS STRING) AS thitruong,
    CAST(bo_phan AS STRING) AS phongban,
    'QUẢN LÝ DN'      AS danhmucchiphi,
    'Công nghệ'      AS nhomchiphi,
    'Hệ thống VP Số' AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    SAFE_CAST(chi_phi_tai_khoan AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    CAST(NULL AS NUMERIC) AS tienbandia,
    CAST(NULL AS NUMERIC) AS tigia,
    CAST(NULL AS STRING)  AS donvitiente,

    CAST(NULL AS TIMESTAMP) AS ngaylenphieu,
    TIMESTAMP(PARSE_DATE('%Y-%m', thang)) AS ngaythanhtoan,

    CONCAT(
      'Tài khoản Lark cho nhân sự ',
      CAST(ten_nguoi_quan_ly AS STRING)
    ) AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    CAST(NULL AS STRING) AS nguoitaophieu,
    CAST(NULL AS STRING) AS nguoiduyetphieu,
    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(NULL AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_lark__phan_bo_tai_khoan_lark`
),

src_hoan_tra AS (
/* 4. Nguồn chi phí: File nhập tay - Điền form từ các BU*/
  WITH spend_dedup AS (
  SELECT * EXCEPT(rn)
  FROM (
    SELECT
      s.*,
      ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(s.name))
        ORDER BY s.id DESC
      ) AS rn
    FROM `hv-data.hv_money_dwh.m_spendings` s
  )
  WHERE rn = 1
)

SELECT
    CAST(NULL AS STRING) AS maphieuchi,
    CAST(NULL AS STRING) AS malenhchi,
    'Thanh toán'  AS loaiphieu,
    CAST(NULL AS STRING) AS tochuc,
    CASE
        WHEN team IN (
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
    CAST(thi_truong AS STRING) AS thitruong,
    CAST(team AS STRING) AS phongban,
    CAST(spendcat.name AS STRING) AS danhmucchiphi,
    CAST(spendtype.name AS STRING) AS nhomchiphi,
    CAST(spend.name AS STRING) AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    CAST(so_tien_hoan * -1 AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    CAST(NULL AS NUMERIC) AS tienbandia,
    CAST(NULL AS NUMERIC) AS tigia,
    CAST(NULL AS STRING)  AS donvitiente,

    CAST(NULL AS TIMESTAMP) AS ngaylenphieu,
    TIMESTAMP_MILLIS(`ngay`) AS ngaythanhtoan,

    CAST(mo_ta_noi_dung_hoan_tien AS STRING) AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    CAST(NULL AS STRING) AS nguoitaophieu,
    CAST(NULL AS STRING) AS nguoiduyetphieu,
    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(tai_khoan_nhan AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_chi_phi_hoan_tra` AS cp
      LEFT JOIN `spend_dedup` AS spend ON spend.name = cp.chi_phi 
    LEFT JOIN `hv-data.hv_money_dwh.m_spendings_types` AS spendtype ON spendtype.id = spend.spending_type_id
    LEFT JOIN `hv-data.hv_money_dwh.m_spending_categories` AS spendcat ON spendcat.id = spendtype.spending_category_id
),

src_chi_ngoai AS (
/* 5. Nguồn chi phí: File nhập tay - Điền form từ các BU */
  WITH spendtype_dedup AS (
  SELECT * EXCEPT(rn)
  FROM (
    SELECT
      s.*,
      ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(s.name))
        ORDER BY s.id DESC
      ) AS rn
    FROM `hv-data.hv_money_dwh.m_spendings_types` AS s
  )
  WHERE rn = 1
)

SELECT
    CAST(NULL AS STRING) AS maphieuchi,
    CAST(NULL AS STRING) AS malenhchi,
    'Thanh toán'  AS loaiphieu,
    CAST(NULL AS STRING) AS tochuc,
    CASE
        WHEN bo_phan IN (
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
    CAST(thi_truong AS STRING) AS thitruong,
    CAST(bo_phan AS STRING) AS phongban,
    CAST(spendcat.name AS STRING) AS danhmucchiphi,
    CAST(nhom_chi_phi AS STRING) AS nhomchiphi,
    CAST(chi_phi AS STRING) AS loaichiphi,
    CAST(NULL AS STRING) AS motaloaicp,
    CAST(so_tien_vnd AS NUMERIC) AS tienvnd,
    CAST(NULL AS NUMERIC) AS tienvat,
    CAST(so_tien_chi AS NUMERIC) AS tienbandia,
    CAST(ty_gia AS NUMERIC) AS tigia,
    CAST(NULL AS STRING)  AS donvitiente,

    CAST(NULL AS TIMESTAMP) AS ngaylenphieu,
    TIMESTAMP_MILLIS(`ngay_thanh_toan`) AS ngaythanhtoan,

    CAST(noi_dung_chi AS STRING) AS noidungchi,
    CAST(NULL AS STRING) AS noidungthanhtoan,
    CAST(NULL AS STRING) AS nguoitaophieu,
    CAST(NULL AS STRING) AS nguoiduyetphieu,
    CAST(NULL AS STRING) AS nguoichitien,
    CAST(NULL AS STRING) AS taikhoanchi,
    CAST(NULL AS STRING) AS sotaikhoanchi,
    CAST(NULL AS STRING) AS tennganhangchi,
    CAST(NULL AS STRING) AS viettatnganhangchi,
    CAST(NULL AS STRING) AS taikhoannhan,
    CAST(NULL AS STRING) AS sotaikhoannhan,
    CAST(NULL AS STRING) AS tennganhangnhan,
    CAST(NULL AS STRING) AS viettatnganhangnhan
  FROM `hv-data.lark_dwh.lark_base_chi_phi_chi_ngoai__dong_tien` AS cp
      LEFT JOIN `spendtype_dedup` AS spendtype ON spendtype.name = cp.nhom_chi_phi
    LEFT JOIN `hv-data.hv_money_dwh.m_spending_categories` AS spendcat ON spendcat.id = spendtype.spending_category_id
  WHERE bo_phan <> 'Vận hành chung'
)

SELECT * FROM src_fin
UNION ALL SELECT * FROM src_global_phieu
UNION ALL SELECT * FROM src_global_phieu_bu
UNION ALL SELECT * FROM src_tien_com
UNION ALL SELECT * FROM src_lark_account
UNION ALL SELECT * FROM src_hoan_tra
UNION ALL SELECT * FROM src_chi_ngoai

