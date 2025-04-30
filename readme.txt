README - METRO Data Warehouse Project
________________


1. Project Overview
The METRO Data Warehouse (DW) project is a scalable system designed to store, process, and analyze transactional and master data from METRO stores in Pakistan. It centralizes raw data from various sources, integrates it using the MESHJOIN algorithm, and organizes it into a Star Schema to support OLAP (Online Analytical Processing) queries. The final processed data enables actionable business insights, such as revenue trends, customer behavior, and supplier performance.
________________


2. Prerequisites

Before running the project, ensure you meet the following prerequisites:
1. Database Environment:
   * Install MySQL or a compatible relational database management system.
   * Set up MySQL Workbench or a terminal-based SQL client to execute scripts.

2. Java Environment:
   * Install JDK 8 or higher for running the ETL pipeline.
   * Add the MySQL JDBC driver (mysql-connector-java-X.X.X.jar) to your Java classpath.

3. Data Files:
   * Ensure the raw CSV files (transactions.csv, customers.csv, products.csv) are available for staging.
________________


3. Setting Up the Database

1. Create the Database:
Use the metro_dw_dump.sql script to create the database and schema. Run the following in your MySQL environment:
	SOURCE /path/to/metro_dw_dump.sql;

2. Verify Schema:
   * Ensure the following tables exist in the METRO_DW database:
      * sales_fact, customers, products, transactions_staging, customers_staging, products_staging.
      * Views: STORE_QUARTERLY_SALES, YEARLY_REVENUE_ROLLUP.

3. Load Data into Staging Tables:
Import raw data from CSV files into staging tables using the following commands:

	LOAD DATA INFILE '/path/to/transactions.csv' 
	INTO TABLE transactions_staging
	FIELDS TERMINATED BY ',' 
	LINES TERMINATED BY '\n';


	LOAD DATA INFILE '/path/to/customers.csv' 
	INTO TABLE customers_staging
	FIELDS TERMINATED BY ',' 
	LINES TERMINATED BY '\n';


	LOAD DATA INFILE '/path/to/products.csv' 
	INTO TABLE products_staging
	FIELDS TERMINATED BY ',' 
	LINES TERMINATED BY '\n';
   * ________________


4. Running the ETL Process

1. Set Up the Java Project:
   * Include the following Java files in your project:
      * DatabaseConnection.java
      * MeshJoin.java
      * main.java

2. Compile the Project:
Use a Java IDE (e.g., IntelliJ, Eclipse) or compile using the terminal:


javac -cp .:mysql-connector-java-X.X.X.jar main.java

3. Run the ETL Process:
Execute the compiled project:

java -cp .:mysql-connector-java-X.X.X.jar main
   * This will perform the following steps:
      * Process raw data in staging tables.
      * Load master data (products, customers) into dimension tables.
      * Populate the sales_fact table with enriched transactional data.
4. Output:
   * The sales_fact table will be populated, and OLAP views will be ready for analysis.
________________


5. Performing OLAP Queries

1. Predefined OLAP Views:
   * Query the views to analyze aggregated data:
Quarterly Sales by Store:
        SELECT * FROM STORE_QUARTERLY_SALES LIMIT 10;
Yearly Revenue Rollup:
        SELECT * FROM YEARLY_REVENUE_ROLLUP LIMIT 10;
      * 2. Custom Queries:
   * Craft custom OLAP queries to analyze the data. Examples:
	Top Products by Revenue:

	SELECT p.product_name, SUM(sf.total_sale) AS total_revenue
	FROM sales_fact sf
	JOIN products p ON sf.product_id = p.product_id
	GROUP BY p.product_name
	ORDER BY total_revenue DESC
	LIMIT 10;
      * Supplier Contribution:

	SELECT p.supplier_name, SUM(sf.total_sale) AS total_sales
	FROM sales_fact sf
	JOIN products p ON sf.product_id = p.product_id
	GROUP BY p.supplier_name
	ORDER BY total_sales DESC;
      * ________________


6. Verifying Results

After running the ETL and OLAP queries, validate the results:
1. Fact Table Validation:
Check that the sales_fact table is populated correctly:
        SELECT * FROM sales_fact LIMIT 10;
2. View Validation:
Ensure that predefined views return meaningful results:
        SELECT * FROM STORE_QUARTERLY_SALES LIMIT 10;
	SELECT * FROM YEARLY_REVENUE_ROLLUP LIMIT 10;
3. Row Counts:
Verify row counts for all tables:
	SELECT COUNT(*) FROM sales_fact;
	SELECT COUNT(*) FROM customers;
	SELECT COUNT(*) FROM products;
