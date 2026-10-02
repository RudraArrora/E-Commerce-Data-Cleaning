USE ecommerce_project;


-- ==========================================
-- SECTION 1: SALES ANALYSIS
-- ==========================================

-- Query 1: Total Revenue

SELECT
    COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
FROM cleaned_sales;


-- Query 2: Total Orders

SELECT
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM cleaned_sales;


-- Query 3: Average Order Value

SELECT
    COALESCE(
        ROUND(
            SUM(Revenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
            2
        ),
        0
    ) AS average_order_value
FROM cleaned_sales;


-- Query 4: Total Units Sold

SELECT
    COALESCE(SUM(Quantity), 0) AS total_units_sold
FROM cleaned_sales;



-- ==========================================
-- SECTION 2: TIME-BASED ANALYSIS
-- ==========================================

-- Query 5: Monthly Revenue

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
    COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
FROM cleaned_sales
GROUP BY sales_month
ORDER BY sales_month;


-- Query 6: Monthly Orders

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM cleaned_sales
GROUP BY sales_month
ORDER BY sales_month;


-- Query 7: Month-over-Month Revenue Growth

SELECT
    sales_month,
    monthly_revenue,
    previous_month_revenue,

    ROUND(
        (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS growth_percentage

FROM (
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM (
        SELECT
            DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
            SUM(Revenue) AS monthly_revenue
        FROM cleaned_sales
        GROUP BY sales_month
    ) AS monthly_sales
) AS growth_data

ORDER BY sales_month;


-- ==========================================
-- SECTION 3: PRODUCT ANALYSIS
-- ==========================================

-- Query 8: Top 10 Products by Revenue

SELECT
    StockCode,
    MAX(Description) AS product_name,
    COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
FROM cleaned_sales
GROUP BY StockCode
ORDER BY total_revenue DESC
LIMIT 10;


-- Query 9: Top 3 Products by Revenue Using DENSE_RANK

SELECT *
FROM (
    SELECT
        StockCode,
        product_name,
        total_revenue,

        DENSE_RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS product_rank

    FROM (
        SELECT
            StockCode,
            MAX(Description) AS product_name,
            COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
        FROM cleaned_sales
        GROUP BY StockCode
    ) AS product_sales

) AS ranked_products

WHERE product_rank <= 3
ORDER BY product_rank;


-- Query 10: Top 10 Products by Quantity Sold

SELECT
    StockCode,
    MAX(Description) AS product_name,
    COALESCE(SUM(Quantity), 0) AS units_sold
FROM cleaned_sales
GROUP BY StockCode
ORDER BY units_sold DESC
LIMIT 10;



-- ==========================================
-- SECTION 4: GEOGRAPHIC ANALYSIS
-- ==========================================

-- Query 11: Revenue by Country

SELECT
    Country,
    COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
FROM cleaned_sales
GROUP BY Country
ORDER BY total_revenue DESC;


-- Query 12: Top 3 Countries by Revenue Using DENSE_RANK

SELECT *
FROM (
    SELECT
        Country,
        total_revenue,

        DENSE_RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS country_rank

    FROM (
        SELECT
            Country,
            COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_revenue
        FROM cleaned_sales
        GROUP BY Country
    ) AS country_sales

) AS ranked_countries

WHERE country_rank <= 3
ORDER BY country_rank;



-- ==========================================
-- SECTION 5: CUSTOMER ANALYSIS
-- ==========================================

-- Query 13: Total Unique Customers

SELECT
    COUNT(DISTINCT CustomerID) AS total_customers
FROM cleaned_sales;


-- Query 14: Top 10 Customers by Spending

SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    COALESCE(ROUND(SUM(Revenue), 2), 0) AS total_spending
FROM cleaned_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_spending DESC
LIMIT 10;


-- Query 15: Repeat vs One-Time Customers

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS customer_type,

    COUNT(*) AS total_customers

FROM (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS total_orders
    FROM cleaned_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
) AS customer_orders

GROUP BY customer_type;