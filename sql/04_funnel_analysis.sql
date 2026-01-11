 # funnel analysis
  
  WITH funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,

        MIN(CASE WHEN LOWER(e.event_type) = 'trial' THEN e.event_date END)       AS trial_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'activated' THEN e.event_date END)  AS activated_date,

        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,
        MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))   AS churn_date,

        c.segment,
        c.country
    FROM customers c
    LEFT JOIN events e
        ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s
        ON c.customer_id = s.customer_id
    GROUP BY
        c.customer_id, c.signup_date, c.segment, c.country
)

SELECT * FROM funnel;


# funnel counts + conversion rates

WITH funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'trial' THEN e.event_date END)       AS trial_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'activated' THEN e.event_date END)  AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,
        MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))   AS churn_date,
        c.segment
    FROM customers c
    LEFT JOIN events e ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.signup_date, c.segment
)

SELECT
    COUNT(*) AS signup_customers,
    SUM(trial_date IS NOT NULL) AS trial_customers,
    SUM(activated_date IS NOT NULL) AS activated_customers,
    SUM(paid_date IS NOT NULL) AS paid_customers,
    SUM(churn_date IS NOT NULL) AS churned_customers,

    -- conversions
    SUM(trial_date IS NOT NULL) / COUNT(*) AS signup_to_trial,
    SUM(activated_date IS NOT NULL) / NULLIF(SUM(trial_date IS NOT NULL), 0) AS trial_to_activated,
    SUM(paid_date IS NOT NULL) / NULLIF(SUM(activated_date IS NOT NULL), 0) AS activated_to_paid,
    SUM(churn_date IS NOT NULL) / NULLIF(SUM(paid_date IS NOT NULL), 0) AS paid_to_churn
FROM funnel;


#Funnel performance by  segment

WITH funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'trial' THEN e.event_date END)       AS trial_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'activated' THEN e.event_date END)  AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,
        MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))   AS churn_date,
        c.segment
    FROM customers c
    LEFT JOIN events e ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.signup_date, c.segment
)

SELECT
    segment,
    COUNT(*) AS signup_customers,
    SUM(trial_date IS NOT NULL) AS trial_customers,
    SUM(activated_date IS NOT NULL) AS activated_customers,
    SUM(paid_date IS NOT NULL) AS paid_customers,

    SUM(paid_date IS NOT NULL) / COUNT(*) AS signup_to_paid_conversion
FROM funnel
GROUP BY segment
ORDER BY signup_to_paid_conversion DESC;

#Acquisition source breakdown

WITH first_source AS (
    SELECT
        customer_id,
        SUBSTRING_INDEX(
            GROUP_CONCAT(source ORDER BY event_date ASC),
            ',', 1
        ) AS acquisition_source
    FROM events
    GROUP BY customer_id
),
funnel AS (
    SELECT
        c.customer_id,
        fs.acquisition_source,
        c.signup_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'trial' THEN e.event_date END)       AS trial_date,
        MIN(CASE WHEN LOWER(e.event_type) = 'activated' THEN e.event_date END)  AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date
    FROM customers c
    LEFT JOIN first_source fs ON c.customer_id = fs.customer_id
    LEFT JOIN events e ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, fs.acquisition_source, c.signup_date
)

SELECT
    acquisition_source,
    COUNT(*) AS signup_customers,
    SUM(paid_date IS NOT NULL) AS paid_customers,
    SUM(paid_date IS NOT NULL) / COUNT(*) AS signup_to_paid_conversion
FROM funnel
GROUP BY acquisition_source
ORDER BY signup_to_paid_conversion DESC;



# CUSTOMER-LEVEL FUNNEL BASE TABLE (below view is for powerbi)


DROP VIEW IF EXISTS funnel_customer;

CREATE VIEW funnel_customer AS
SELECT
    c.customer_id,
    c.signup_date,
    -- dimensions
    CASE WHEN c.segment IS NULL OR TRIM(c.segment) = '' THEN 'unknown'
         ELSE LOWER(TRIM(c.segment)) END AS segment,
    CASE WHEN c.country IS NULL OR TRIM(c.country) = '' THEN 'unknown'
         ELSE UPPER(TRIM(c.country)) END AS country,

    -- event milestones
    MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'trial' THEN e.event_date END)      AS trial_date,
    MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'activated' THEN e.event_date END) AS activated_date,

    -- subscription milestones
    MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,
    MIN(STR_TO_DATE(s.end_date,   '%Y-%m-%d')) AS churn_date

FROM customers c
LEFT JOIN events e
    ON c.customer_id = e.customer_id
