USE ecommerce_project;


-- =====================================================
-- QUERY 1: FIND MISSING VALUES
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(CustomerID IS NULL) AS missing_customer_id,

    SUM(Description IS NULL) AS missing_description,

    SUM(InvoiceNo IS NULL) AS missing_invoice,

    SUM(Quantity IS NULL) AS missing_quantity,

    SUM(UnitPrice IS NULL) AS missing_price

FROM raw_sales;



-- =====================================================
-- QUERY 2: CHECK EMPTY DESCRIPTIONS
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(Description IS NULL) AS null_descriptions,

    SUM(TRIM(Description) = '') AS empty_descriptions,

    SUM(
        Description IS NULL
        OR TRIM(Description) = ''
    ) AS total_missing_descriptions

FROM raw_sales;



-- =====================================================
-- QUERY 3: IDENTIFY DUPLICATE RECORDS
-- =====================================================

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,

    COUNT(*) AS duplicate_count

FROM raw_sales

GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;



-- =====================================================
-- QUERY 4: COUNT TOTAL DUPLICATE ROWS
-- =====================================================

SELECT
    COALESCE(
        SUM(duplicate_count - 1),
        0
    ) AS total_duplicate_rows

FROM (
    SELECT
        COUNT(*) AS duplicate_count

    FROM raw_sales

    GROUP BY
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country

    HAVING COUNT(*) > 1

) AS duplicates;



-- =====================================================
-- QUERY 5: IDENTIFY INVALID QUANTITIES AND PRICES
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(Quantity < 0) AS negative_quantity,

    SUM(Quantity = 0) AS zero_quantity,

    SUM(UnitPrice < 0) AS negative_price,

    SUM(UnitPrice = 0) AS zero_price

FROM raw_sales;



-- =====================================================
-- QUERY 6: IDENTIFY CANCELLED TRANSACTIONS
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(
        InvoiceNo LIKE 'C%'
    ) AS cancelled_transactions,

    SUM(
        InvoiceNo NOT LIKE 'C%'
    ) AS non_cancelled_transactions

FROM raw_sales;



-- =====================================================
-- QUERY 7: COMPARE CANCELLATIONS AND NEGATIVE QUANTITIES
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(
        InvoiceNo LIKE 'C%'
        AND Quantity < 0
    ) AS cancelled_negative_quantity,

    SUM(
        InvoiceNo NOT LIKE 'C%'
        AND Quantity < 0
    ) AS negative_without_cancellation,

    SUM(
        InvoiceNo LIKE 'C%'
        AND Quantity >= 0
    ) AS cancellation_without_negative

FROM raw_sales;



-- =====================================================
-- QUERY 8: CHECK INVOICE DATE FORMAT
-- =====================================================

SELECT
    InvoiceDate,

    COUNT(*) AS total_records

FROM raw_sales

GROUP BY InvoiceDate

ORDER BY InvoiceDate

LIMIT 10;



-- =====================================================
-- QUERY 9: PREVIEW DATE CONVERSION
-- =====================================================

SELECT
    InvoiceNo,

    InvoiceDate,

    STR_TO_DATE(
        InvoiceDate,
        '%d/%m/%y %H:%i'
    ) AS cleaned_invoice_date

FROM raw_sales

LIMIT 10;



-- =====================================================
-- CHECK WHETHER CLEANED TABLE ALREADY EXISTS
-- =====================================================

SHOW TABLES LIKE 'cleaned_sales';



-- =====================================================
-- QUERY 10: CREATE CLEANED SALES TABLE
-- ACTUAL DATA CLEANING HAPPENS HERE
-- =====================================================

CREATE TABLE IF NOT EXISTS cleaned_sales AS

SELECT DISTINCT

    TRIM(InvoiceNo) AS InvoiceNo,

    TRIM(StockCode) AS StockCode,

    TRIM(Description) AS Description,

    Quantity,

    STR_TO_DATE(
        InvoiceDate,
        '%d/%m/%y %H:%i'
    ) AS InvoiceDate,

    UnitPrice,

    NULLIF(
        TRIM(CustomerID),
        ''
    ) AS CustomerID,

    TRIM(Country) AS Country,

    ROUND(
        Quantity * UnitPrice,
        2
    ) AS Revenue

FROM raw_sales

WHERE
    InvoiceNo IS NOT NULL

    AND TRIM(InvoiceNo) <> ''

    AND InvoiceNo NOT LIKE 'C%'

    AND Quantity > 0

    AND UnitPrice > 0

    AND Description IS NOT NULL

    AND TRIM(Description) <> '';



-- =====================================================
-- QUERY 11: VERIFY CLEANED DATA
-- =====================================================

SELECT
    COUNT(*) AS total_cleaned_records,

    ROUND(
        SUM(Revenue),
        2
    ) AS total_revenue,

    COUNT(DISTINCT InvoiceNo)
        AS total_orders,

    COUNT(DISTINCT CustomerID)
        AS total_customers

FROM cleaned_sales;



-- =====================================================
-- QUERY 12: FINAL DATA QUALITY VALIDATION
-- =====================================================

SELECT
    COUNT(*) AS total_records,

    SUM(
        CustomerID IS NULL
        OR TRIM(CustomerID) = ''
    ) AS missing_customer_ids,

    SUM(
        Description IS NULL
        OR TRIM(Description) = ''
    ) AS missing_descriptions,

    SUM(
        Quantity <= 0
    ) AS invalid_quantities,

    SUM(
        UnitPrice <= 0
    ) AS invalid_prices,

    SUM(
        InvoiceNo LIKE 'C%'
    ) AS cancelled_transactions,

    SUM(
        InvoiceDate IS NULL
    ) AS invalid_dates,

    SUM(
        Revenue <= 0
    ) AS invalid_revenue

FROM cleaned_sales;



-- =====================================================
-- QUERY 13: COMPARE RAW AND CLEANED RECORD COUNTS
-- =====================================================

SELECT
    (SELECT COUNT(*)
     FROM raw_sales) AS raw_records,

    (SELECT COUNT(*)
     FROM cleaned_sales) AS cleaned_records,

    (
        (SELECT COUNT(*)
         FROM raw_sales)

        -

        (SELECT COUNT(*)
         FROM cleaned_sales)

    ) AS removed_records;