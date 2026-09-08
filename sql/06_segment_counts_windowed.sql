SELECT
  segment,
  COUNT(*) AS total_visitors,
  SUM(converted) AS converted_visitors
FROM `retail_rockets.windowed_segments`
GROUP BY segment
