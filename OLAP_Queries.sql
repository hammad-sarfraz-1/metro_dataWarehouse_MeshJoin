-- Query 1: Product Revenue by Day Type
SELECT 
    p.product_name,
    CASE 
        WHEN DAYOFWEEK(sf.order_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    MONTH(sf.order_date) AS month,
    SUM(sf.total_sale) AS total_revenue
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
WHERE 
    YEAR(sf.order_date) = 2019
GROUP BY 
    p.product_name, day_type, MONTH(sf.order_date)
ORDER BY 
    total_revenue DESC
LIMIT 5;

-- Query 2: Quarterly Sales and Growth Rate by Store
SELECT 
    p.store_name,
    QUARTER(sf.order_date) AS quarter,
    SUM(sf.total_sale) AS quarterly_sales,
    ROUND(
        (SUM(sf.total_sale) - LAG(SUM(sf.total_sale)) OVER (PARTITION BY p.store_name ORDER BY QUARTER(sf.order_date))) / 
        LAG(SUM(sf.total_sale)) OVER (PARTITION BY p.store_name ORDER BY QUARTER(sf.order_date)) * 100, 
        2
    ) AS growth_rate
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
WHERE 
    YEAR(sf.order_date) = 2017
GROUP BY 
    p.store_name, QUARTER(sf.order_date)
ORDER BY 
    p.store_name, quarter;

-- Query 3: Total Sales by Store, Supplier, and Product
SELECT 
    p.store_name,
    p.supplier_name,
    p.product_name,
    SUM(sf.total_sale) AS total_sales
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
GROUP BY 
    p.store_name, p.supplier_name, p.product_name
ORDER BY 
    p.store_name, p.supplier_name, p.product_name;

-- Query 4: Seasonal Sales by Product
SELECT 
    p.product_name,
    CASE 
        WHEN MONTH(sf.order_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(sf.order_date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(sf.order_date) IN (9, 10, 11) THEN 'Fall'
        ELSE 'Winter'
    END AS season,
    SUM(sf.total_sale) AS total_sales
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
GROUP BY 
    p.product_name, season
ORDER BY 
    p.product_name, season;

-- Query 5: Monthly Volatility in Revenue
SELECT 
    p.store_name,
    p.supplier_name,
    MONTH(sf.order_date) AS month,
    SUM(sf.total_sale) AS monthly_revenue,
    ROUND(
        IFNULL(
            (SUM(sf.total_sale) - LAG(SUM(sf.total_sale)) OVER (PARTITION BY p.store_name, p.supplier_name ORDER BY MONTH(sf.order_date))) /
            LAG(SUM(sf.total_sale)) OVER (PARTITION BY p.store_name, p.supplier_name ORDER BY MONTH(sf.order_date)) * 100, 
            0
        ), 
        2
    ) AS volatility
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
WHERE 
    YEAR(sf.order_date) = 2019
GROUP BY 
    p.store_name, p.supplier_name, MONTH(sf.order_date)
ORDER BY 
    p.store_name, p.supplier_name, month;

-- Query 6: Frequently Bought Together Products
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS frequency
FROM 
    sales_fact sf1
JOIN 
    sales_fact sf2 ON sf1.order_id = sf2.order_id AND sf1.product_id < sf2.product_id
JOIN 
    products p1 ON sf1.product_id = p1.product_id
JOIN 
    products p2 ON sf2.product_id = p2.product_id
GROUP BY 
    p1.product_name, p2.product_name
ORDER BY 
    frequency DESC
LIMIT 5;

-- Query 7: Revenue by Store, Supplier, and Product over Time
SELECT 
    p.store_name,
    p.supplier_name,
    p.product_name,
    YEAR(sf.order_date) AS year,
    SUM(sf.total_sale) AS total_revenue
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
GROUP BY 
    p.store_name, p.supplier_name, p.product_name, YEAR(sf.order_date)
UNION ALL
SELECT 
    p.store_name,
    p.supplier_name,
    NULL AS product_name,
    NULL AS year,
    SUM(sf.total_sale) AS total_revenue
FROM 
    sales_fact sf
JOIN 
    products p ON sf.product_id = p.product_id
GROUP BY 
    p.store_name, p.supplier_name
ORDER BY 
    1, 2, 3, 4;

