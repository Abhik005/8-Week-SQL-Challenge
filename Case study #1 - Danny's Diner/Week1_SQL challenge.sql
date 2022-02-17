CREATE SCHEMA dannys_diner

Use dannys_diner

Create Table sales (
 customer_id varchar(1),
 order_date date,
 product_id integer
 );
 
 Insert into sales values
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3')
  
  
  Create table menu
  ( product_id int,
    product_name varchar(5),
    price int
    )
  
INSERT INTO menu
VALUES ('1', 'sushi', '10'),
       ('2', 'curry', '15'),
        ('3', 'ramen', '12')

Create table members
( customer_id varchar(1),
 join_date date
 )
  
  Insert into members 
  Values ('A', '2021-01-07'),
          ('B', '2021-01-09')
  
  Select * from members
  Select * from menu
  Select * from sales
  
 -- 1. What is the total amount each customer spent at the restaurant?
 
   Select s.customer_id, sum(m.price) as total_price
   from sales s 
   join menu m on s.product_id = m.product_id
   group by s.customer_id
  
 -- 2. How many days has each customer visited the restaurant?
  
  Select customer_id,count(distinct(order_date)) as visit_count 
  from sales
  group by customer_id
  
  -- 3. What was the first item from the menu purchased by each customer?
  
  Select * from
  (Select s.customer_id, s.order_date, m.product_name,
  dense_rank() over (partition by s.customer_id order by s.order_date asc) as rank_num
  from sales s
  join menu m on 
  s.product_id = m.product_id ) as result 
  where rank_num = 1
  
 -- Alternate sol
  WITH ordered_sales_cte AS
(
   SELECT customer_id, order_date, product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date) AS rn
   FROM sales AS s
   JOIN menu AS m
      ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM ordered_sales_cte
WHERE rn = 1
GROUP BY customer_id, product_name
 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  
  Select Top 1 (count(s.product_id)) as most_purchased , m.product_name
  from sales s
  join menu m on s.product_id = m.product_id
  group by s.product_id, m.product_name
  order by most_purchased desc
  
 -- Alternative
 
 Select * from
 ( Select m.product_name, count(m.product_name) as most_purchased
  from sales s
  join menu m on s.product_id = m.product_id
  group by product_name) as result
  order by most_purchased desc
  limit 1
  
   -- 5. Which item was the most popular for each customer?
   
   Select * from
   ( Select s.customer_id, m.product_name, count(m.product_id) as product_count,
   dense_rank() over ( partition by s.customer_id order by count(m.product_name) desc) as rnk
   from sales s
   join menu m on s.product_id = m.product_id
   group by 1,2) as favourites
   where rnk = 1
 
 -- using CTE
 
 With favourites as (
  Select s.customer_id, m.product_name, count(m.product_id) as product_count,
   dense_rank() over ( partition by s.customer_id order by count(m.product_name) desc) as rnk
   from sales s
   join menu m on s.product_id = m.product_id
   group by s.customer_id, m.product_name
   )
   Select customer_id, product_name , product_count
   from favourites
   where rnk =1
  
  -- 6. Which item was purchased first by the customer after they became a member?
  
  Select * from
  ( Select s.customer_id, m.product_name , 
  dense_rank() over ( partition by s.customer_id order by s.order_date asc) as rn
  from sales s
  join menu m on s.product_id = m.product_id
  join members a on s.customer_id = a.customer_id
  where a.join_date <= s.order_date
  ) as first_order
  where rn=1
  
 -- using cte
 
 With First_count as 
 ( 
   Select s.customer_id, m.product_name , 
  dense_rank() over ( partition by s.customer_id order by s.order_date asc) as rn
  from sales s
  join menu m on s.product_id = m.product_id
  join members a on s.customer_id = a.customer_id
  where a.join_date <= s.order_date
  )
  Select customer_id, product_name
  from First_count
  where rn=1
  
  -- 7. Which item was purchased just before the customer became a member?
  
  Select * from
  ( Select s.customer_id,s.order_date, m.product_name,
  dense_rank() over (partition by s.customer_id order by s.order_date desc) as rn
  from sales s
  join menu m on s.product_id = m.product_id
  join members a on s.customer_id = a.customer_id
  where a.join_date > s.order_date
  ) as first_purchase
  where rn = 1
  
  -- using CTE
  
  With product_before_member as
  ( 
     Select s.customer_id,s.order_date, m.product_name,
  dense_rank() over (partition by s.customer_id order by s.order_date desc) as rn
  from sales s
  join menu m on s.product_id = m.product_id
  join members a on s.customer_id = a.customer_id
  where a.join_date > s.order_date
  ) 
  Select customer_id, product_name
  from product_before_member
  where rn = 1
  
  -- 8. What is the total items and amount spent for each member before they became a member?
  
  Select s.customer_id , count(distinct m.product_name) as unique_items,
  sum(m.price) as total_spent
  from sales s
  join menu m on s.product_id = m.product_id
  join members a on s.customer_id = a.customer_id
  where a.join_date > s.order_date
  group by s.customer_id
  
 -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 
  
  Select s.customer_id,
  sum(case when m.product_name not in ('sushi') then m.price*10 else m.price*20 end) as points
  from sales s
  join menu m
  on s.product_id = m.product_id
  group by 1
  order by 1
  
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?

SELECT s.customer_id, 
SUM(CASE WHEN s.order_date BETWEEN a.join_date AND a.special_date THEN m.price*20 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name NOT IN ('sushi') THEN m.price*10 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name IN ('sushi') THEN m.price*20 
ELSE NULL END) AS special_points
FROM 
(
	SELECT *, a.join_date + INTERVAL '1 week' AS special_date
	FROM members a
) AS a
JOIN sales s
ON s.customer_id = a.customer_id
JOIN menu m 
ON m.product_id = s.product_id
GROUP BY 1

-- alternate 
Select s.customer_id, sum(
case when s.order_date >= a.join_date
     and s.order_date < adddate(a.join_date, interval 7 day)
     then m.price*20
     else
         case 
             when m.product_id = 1 then m.price*20
             else m.price*10
		end
	end
) as new_points
from sales s
left join members a
on s.customer_id = a.customer_id
inner join menu m 
on m.product_id = s.product_id
group by s.customer_id










  
  