LEFT JOIN subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY
    c.customer_id, c.signup_date,
    CASE WHEN c.segment IS NULL OR TRIM(c.segment) = '' THEN 'unknown'
         ELSE LOWER(TRIM(c.segment)) END,
    CASE WHEN c.country IS NULL OR TRIM(c.country) = '' THEN 'unknown'
         ELSE UPPER(TRIM(c.country)) END;


# 2) FUNNEL COUNTS + CONVERSION RATES + DROPOFFS (Overall)


SELECT
    COUNT(DISTINCT customer_id) AS signup_customers,
    COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END) AS trial_customers,
    COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END) AS activated_customers,
    COUNT(DISTINCT CASE WHEN paid_date IS NOT NULL THEN customer_id END) AS paid_customers,
    COUNT(DISTINCT CASE WHEN churn_date IS NOT NULL THEN customer_id END) AS churned_customers,

    -- Conversion Rates
    COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END)
      / NULLIF(COUNT(DISTINCT customer_id), 0) AS cr_signup_to_trial,

    COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END)
      / NULLIF(COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END), 0) AS cr_trial_to_activated,

    COUNT(DISTINCT CASE WHEN paid_date IS NOT NULL THEN customer_id END)
      / NULLIF(COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END), 0) AS cr_activated_to_paid,

    COUNT(DISTINCT CASE WHEN churn_date IS NOT NULL THEN customer_id END)
      / NULLIF(COUNT(DISTINCT CASE WHEN paid_date IS NOT NULL THEN customer_id END), 0) AS cr_paid_to_churn,

    -- Drop-offs
    COUNT(DISTINCT customer_id)
      - COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END) AS drop_signup_to_trial,

    COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END)
      - COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END) AS drop_trial_to_activated,

    COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END)
      - COUNT(DISTINCT CASE WHEN paid_date IS NOT NULL THEN customer_id END) AS drop_activated_to_paid

FROM funnel_customer;

# to understand the customer_lifecycle
WITH customer_funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,

        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'trial_start' THEN e.event_date END) AS trial_date,
        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'activated' THEN e.event_date END)   AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,

        COALESCE(
            MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'churned' THEN e.event_date END),
            MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))
        ) AS churn_date

    FROM customers c
    LEFT JOIN events e
        ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s
        ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.signup_date
)
SELECT *
FROM customer_funnel
LIMIT 20;

# to understand the customers by stage
WITH customer_funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,
        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'trial_start' THEN e.event_date END) AS trial_date,
        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'activated' THEN e.event_date END)   AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,
        COALESCE(
            MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'churned' THEN e.event_date END),
            MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))
        ) AS churn_date
    FROM customers c
    LEFT JOIN events e ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.signup_date
)

SELECT
    COUNT(DISTINCT customer_id) AS signup_customers,
    COUNT(DISTINCT CASE WHEN trial_date IS NOT NULL THEN customer_id END) AS trial_customers,
    COUNT(DISTINCT CASE WHEN activated_date IS NOT NULL THEN customer_id END) AS activated_customers,
    COUNT(DISTINCT CASE WHEN paid_date IS NOT NULL THEN customer_id END) AS paid_customers,
    COUNT(DISTINCT CASE WHEN churn_date IS NOT NULL THEN customer_id END) AS churned_customers
FROM customer_funnel;




WITH customer_funnel AS (
    SELECT
        c.customer_id,
        c.signup_date,

        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'trial_start' THEN e.event_date END) AS trial_date,
        MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'activated' THEN e.event_date END)   AS activated_date,
        MIN(STR_TO_DATE(s.start_date, '%Y-%m-%d')) AS paid_date,

        COALESCE(
            MIN(CASE WHEN LOWER(TRIM(e.event_type)) = 'churned' THEN e.event_date END),
            MIN(STR_TO_DATE(s.end_date, '%Y-%m-%d'))
        ) AS churn_date
    FROM customers c
    LEFT JOIN events e ON c.customer_id = e.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.signup_date
)

SELECT
    COUNT(DISTINCT customer_id) AS signup_customers,

    COUNT(DISTINCT CASE 
        WHEN trial_date IS NOT NULL THEN customer_id 
    END) AS trial_customers,

    COUNT(DISTINCT CASE 
        WHEN trial_date IS NOT NULL 
         AND activated_date IS NOT NULL THEN customer_id 
    END) AS activated_customers,

    COUNT(DISTINCT CASE 
        WHEN trial_date IS NOT NULL 
         AND activated_date IS NOT NULL
         AND paid_date IS NOT NULL THEN customer_id 
    END) AS paid_customers,

    COUNT(DISTINCT CASE 
        WHEN trial_date IS NOT NULL 
         AND activated_date IS NOT NULL
         AND paid_date IS NOT NULL
         AND churn_date IS NOT NULL THEN customer_id 
    END) AS churned_customers

FROM customer_funnel;