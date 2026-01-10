# 02_data_cleaning.sql

select *
from customers 
limit 300

SELECT *
FROM customers
where signup_date is null 



START TRANSACTION;
UPDATE customers
SET segment = 'unspecified'
WHERE segment = ''

SELECT segment, COUNT(*) FROM customers GROUP BY segment;

ROLLBACK;
COMMIT;

START TRANSACTION;
UPDATE customers
SET signup_date = 'unknown'
WHERE signup_date is null 

ROLLBACK;
COMMIT;

select *
from subscriptions  
limit 300 


select *
from events 
limit 300

describe events  #to describe the table 

ALTER TABLE events
MODIFY event_date DATE