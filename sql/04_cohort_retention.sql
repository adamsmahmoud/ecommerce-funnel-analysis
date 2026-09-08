WITH visitor_first_seen AS (
  SELECT visitorid, MIN(DATE(TIMESTAMP_MILLIS(timestamp))) AS first_seen
  FROM `retail_rockets.events`
  GROUP BY visitorid
),
cohorts AS (
  SELECT visitorid, DATE_TRUNC(first_seen, WEEK) AS cohort_week
  FROM visitor_first_seen
),
activity AS (
  SELECT DISTINCT visitorid, DATE_TRUNC(DATE(TIMESTAMP_MILLIS(timestamp)), WEEK) AS activity_week
  FROM `retail_rockets.events`
),
max_week AS (
  SELECT MAX(DATE_TRUNC(DATE(TIMESTAMP_MILLIS(timestamp)), WEEK)) AS max_week FROM `retail_rockets.events`
),
cohort_sizes AS (
  SELECT cohort_week, COUNT(DISTINCT visitorid) AS cohort_size
  FROM cohorts
  GROUP BY cohort_week
)
SELECT
  c.cohort_week,
  DATE_DIFF(a.activity_week, c.cohort_week, WEEK) AS week_number,
  COUNT(DISTINCT c.visitorid) AS active_visitors,
  cs.cohort_size,
  COUNT(DISTINCT c.visitorid) / cs.cohort_size AS retention_rate,
  DATE_DIFF(mw.max_week, c.cohort_week, WEEK) AS weeks_observable
FROM cohorts c
JOIN activity a ON c.visitorid = a.visitorid
JOIN cohort_sizes cs ON c.cohort_week = cs.cohort_week
CROSS JOIN max_week mw
GROUP BY c.cohort_week, week_number, cs.cohort_size, weeks_observable
ORDER BY c.cohort_week, week_number
