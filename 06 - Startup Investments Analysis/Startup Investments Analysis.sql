-- Ниже приведены примеры SQL-запросов, сделанных в ходе исследования

-- ==========================================================================

WITH
i AS
(SELECT *,
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund)

SELECT activity,
       ROUND(AVG(investment_rounds)) AS average
FROM i
GROUP BY activity
ORDER BY average;

-- ==========================================================================

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE DATE_TRUNC('year', CAST(founded_at AS date)) BETWEEN '2010-01-01' AND '2012-01-01'
GROUP BY country_code
HAVING MIN(invested_companies) <> 0
ORDER BY avg DESC,
         country_code
LIMIT 10;

-- ==========================================================================

WITH
c AS
(SELECT id
FROM company
WHERE id IN
        (SELECT company_id
         FROM funding_round
         WHERE is_last_round = is_first_round 
               AND is_last_round = 1
         GROUP BY company_id)
      AND status = 'closed')
      
SELECT p.id,
       COUNT(e.instituition)
FROM c
JOIN people AS p ON p.company_id = c.id
JOIN education AS e ON e.person_id = p.id
GROUP BY p.id;

-- ==========================================================================

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       r.raised_amount AS amount
FROM investment AS i
LEFT JOIN company AS c ON c.id = i.company_id
LEFT JOIN fund AS f ON f.id = i.fund_id
JOIN (SELECT *
      FROM funding_round
      WHERE EXTRACT(YEAR FROM CAST(funded_at AS date)) IN (2012, 2013)) AS r ON r.id = i.funding_round_id
WHERE c.milestones > 6;  

-- ==========================================================================

SELECT c.name AS buyer,
       a.price_amount,
       c2.name AS bought,
       c2.funding_total,
       ROUND(a.price_amount / c2.funding_total)
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id = c.id
LEFT JOIN company AS c2 ON a.acquired_company_id = c2.id
WHERE a.price_amount <> 0 
      AND c2.funding_total <> 0
ORDER BY price_amount DESC, 
         bought
LIMIT 10;

-- ==========================================================================

SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
FROM company AS c
LEFT JOIN funding_round as fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
      AND fr.raised_amount <> 0
      AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013;

-- ==========================================================================

WITH
funds AS
    (SELECT EXTRACT(MONTH FROM fr.funded_at) AS month,
            COUNT(DISTINCT f.name) AS fund_count
    FROM funding_round AS fr
    LEFT JOIN investment AS i ON i.funding_round_id = fr.id
    LEFT JOIN fund as f ON f.id = i.fund_id
    WHERE EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2010 AND 2013
          AND country_code = 'USA'
    GROUP BY EXTRACT(MONTH FROM fr.funded_at)),
    
deals AS
    (SELECT EXTRACT(MONTH FROM acquired_at) AS month,
           COUNT(acquired_company_id) AS total_companies,
           SUM(price_amount) AS total_sum
    FROM acquisition   
    WHERE EXTRACT(YEAR FROM acquired_at) BETWEEN 2010 AND 2013
    GROUP BY EXTRACT(MONTH FROM acquired_at))

SELECT f.month,
       f.fund_count,
       d.total_companies,
       d.total_sum
FROM funds AS f
JOIN deals AS d ON d.month = f.month;

-- ==========================================================================

WITH
inv_2011 AS 
    (SELECT country_code,
           AVG(funding_total) AS avg_2011
    FROM company
    WHERE EXTRACT(YEAR FROM founded_at) BETWEEN 2011 AND 2013
    GROUP BY country_code,
             EXTRACT(YEAR FROM founded_at)
    HAVING EXTRACT(YEAR FROM founded_at) = 2011),
    
inv_2012 AS 
    (SELECT country_code,
           AVG(funding_total) AS avg_2012
    FROM company
    WHERE EXTRACT(YEAR FROM founded_at) BETWEEN 2011 AND 2013
    GROUP BY country_code,
             EXTRACT(YEAR FROM founded_at)
    HAVING EXTRACT(YEAR FROM founded_at) = 2012),
    
inv_2013 AS 
    (SELECT country_code,
           AVG(funding_total) AS avg_2013
    FROM company
    WHERE EXTRACT(YEAR FROM founded_at) BETWEEN 2011 AND 2013
    GROUP BY country_code,
             EXTRACT(YEAR FROM founded_at)
    HAVING EXTRACT(YEAR FROM founded_at) = 2013)
    
SELECT inv_2011.country_code,
       avg_2011,
       avg_2012,
       avg_2013
FROM inv_2011
JOIN inv_2012 ON inv_2012.country_code = inv_2011.country_code
JOIN inv_2013 ON inv_2013.country_code = inv_2011.country_code
ORDER BY avg_2011 DESC;

-- ==========================================================================
