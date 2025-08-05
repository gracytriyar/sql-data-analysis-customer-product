-- Customer Report
-- ============================================================
-- Purpose:
-- - This report consolidates key customer metrics and behaviors

-- Highlights:
-- 1. Gathers essential fields such as names, ages, and transaction details.
-- 2. Segments customers into categories (VIP, Regular, New) and age groups.
-- 3. Aggregates customer-level metrics:
--    - total orders
--    - total sales
--    - total quantity purchased
--    - total products
--    - lifespan (in months)
-- 4. Calculates valuable KPIs:
--    - recency (months since last order)
--    - average order value
--    - average monthly spend
-- ============================================================
 CREATE VIEW report_customers as
with base_query as(
/*--------------------------------------------------------------------------------------------
1) Base Query: Retrieves  core columns from tables
---------------------------------------------------------------------------------------*/
select 
s.order_number,
s.product_key,
s.order_date,
s.sales_amount,
s.quantity,
c.customer_key,
c.customer_number,
c.first_name,
c.last_name,
concat(c.first_name,' ',c.last_name) as customer_name,
timestampdiff(year,c.birthdate,curdate()) as age
from sales as s
left join customers as c
on c.customer_key = s.customer_key
where s.order_date is not null),
customer_aggregate as(
/*-----------------------------------------------------------------------------------------------------
 2) Customer Aggregation: Summarizes key metrics at the customer level
   ---------------------------------------------------------------------------------------*/
select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
timestampdiff(month,min(order_date),max(order_date))as lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age)
select 
customer_key,
customer_number,
customer_name,
age,
case when age<20 then 'Under 20'
	when  age between 20 and 29 then '20-29'
    when age between 30 and 39 then '30-39'
    when  age between 40 and 49 then 'Under 20'
    else '50 Above'
    end as age_group ,
case when lifespan >=12 and total_sales > 5000 then 'VIP'
	 when lifespan >=12 and total_sales <= 5000 then 'Regular'
     else 'New'
     end as customer_segment,
      last_order_date,
      timestampdiff(month,last_order_date,curdate()) as recency,
total_orders,
 total_sales,
total_quantity,
total_products,
lifespan,
-- Compuate average order value (AVO)
case when total_orders = 0 then 0
else 
total_sales / total_orders 
end as avg_order_value,
-- Compuate avg monthly spend
case when lifespan = 0 then total_sales
else total_sales/lifespan
end as avg_monthly_spend
from customer_aggregate;

select * from report_customers;



