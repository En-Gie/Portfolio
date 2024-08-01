-- Ниже приведены примеры SQL-запросов, сделанных в ходе исследования

-- ==========================================================================

SELECT p.title,
       u.id,
       p.score,
       ROUND(AVG(score) OVER (PARTITION BY u.id))
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
WHERE title IS NOT NULL
      AND score <> 0;

-- ==========================================================================

WITH
info AS
(SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN 350 >= views AND views >= 100 THEN 2
           WHEN views <= 100 THEN 3
       END AS category
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
      AND views > 0),
info_max AS      
(SELECT *,
       MAX(views) OVER (PARTITION BY category)
FROM info)

SELECT id,
       views,
       category
FROM info_max
WHERE views = max
ORDER BY views DESC, id;

-- ==========================================================================

SELECT DISTINCT u.id,
       (MIN(p.creation_date) OVER (PARTITION BY u.id)) - u.creation_date
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON p.user_id = u.id

-- ==========================================================================

SELECT u.id,
       p.creation_date,
       p.views_count,
       SUM(p.views_count) OVER (PARTITION BY u.id ORDER BY p.creation_date)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id;

-- ==========================================================================

WITH
data AS
(SELECT EXTRACT(MONTH FROM creation_date) AS month,
       COUNT(id) AS post_count
FROM stackoverflow.posts
WHERE DATE_TRUNC('day', creation_date) BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY EXTRACT(MONTH FROM creation_date))

SELECT *,
       ROUND((post_count::numeric / (LAG(post_count) OVER (ORDER BY month))) * 100, 2) - 100 AS diff
FROM data

-- ==========================================================================

WITH
top_user AS
(SELECT user_id
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY COUNT(id) DESC
LIMIT 1)

SELECT DISTINCT EXTRACT(WEEK FROM p.creation_date) AS week,
       MAX(p.creation_date) OVER (PARTITION BY EXTRACT(WEEK FROM p.creation_date)) AS latest_post
FROM stackoverflow.posts p
JOIN top_user tu ON tu.user_id = p.user_id
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'

-- ==========================================================================
