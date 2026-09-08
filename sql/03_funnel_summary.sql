WITH first_view AS (
  SELECT visitorid, MIN(timestamp) AS first_view_ts
  FROM `retail_rockets.events`
  WHERE event = 'view'
  GROUP BY visitorid
),
first_cart AS (
  SELECT visitorid, MIN(timestamp) AS first_cart_ts
  FROM `retail_rockets.events`
  WHERE event = 'addtocart'
  GROUP BY visitorid
),
first_purchase AS (
  SELECT visitorid, MIN(timestamp) AS first_purchase_ts
  FROM `retail_rockets.events`
  WHERE event = 'transaction'
  GROUP BY visitorid
),
carted AS (
  SELECT fc.visitorid
  FROM first_cart fc
  JOIN first_view fv ON fc.visitorid = fv.visitorid
  WHERE fc.first_cart_ts > fv.first_view_ts
),
purchased AS (
  SELECT fp.visitorid
  FROM first_purchase fp
  JOIN first_cart fc ON fp.visitorid = fc.visitorid
  WHERE fp.first_purchase_ts > fc.first_cart_ts
)
SELECT 'view' AS event, COUNT(DISTINCT visitorid) AS visitors FROM first_view
UNION ALL
SELECT 'addtocart' AS event, COUNT(DISTINCT visitorid) AS visitors FROM carted
UNION ALL
SELECT 'transaction' AS event, COUNT(DISTINCT visitorid) AS visitors FROM purchased
