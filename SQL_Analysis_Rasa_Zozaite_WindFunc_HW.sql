/*Task 1
Create a query to produce a sales report highlighting the top customers with the highest sales across 
different sales channels. This report should list the top 5 customers for each channel. 
Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
which represents the percentage of a customer's sales relative to the total sales within their 
respective channel.*/

-- I used ctes because I found it more comfortable to work with and it was clearer to present logic. And I kinda started to like ctes. 
-- I didnt use here, but I was thinking about CREATE VIEW or CREATE FUNCTION with parameters for more rerunnable and reusable code, because it ismore comfortable to use as a function and retrieve information as a view in a perspective. 


WITH cust_channel_totals AS (															-- order to aggregate per customer/channel and compute channel total
  SELECT
    s.channel_id, 
    s.cust_id, 
    SUM(s.amount_sold)										AS cust_total,  				-- computing each customer’s total sales in that channel
    SUM(SUM(s.amount_sold))OVER (PARTITION BY s.channel_id)	AS channel_total     		-- the inner SUM(...) gives cust_total. The outer sum adds up all customer totals within the same channel, giving the channel’s overall sales
  FROM sh.sales s 
  GROUP BY 
    s.channel_id, 
    s.cust_id
),
ranked_customers AS (																-- ranking within each channel  
  SELECT
    cct.channel_id, 
    cct.cust_id,
    cct.cust_total,
    cct.channel_total,
    ROW_NUMBER()OVER (PARTITION BY cct.channel_id ORDER BY cct.cust_total DESC )AS rn 								-- assigning a unique rank to each row within a partition; used row, because rank would assign customers with the same 	
  FROM cust_channel_totals cct
)
SELECT 																		--final query 
  		ch.channel_desc, 
  		cu.cust_last_name,
  		cu.cust_first_name,
  		TO_CHAR(rc.cust_total,   'FM99999990.00')   							AS total_sales,   		-- turning a numeric value into a formatted string
  		TO_CHAR((rc.cust_total / rc.channel_total) * 100,'FM990.0000') || '%'	AS sales_percentage   					-- calculating KPI, adding % symbol
FROM ranked_customers rc 
INNER	JOIN sh.channels  ch ON rc.channel_id = ch.channel_id 											-- inner, because I need customers and channels that actually exist and have data
INNER	JOIN sh.customers cu ON rc.cust_id    = cu.cust_id
WHERE rc.rn <= 5       																-- top 5 per channel customers
ORDER BY
	ch.channel_desc ASC,
	total_sales DESC;

 		
  		

/*Task 2
Create a query to retrieve data for a report that displays the total sales for all products in 
the Photo category in the Asian region for the year 2000. 
Calculate the overall report total and name it 'YEAR_SUM'*/

/*Display the sales amount with two decimal places
Display the result in descending order of 'YEAR_SUM'
For this report, consider exploring the use of the crosstab function.*/


--with windows function


WITH filtered_sales AS ( --selecting product name in order to group and display results per product
  SELECT
    	p.prod_name,
    	t.calendar_quarter_number 																AS quarter, 		-- shows quarters as a numbers and later lets separate by quarter
    	ROUND(SUM(s.amount_sold) OVER (PARTITION BY p.prod_id, t.calendar_quarter_number), 2)	AS quarter_total,					-- computing the total sales for that product in that specific quarter
    	ROUND(SUM(s.amount_sold) OVER (PARTITION BY p.prod_id), 2) 								AS year_total		-- getting the total sales for that product for the whole year (ignoring quarters)
  FROM sales s
  INNER	JOIN times t		ON 	s.time_id = t.time_id 			AND 									-- table to filter sales by year 2000 only
  								t.calendar_year = 2000                                                			-- using inner joins because I need only  rows with full matches
  INNER JOIN customers c	ON 	s.cust_id = c.cust_id
  INNER JOIN countries co 	ON 	c.country_id = co.country_id	AND										--filtering only customers from Asia, ensuring regional specificity
  								TRIM(BOTH FROM co.country_region ::text) ILIKE 'asia'					-- TRIM for trimming spacees, a case-insensitive match with wildcard ILIKE,  casting any non-text to text
  INNER JOIN products  p 	ON 	s.prod_id = p.prod_id 			AND 									-- filtering only products in the 'Photo' category — another requirement.
  								TRIM(BOTH FROM p.prod_category::text) ILIKE 'photo'
)
SELECT
  prod_name,
  COALESCE( MAX(quarter_total) FILTER (WHERE quarter = 1), 0.00 ) AS q1,								-- using coalesce(..., 0) to make sure that if there were no sales in that quarter, we get 0 instead of NULL. If I left null value, then null value would not count
  COALESCE( MAX(quarter_total) FILTER (WHERE quarter = 2), 0.00 ) AS q2,								-- filtering quarter_total down to a specific quarter using FILTER (WHERE quarter = N)
  COALESCE( MAX(quarter_total) FILTER (WHERE quarter = 3), 0.00 ) AS q3,
  COALESCE( MAX(quarter_total) FILTER (WHERE quarter = 4), 0.00 ) AS q4,
  year_total AS year_sum 														-- using the pre‐computed year_total
