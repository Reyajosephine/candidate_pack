-- Data & AI Challenge: SQL statements copied from analysis.ipynb
-- This is a separate query file. The supplied queries_template.sql is not modified.
-- Run against the in-memory SQLite database created in Step 22 of analysis.ipynb.
-- clean_orders is loaded in Step 22; products is loaded in Step 29.

-- STEP 23: Monthly revenue SQL
WITH monthly_sales AS (

    SELECT
        strftime('%Y-%m', order_date_clean) AS sales_month,

        MIN(order_date_clean) AS first_transaction_date,
        MAX(order_date_clean) AS last_transaction_date,

        COUNT(DISTINCT order_id) AS total_transactions,

        COUNT(DISTINCT order_date_clean) AS active_sales_days,

        SUM(quantity) AS total_units_sold,

        SUM(revenue_inr) AS total_revenue,

        AVG(revenue_inr) AS average_transaction_value

    FROM clean_orders

    WHERE status = 'completed'

    GROUP BY strftime('%Y-%m', order_date_clean)
),

revenue_comparison AS (

    SELECT
        *,

        LAG(total_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT
    sales_month,
    first_transaction_date,
    last_transaction_date,
    active_sales_days,
    total_transactions,
    total_units_sold,
    total_revenue,
    ROUND(average_transaction_value, 2)
        AS average_transaction_value,

    ROUND(
        total_revenue - previous_month_revenue, 2
    ) AS revenue_change,

    ROUND(
        100.0 * (
            total_revenue - previous_month_revenue
        ) / NULLIF(previous_month_revenue, 0),
        2
    ) AS revenue_growth_percentage

FROM revenue_comparison

ORDER BY sales_month;


-- STEP 26: Verify that the products lookup table is available
SELECT * FROM products LIMIT 5;


-- STEP 26: Top 10 products by revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(c.quantity) AS total_units_sold,
    COUNT(DISTINCT c.order_id) AS total_orders,
    ROUND(SUM(c.revenue_inr), 2) AS total_revenue,
    ROUND(
        100.0 * SUM(c.revenue_inr) /
        (SELECT SUM(revenue_inr) FROM clean_orders),
        2
    ) AS revenue_contribution_percentage
FROM clean_orders c
JOIN products p
    ON c.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- STEP 27: Compare product revenue between August and September
SELECT
    p.product_id,
    p.product_name,
    p.category,

    SUM(CASE
        WHEN strftime('%m', c.order_date_clean) = '08'
        THEN c.revenue_inr ELSE 0
    END) AS august_revenue,

    SUM(CASE
        WHEN strftime('%m', c.order_date_clean) = '09'
        THEN c.revenue_inr ELSE 0
    END) AS september_revenue,

    SUM(CASE
        WHEN strftime('%m', c.order_date_clean) = '09'
        THEN c.revenue_inr ELSE 0
    END)
    -
    SUM(CASE
        WHEN strftime('%m', c.order_date_clean) = '08'
        THEN c.revenue_inr ELSE 0
    END) AS revenue_change

FROM clean_orders c
JOIN products p
    ON c.product_id = p.product_id

GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue_change ASC;


-- STEP 28: Analyze new versus repeat customers
WITH ranked_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date_clean,
        revenue_inr,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date_clean, order_id
        ) AS order_number
    FROM clean_orders
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN order_number = 1 THEN 'New'
            ELSE 'Repeat'
        END AS customer_type
    FROM ranked_orders
)

SELECT
    strftime('%Y-%m', order_date_clean) AS sales_month,
    customer_type,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(revenue_inr), 2) AS total_revenue,
    ROUND(AVG(revenue_inr), 2) AS average_order_revenue

FROM customer_segments

GROUP BY
    strftime('%Y-%m', order_date_clean),
    customer_type

ORDER BY
    sales_month,
    customer_type;


-- STEP 29: Investigate why Laptop 16 revenue declined
SELECT
    strftime('%Y-%m', order_date_clean) AS sales_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_inr), 2) AS total_revenue,
    ROUND(AVG(unit_price), 2) AS average_unit_price
FROM clean_orders
WHERE product_id = 'P010'
GROUP BY strftime('%Y-%m', order_date_clean)
ORDER BY sales_month;


-- STEP 30: Validate monthly data coverage
SELECT
    strftime('%Y-%m', order_date_clean) AS sales_month,
    MIN(order_date_clean) AS first_order_date,
    MAX(order_date_clean) AS last_order_date,
    COUNT(DISTINCT order_date_clean) AS active_sales_days,
    COUNT(DISTINCT order_id) AS total_orders
FROM clean_orders
GROUP BY strftime('%Y-%m', order_date_clean)
ORDER BY sales_month;
