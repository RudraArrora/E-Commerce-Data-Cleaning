# E-Commerce Sales Analytics (MySQL)

An end-to-end SQL project on e-commerce transaction data: load raw data, clean it, and answer business questions about revenue, products, countries and customers.

## Project Overview

| Item | Detail |
|---|---|
| Tool | MySQL |
| Dataset | Online Retail transactions (UCI Online Retail dataset) |
| Raw table | `raw_sales` |
| Clean table | `cleaned_sales` |
| Skills shown | Data cleaning, aggregation, subqueries, window functions (`LAG`, `DENSE_RANK`), NULL-safe calculations |

### Raw columns

| Column | Meaning |
|---|---|
| InvoiceNo | Order number. Starts with `C` if the order was cancelled |
| StockCode | Product code |
| Description | Product name |
| Quantity | Units bought (negative for returns) |
| InvoiceDate | Date and time of the order (stored as text in raw) |
| UnitPrice | Price per unit |
| CustomerID | Customer identifier (many are missing) |
| Country | Customer's country |

## Project Structure

```
01_data_creation.sql      -> create database and raw table
02_data_cleaning.sql      -> check data quality, build cleaned_sales
03_company_analytics.sql  -> business analysis on cleaned_sales
```

Run the files in order. Import the CSV into `raw_sales` after running file 01.

---

## File 01: Data Creation (`01_data_creation.sql`)

Sets up the database and the empty raw table. Every column is kept in a loose type (dates as text) so the CSV imports without errors. Conversion happens later during cleaning.

| Query | What it does |
|---|---|
| Query 1 | Creates the database `ecommerce_project` if it does not already exist |
| Query 2 | Selects that database so all later statements run inside it |
| Query 3 | Creates the `raw_sales` table with the 8 source columns. `InvoiceDate` is `VARCHAR` on purpose, so the import never fails on date formats |
| Query 4 | `DESCRIBE raw_sales` shows column names and types to confirm the table was built correctly |
| Query 5 | Counts rows in `raw_sales` to confirm the CSV import loaded fully |
| Query 6 | Shows the first 10 rows as a quick sanity check on the imported data |

---

## File 02: Data Cleaning (`02_data_cleaning.sql`)

Follows the standard approach: **inspect problems first, fix them, then validate.**

### Part A: Data quality checks (on `raw_sales`)

| Query | What it does | Why it matters |
|---|---|---|
| Query 1: Missing values | Counts NULLs in CustomerID, Description, InvoiceNo, Quantity and UnitPrice | Shows which columns have gaps. CustomerID is usually the largest |
| Query 2: Empty descriptions | Counts NULL descriptions, blank (`''`) descriptions, and the total of both | Imports often store blanks as empty text instead of NULL, so checking only NULL misses them |
| Query 3: Duplicate records | Groups by all columns and lists rows that appear more than once, with the count | Finds exact repeated rows |
| Query 4: Total duplicate rows | Adds up the extra copies (`count - 1` for each duplicate group) | Gives the number of rows that would be removed. `COALESCE` returns 0 if there are none |
| Query 5: Invalid quantities and prices | Counts negative and zero values in Quantity and UnitPrice | Negative or zero values are returns, adjustments or bad data, not real sales |
| Query 6: Cancelled transactions | Counts invoices starting with `C` vs the rest | Cancelled orders should not count as revenue |
| Query 7: Cancellations vs negative quantity | Cross-checks the cancellation flag against negative quantity (cancelled and negative, negative but not cancelled, cancelled but not negative) | Tests whether the two signals overlap, so you know if one filter is enough |
| Query 8: Invoice date format | Lists distinct raw date strings with counts | Lets you see the actual date format before converting |
| Query 9: Preview date conversion | Tests `STR_TO_DATE(InvoiceDate, '%d/%m/%y %H:%i')` on 10 rows | Confirms the conversion works before applying it to the whole table |

### Part B: Build the clean table

| Query | What it does |
|---|---|
| Check table exists | `SHOW TABLES LIKE 'cleaned_sales'` checks whether the clean table is already there |
| Query 10: Create `cleaned_sales` | The actual cleaning step (details below) |

**Cleaning rules applied in Query 10:**

1. `SELECT DISTINCT` removes exact duplicate rows
2. `TRIM()` removes extra spaces from InvoiceNo, StockCode, Description and Country
3. `STR_TO_DATE()` converts the text date into a real `DATETIME`
4. `NULLIF(TRIM(CustomerID), '')` turns blank CustomerIDs into proper NULLs
5. Adds a new column `Revenue = ROUND(Quantity * UnitPrice, 2)`
6. Filters out rows where:
   - InvoiceNo is missing or blank
   - InvoiceNo starts with `C` (cancelled)
   - Quantity is 0 or negative
   - UnitPrice is 0 or negative
   - Description is missing or blank

### Part C: Validation

| Query | What it does |
|---|---|
| Query 11: Verify cleaned data | Shows total rows, total revenue, distinct orders and distinct customers in `cleaned_sales` |
| Query 12: Final validation | Re-runs the problem checks on the clean table. Every count should be `0`, except missing customer IDs, which is a deliberate choice (see Assumptions) |
| Query 13: Raw vs cleaned | Compares row counts and shows how many records were removed |

