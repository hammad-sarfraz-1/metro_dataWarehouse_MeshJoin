-- Create Database
CREATE DATABASE IF NOT EXISTS METRO_DW;
USE METRO_DW;

-- 1. Staging Tables
-- Transactions Staging Table
CREATE TABLE IF NOT EXISTS transactions_staging (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    quantity_ordered INT NOT NULL
);

-- Customers Staging Table
CREATE TABLE IF NOT EXISTS customers_staging (
    customer_id INT NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    gender VARCHAR(10) NOT NULL
);

-- Products Staging Table
CREATE TABLE IF NOT EXISTS products_staging (
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL,
    supplier_id INT NOT NULL,
    supplier_name VARCHAR(255) NOT NULL
);

-- 2. Dimension Tables
-- Customers Table
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255),
    gender VARCHAR(10)
);

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    product_price DECIMAL(10, 2),
    supplier_id INT,
    supplier_name VARCHAR(255)
);

-- Stores Table
CREATE TABLE IF NOT EXISTS stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255),
    store_location VARCHAR(255)
);

-- Time Table
CREATE TABLE IF NOT EXISTS time (
    time_id INT PRIMARY KEY AUTO_INCREMENT,
    order_date DATE NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

-- 3. Fact Table
-- Sales Fact Table
CREATE TABLE IF NOT EXISTS sales_fact (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    product_id INT,
    customer_id INT,
    store_id INT,
    quantity INT NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL,
    total_sale DECIMAL(15, 2) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- 4. Insert Data into Dimensions
-- Deduplicate and insert customers
INSERT INTO customers (customer_id, customer_name, gender)
SELECT DISTINCT customer_id, customer_name, gender
FROM customers_staging;

-- Deduplicate and insert products
INSERT INTO products (product_id, product_name, product_price, supplier_id, supplier_name)
SELECT DISTINCT product_id, product_name, product_price, supplier_id, supplier_name
FROM products_staging;

-- 5. Populate Time Dimension
INSERT INTO time (order_date, month, quarter, year)
SELECT DISTINCT order_date,
       MONTH(order_date) AS month,
       QUARTER(order_date) AS quarter,
       YEAR(order_date) AS year
FROM transactions_staging;

-- 6. Populate Fact Table
INSERT INTO sales_fact (order_id, order_date, product_id, customer_id, quantity, product_price, total_sale)
SELECT ts.order_id,
       ts.order_date,
       ts.product_id,
       ts.customer_id,
       ts.quantity_ordered,
       p.product_price,
       ts.quantity_ordered * p.product_price AS total_sale
FROM transactions_staging ts
JOIN products p ON ts.product_id = p.product_id;

-- 7. Derived Views for OLAP
-- Quarterly Sales by Store View
CREATE OR REPLACE VIEW STORE_QUARTERLY_SALES AS
SELECT st.store_name,
       t.year,
       t.quarter,
       SUM(sf.total_sale) AS total_sales
FROM sales_fact sf
JOIN time t ON sf.order_date = t.order_date
JOIN stores st ON sf.store_id = st.store_id
GROUP BY st.store_name, t.year, t.quarter;

-- Yearly Revenue Rollup View
CREATE OR REPLACE VIEW YEARLY_REVENUE_ROLLUP AS
SELECT t.year,
       SUM(sf.total_sale) AS total_revenue
FROM sales_fact sf
JOIN time t ON sf.order_date = t.order_date
GROUP BY t.year;

-- Product Performance by Month View
CREATE OR REPLACE VIEW PRODUCT_MONTHLY_PERFORMANCE AS
SELECT p.product_name,
       t.month,
       t.year,
       SUM(sf.total_sale) AS total_sales
FROM sales_fact sf
JOIN products p ON sf.product_id = p.product_id
JOIN time t ON sf.order_date = t.order_date
GROUP BY p.product_name, t.month, t.year;

-- Store and Supplier Contribution View
CREATE OR REPLACE VIEW SUPPLIER_STORE_CONTRIBUTION AS
SELECT st.store_name,
       p.supplier_name,
       SUM(sf.total_sale) AS total_sales
FROM sales_fact sf
JOIN products p ON sf.product_id = p.product_id
JOIN stores st ON sf.store_id = st.store_id
GROUP BY st.store_name, p.supplier_name;

-- 8. Indexes for Query Optimization
CREATE INDEX idx_sales_fact_date ON sales_fact(order_date);
CREATE INDEX idx_sales_fact_product ON sales_fact(product_id);
CREATE INDEX idx_sales_fact_customer ON sales_fact(customer_id);

-- 9. Validation Queries
-- Count Rows in Each Table
SELECT 'sales_fact' AS table_name, COUNT(*) AS row_count FROM sales_fact
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'time', COUNT(*) FROM time;

-- Verify Fact Table Data
SELECT * FROM sales_fact LIMIT 10;

-- Verify OLAP Views
SELECT * FROM STORE_QUARTERLY_SALES LIMIT 10;
SELECT * FROM YEARLY_REVENUE_ROLLUP LIMIT 10;
SELECT * FROM PRODUCT_MONTHLY_PERFORMANCE LIMIT 10;
SELECT * FROM SUPPLIER_STORE_CONTRIBUTION LIMIT 10;

