WITH visitor_summary AS (
  SELECT
    visitorid,
    COUNT(DISTINCT DATE(TIMESTAMP_MILLIS(timestamp))) AS distinct_days,
    MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS converted
  FROM `retail_rockets.sessions`
  GROUP BY visitorid
)
SELECT
  CASE WHEN distinct_days > 1 THEN 'returning' ELSE 'first_time' END AS segment,
  COUNT(*) AS total_visitors,
  SUM(converted) AS converted_visitors
FROM visitor_summary
GROUP BY segment