---

## File 03: Company Analytics (`03_company_analytics.sql`)

All queries run on `cleaned_sales`. `COALESCE` and `NULLIF` are used so empty results or zero denominators never break a calculation.

### Section 1: Sales Analysis

| Query | Business question | How it works |
|---|---|---|
| Query 1: Total Revenue | How much money did we make? | `SUM(Revenue)` over all rows |
| Query 2: Total Orders | How many orders were placed? | `COUNT(DISTINCT InvoiceNo)`. Distinct is needed because one order has many line items |
| Query 3: Average Order Value (AOV) | How much does an average order bring in? | Total revenue divided by distinct orders. `NULLIF` avoids divide-by-zero |
| Query 4: Total Units Sold | How many items were sold? | `SUM(Quantity)` |

### Section 2: Time-Based Analysis

| Query | Business question | How it works |
|---|---|---|
| Query 5: Monthly Revenue | How does revenue change month to month? | `DATE_FORMAT(InvoiceDate, '%Y-%m')` makes a month label, then groups and sums revenue |
| Query 6: Monthly Orders | How does order volume change month to month? | Same grouping, but counts distinct invoices |
| Query 7: Month-over-Month Growth | Is revenue growing or shrinking, and by how much? | Three nested layers: (1) monthly revenue, (2) `LAG()` pulls the previous month's revenue onto the same row, (3) growth % = (current - previous) / previous x 100. The first month shows NULL since it has no previous month |

### Section 3: Product Analysis

| Query | Business question | How it works |
|---|---|---|
| Query 8: Top 10 Products by Revenue | Which products earn the most? | Groups by StockCode, sums revenue, sorts descending, takes 10. `MAX(Description)` picks one name per product since descriptions can vary |
| Query 9: Top 3 Products (DENSE_RANK) | Who are the top 3 products, handling ties properly? | `DENSE_RANK()` ranks products by revenue without skipping numbers after ties, then keeps rank 3 or better. Unlike `LIMIT 3`, it returns all tied products |
| Query 10: Top 10 Products by Quantity | Which products sell the most units? | Same as Query 8 but ranks by `SUM(Quantity)`. A product can be high in units but low in revenue (cheap items) |

### Section 4: Geographic Analysis

| Query | Business question | How it works |
|---|---|---|
| Query 11: Revenue by Country | Which markets matter most? | Groups by Country and sums revenue |
| Query 12: Top 3 Countries (DENSE_RANK) | Which 3 countries lead? | Same ranking pattern as Query 9, applied to countries |

### Section 5: Customer Analysis

| Query | Business question | How it works |
|---|---|---|
| Query 13: Total Unique Customers | How many known customers do we have? | `COUNT(DISTINCT CustomerID)`. NULLs are ignored automatically |
| Query 14: Top 10 Customers by Spending | Who are our best customers? | Groups by CustomerID (excluding NULLs), counts orders, sums spending, sorts descending |
| Query 15: Repeat vs One-Time Customers | How loyal are our customers? | The inner query counts orders per customer. The outer query labels customers with 1 order as "One-Time" and the rest as "Repeat", then counts each group |

---

## Key Assumptions and Decisions

- **Cancelled orders are excluded.** Any InvoiceNo starting with `C` is removed, so revenue reflects completed sales only. Returns are not netted off.
- **Exact duplicates are removed** with `SELECT DISTINCT`. Some may be genuine repeated line items, so this is a simplifying assumption.
- **Rows with missing CustomerID are kept.** They count towards revenue, orders and product/country analysis, but are excluded from customer-level metrics (Queries 13 to 15).
- **Zero or negative price and quantity rows are removed** as non-sales (adjustments, write-offs, data errors).
- **Rows with no description are removed.**
- **Date format** is assumed to be `dd/mm/yy hh:mm`. Verify against your data (Query 8 and 9 in file 02) before running the clean step. If dates come out NULL, the format string needs changing.
- `CREATE TABLE IF NOT EXISTS cleaned_sales` will not rebuild an existing table. Run `DROP TABLE cleaned_sales;` first if you change the cleaning rules.

## Results Summary

*Fill these in from your own query outputs.*

| Metric | Value |
|---|---|
| Raw records | |
| Cleaned records | |
| Records removed (%) | |
| Total revenue | |
| Total orders | |
| Average order value | |
| Total customers | |
| Top country (share of revenue) | |
| Top product | |
| Peak revenue month | |
| Repeat customers (%) | |

### Key Insights

*Write 3 to 5 findings here, for example:*

1. Which country drives most revenue, and what % share does it hold?
2. Which months peak, and is there seasonality?
3. What % of customers are repeat buyers, and how much more do they spend?
4. Are the top products high-volume low-price items or high-value items?

## How to Run

1. Run `01_data_creation.sql` to create the database and `raw_sales`.
2. Import the dataset CSV into `raw_sales` (MySQL Workbench Table Data Import Wizard).
3. Run `02_data_cleaning.sql` to inspect issues and build `cleaned_sales`.
4. Run `03_company_analytics.sql` to generate the business metrics.
