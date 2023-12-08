USE danny;



-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_price
FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id 
ORDER BY total_price DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_visiting_days
FROM sales GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH cte1 AS (
SELECT s.customer_id, s.order_date, m.product_name, 
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
FROM sales s JOIN menu m
ON s.product_id = m.product_id)
SELECT customer_id, product_name, order_date FROM cte1 WHERE rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(m.product_name) AS no_of_purchases
FROM menu m JOIN sales s
ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY no_of_purchases DESC;

-- 5. Which item was the most popular for each customer?
WITH cte1 AS (
SELECT s.customer_id, m.product_name, COUNT(m.product_name) AS product_count,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS rn
FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)
SELECT customer_id, product_name, product_count FROM cte1 WHERE rn = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte1 AS (
SELECT s.customer_id, s.order_date, m.product_name, mb.join_date,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
FROM sales s JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE mb.join_date <  s.order_date)
SELECT customer_id, join_date, order_date, product_name  FROM cte1 WHERE rn = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH cte1 AS (
SELECT s.customer_id, s.order_date, m.product_name,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
FROM sales s JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE mb.join_date > s.order_date)
SELECT customer_id, order_date, product_name FROM cte1 WHERE rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(m.product_name) AS total_products, SUM(m.price) AS total_price
FROM sales s JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE mb.join_date > s.order_date
GROUP BY s.customer_id;
  
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH cte1 AS (
SELECT *,
CASE 
	WHEN m.product_name = 'sushi' THEN  m.price*20
    WHEN m.product_name <> 'sushi' THEN m.price*10
END AS points
FROM sales s JOIN menu m
USING(product_id))
SELECT customer_id, SUM(points) AS total_points FROM cte1
GROUP BY customer_id
ORDER BY total_points DESC;
  
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte1 AS (
SELECT *, 
CASE
	WHEN s.order_date > mb.join_date + 6 THEN m.price*20
    ELSE m.price*10
END AS points
FROM sales s JOIN menu m USING(product_id)
LEFT JOIN members mb USING(customer_id))
SELECT customer_id, SUM(points) AS total_points FROM cte1
WHERE MONTH(order_date) = 1 GROUP BY customer_id
ORDER BY total_points DESC;

-- Bonus 1: Join all things
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS memb
FROM sales s JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members mb 
ON s.customer_id = mb.customer_id;

-- Bonus 2: Rank all things
WITH cte1 AS (
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
	WHEN s.order_date >= mb.join_date THEN 'Y'
    ELSE 'N'
END AS memb
FROM sales s JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id)
SELECT *,
CASE  
	WHEN memb = 'N' THEN 'null'
    ELSE RANK() OVER (PARTITION BY customer_id, memb ORDER BY order_date) 
END AS ranking
FROM cte1; 