FROM filtered_sales
GROUP BY prod_name, year_total														-- grouping down to one row per product
ORDER BY year_sum DESC;															-- sorting final rows


-- with crosstab

SELECT
  prod_name,
  ROUND(COALESCE(q1, 0), 2)                AS q1,  											-- q1 - quarter, coalesce ensures that if there were no sales in Q1, we show 0 instead of NULL
  ROUND(COALESCE(q2, 0), 2)                AS q2, 											-- ROUND(..., 2) formats the number to 2 decimal places
  ROUND(COALESCE(q3, 0), 2)                AS q3,
  ROUND(COALESCE(q4, 0), 2)                AS q4,
  ROUND(COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0), 2) AS year_sum 						-- calculating total annual sales by summing all 4 quarters
FROM crosstab(																-- query for the pivot
  $$
    SELECT
      		p.prod_name,
      		t.calendar_quarter_number AS quarter,											-- category of quarter (Q1, Q2, Q3, Q4)
      		SUM(s.amount_sold)        AS total_amount										-- the value to pivot — total sales
    FROM sales s
    INNER	JOIN times t		ON	s.time_id = t.time_id 			AND                    				-- filtering only sales from year 2000
							 		t.calendar_year = 2000
    INNER	JOIN customers c    ON	s.cust_id = c.cust_id
    INNER	JOIN countries co   ON	c.country_id = co.country_id	AND 	
									TRIM(BOTH FROM co.country_region ::text) ILIKE 'asia'		-- filtering only customers from Asia
    INNER	JOIN products p     ON	s.prod_id = p.prod_id 			AND 
									TRIM(BOTH FROM p.prod_category::text) ILIKE 'photo'		-- filtering only products from the "Photo" category
    GROUP BY 
			p.prod_name, 
			t.calendar_quarter_number
    ORDER BY 
			p.prod_name,
			t.calendar_quarter_number
  $$,
  $$ VALUES (1), (2), (3), (4) $$  													-- showing  crosstab() that the categories are quarters 1–4 in order
) AS ct (  																-- defining the output structure for the pivoted result
  prod_name text,
  q1 numeric,
  q2 numeric,
  q3 numeric,
  q4 numeric
)
ORDER BY year_sum DESC;  	



/*Task 3
Create a query to generate a sales report for customers ranked in the top 300 based on total sales 
in the years 1998, 1999, and 2001. 
The report should be categorized based on sales channels, 
and separate calculations should be performed for each channel.*/
/*You need to find top 300 customers on sales_channel for each of 3 years. 
 And then define customers who was presented in top 300 list in all of these years 
 (who was 3 times in top 300).*/

-- to find top 300 customers for each year 1998, 1999 and 2001


