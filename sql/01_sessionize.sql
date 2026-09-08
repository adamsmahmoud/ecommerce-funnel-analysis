SELECT
  visitorid,
  timestamp,
  event,
  itemid,
  transactionid,
  SUM(new_session) OVER (
    PARTITION BY visitorid
    ORDER BY timestamp
  ) AS session_id
FROM (
  SELECT
    *,
    CASE
      WHEN timestamp - LAG(timestamp) OVER (PARTITION BY visitorid ORDER BY timestamp) > 30 * 60 * 1000
        OR LAG(timestamp) OVER (PARTITION BY visitorid ORDER BY timestamp) IS NULL
      THEN 1
      ELSE 0
    END AS new_session
  FROM `retail_rockets.events`
)
