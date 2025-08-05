-- Product Report
-- =================================================================
-- Purpose:
-- - This report consolidates key product metrics and behaviors.

-- Highlights:
-- 1. Gathers essential fields such as product name, category, subcategory, and cost.
-- 2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
-- 3. Aggregates product-level metrics:
--    - total orders
--    - total sales
--    - total quantity sold
--    - total customers (unique)
--    - lifespan (in months)
-- 4. Calculates valuable KPIs:
--    - recency (months since last sale)
--    - average order revenue (AOR)
--    - average monthly revenue
-- ===================================================================================================================================================================================================
 Create view report_product as 
with base_query as (
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1) Base Query: Retrieves  core columns from tables
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
select 
s.order_number,
s.order_date,
s.customer_key,
s.sales_amount,
s.quantity,
s.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from sales as s
left join products as p
on s.product_key = p.product_key
where s.order_date is not null),
product_aggregations as (
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2) Product Aggregations: Summarizes key metric at the product level
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
select 
product_key,
product_name,
category,
subcategory,
cost,
timestampdiff(month,min(order_date),max(order_date))as lifespan,
max(order_date) as last_sale_date,
count(distinct order_number)as total_orders,
count(distinct customer_key) as total_customers,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
round(avg(cast(sales_amount as float)/ nullif(quantity,0)),1) as avg_selling_price
from base_query
group by
product_key,
product_name,
category,
subcategory,
cost)
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3) Final Query: Combines all product results into one output
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
select
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
timestampdiff(month,last_sale_date,curdate()) asrecency_in_months,
case when total_sales>50000 then 'High-Performance'
when total_sales >=10000 then 'Mid-Range'
else 'Low-Performer'
end as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers
avg_selling_price,
-- Average Order Revenue (AOR)
case 
when total_orders = 0 then 0
else total_sales / total_orders
end as avg_order_revenue,

-- Average Monthly Revenue
case 
when lifespan = 0 then total_sales
else total_sales / lifespan
end as avg_monthly_revenue

from product_aggregations;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
select *
from report_product;








