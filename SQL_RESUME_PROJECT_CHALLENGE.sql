#SQL_RESUME_PROJECT_CODEBASICS_CHALLENGE

# TASK-1 > Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

				SELECT * FROM gdb023.dim_customer;
				# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
				select  DISTINCT market
				from dim_customer
				where customer = 'atliq exclusive' and region = "apac"; 
-- ___________________________________________________________________________________________________________________

# Task-2 > What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020,  unique_products_2021, percentage_chg

				WITH temp AS (
				SELECT COUNT(DISTINCT product_code) AS product_count,fiscal_year
				FROM fact_sales_monthly
				GROUP BY fiscal_year)
				SELECT a.product_count AS unique_products_2020, b.product_count AS unique_products_2021, 
						round((b.product_count-a.product_count)/a.product_count*100,2) AS percentage_chg
					FROM temp a
					JOIN temp b
					WHERE a.fiscal_year = 2020 and b.fiscal_year = 2021;
-- ___________________________________________________________________________________________________________________________

#Task- 3 > Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields, segment , product_count
 
				 SELECT 
					segment, count(product) AS product_count
				FROM dim_product
				GROUP BY  segment
				ORDER BY product_count DESC;
-- ____________________________________________________________________________________________________________________________

# Task- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
		-- segment product_count_2020 product_count_2021 difference 

		With temp AS (
				SELECT segment, count(DISTINCT product_code) AS product_count,fiscal_year
					FROM fact_sales_monthly s
					JOIN dim_product p
						USING (product_code)
					GROUP BY segment, fiscal_year),
			tbl AS (
				SELECT a.segment,a.product_count AS product_count_2020,b.product_count AS product_count_2021
				FROM temp a
				JOIN temp b
				USING (segment)
				WHERE a.fiscal_year =2020 AND b.fiscal_year=2021)
			SELECT segment, product_count_2020, product_count_2021,product_count_2021-product_count_2020 AS difference
			FROM tbl
            ORDER BY difference DESC;

-- _____________________________________________________________________________________________________________________
#Task-5. Get the products that have the highest and lowest manufacturing costs. 
		-- The final output should contain these fields, product_code product manufacturing_cost

SELECT p.product_code,product, ROUND(manufacturing_cost,2) AS manufacturing_cost
	FROM fact_manufacturing_cost m 
	JOIN dim_product p
		ON p.product_code= m.product_code
WHERE manufacturing_cost IN ( (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) ,
							(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost))
ORDER BY manufacturing_cost DESC;
-- ______________________________________________________________________________________________

# Task 6- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
		-- for the fiscal year 2021 and in the Indian market. 
		-- The final output contains these fields, customer_code customer average_discount_percentage

				WITH pre AS (
					SELECT customer_code, AVG(pre_invoice_discount_pct) AS average_discount_percentage
						FROM fact_pre_invoice_deductions
						WHERE fiscal_year = 2021
						GROUP BY customer_code)
				SELECT customer_code, customer, ROUND(average_discount_percentage*100,2) AS average_discount_percentage
					FROM pre  p
					JOIN dim_customer
						USING(customer_code)
					WHERE market = "India"
					   ORDER BY average_discount_percentage DESC
					   LIMIT 5;

-- _________________________________________________________________________________________
#Task-7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- 		This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
		#The final report contains these columns: Month Year Gross sales Amount 8.

			WITH temp AS (    
			SELECT MONTH(s.date) as monthnum, MONTHNAME(s.date) as month,s.fiscal_year,sold_quantity*gross_price AS gross_price
					FROM fact_sales_monthly s
					JOIN fact_gross_price
						USING (product_code,fiscal_year)
					 JOIN dim_customer c USING (customer_code)
					 WHERE c.customer = "Atliq Exclusive")
			SELECT MONTH, fiscal_year, ROUND(sum(gross_price)/1000000, 2) AS Gross_sales_Amnt_mln
			FROM temp
			GROUP BY fiscal_year, MONTH;
-- ________________________________________________________________________________________________________________________

#Task-8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- 		The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

			SELECT CONCAT("Q ",CEIL(MONTH(DATE_ADD(date, INTERVAL 4 MONTH))/3)) AS Quarter, 
					ROUND(CONCAT(SUM(sold_quantity)/1000000, " M"),2) AS total_sold
			FROM fact_sales_monthly where fiscal_year = 2020
			 GROUP BY quarter 
			 ORDER BY total_sold DESC;
			-- ________________________________________________________________________________________________________________________

			#Task-9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
			#The final output contains these fields, channel gross_sales_mln percentage

			WITH temp AS (
				SELECT c.channel,SUM(s.sold_quantity*g.gross_price) AS gross_sales
				FROM fact_sales_monthly s
				JOIN fact_gross_price g	USING (product_code)
				JOIN dim_customer c USING(customer_code)
					WHERE s.fiscal_year = 2021
					GROUP BY c.channel)
			  SELECT channel, ROUND(gross_sales/1000000,2) AS gross_sales_mln,ROUND(gross_sales/sum(gross_sales) OVER() *100,2) AS percentage
				FROM temp
				ORDER BY percentage DESC;
-- ________________________________________________________________________________________________________________________

#Task-10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- 		 The final output contains these fields, division product_code, product total_sold_quantity, rank_order
  
		WITH temp AS (
			SELECT fiscal_year, division, product_code, CONCAT(product,"(",variant,")") AS product,SUM(sold_quantity) AS total_sold_quantity
				FROM fact_sales_monthly s 
				JOIN dim_product p USING(product_code)
				GROUP BY division, product_code),
			temp2 AS (
		SELECT
			 division, product_code,product, total_sold_quantity, 
			 DENSE_RANK() OVER ( PARTITION BY division ORDER BY total_sold_quantity DESC) AS rnk
			FROM temp
			WHERE fiscal_year= 2021)
			SELECT division, product_code,product, total_sold_quantity FROM temp2
			WHERE rnk <4
			ORDER BY total_sold_quantity DESC
    