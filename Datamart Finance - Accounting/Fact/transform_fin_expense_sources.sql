WITH rules AS (
  -- old_spend (C1), old_type (C2)  ->  new_spend (C5), new_type (C6)
  SELECT 'Quỹ phúc lợi dự án - Team' AS old_spend, 'Quỹ phúc lợi' AS old_type,
         'Chế độ chính sách' AS new_spend, 'Lương Khối Kinh doanh BU' AS new_type
  UNION ALL SELECT 'Shopee','Tiền ads','Chi phí Ads sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Lazada','Tiền ads','Chi phí Ads sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Tiktok Shop','Tiền ads','Chi phí Ads sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Quỹ phúc lợi Cty','Quỹ phúc lợi','Chế độ chính sách','Lương Khối Kinh doanh BU'
  UNION ALL SELECT 'Nạp Ads Fb Invoie','Tiền ads','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Thuế GTGT','Thuế doanh nghiệp','Thuế VAT','Thuế VAT'
  UNION ALL SELECT 'Thuế TNDN','Thuế doanh nghiệp','Thuế TNDN','Thuế TNDN'
  UNION ALL SELECT 'Bảo hiểm xã hội','BHXH - Chi phí công đoàn','BHXH','Lương K.VH Tổng Cty'
  UNION ALL SELECT 'Chi phí công đoàn','BHXH - Chi phí công đoàn','BHXH','Lương K.VH Tổng Cty'
  UNION ALL SELECT 'Chi phí đào tạo','Chi khác','Đào tạo','Tuyển dụng & Đào tạo'
  UNION ALL SELECT 'Chi phí YEP HV Holding','Chi khác','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Zalo ads','Tiền ads','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Chiết khấu Tiktok','Tài nguyên MKT','Phí sàn & marketing sàn khác','Phí & Marketing sàn'
  UNION ALL SELECT 'Mua mới trang thiết bị','Trang thiết bị vật dụng','CCDC & Sửa chữa','Chi phí VP'
  UNION ALL SELECT 'Chi phí sửa chữa, tân trang','Trang thiết bị vật dụng','CCDC & Sửa chữa','Chi phí VP'
  UNION ALL SELECT 'Văn phòng phẩm','Trang thiết bị vật dụng','Văn phòng phẩm','Chi phí VP'
  UNION ALL SELECT 'Tiền điện','Chi phí điện-nước- hotline - VS','Năng lượng','Chi phí VP'
  UNION ALL SELECT 'Tiền nước','Chi phí điện-nước- hotline - VS','Năng lượng','Chi phí VP'
  UNION ALL SELECT 'Cước hotline','Chi phí điện-nước- hotline - VS','Năng lượng','Chi phí VP'
  UNION ALL SELECT 'Nước uống','Chi phí điện-nước- hotline - VS','Phí vận hành VP','Chi phí VP'
  UNION ALL SELECT 'Internet','Chi phí điện-nước- hotline - VS','Năng lượng','Chi phí VP'
  UNION ALL SELECT 'Chi phí vệ sinh','Chi phí điện-nước- hotline - VS','Phí vận hành VP','Chi phí VP'
  UNION ALL SELECT 'Phí đăng tin','Chi phí tuyển dụng','Tuyển dụng','Tuyển dụng & Đào tạo'
  UNION ALL SELECT 'Cước vận chuyển nội địa','Cước vận chuyển','Phí vận chuyển đến khách','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'Cước vận chuyển Quốc tế','Cước vận chuyển','Phí vận chuyển đến khách','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'Chi phí thuê kho','Chi phí kho','Chi phí lưu kho & xử lý đơn hàng','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'Băng keo','Chi phí kho','Chi phí lưu kho & xử lý đơn hàng','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'xốp khí','Chi phí kho','Chi phí lưu kho & xử lý đơn hàng','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'Chi phí hộp carton','Chi phí kho','Chi phí lưu kho & xử lý đơn hàng','Chi phí Logistics đến Khách hàng'
  UNION ALL SELECT 'Chi phí VAT','Kế toán - Nhân sự','Thuế VAT','Thuế VAT'
  UNION ALL SELECT 'Thưởng KPI Tuyển dụng','Kế toán - Nhân sự','Tuyển dụng','Tuyển dụng & Đào tạo'
  UNION ALL SELECT 'Chi phí hồ sơ pháp lý','Kế toán - Nhân sự','Chi phí pháp lý','Pháp lý & DV Thuê ngoài'
  UNION ALL SELECT 'Chi phí thuê','Chi phí mặt bằng công ty','Thuê mặt bằng','Chi phí VP'
  UNION ALL SELECT 'Trang trí Team','Trang thiết bị vật dụng','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Hoàn tiền COD','Thuế TMĐT','Chi phí hủy hàng/hết hạn','Chi phí hủy hàng/hết hạn'
  UNION ALL SELECT 'Tool Facebook','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Phí dịch vụ triển khai chiến dịch MKT sàn TMĐT','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'BM + VIA facebook','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Nuôi invoice FB','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Phí Brand Abera','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Book đơn ảo','Tài nguyên MKT','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Mua, gia hạn domain','Tài nguyên MKT','Hạ tầng CNTT','Công nghệ'
  UNION ALL SELECT 'Mua, gia hạn Driver','Thuế TMĐT','Hạ tầng CNTT','Công nghệ'
  UNION ALL SELECT 'Chi phí Lark','Chi khác','Hệ thống VP số','Công nghệ'
  UNION ALL SELECT 'Booking voice','Tài nguyên MKT','Nguyên liệu Marketing ngoài sàn','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Chụp hình Sp','Tài nguyên MKT','Nguyên liệu Marketing ngoài sàn','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Quay dựng Video','Tài nguyên MKT','Nguyên liệu Marketing ngoài sàn','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Thiết kế logo, in ấn bao bì','Tài nguyên MKT','Nguyên liệu Marketing ngoài sàn','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'booking mẫu','Tài nguyên MKT','KOL/KOC','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'book KOC, KOL','Tài nguyên MKT','KOL/KOC','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'booking livesteam','Tài nguyên MKT','KOL/KOC','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Giấy công bố sản phẩm','Tài nguyên MKT','Chi phí pháp lý','Pháp lý & DV Thuê ngoài'
  UNION ALL SELECT 'Cước vận chuyển','Chi phí kho','Phí vận chuyển hàng về kho','Phí logistics'
  UNION ALL SELECT 'Phí giao dịch ngân hàng','Chi khác','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Chi phí tiếp khách','Chi khác','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Chi phí công tác','Chi khác','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Nạp tiền TK Công ty','Chi khác','Phí hành chính khác','Chi phí VP'
  UNION ALL SELECT 'Chi phí PCN','Chi khác','Hoàn chi phí vận hành','Hoàn chi phí Vận hành'
  UNION ALL SELECT 'Chi phí hỗ trợ nghỉ việc','Chi khác','Chế độ chính sách','Lương K.VH Tổng Cty'
  UNION ALL SELECT 'Lương Dự án, Team','Lương - thưởng','Lương','Lương Khối Kinh doanh BU'
  UNION ALL SELECT 'Thưởng MKT','Lương - thưởng','Thưởng','Lương Khối Kinh doanh BU'
  UNION ALL SELECT 'Chốt thưởng','Chốt thưởng Dự Án','Thưởng','Lương Khối Kinh doanh BU'
  UNION ALL SELECT 'Thưởng TLS','Lương - thưởng','Thưởng','Lương Khối Kinh doanh BU'
  UNION ALL SELECT 'Hàng nhập khẩu','Nhập hàng','Tiền hàng sản xuất','Tiền hàng sản xuất'
  UNION ALL SELECT 'Hàng dự án','Nhập hàng','Tiền hàng sản xuất','Tiền hàng sản xuất'
  UNION ALL SELECT 'Tiền hàng NVL','Tiền hàng sản xuất','Tiền hàng sản xuất','Tiền hàng sản xuất'
  UNION ALL SELECT 'Tạm ứng thanh toán NCC','Tạm ứng thanh toán NCC','Tiền hàng sản xuất','Tiền hàng sản xuất'
  UNION ALL SELECT 'Chi phí Headhunt','Chi phí tuyển dụng','Tuyển dụng','Tuyển dụng & Đào tạo'
  UNION ALL SELECT 'Tool Titok','Tài nguyên MKT','Phí sàn & marketing sàn khác','Phí & Marketing sàn'
  UNION ALL SELECT 'Phí rút tiền từ sàn','Thuế TMĐT','Phí thanh toán','Phí & Marketing sàn'
  UNION ALL SELECT 'Thuế Tiktok','Thuế TMĐT','Phí thuế sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Thuế Shopee','Thuế TMĐT','Phí thuế sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Thuế Lazada','Thuế TMĐT','Phí thuế sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Tiktok','Tiền ads','Chi phí Ads sàn','Phí & Marketing sàn'
  UNION ALL SELECT 'Google','Tiền ads','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
  UNION ALL SELECT 'Facebook','Tiền ads','Chi phí marketing ngoài sàn khác','Chi phí Marketing ngoài sàn'
),

