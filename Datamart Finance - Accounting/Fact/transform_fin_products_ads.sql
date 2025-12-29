WITH Calc AS (
  SELECT
    tt.CountryCode AS thitruong,
    bu.name AS bu_phongban,

    -- yyyy-mm từ DateKey (INT64 hoặc STRING 'yyyymmdd')
    CONCAT(
      SUBSTR(CAST(ads.DateKey AS STRING), 1, 4),
      '-',
      SUBSTR(CAST(ads.DateKey AS STRING), 5, 2)
    ) AS thang,

    -- Channel (tương đương CROSS APPLY)
    CASE
      WHEN ads.PlatformId = 1 AND ads.IsEcom is true THEN 'TikTok Shop'
      WHEN ads.PlatformId = 1 AND ads.IsEcom is false THEN 'TikTok Landing'
      WHEN ads.PlatformId = 2 THEN 'Google'
      WHEN ads.PlatformId = 3 THEN 'Facebook'
      WHEN ads.PlatformId = 5 THEN 'Zalo'
      WHEN ads.PlatformId = 6 THEN 'TMĐT'
      WHEN ads.PlatformId = 4 THEN 'Other'
      ELSE 'Others'
    END AS Channel,

    -- Rate (tương đương CROSS APPLY)
    CASE
      WHEN ads.Currency = 'VND' THEN 1.0
      WHEN ads.Currency = 'USD' AND ads.PlatformId = 1 THEN ex.exchange_rate_tiktok
      WHEN ads.Currency = 'USD' AND ads.PlatformId = 2 THEN ex.exchange_rate_google
      WHEN ads.Currency = 'USD' AND ads.PlatformId = 3 THEN ex.exchange_rate_facebook
      WHEN ads.Currency = 'USD' AND ads.PlatformId IN (4,6) THEN ex.exchange_rate_other
      ELSE 1.0
    END AS Rate,

    ads.AdsFeeTotal
  FROM `hv-data.hvnet_products_dwh.Pd_Products_Ads_pd_products_ads` AS ads
  LEFT JOIN `hv-data.hvnet_products_dwh.us_projects_teams` t
    ON t.Id = ads.TeamId
  LEFT JOIN `hv-data.hvnet_products_dwh.us_users` u
    ON t.Management_Employee = u.UserName
  LEFT JOIN `hv-data.hvnet_products_dwh.us_countries` AS tt
    ON tt.CountryId = ads.CountryId
  LEFT JOIN `hv-data.hvnet_products_dwh.us_bussiness_units` AS bu
    ON bu.Id = u.bu_id
  LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` AS ex
    ON CAST(ex.DateKey AS STRING) = CAST(ads.DateKey AS STRING)
   AND ex.ProjectId = ads.ProjectId
  WHERE CAST(ads.DateKey AS INT64) >= 20251001
    AND bu.name IS NOT NULL
)

SELECT
  thitruong,
  bu_phongban,
  thang,
  Channel,
  CAST(SUM(AdsFeeTotal * Rate) AS INT64) AS amount,

  -- ===== CHI TIẾT =====
  CASE
    WHEN Channel IN ('TikTok Shop', 'TMĐT')
    THEN 'Chi phí Ads sàn'
    ELSE 'Chi phí Ads các kênh social'
  END AS chitiet,

  -- ===== NHÓM =====
  CASE
    WHEN Channel IN ('TikTok Shop', 'TMĐT')
    THEN 'Phí sàn & marketing sàn'
    ELSE 'Chi phí Marketing ngoài sàn'
  END AS nhom,

  -- ===== DANH MỤC =====
  'CP BÁN HÀNG' AS danhmuc,

  -- ===== MỤC =====
  'Chi phí' AS muc

FROM Calc
GROUP BY
  thitruong,
  bu_phongban,
  thang,
  Channel,
  chitiet,
  nhom
ORDER BY
  thitruong,
  bu_phongban,
  thang,
  Channel;
