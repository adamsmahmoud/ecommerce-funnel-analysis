WITH visitor_first_seen AS (
  SELECT visitorid, MIN(DATE(TIMESTAMP_MILLIS(timestamp))) AS first_seen
  FROM `retail_rockets.events`
  GROUP BY visitorid
),
first_day_events AS (
  SELECT e.visitorid, e.event
  FROM `retail_rockets.events` e
  JOIN visitor_first_seen fs ON e.visitorid = fs.visitorid
  WHERE DATE(TIMESTAMP_MILLIS(e.timestamp)) = fs.first_seen
),
first_day_segment AS (
  SELECT
    visitorid,
    CASE
      WHEN MAX(CASE WHEN event IN ('addtocart', 'transaction') THEN 1 ELSE 0 END) = 1 THEN 'carted'
      ELSE 'viewed_only'
    END AS segment
  FROM first_day_events
  GROUP BY visitorid
),
cohorts AS (
  SELECT vfs.visitorid, DATE_TRUNC(vfs.first_seen, WEEK) AS cohort_week, fds.segment
  FROM visitor_first_seen vfs
  JOIN first_day_segment fds ON vfs.visitorid = fds.visitorid
),
activity AS (
  SELECT DISTINCT visitorid, DATE_TRUNC(DATE(TIMESTAMP_MILLIS(timestamp)), WEEK) AS activity_week
  FROM `retail_rockets.events`
),
max_week AS (
  SELECT MAX(DATE_TRUNC(DATE(TIMESTAMP_MILLIS(timestamp)), WEEK)) AS max_week FROM `retail_rockets.events`
),
cohort_sizes AS (
  SELECT cohort_week, segment, COUNT(DISTINCT visitorid) AS cohort_size
  FROM cohorts
  GROUP BY cohort_week, segment
)
SELECT
  c.cohort_week,
  c.segment,
  DATE_DIFF(a.activity_week, c.cohort_week, WEEK) AS week_number,
  COUNT(DISTINCT c.visitorid) AS active_visitors,
  cs.cohort_size,
  COUNT(DISTINCT c.visitorid) / cs.cohort_size AS retention_rate,
  DATE_DIFF(mw.max_week, c.cohort_week, WEEK) AS weeks_observable
FROM cohorts c
JOIN activity a ON c.visitorid = a.visitorid
JOIN cohort_sizes cs ON c.cohort_week = cs.cohort_week AND c.segment = cs.segment
CROSS JOIN max_week mw
GROUP BY c.cohort_week, c.segment, week_number, cs.cohort_size, weeks_observable
HAVING week_number <= weeks_observable
ORDER BY c.cohort_week, c.segment, week_number
