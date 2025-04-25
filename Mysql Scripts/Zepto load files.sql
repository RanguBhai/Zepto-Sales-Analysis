

-- Disable FK checks to avoid order issues temporarily
SET FOREIGN_KEY_CHECKS=0;

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\zepto_customers.csv"
INTO TABLE zepto_customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\zepto_product_catalog.csv"
INTO TABLE zepto_product_catalog
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\zepto_orders.csv"
INTO TABLE zepto_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\zepto_order_items.csv"
INTO TABLE zepto_order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Re-enable FK checks
SET FOREIGN_KEY_CHECKS=1;
