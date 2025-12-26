-- Facebook Ads
SELECT
  'FB-ADS' as source,
  facebook_ads.account_id,
  facebook_ads.account_name,
  facebook_ads.campaign_id,
  facebook_ads.campaign_name,
  DATE(facebook_ads.date_start) as segments_date,

  facebook_ads.spend,
  facebook_ads.account_currency as currency,

-- Currency exchange 
  IF(
    facebook_ads.account_currency = 'USD',
    cur_exc.exchange_rate_facebook,
    1
  ) AS exchange_rate,

  projectx.CountryId                  AS CountryKey,
  user.bu_id                          AS BusinessUnitKey,
  campaigns_all_sources.project_id    AS ProjectKey,
  campaigns_all_sources.team_id       AS TeamKey,
  campaigns_all_sources.product_id    AS ProductKey,
  team.Management_Employee            AS MarketerEmployeeId, 

  facebook_ads.impressions,  
  facebook_ads.reach,
  facebook_ads.clicks,
  0 AS conversion,

-- Parse purchases
  (
    SELECT CAST(JSON_EXTRACT_SCALAR(action, '$.value') AS INT64)
    FROM UNNEST(actions) as action
    WHERE JSON_EXTRACT_SCALAR(action, '$.action_type') = 'purchase'
  ) as purchases,
  
  -- Parse leads (offsite_content_view_add_meta_leads)
  (
    SELECT CAST(JSON_EXTRACT_SCALAR(action, '$.value') AS INT64)
    FROM UNNEST(actions) as action
    WHERE JSON_EXTRACT_SCALAR(action, '$.action_type') = 'offsite_content_view_add_meta_leads'
  ) as leads,
  
  -- Parse add to cart
  (
    SELECT CAST(JSON_EXTRACT_SCALAR(action, '$.value') AS INT64)
    FROM UNNEST(actions) as action
    WHERE JSON_EXTRACT_SCALAR(action, '$.action_type') = 'add_to_cart'
  ) as add_to_cart,
  
  -- Parse initiate checkout
  (
    SELECT CAST(JSON_EXTRACT_SCALAR(action, '$.value') AS INT64)
    FROM UNNEST(actions) as action
    WHERE JSON_EXTRACT_SCALAR(action, '$.action_type') = 'initiate_checkout'
  ) as initiate_checkout, 
  NULL as videoViews,
  NULL as interactions
FROM `hv-data`.`facebook_ads_dwh.facebook_ads_campaign_insights` facebook_ads
LEFT JOIN `ads_dwh.campaigns_all_sources` campaigns_all_sources 
  ON facebook_ads.campaign_id = campaigns_all_sources.campaign_id and campaigns_all_sources.source = 'FB-ADS' 
LEFT JOIN `hvnet_products_dwh.us_projects_teams` team 
        ON campaigns_all_sources.team_id = team.Id
