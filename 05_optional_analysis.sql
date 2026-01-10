# data exploration

SELECT
  COUNT(*) AS total_subscriptions,
  SUM(end_date IS NULL) AS active_subscriptions, 
  sum(end_date is not null) as end_subscriptions
FROM subscriptions;

------------
SELECT
  COUNT(*) AS total_customers,
  SUM(segment IS NULL) AS missing_segment,
  SUM(signup_date IS NULL) AS missing_signup_date
FROM customers;

SELECT
  MIN(monthly_price) AS min_price,
  MAX(monthly_price) AS max_price,
  round(AVG(monthly_price), 2) AS avg_price
FROM subscriptions;

--
# Detect upgrade and downgrade patterns in customers
WITH ordered AS (
  SELECT
      s.*,
      LAG(monthly_price) OVER (
        PARTITION BY customer_id
        ORDER BY start_dt
      ) AS prev_price
  FROM subscriptions s
)
SELECT
    customer_id,
    start_dt,
    end_dt,
    prev_price,
    monthly_price,
    CASE
      WHEN prev_price IS NULL THEN 'first'
      WHEN monthly_price > prev_price THEN 'upgrade'
      WHEN monthly_price < prev_price THEN 'downgrade'
      ELSE 'same'
    END AS movement_type
FROM ordered
ORDER BY customer_id, start_dt;


#Rank subscriptions by monthly_price within each month (pricing analysis)
WITH active_subs AS (
  SELECT
      customer_id,
      monthly_price,
      DATE_FORMAT(start_dt, '%Y-%m-01') AS start_month
  FROM subscriptions
)
SELECT
    customer_id,
    monthly_price,
    start_month,
    RANK() OVER (PARTITION BY start_month ORDER BY monthly_price DESC) AS price_rank
FROM active_subs
ORDER BY start_month, price_rank;

# Rank customers by longest tenure
WITH tenure AS (
  SELECT
      customer_id,
      SUM(
        DATEDIFF(
          COALESCE(end_dt, CURDATE()),
          start_dt
        )
      ) AS tenure_days
  FROM subscriptions
  GROUP BY customer_id
)
SELECT
    customer_id,
    tenure_days,
    DENSE_RANK() OVER (ORDER BY tenure_days DESC) AS tenure_rank
FROM tenure
ORDER BY tenure_days DESC;


#Rank customers by total revenue (Top customers)
WITH customer_rev AS (
  SELECT
      customer_id,
      SUM(monthly_price) AS total_mrr_value
  FROM subscriptions
  GROUP BY customer_id
)
SELECT
    customer_id,
    total_mrr_value,
    DENSE_RANK() OVER (ORDER BY total_mrr_value DESC) AS revenue_rank
FROM customer_rev
ORDER BY total_mrr_value DESC;


# date based aggregation

#Monthly Signups
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS month,
  COUNT(*) AS paid_customers
FROM customers 
WHERE signup_date is not null 
GROUP BY month
ORDER BY month;


#Monthly Paid Conversions (Paid_date based)
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS month,
  COUNT(*) AS paid_customers
FROM customers c 
left join subscriptions s
on c.customer_id =  s.customer_id
WHERE end_date IS  NULL
GROUP BY month
ORDER BY month;

#Monthly Churned Customers (Customer churn_date)
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS month,
  COUNT(*) AS paid_customers
FROM customers c 
left join subscriptions s
on c.customer_id =  s.customer_id
WHERE end_date IS not NULL
GROUP BY month
ORDER BY month;

#Funnel conversion rate month-wise (Signup → Paid)
WITH signup AS (
  SELECT DATE_FORMAT(signup_date, '%Y-%m-01') AS month, COUNT(*) AS signups
  FROM customers
  WHERE signup_date IS NOT NULL
  GROUP BY month
),
paid AS (
  SELECT DATE_FORMAT(start_date, '%Y-%m-01') AS month, COUNT(*) AS paid_customers
  FROM subscriptions
  WHERE start_date IS NOT NULL
  GROUP BY month
)
SELECT
  s.month,
  s.signups,
  COALESCE(p.paid_customers,0) AS paid_customers,
  ROUND(COALESCE(p.paid_customers,0)/s.signups, 3) AS signup_to_paid_rate
FROM signup s
LEFT JOIN paid p ON p.month = s.month
ORDER BY s.month;

#Churn lag analysis (Paid → Churn)
SELECT
  DATE_FORMAT(end_date, '%Y-%m-01') AS churn_month,
  ROUND(AVG(DATEDIFF(end_date, start_date)), 1) AS avg_days_paid_to_churn,
  COUNT(*) AS churned_customers
FROM subscriptions
WHERE end_date IS NOT NULL AND start_date IS NOT NULL
GROUP BY churn_month
ORDER BY churn_month;

