use saas_project 

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    signup_date DATE,
    segment VARCHAR(100),
    country VARCHAR(100),
    is_enterprise BOOLEAN
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  customer_id,
  @signup_date,
  segment,
  country,
  @is_enterprise
)
SET 
  signup_date =
    CASE
      WHEN @signup_date = '' THEN NULL
      ELSE STR_TO_DATE(@signup_date, '%d-%m-%Y')
    END,
  is_enterprise =
    CASE
      WHEN LOWER(@is_enterprise) = 'True' THEN 1
      WHEN LOWER(@is_enterprise) = 'False' THEN 0
      ELSE NULL
    END;


START TRANSACTION;
UPDATE customers
SET is_enterprise = 1
WHERE segment = 'Enterprise' ;
COMMIT;

START TRANSACTION;
UPDATE customers
SET is_enterprise = 0
WHERE segment in ('Mid-Market', 'SMB' , '') and segment is null 
rollback;
COMMIT;

START TRANSACTION;
UPDATE customers
SET is_enterprise = 0
WHERE is_enterprise is null 
COMMIT;

#sanity check/ data validation
select is_enterprise, count(*)
from customers
group by is_enterprise

SELECT segment, COUNT(*) 
FROM customers
GROUP BY segment


CREATE TABLE events (
    event_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    event_type VARCHAR(100),
    event_date DATETIME not null,
    source varchar(50), 
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
); 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/events.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  event_id,
  customer_id,
  event_type,
  @event_date,
  source
)
SET 
  event_date =
    CASE
      WHEN @event_date = '' THEN NULL
      ELSE STR_TO_DATE(@event_date, '%d-%m-%Y')
    END;
    
    
    
CREATE TABLE subscriptions (
    subscription_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    start_date DATE,
    end_date DATE,
    monthly_price float, 
    status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

TRUNCATE TABLE subscriptions;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/subscriptions.csv'
INTO TABLE subscriptions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  subscription_id,
  customer_id,
  @start_date,
  @end_date,
  monthly_price,
  status
)
SET
  start_date =
    CASE
      WHEN @start_date = '' THEN NULL
      ELSE STR_TO_DATE(@start_date, '%d-%m-%Y')
    END,
  end_date =
    CASE
      WHEN @end_date = '' THEN NULL
      ELSE STR_TO_DATE(@end_date, '%d-%m-%Y')
    END;



DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
  date_key DATE NOT NULL,
  year INT NOT NULL,
  quarter INT NOT NULL,
  month INT NOT NULL,
  day INT NOT NULL,
  month_start DATE NOT NULL,
  month_end DATE NOT NULL,
  PRIMARY KEY (date_key),
  KEY idx_month_start (month_start),
  KEY idx_year_month (year, month)
);

TRUNCATE TABLE dim_date;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dates.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@date_key, year, quarter, month, day, @month_start, @month_end)
SET
  date_key    = STR_TO_DATE(@date_key, '%d-%m-%Y'),
  month_start = STR_TO_DATE(@month_start, '%d-%m-%Y'),
  month_end   = STR_TO_DATE(@month_end, '%d-%m-%Y');