src_fin AS (
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
  CAST(paytrans.id AS STRING)  AS malenhchi,
  CAST(paycat.name AS STRING)  AS loaiphieu,
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
      'Phòng Giải pháp - Chiến lược',
      'Phòng Vận hành thị trường toàn cầu',
      'Bộ phận Quản trị thương hiệu ABERA'
    ) THEN 'Khối Vận hành'
    ELSE 'Khối Kinh doanh'
  END AS khoi,
  tt.name AS thitruong,
  bu.name AS phongban,

  spendcat.name AS danhmucchiphi,

  -- nhomchiphi: mapping riêng cho org=5 & tháng 10/2025
  CASE
    WHEN org.id = 5
     AND DATE(pay.payment_datetime) >= '2025-10-01'
     AND DATE(pay.payment_datetime) <  '2025-11-01'
    THEN COALESCE(r.new_type, spendtype.name)
    ELSE spendtype.name
  END AS nhomchiphi,

  -- loaichiphi: mapping riêng cho org=5 & tháng 10/2025
  CASE
    WHEN org.id = 5
     AND DATE(pay.payment_datetime) >= '2025-10-01'
     AND DATE(pay.payment_datetime) <  '2025-11-01'
    THEN COALESCE(r.new_spend, spend.name)
    ELSE spend.name
  END AS loaichiphi,

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

