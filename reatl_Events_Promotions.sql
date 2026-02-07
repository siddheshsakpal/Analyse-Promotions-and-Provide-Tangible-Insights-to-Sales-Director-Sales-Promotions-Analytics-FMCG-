#High-Value Discounted Products
#Provide a list of products with a base price greater than 500 that are featured under the promo type ‘BOGOF’ (Buy One Get One Free).
select distinct f.product_code, p.product_name, base_price, f.promo_type from fact_events f 
join dim_products as p on f.product_code = p.product_code where base_price > 500 and promo_type = "BOGOF" ;
#Generate a report that provides an overview of the number of stores in each city, 
#sorted in descending order of store count. The report should include city and store count.
select City, count(store_id) as Total_Stores from dim_stores group by city order by Total_Stores DESC;
#Generate a report that displays each campaign along with the total revenue generated before and after the campaign. The report should include: campaign_name, total_revenue (before_promotion), and total_revenue (after_promotion). Display the values in millions.
SELECT campaign_name,concat(round(sum(base_price * `quantity_sold(before_promo)`)/1000000,2),'M')

 as `Total_Revenue(Before_Promotion)`,
concat(round(sum(
case
when promo_type = "BOGOF" then base_price * 0.5 * 2*(`quantity_sold(after_promo)`)
when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
when promo_type = "500 cashback" then (base_price-500)*  `quantity_sold(after_promo)`
end)/1000000,2),'M') as `Total_Revenue(After_Promotion)`
 FROM retail_events_db.fact_events join dim_campaigns c using (campaign_id) group by campaign_id;
#Produce a report that calculates the Incremental Sold Quantity Percentage (ISU%) for each category during the Diwali campaign. Additionally, rank the categories based on ISU%. The report should include category, isu%, and rank order.Produce a report that calculates the Incremental Sold Quantity Percentage (ISU%) for each category during the Diwali campaign. Additionally, rank the categories based on ISU%. The report should include category, isu%, and rank order.
with cte1 as(
SELECT *,(if(promo_type = "BOGOF",`quantity_sold(after_promo)` * 2 ,`quantity_sold(after_promo)`)) as quantities_sold_AP 
FROM retail_events_db.fact_events 
join dim_campaigns using(campaign_id)
join dim_products using (product_code)
where campaign_name = "Diwali" ),

cte2 as(
select 
campaign_name, category,
((sum(quantities_sold_AP) - sum(`quantity_sold(before_promo)`))/sum(`quantity_sold(before_promo)`)) * 100 as `ISU%`
 from cte1 group by category 
 )
 
 select campaign_name, category, `ISU%`, rank() over(order by `ISU%`DESC) as `ISU%_Rank` from cte2;
 
 #Create a report featuring the Top 5 products ranked by Incremental Revenue Percentage (IR%) across all campaigns. The report should include product name, category, and ir%.
 with cte1 as(
SELECT category,product_name,sum(base_price * `quantity_sold(before_promo)`) as Total_Revenue_BP,
sum(
case
when promo_type = "BOGOF" then base_price * 0.5 * 2*(`quantity_sold(after_promo)`)
when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
when promo_type = "500 cashback" then (base_price-500)*  `quantity_sold(after_promo)`
end) as Total_Revenue_AP FROM retail_events_db.fact_events 
join dim_products using (product_code) 
join dim_campaigns using(campaign_id)
group by product_name,category),

cte2 as(
select *,(total_revenue_AP - total_revenue_BP) as IR,  
((total_revenue_AP - total_revenue_BP)/total_revenue_BP) * 100 as `IR%`
from cte1)
#Create a report featuring the Top 5 products ranked by Incremental Revenue Percentage (IR%) across all campaigns. The report should include product name, category, and ir%.
select product_name,category,`IR`,`IR%`, rank() over(order by`IR%` DESC ) as Rank_IR from cte2 limit 5
