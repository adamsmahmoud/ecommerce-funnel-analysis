WITH visitor_first_view AS (
  SELECT visitorid, MIN(timestamp) AS first_view_ts
  FROM `retail_rockets.events`
  WHERE event = 'view'
  GROUP BY visitorid
),
visitor_first_cart AS (
  SELECT visitorid, MIN(timestamp) AS first_cart_ts
  FROM `retail_rockets.events`
  WHERE event = 'addtocart'
  GROUP BY visitorid
),
visitor_first_purchase AS (
  SELECT visitorid, MIN(timestamp) AS first_purchase_ts
  FROM `retail_rockets.events`
  WHERE event = 'transaction'
  GROUP BY visitorid
),
visitor_carted AS (
  SELECT fc.visitorid
  FROM visitor_first_cart fc
  JOIN visitor_first_view fv ON fc.visitorid = fv.visitorid
  WHERE fc.first_cart_ts > fv.first_view_ts
),
visitor_purchased AS (
  SELECT fp.visitorid
  FROM visitor_first_purchase fp
  JOIN visitor_first_cart fc ON fp.visitorid = fc.visitorid
  WHERE fp.first_purchase_ts > fc.first_cart_ts
),
session_first_view AS (
  SELECT visitorid, session_id, MIN(timestamp) AS first_view_ts
  FROM `retail_rockets.sessions`
  WHERE event = 'view'
  GROUP BY visitorid, session_id
),
session_first_cart AS (
  SELECT visitorid, session_id, MIN(timestamp) AS first_cart_ts
  FROM `retail_rockets.sessions`
  WHERE event = 'addtocart'
  GROUP BY visitorid, session_id
),
session_first_purchase AS (
  SELECT visitorid, session_id, MIN(timestamp) AS first_purchase_ts
  FROM `retail_rockets.sessions`
  WHERE event = 'transaction'
  GROUP BY visitorid, session_id
),
session_carted AS (
  SELECT fc.visitorid, fc.session_id
  FROM session_first_cart fc
  JOIN session_first_view fv ON fc.visitorid = fv.visitorid AND fc.session_id = fv.session_id
  WHERE fc.first_cart_ts > fv.first_view_ts
),
session_purchased AS (
  SELECT fp.visitorid, fp.session_id
  FROM session_first_purchase fp
  JOIN session_first_cart fc ON fp.visitorid = fc.visitorid AND fp.session_id = fc.session_id
  WHERE fp.first_purchase_ts > fc.first_cart_ts
),
visitor_counts AS (
  SELECT 'view' AS event, COUNT(DISTINCT visitorid) AS visitor_count FROM visitor_first_view
  UNION ALL
  SELECT 'addtocart', COUNT(DISTINCT visitorid) FROM visitor_carted
  UNION ALL
  SELECT 'transaction', COUNT(DISTINCT visitorid) FROM visitor_purchased
),
session_counts AS (
  SELECT 'view' AS event, COUNT(*) AS session_count FROM session_first_view
  UNION ALL
  SELECT 'addtocart', COUNT(*) FROM session_carted
  UNION ALL
  SELECT 'transaction', COUNT(*) FROM session_purchased
)
SELECT
  vc.event,
  vc.visitor_count,
  sc.session_count
FROM visitor_counts vc
JOIN session_counts sc ON vc.event = sc.event