-- join rules theo (spend.name + spendtype.name)
LEFT JOIN rules r
  ON r.old_spend = spend.name
 AND r.old_type  = spendtype.name

WHERE pay.status_id = 3  --Chỉ lấy Phiếu ở trạng thái Đã hoàn thành
  AND pay.typeform = 1   --Chỉ lấy Phiếu đề nghị chi - Loại Thanh toán
  AND DATE(pay.payment_datetime) >= '2025-10-01'  -- Phạm vi dữ liệu lấy từ 01-10-2025
  AND (
    -- Phạm vi dữ liệu: Quỹ HV Net DNA
    (
      org.id = 3
      AND (team.id = 1105)
      AND (spendcat.id NOT IN (2,3,4)
      OR spend.id IN (1432,1361,1357,1362,1358,1356,1359,1355,1366,1368,1369,1377,1376,1373,1372))
    )

    OR

    -- Phạm vi dữ liệu: Khải Hoàn Net (lấy từ 01-10-2025)
    (
      org.id = 5
      AND (spendcat.id NOT IN (17,15,16)
      OR spendtype.id IN (1117,1119,1120)
      OR spend.id IN (1433,1440,1434,1436,1438,1439,1437,1482))
    )
  )
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
            'Phòng Giải pháp - Chiến lược',
             'Phòng Vận hành thị trường toàn cầu',
      'Bộ phận Quản trị thương hiệu ABERA'
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
    AND (danh_muc_chi_phi NOT IN ('CP BÁN HÀNG','QUẢN LÝ DN')
    OR phan_loai_chi IN ('Lương Khối Kinh doanh BU','Lương K. VH BU','Lương K.VH Tổng Cty')
    OR loai_chi = 'Phí vận chuyển đến khách hàng')
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
            'Phòng Giải pháp - Chiến lược',
            'Phòng Vận hành thị trường toàn cầu',
      'Bộ phận Quản trị thương hiệu ABERA'
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
    AND (danh_muc_chi_phi NOT IN ('CP BÁN HÀNG','QUẢN LÝ DN')
    OR phan_loai_chi IN ('Lương Khối Kinh doanh BU','Lương K. VH BU','Lương K.VH Tổng Cty')
    OR loai_chi IN ('Chi phí Ads sàn','Phí vận chuyển đến khách hàng'))
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
            'Phòng Giải pháp - Chiến lược',
            'Phòng Vận hành thị trường toàn cầu',
      'Bộ phận Quản trị thương hiệu ABERA'
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
  WHERE spendcat.name NOT IN ('CP BÁN HÀNG','QUẢN LÝ DN','PHÍ DỰ PHÒNG DN')
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
            'Phòng Giải pháp - Chiến lược',
            'Phòng Vận hành thị trường toàn cầu',
      'Bộ phận Quản trị thương hiệu ABERA'
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
  WHERE bo_phan = 'Vận hành chung'
    OR spendcat.name NOT IN ('CP BÁN HÀNG','QUẢN LÝ DN','PHÍ DỰ PHÒNG DN')
)

SELECT * FROM src_fin 
UNION ALL SELECT * FROM src_global_phieu 
UNION ALL SELECT * FROM src_global_phieu_bu 
UNION ALL SELECT * FROM src_hoan_tra 
UNION ALL SELECT * FROM src_chi_ngoai 
