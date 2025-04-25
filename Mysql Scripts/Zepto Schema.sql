DROP  DATABASE Zepto;

create database Zepto;
use Zepto;

-- Customers Table
CREATE TABLE zepto_customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    signup_date DATE
);

-- Orders Table

CREATE TABLE zepto_orders (
    order_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE,
    order_amount DECIMAL(10, 2),
    month_id INT,
    year_id INT,
    FOREIGN KEY (customer_id) REFERENCES zepto_customers(customer_id)
);


-- Product Catalog Table
CREATE TABLE zepto_product_catalog (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10, 2)
);

-- Order Items Table

CREATE TABLE zepto_order_items (
    order_item_id varchar(20),
    order_id VARCHAR(15),
    product_id VARCHAR(10),
    quantity INT,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES zepto_orders(order_id),
    FOREIGN KEY (product_id) REFERENCES zepto_product_catalog(product_id)
);
