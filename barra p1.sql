create database barra;
use barra;

-- Change over time

select year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from sales 
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date);

-- cummulative Analysis
-- calculate the total sales per month and running total of sales over time.

select 
	order_year,
	order_month,
	total_sales,
	sum(total_sales) over(partition by order_year,order_month order by order_year,order_month) as running_total_sales 
from (
     select 
			year(order_date) as order_year,
			month(order_date) as order_month,
			sum(sales_amount) as total_sales
from sales 
where order_date is not null
group by year(order_date), month(order_date)
)as f;

-- Performance Analysis
--  analyze the yearly performance of products by comparing each product's sales to 
-- both its average sales performance and the previous year's sales.
with yearly_product_sales as (select year(s.order_date) as order_date,
p.product_id, p.product_name, round(sum(s.sales_amount),0) as current_sales
from products as p
join sales as s
on p.product_key = s.product_key
where year(s.order_date) is not null
group by year(s.order_date),
p.product_id, p.product_name
order by year(s.order_date))
select order_date, product_name,
current_sales,round(avg(current_sales)over(partition by product_name),0)as avg_sales,
current_sales - round(avg(current_sales)over(partition by product_name),0) as diff_avg,
case when current_sales - round(avg(current_sales)over(partition by product_name),0)>0 then
'Above avg' 
when current_sales - round(avg(current_sales)over(partition by product_name),0)<0 then
'Below avg' else 'AVG'
end avg_change,
lag(current_sales)over(partition by product_name order by order_date) as pvs_year_sales,
current_sales - lag(current_sales)over(partition by product_name order by order_date) as diff_py,
case when current_sales - lag(current_sales)over(partition by product_name order by order_date)>0 then 'Increase'
when current_sales - lag(current_sales)over(partition by product_name order by order_date) <0 then 'Decrease'
else 'No change'
end py_change
from yearly_product_sales
group by order_date, product_name,
current_sales;

-- Part to Whole Analysis
-- Which categories contribute the most to overall sales

with totals as (select p.category , sum(s.sales_amount) as total_sales
from products as p
join sales as s
on s.product_key = p.product_key
group by p.category)
select category , total_sales,sum(total_sales)over() overall_sales,
concat(round((total_sales/sum(total_sales)over())*100,2),'%')as percentage_contri
from totals
order by total_sales desc;

-- Data Segmentation
-- Segment products into cost ranges and count how many products fall into each segment.

with product_segments as (
select product_key,product_name,cost,
case when cost <100 then 'Below 100'
when cost between 100  and 500 then '100-500'
when cost between 500 and 1000 then '500-1000'
else 'Above 1000'
end cost_range
from products)
select cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc;




