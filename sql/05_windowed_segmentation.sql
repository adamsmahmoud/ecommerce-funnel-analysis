WITH first_seen AS (
  SELECT visitorid, MIN(DATE(TIMESTAMP_MILLIS(timestamp))) AS first_seen_date
  FROM `retail_rockets.events`
  GROUP BY visitorid
),
bounds AS (
  SELECT MAX(DATE(TIMESTAMP_MILLIS(timestamp))) AS max_date
  FROM `retail_rockets.events`
),
eligible AS (
  SELECT fs.visitorid, fs.first_seen_date
  FROM first_seen fs
  CROSS JOIN bounds b
  WHERE DATE_ADD(fs.first_seen_date, INTERVAL 7 DAY) <= b.max_date
),
events_dated AS (
  SELECT
    e.visitorid,
    DATE(TIMESTAMP_MILLIS(e.timestamp)) AS event_date,
    e.event
  FROM `retail_rockets.events` e
  JOIN eligible el ON e.visitorid = el.visitorid
),
label_window AS (
  SELECT ed.visitorid, ed.event_date, ed.event
  FROM events_dated ed
  JOIN eligible el ON ed.visitorid = el.visitorid
  WHERE ed.event_date BETWEEN el.first_seen_date AND DATE_ADD(el.first_seen_date, INTERVAL 7 DAY)
),
label_summary AS (
  SELECT
    visitorid,
    COUNT(DISTINCT event_date) AS distinct_days_0_7,
    MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased_in_window
  FROM label_window
  GROUP BY visitorid
),
outcome AS (
  SELECT
    ed.visitorid,
    MAX(CASE WHEN ed.event = 'transaction' THEN 1 ELSE 0 END) AS converted_after_day7
  FROM events_dated ed
  JOIN eligible el ON ed.visitorid = el.visitorid
  WHERE ed.event_date > DATE_ADD(el.first_seen_date, INTERVAL 7 DAY)
  GROUP BY ed.visitorid
)
SELECT
  el.visitorid,
  el.first_seen_date,
  ls.distinct_days_0_7,
  ls.purchased_in_window,
  CASE WHEN ls.distinct_days_0_7 >= 2 THEN 'returning' ELSE 'first_time' END AS segment,
  COALESCE(o.converted_after_day7, 0) AS converted
FROM eligible el
JOIN label_summary ls ON el.visitorid = ls.visitorid
LEFT JOIN outcome o ON el.visitorid = o.visitorid
WHERE ls.purchased_in_window = 0
