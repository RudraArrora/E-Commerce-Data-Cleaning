-- =====================================================
-- E-COMMERCE DATA ANALYTICS PROJECT
-- FILE 01: DATABASE AND TABLE CREATION
-- =====================================================


-- Query 1: Create database

CREATE DATABASE IF NOT EXISTS ecommerce_project;


-- Query 2: Select database

USE ecommerce_project;


-- Query 3: Create raw sales table

CREATE TABLE IF NOT EXISTS raw_sales (

    InvoiceNo VARCHAR(20),

    StockCode VARCHAR(20),

    Description TEXT,

    Quantity INT,

    InvoiceDate VARCHAR(30),

    UnitPrice DECIMAL(12,2),

    CustomerID VARCHAR(20),

    Country VARCHAR(100)

);


-- Query 4: Verify table structure

DESCRIBE raw_sales;


-- Query 5: Verify imported records

SELECT
    COUNT(*) AS total_records
FROM raw_sales;


-- Query 6: Preview dataset

SELECT *
FROM raw_sales
LIMIT 10;