LEFT JOIN `hvnet_products_dwh.us_projects` projectx on campaigns_all_sources.project_id = projectx.Id
LEFT JOIN `hvnet_products_dwh.us_users` user on team.Management_Employee = user.UserName
LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` cur_exc 
        ON projectx.CountryId  = cur_exc.CountryId AND campaigns_all_sources.project_id = cur_exc.ProjectId 
        AND cur_exc.DateKey = CAST(FORMAT_DATE('%Y%m%d', DATE(facebook_ads.date_start)) AS INT64
)
    

UNION ALL

-- TikTok Ads
SELECT
  'TIKTOK-ADS' as source,
  tiktok_ads.account_id, 
  tiktok_ads.account_name, 
  tiktok_ads.campaign_id,
  tiktok_ads_campaign.campaign_name,
  DATE(tiktok_ads.stat_time_day) as segments_date,

  tiktok_ads.spend,
  campaigns_all_sources.currency      as currency,

  -- Currency exchange 
  IF(
    campaigns_all_sources.currency = 'USD',
    cur_exc.exchange_rate_tiktok,
    1
  ) AS exchange_rate,

  projectx.CountryId                  AS CountryKey,
  user.bu_id                          AS BusinessUnitKey,
  campaigns_all_sources.project_id    AS ProjectKey,
  campaigns_all_sources.team_id       AS TeamKey,
  campaigns_all_sources.product_id    AS ProductKey,
  team.Management_Employee            AS MarketerEmployeeId, 

  tiktok_ads.impressions,
  tiktok_ads.reach,
  tiktok_ads.clicks,
  SAFE_CAST(tiktok_ads.conversion AS INT64) as conversions,

  NULL as purchases,
  NULL as leads,
  NULL as add_to_cart,
  NULL as initiate_checkout,
  NULL as videoViews,
  NULL as interactions

FROM `tiktok_ads_dwh.tiktok_ads` tiktok_ads
LEFT JOIN `tiktok_ads_dwh.tiktok_ads_campaign` tiktok_ads_campaign 
  ON tiktok_ads.campaign_id = tiktok_ads_campaign.campaign_id
LEFT JOIN `ads_dwh.campaigns_all_sources` campaigns_all_sources 
  ON tiktok_ads.campaign_id = campaigns_all_sources.campaign_id and campaigns_all_sources.source = 'TIKTOK-ADS' 
LEFT JOIN `hvnet_products_dwh.us_projects_teams` team 
        ON campaigns_all_sources.team_id = team.Id
LEFT JOIN `hvnet_products_dwh.us_projects` projectx on campaigns_all_sources.project_id = projectx.Id
LEFT JOIN `hvnet_products_dwh.us_users` user on team.Management_Employee = user.UserName
LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` cur_exc 
        ON projectx.CountryId  = cur_exc.CountryId AND campaigns_all_sources.project_id = cur_exc.ProjectId 
        AND cur_exc.DateKey = CAST(FORMAT_DATE('%Y%m%d', DATE(tiktok_ads.stat_time_day)) AS INT64)


UNION ALL

-- Google Ads
SELECT
  'GG-ADS' as source,
  google_ads.account_id, 
  google_ads.account_name, 
  google_ads.campaign_id,
  google_ads.campaign_name,
  google_ads.segments_date,
  SUM(google_ads.metrics.costMicros) / 1000000 AS spend,
  campaigns_all_sources.currency AS currency,

  -- Currency exchange 
  IF(
    campaigns_all_sources.currency = 'USD',
    cur_exc.exchange_rate_google,
    1
  ) AS exchange_rate,

  projectx.CountryId                  AS CountryKey,
  user.bu_id                          AS BusinessUnitKey,
  campaigns_all_sources.project_id    AS ProjectKey,
  campaigns_all_sources.team_id       AS TeamKey,
  campaigns_all_sources.product_id    AS ProductKey,
  team.Management_Employee            AS MarketerEmployeeId,

  SUM(google_ads.metrics.impressions) AS impressions,
  NULL as reach,
  SUM(google_ads.metrics.interactions) AS clicks,
  SUM(google_ads.metrics.conversions) AS conversions,
  NULL as purchases,
  NULL as leads,
  NULL as add_to_cart,
  NULL as initiate_checkout,
  SUM(google_ads.metrics.videoViews) AS videoViews,
  SUM(google_ads.metrics.interactions) AS interactions
FROM `google_ad_manager_dwh.google_ad_manager_report` google_ads

LEFT JOIN `ads_dwh.campaigns_all_sources` campaigns_all_sources 
  ON google_ads.campaign_id = campaigns_all_sources.campaign_id and campaigns_all_sources.source = 'GG-ADS' 
LEFT JOIN `hvnet_products_dwh.us_projects_teams` team 
        ON campaigns_all_sources.team_id = team.Id
LEFT JOIN `hvnet_products_dwh.us_projects` projectx on campaigns_all_sources.project_id = projectx.Id
LEFT JOIN `hvnet_products_dwh.us_users` user on team.Management_Employee = user.UserName
LEFT JOIN `hv-data.hvnet_products_dwh.Currency_Exchange_currency_exchange` cur_exc 
        ON projectx.CountryId  = cur_exc.CountryId AND campaigns_all_sources.project_id = cur_exc.ProjectId 
        AND cur_exc.DateKey = CAST(FORMAT_DATE('%Y%m%d', google_ads.segments_date) AS INT64)

GROUP BY ALL