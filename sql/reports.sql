use mamaearth;
-- =========================================
-- Total orders, revenue and AOV
-- =========================================
-- Output: total_orders | total_revenue | avg_order_value
-- Output: 180          | 99860.20      | 554.78

SELECT 
    COUNT(*) AS total_orders,
    round(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100)),2) AS total_revenue,
    round(AVG(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100)),2) AS avg_order_value
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id;

-- =========================================
-- COUNT(*) vs COUNT(column)
-- =========================================
-- Output: total_rows | rated_orders | unrated_orders
-- Output: 180        | 165          | 15
  
select 
	count(*),
    count(rating),
    count(*) - count(rating)
from 
orders;

-- =========================================
-- Customers with zero orders (LEFT JOIN & NOT IN)
-- =========================================
-- Output (LEFT JOIN): customer_id | name
-- Output (LEFT JOIN): C045        | Vihaan

SELECT 
    c.customer_id,
    c.name
FROM customers c
LEFT JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id
HAVING 
    COUNT(o.order_id) = 0;

-- Output (NOT IN): customer_id | name
-- Output (NOT IN): C045        | Vihaan

SELECT 
    c.customer_id,
    c.name
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE customer_id IS NOT NULL
);

-- =========================================
-- City-level return rates (> 20%)
-- =========================================
-- Output: city      | total_orders | returned_orders | return_rate_pct
-- Output: Jaipur    | 19           | 8               | 42.1
-- Output: Lucknow   | 49           | 15              | 30.6
-- Output: Bangalore | 33           | 8               | 24.2
SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.returned) AS returned_orders,
    ROUND(100.0 * SUM(o.returned) / COUNT(o.order_id), 1) AS return_rate_pct
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY 
    c.city
HAVING 
    ROUND(100.0 * SUM(o.returned) / COUNT(o.order_id), 1) > 20
ORDER BY 
    return_rate_pct DESC;

-- =========================================
-- Customer spend ranking (LIMIT & OFFSET)
-- =========================================
-- Tie-break rule: customer_id ASC ensures deterministic sorting for customers with identical spend.

-- Top 5 Spenders
-- Output: customer_id | name    | total_spend
-- Output: C043        | Reyansh | 12920.00
-- Output: C026        | Isha    | 8371.60
-- Output: C008        | Meera   | 4564.60
-- Output: C011        | Arjun   | 4111.00
-- Output: C042        | Sanya   | 3785.00
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN products p 
    ON o.product_id = p.product_id
GROUP BY 
    c.customer_id
ORDER BY 
    total_spend DESC, 
    c.customer_id ASC
LIMIT 5;

-- Spenders ranked 3 to 5
-- Output: customer_id | name  | total_spend
-- Output: C008        | Meera | 4564.60
-- Output: C011        | Arjun | 4111.00
-- Output: C042        | Sanya | 3785.00
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN products p 
    ON o.product_id = p.product_id
GROUP BY 
    c.customer_id
ORDER BY 
    total_spend DESC, 
    c.customer_id ASC
LIMIT 3
Offset 2;

-- =========================================
-- Category revenue breakdown
-- =========================================
-- Output: category     | order_count | category_revenue
-- Output: Haircare     | 54          | 44956.10
-- Output: Skincare     | 60          | 27346.00
-- Output: Babycare     | 30          | 16805.00
-- Output: PersonalCare | 36          | 10753.10
SELECT 
    p.category,
    COUNT(o.order_id) AS order_count,
    ROUND(SUM(o.quantity * p.price * (1 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS category_revenue
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY 
    p.category
ORDER BY 
    category_revenue DESC;

-- =========================================
-- Customers starting with 'A'
-- =========================================
-- Output: customer_id | name
-- Output: Aarav
-- Output: Aditi
-- Output: Ananya
-- Output: Arjun
-- Output: Aryan
-- Output: Anika
-- Output: Aditya
-- Output: Aisha
-- Output: Ayaan
-- Output: Aria
SELECT DISTINCT
    c.name
FROM customers c
WHERE 
    c.name LIKE 'A%';

-- =========================================
-- Distinct customer acquisition sources
-- =========================================
-- Output: acquisition_source
-- Output: Ad
-- Output: Organic
-- Output: Referral
-- Output: Social

SELECT DISTINCT
    c.acquisition_source
FROM customers c;

-- =========================================
-- Add and populate loyalty tier
-- =========================================
ALTER TABLE customers
ADD COLUMN loyalty_tier VARCHAR(10);
SET SQL_SAFE_UPDATES = 0;
UPDATE customers
SET loyalty_tier = CASE 
    WHEN city_tier = 1 THEN 'Gold' 
    ELSE 'Silver' 
END;
SET SQL_SAFE_UPDATES = 1;
-- Output: loyalty_tier | COUNT(*)
-- Output: Gold         | 28
-- Output: Silver       | 17
SELECT loyalty_tier, COUNT(*) FROM customers GROUP BY loyalty_tier;
