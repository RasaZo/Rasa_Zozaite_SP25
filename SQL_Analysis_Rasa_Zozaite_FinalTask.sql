/*TASK 1. Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold).
The resulting report should include the following columns:
CHANNEL_DESC
COUNTRY_REGION
SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent sign (%) at the end.
Display the result in descending order of SALES*/


WITH per_region AS ( -- 
SELECT
		ch.channel_desc,
		co.country_region,
		SUM(s.quantity_sold)	AS region_sales  					-- total quantity sold per channel and country region
FROM sales   s
INNER JOIN channels ch			ON s.channel_id = ch.channel_id  			-- combining sales with their corresponding channels, customers, and countries
INNER JOIN customers c			ON s.cust_id    = c.cust_id
INNER JOIN countries co			ON c.country_id = co.country_id
GROUP BY 
		ch.channel_desc,
		co.country_region
),
ranked AS (
  SELECT
    channel_desc,
    country_region,
    region_sales,
    ROW_NUMBER() OVER (PARTITION BY channel_desc  ORDER BY region_sales DESC) AS rn,      			-- top region per channel
    region_sales / SUM(region_sales) OVER (PARTITION BY channel_desc) * 100 AS pct_of_channel  -- calculating the percentage contribution of each region’s sales within its channel
  FROM per_region
)
SELECT
  channel_desc,
  country_region,
  TO_CHAR(region_sales, 'FM999,990.00')            AS sales,
  TO_CHAR(pct_of_channel,  'FM90.00"%"')           AS sales_pct
FROM ranked
WHERE rn = 1  																		-- only the top region per channel is selected
ORDER BY region_sales DESC;





/* TASK 2. 
Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year.
a)Determine the sales for each subcategory from 1998 to 2001.

b)Calculate the sales for the previous year for each subcategory.
c)Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
d)Generate a dataset with a single column containing the identified prod_subcategory values.*/


-
WITH yearly_sales AS ( -- calculating total sales per product subcategory and year
  SELECT
    p.prod_subcategory,
    EXTRACT(YEAR FROM s.time_id)::INT AS sale_year, 
    SUM(s.amount_sold)               AS total_amount
  FROM sales    s
  JOIN products p ON s.prod_id = p.prod_id
  WHERE s.time_id BETWEEN '1998-01-01' AND '2001-12-31' 		-- filtering only the years 1998 to 2001
  GROUP BY prod_subcategory, sale_year
),
yearly_with_prior AS (  										-- getting the previous year’s sales for comparison
  SELECT
    prod_subcategory,
    sale_year,
    total_amount,
    LAG(total_amount) OVER (PARTITION BY prod_subcategory ORDER BY sale_year) AS prior_year_amount --looks “one row back” in the same subcategory, ordered by year, fetching the previous year’s total.
  FROM yearly_sales
),
yearly_growth AS (
  SELECT
    prod_subcategory,
    sale_year,
    total_amount,
    prior_year_amount,
    CASE 
      WHEN prior_year_amount IS NULL THEN NULL
      WHEN total_amount > prior_year_amount THEN 1
      ELSE 0
    END AS grew              -- checking  whether sales grew compared to the prior year
  FROM yearly_with_prior
),
consistent AS (   -- identifying  subcategories where sales grew every year from 1999 to 2001
  SELECT
    prod_subcategory
  FROM yearly_growth
  WHERE sale_year BETWEEN 1999 AND 2001
  GROUP BY prod_subcategory
  HAVING MIN(grew) = 1   	   -- if the minimum value of grew is 1, that means sales grew every year
)
SELECT prod_subcategory 		--getting final view of the table
FROM consistent
ORDER BY prod_subcategory;





/* TASK 3 Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. 
 In the report you have to analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' 
across the distribution channels 'Partners' and 'Internet'.

The resulting report should include the following columns:
CALENDAR_YEAR: The calendar year
CALENDAR_QUARTER_DESC: The quarter of the year
PROD_CATEGORY: The product category
SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. 
For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include the percent sign 
(%) at the end.
CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
The final result should be sorted in ascending order based on two criteria: 
first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending
*/


WITH date_category_sorted AS (  													-- cte for filtering information
    SELECT
        t.calendar_year,
        t.calendar_quarter_desc,
        t.calendar_quarter_number,
        p.prod_category,
        ROUND(SUM(s.amount_sold), 2) AS "sales$"  								 --summing  sales
    FROM sales s
    INNER JOIN times t ON s.time_id = t.time_id
    INNER JOIN products p ON s.prod_id = p.prod_id
    WHERE 
        s.time_id BETWEEN '1999-01-01' AND '2000-12-31'  						-- filtering data for years 1999 and 2000 only
        AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')  -- limiting prod. category
        AND s.channel_id IN (SELECT channel_id 
                             FROM channels 
                             WHERE channel_desc IN ('Partners', 'Internet'))  -- limiting sales channels to Partners and Internet.
    GROUP BY 
        t.calendar_year,
        t.calendar_quarter_desc,
        t.calendar_quarter_number,
        p.prod_category
),
difference_percent AS ( 									-- this cte is used for calculating diff_percent
    SELECT 
        calendar_year,
        calendar_quarter_desc,
        calendar_quarter_number, 							-- useful  when using case 1 THEN 'N/A'
        prod_category,
        sales$,
        CASE   
            WHEN calendar_quarter_number = 1 THEN 'N/A'
            ELSE TO_CHAR(
                ROUND(
                    ((sales$ - 
                      FIRST_VALUE(sales$) OVER (PARTITION BY calendar_year, prod_category    -- to retrieve the Q1 sales dynamically for the correct product category and year
                                                ORDER BY calendar_quarter_number)) 
                    / FIRST_VALUE(sales$) OVER (PARTITION BY calendar_year, prod_category 
                                                ORDER BY calendar_quarter_number)) * 100, 2), 'FM999990.00') || '%' 
        END AS diff_percent
    FROM date_category_sorted
)
SELECT  -- last query for the final result 
    calendar_year,
    calendar_quarter_desc,
    prod_category,
    sales$,
    diff_percent,
    ROUND(SUM(sales$) OVER ( PARTITION BY calendar_year  ORDER BY calendar_quarter_number ), 2 ) AS "cum_sum$"  -- this adds sales values cumulatively across quarters per year, regardless of product category
FROM difference_percent
ORDER BY 
    calendar_year ASC, 
    calendar_quarter_desc ASC, 
    sales$ DESC;

















