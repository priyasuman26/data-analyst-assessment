-- ============================================================
-- 02_data_cleaning.sql
-- Purpose:
--   Basic data profiling + cleaning steps for customers,
--   subscriptions, events, and calendar table (dim_date).
--
-- Notes:
--   - This script includes some exploratory SELECTs.
--   - Data cleaning is done with explicit assumptions documented.
--   - Use transactions where we want to “test” before committing.
-- ============================================================


-- -----------------------------
-- 1) Customers table sanity check
-- -----------------------------
SELECT *
FROM customers
LIMIT 300;


-- Find customers missing signup_date
-- Assumption: signup_date is expected to be present for all/most customers.
SELECT *
FROM customers
WHERE signup_date IS NULL;



-- -----------------------------
-- 2) Standardize customer segment values
-- -----------------------------
START TRANSACTION;

-- Assumption:
--   segment = '' (blank) is missing data and should be treated as "unspecified".
UPDATE customers
SET segment = 'unspecified'
WHERE segment = '';

-- Quick distribution check before committing
SELECT segment, COUNT(*)
FROM customers
GROUP BY segment;

-- If results look correct, COMMIT. Otherwise ROLLBACK.
ROLLBACK;
COMMIT;



-- -----------------------------
-- 3) Handling missing signup_date
-- -----------------------------
START TRANSACTION;

-- WARNING / Assumption:
--   Setting a DATE field to 'unknown' is not valid and breaks date analytics.
--  
UPDATE customers
SET signup_date = 'unknown'
WHERE signup_date IS NULL;

-- Not committing because this should NOT be applied if signup_date is DATE type.
ROLLBACK;
COMMIT;



-- -----------------------------
-- 4) Subscriptions sanity check
-- -----------------------------
SELECT *
FROM subscriptions
LIMIT 300;



-- -----------------------------
-- 5) Events sanity check & schema cleanup
-- -----------------------------
SELECT *
FROM events
LIMIT 300;


-- Check schema
DESCRIBE events;  -- to describe the table


-- Assumption:
--   event_date should be stored as DATE type for time-based analysis.

ALTER TABLE events
MODIFY event_date DATE;



-- -----------------------------
-- 6) dim_date checks
-- -----------------------------
SELECT *
FROM dim_date;



-- Confirm datatype
SHOW COLUMNS FROM dim_date LIKE 'yearmonth';


-- Expanding to VARCHAR(10) 

ALTER TABLE dim_date
MODIFY COLUMN yearmonth VARCHAR(10);


-- Populate yearmonth consistently from month_start
-- Assumption:
--   dim_date.month_start is accurate and is the month bucket we want to use.
UPDATE dim_date
SET yearmonth = DATE_FORMAT(month_start, '%Y-%m');


-- Quick check
SELECT *
FROM dim_date
ORDER BY date_key
LIMIT 10;



-- -----------------------------
-- 7) Normalize subscription dates into DATE columns
-- -----------------------------
-- Assumption:
--   subscriptions.start_date and subscriptions.end_date were originally loaded as text.
--   Creating start_dt/end_dt ensures clean joins and avoids STR_TO_DATE in every metric query.
ALTER TABLE subscriptions
ADD COLUMN start_dt DATE NULL,
ADD COLUMN end_dt DATE NULL;


SELECT *
FROM subscriptions;


-- Clean blank end_date values (common CSV issue)
-- Assumption:
--   end_date = '' means no churn yet, so it should be treated as NULL.
UPDATE subscriptions
SET end_date = NULL
WHERE TRIM(end_date) = '';


-- Validation check: confirm blanks converted to NULL
SELECT COUNT(*) AS blank_end_dates
FROM subscriptions
WHERE end_date IS NULL;




-- Add index for performance on time-based joins
-- Assumption:
--   Most SaaS metrics will join by active period (start_dt/end_dt) against calendar months.
CREATE INDEX idx_sub_start_end ON subscriptions(start_dt, end_dt);

select *
from subscriptions 

UPDATE subscriptions
SET end_date = NULL
WHERE TRIM(end_date) = '';

SELECT COUNT(*) AS blank_end_dates
FROM subscriptions
WHERE end_date IS NULL;

UPDATE subscriptions
SET start_dt = STR_TO_DATE(start_date, '%Y-%m-%d'),
    end_dt   = STR_TO_DATE(end_date, '%Y-%m-%d');

UPDATE subscriptions
SET start_dt = STR_TO_DATE(start_date, '%Y-%m-%d'),
    end_dt   = CASE
                 WHEN end_date IS NULL THEN NULL
                 ELSE STR_TO_DATE(end_date, '%Y-%m-%d')
               END;

CREATE INDEX idx_sub_start_end ON subscriptions(start_dt, end_dt);


