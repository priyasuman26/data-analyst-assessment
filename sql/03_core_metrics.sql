# MRR

  WITH month_calendar AS (
  SELECT DISTINCT month_start
  FROM dim_date
)
SELECT
    mc.month_start AS mrr_month,
    COALESCE(SUM(COALESCE(s.monthly_price,0)), 0) AS mrr
FROM month_calendar mc
LEFT JOIN subscriptions s
  ON s.start_date <= LAST_DAY(mc.month_start)
 AND (s.end_date IS NULL OR s.end_date >= mc.month_start)
WHERE mc.month_start BETWEEN
    (SELECT DATE_FORMAT(MIN(start_date), '%Y-%m-01')
     FROM subscriptions
     WHERE start_date IS NOT NULL)
    AND DATE_FORMAT(CURDATE(), '%Y-%m-01')
GROUP BY mc.month_start
ORDER BY mc.month_start;

# ARR

WITH month_calendar AS (
  SELECT DISTINCT month_start
  FROM dim_date
)
SELECT
    mc.month_start AS arr_month,
    COALESCE(SUM(s.monthly_price), 0) * 12 AS arr
FROM month_calendar mc
LEFT JOIN subscriptions s
  ON s.start_date <= LAST_DAY(mc.month_start)
 AND (s.end_date IS NULL OR s.end_date >= mc.month_start)
WHERE mc.month_start BETWEEN
    (SELECT DATE_FORMAT(MIN(start_date), '%Y-%m-01')
     FROM subscriptions
     WHERE start_date IS NOT NULL)
    AND DATE_FORMAT(CURDATE(), '%Y-%m-01')
GROUP BY mc.month_start
ORDER BY mc.month_start;

#churn

WITH month_calendar AS (
  SELECT DISTINCT month_start
  FROM dim_date
),
churned AS (
  SELECT
      DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
      COUNT(DISTINCT customer_id) AS customers_lost
  FROM subscriptions
  WHERE end_date IS NOT NULL
  GROUP BY churn_month
),
active_base AS (
  SELECT
      mc.month_start,
      COUNT(DISTINCT s.customer_id) AS active_customers
  FROM month_calendar mc
  LEFT JOIN subscriptions s
    -- customer must be active at start of month
    ON s.start_date < mc.month_start
   AND (s.end_date IS NULL OR s.end_date >= mc.month_start)
  GROUP BY mc.month_start
)

SELECT
    mc.month_start AS churn_month,
    COALESCE(c.customers_lost, 0) AS customers_lost,
    COALESCE(a.active_customers, 0) AS active_customers,
    CASE 
      WHEN COALESCE(a.active_customers, 0) = 0 THEN 0
      ELSE COALESCE(c.customers_lost, 0) / a.active_customers
    END AS logo_churn_rate
FROM (SELECT DISTINCT month_start FROM dim_date) mc
LEFT JOIN churned c
  ON c.churn_month = mc.month_start
LEFT JOIN active_base a
  ON a.month_start = mc.month_start
WHERE mc.month_start BETWEEN
    (SELECT DATE_FORMAT(MIN(start_date), '%Y-%m-01')
     FROM subscriptions
     WHERE start_date IS NOT NULL)
    AND DATE_FORMAT(CURDATE(), '%Y-%m-01')
ORDER BY mc.month_start;

# revenue churn

WITH month_calendar AS (
  SELECT DISTINCT month_start
  FROM dim_date
  WHERE month_start <= DATE_FORMAT(CURDATE(), '%Y-%m-01')
),

mrr_start AS (
  -- MRR at the START of each month (active before month_start)
  SELECT
      mc.month_start,
      COALESCE(SUM(s.monthly_price), 0) AS mrr_at_start
  FROM month_calendar mc
  LEFT JOIN subscriptions s
    ON s.start_date < mc.month_start
   AND (s.end_date IS NULL OR s.end_date >= mc.month_start)
  GROUP BY mc.month_start
),

mrr_lost AS (
  -- MRR LOST in that month (subscriptions that ended in that month)
  SELECT
      DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
      COALESCE(SUM(monthly_price), 0) AS mrr_lost
  FROM subscriptions
  WHERE end_date IS NOT NULL
  GROUP BY churn_month
)

SELECT
    ms.month_start AS churn_month,
    ms.mrr_at_start,
    COALESCE(ml.mrr_lost, 0) AS mrr_lost,
    ROUND(
      CASE WHEN ms.mrr_at_start = 0 THEN 0
           ELSE COALESCE(ml.mrr_lost, 0) / ms.mrr_at_start
      END
    , 2) AS revenue_churn_rate,
    ROUND(
      CASE WHEN ms.mrr_at_start = 0 THEN 0
           ELSE (COALESCE(ml.mrr_lost, 0) / ms.mrr_at_start) * 100
      END
    , 2) AS revenue_churn_rate_pct
FROM mrr_start ms
LEFT JOIN mrr_lost ml
  ON ml.churn_month = ms.month_start
WHERE ms.month_start BETWEEN
    (SELECT DATE_FORMAT(MIN(start_date), '%Y-%m-01')
     FROM subscriptions
     WHERE start_date IS NOT NULL)
    AND DATE_FORMAT(CURDATE(), '%Y-%m-01')
  AND ms.mrr_at_start > 0
ORDER BY churn_month;



# Average Revenue per Customer (ARPC)

WITH month_calendar AS (
  SELECT DISTINCT month_start
  FROM dim_date
  WHERE month_start <= DATE_FORMAT(CURDATE(), '%Y-%m-01')
)

SELECT
    mc.month_start AS arpc_month,

    -- total MRR in the month
    COALESCE(SUM(s.monthly_price), 0) AS mrr,

    -- active customers in the month
    COUNT(DISTINCT s.customer_id) AS active_customers,

    -- ARPC
    ROUND(
      CASE 
        WHEN COUNT(DISTINCT s.customer_id) = 0 THEN 0
        ELSE COALESCE(SUM(s.monthly_price), 0) / COUNT(DISTINCT s.customer_id)
      END
    , 2) AS arpc

FROM month_calendar mc
LEFT JOIN subscriptions s
  ON s.start_date <= LAST_DAY(mc.month_start)
 AND (s.end_date IS NULL OR s.end_date >= mc.month_start)

WHERE mc.month_start BETWEEN
    (SELECT DATE_FORMAT(MIN(start_date), '%Y-%m-01')
     FROM subscriptions
     WHERE start_date IS NOT NULL)
    AND DATE_FORMAT(CURDATE(), '%Y-%m-01')

GROUP BY mc.month_start
ORDER BY mc.month_start;
