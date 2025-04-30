# README - METRO Data Warehouse Project

---

## 1. Project Overview

The METRO Data Warehouse (DW) project is a scalable system designed to store, process, and analyze transactional and master data from METRO stores in Pakistan. It centralizes raw data from various sources, integrates it using the MESHJOIN algorithm, and organizes it into a Star Schema to support OLAP (Online Analytical Processing) queries. The final processed data enables actionable business insights, such as revenue trends, customer behavior, and supplier performance.

---

## 2. Prerequisites

Before running the project, ensure you meet the following prerequisites:

### 1. Database Environment:
   * Install MySQL or a compatible relational database management system.
   * Set up MySQL Workbench or a terminal-based SQL client to execute scripts.

### 2. Java Environment:
   * Install JDK 8 or higher for running the ETL pipeline.
   * Add the MySQL JDBC driver (`mysql-connector-java-X.X.X.jar`) to your Java classpath.

### 3. Data Files:
   * Ensure the raw CSV files (`transactions.csv`, `customers.csv`, `products.csv`) are available for staging.

---

## 3. Setting Up the Database

### 1. Create the Database:
Use the `metro_dw_dump.sql` script to create the database and schema. Run the following in your MySQL environment:

```sql
SOURCE /path/to/metro_dw_dump.sql;