WITH channel_yearly AS ( 												-- total per customer/channel/year + rank within year+channel
    SELECT
      EXTRACT(YEAR FROM s.time_id) AS sales_year,
      c.channel_desc,
      s.cust_id,
      SUM(s.amount_sold) AS channel_total 										--total sales amount for that cust/channel/year
    FROM sales s
    INNER JOIN channels c ON s.channel_id = c.channel_id 
    WHERE EXTRACT(YEAR FROM s.time_id) IN (1998,1999,2001) 								-- restricting to only the three years of interest
    GROUP BY sales_year,
    		c.channel_desc,s.cust_id
),
ranked AS ( 														-- ranking each (customer, channel) within each year by their total sales
    SELECT
      sales_year,
      channel_desc,
      cust_id,
      channel_total,
      RANK() OVER (PARTITION BY sales_year, channel_desc ORDER BY channel_total DESC) AS year_rank 			--reseting ranking for each year and channel; highest-selling customer gets rank = 1
    FROM channel_yearly
),
in_top_year AS ( 													-- checking which customers made it to top 300 in that three years
    SELECT
      sales_year,
      channel_desc,
      cust_id,
      channel_total,
      year_rank,
      SUM(CASE WHEN year_rank <= 300 THEN 1 ELSE 0 END)OVER (PARTITION BY channel_desc, cust_id) AS years_in_top 	-- flagging rows where the customer is top 300
    FROM ranked
),
	final_report AS ( 												-- keeping only those who hit top 300 in all three years and sum their sales.
    SELECT
      	channel_desc,
      	cust_id,
      	SUM(channel_total)	AS amount_sold 										-- total amount of sales
    FROM in_top_year
    WHERE 
    	year_rank    <= 300	AND  											-- sorting out only top 300 only
		years_in_top = 3          										-- only customer / channel combos that hit all 3 years
    GROUP BY channel_desc, cust_id
)
SELECT 															-- final query to gather all columns
  		fr.channel_desc,
  		fr.cust_id,
  		cu.cust_last_name,
  		cu.cust_first_name,
  		ROUND(fr.amount_sold,2)	AS amount_sold 									-- rounding off to two decimal places
FROM final_report fr
INNER	JOIN customers cu 		ON cu.cust_id = fr.cust_id
ORDER BY
  		fr.channel_desc,
  		fr.amount_sold   DESC;




/*Task 4
Create a query to generate a sales report for January 2000, February 2000, 
and March 2000 specifically for the Europe and Americas regions.
Display the result by months and by product category in alphabetical order.*/

/*my logic: first I was thinking about  to retrieve Amerikas sales from Jan-March 2000, then Europe sales from Jan-March 2000 and then  
 to combine together. Later I decided to use ctes to sort out data according to date, then region, product category  *  */


WITH date_sorted AS ( -- extracting data for January, Febraury and March 2000
	SELECT
			s.time_id,
    		s.prod_id
	FROM sales s
	INNER	JOIN times t 			ON t.time_id = s.time_id   			-- using INNER JOIN to map sales to the times table, to access the year/month and found matches
	WHERE 	t.calendar_year  = 2000	AND                         				-- filtering by year 2000 and months
			t.calendar_month_number BETWEEN 1 AND 3
	GROUP BY 										-- preventing duplicates
			s.time_id, 
			s.prod_id
),
sales_USA_EU AS ( 										-- filtering Europe and Amerikas sales
	SELECT
    		s.time_id,
    		s.prod_id,
    		s.amount_sold,
    		co.country_region	AS region  
	FROM sales s
	INNER	JOIN customers cust	ON cust.cust_id = s.cust_id 
	INNER	JOIN countries  co	ON cust.country_id = co.country_id
	WHERE	co.country_region 	IN ('Americas','Europe') 				-- filtering from country table
),
product_sales AS ( 										-- geting the product category for each product ID
	SELECT 
		prod_id,
		prod_category
	FROM products
),
final_sales AS (   										-- computing monthly total sales per region and product category
	SELECT DISTINCT										-- with DISTINCT preventing duplicates due joins
    		t.calendar_month_desc        												AS year_month,
    		ps.prod_category,
    ROUND(SUM(sue.amount_sold)FILTER (WHERE UPPER(sue.region) = 'AMERICAS')OVER (PARTITION BY t.calendar_month_desc,ps.prod_category ), 0)	AS americas_sales, -- windowed sums per month/category, separately for each region
    ROUND(SUM(sue.amount_sold)FILTER (WHERE UPPER(sue.region) = 'EUROPE')  OVER (PARTITION BY t.calendar_month_desc,ps.prod_category), 0)	AS europe_sales
	FROM date_sorted ds
	INNER	JOIN sales_USA_EU sue	ON	sue.time_id = ds.time_id 	AND
										sue.prod_id  = ds.prod_id
	INNER	JOIN product_sales ps	ON	ps.prod_id = sue.prod_id
	INNER	JOIN times t 			ON	t.time_id = ds.time_id  		--  adding this join so I can group by the month          
)
SELECT
  fs.year_month,
  fs.prod_category,
  fs.americas_sales,
  fs.europe_sales
FROM final_sales fs
ORDER BY
  fs.year_month,       
  fs.prod_category;









