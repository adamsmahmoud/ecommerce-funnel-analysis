SELECT
  event,
  COUNT(DISTINCT visitorid) AS visitors
FROM `retail_rockets.sessions`
WHERE event IN ('view', 'addtocart', 'transaction')
GROUP BY event
