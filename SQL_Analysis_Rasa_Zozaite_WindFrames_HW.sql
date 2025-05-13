/*TASK 1. Create a query for analyzing the annual sales data for the years 1999 to 2001, 
 * focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.'*/

/*% PREVIOUS PERIOD: This column should display the same percentage values as in the 
'% BY CHANNELS' column but for the previous year*/
/*% DIFF: This column should show the difference between the '% BY CHANNELS' and 
'% PREVIOUS PERIOD' columns, indicating the change in sales percentage from the previous year.*/



WITH prev_year_pct AS (
  SELECT 
    	co.country_region,
    	t.calendar_year AS year_prev,
    	ch.channel_desc,
    	ROUND(100.0 * SUM(s.amount_sold)/ SUM(SUM(s.amount_sold)) OVER (PARTITION BY co.country_region, t.calendar_year), 2) AS percent_prev_year --  calculating, for each region-and-year, what percentage a given channel’s sales represent of that region’s total sales
  FROM sales s
  INNER	JOIN times t 		ON t.time_id = s.time_id 						-- inner joins in order for fully‐qualified sales records to get through
  INNER	JOIN customers c 	ON s.cust_id = c.cust_id
  INNER	JOIN countries co 	ON c.country_id = co.country_id
  INNER	JOIN channels ch 	ON ch.channel_id = s.channel_id
  WHERE t.calendar_year BETWEEN 1998 AND 									-- adding filters for date and region. 1998 is used when calculating previous year
  		2000 AND co.country_region IN ('Americas', 'Asia', 'Europe')
  GROUP BY 
  		co.country_region, 
  		t.calendar_year, 
  		ch.channel_desc
),
curr_year_pct AS (
  SELECT 
    	co.country_region,
    	t.calendar_year AS year_curr,
    	ch.channel_desc,
    	SUM(s.amount_sold) AS total_amount, 								-- sales dollars for this channel + year
    	ROUND(100.0 * SUM(s.amount_sold)/ SUM(SUM(s.amount_sold)) OVER (PARTITION BY co.country_region, t.calendar_year), 2) AS percent_of_total -- calculating this channel’s share of that region’s total sales in the same year
  FROM sales s
  INNER	JOIN times t ON t.time_id = s.time_id 								-- adding date attributes in order to filter by year
  INNER	JOIN customers c ON s.cust_id = c.cust_id 							-- also ensuring every sale is matched to a valid date, customer, region, and channel
  INNER	JOIN countries co ON c.country_id = co.country_id
  INNER	JOIN channels ch ON ch.channel_id = s.channel_id
  WHERE t.calendar_year BETWEEN 1999 AND
  		2001 AND co.country_region IN ('Americas', 'Asia', 'Europe')
  GROUP BY co.country_region, t.calendar_year, ch.channel_desc
)
SELECT  																		-- final query for gathering all columns and showing sales difference in percents
  		c.country_region,
  		c.year_curr 												AS calendar_year,
  		c.channel_desc,
  		c.total_amount 												AS amount_sold,
  		c.percent_of_total || '%' 									AS "% BY CHANNELS",
  		p.percent_prev_year || '%' 									AS "% PREVIOUS PERIOD",
  		ROUND(c.percent_of_total - p.percent_prev_year, 2) || '%'	AS "% DIFF"  -- calculating sales difference between years, adding % sign
FROM curr_year_pct c
LEFT	JOIN prev_year_pct p ON c.country_region = p.country_region AND  	-- using a left join so that even if there’s no matching previous‐year row, the current‐year row still appears
		c.channel_desc = p.channel_desc 							AND 	-- matching on the same geographic region and same sales channels
		c.year_curr = p.year_prev + 1										-- lets pull in p.percent_prev_year as “last year’s percentage
ORDER BY 
		c.country_region	ASC, 
		c.year_curr 		ASC, 
		c.channel_desc 		ASC;






/*TASK 2. You need to create a query that meets the following requirements:
a)Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
b)Include a column named CUM_SUM to display the amounts accumulated during each week.
c)Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, 
current, and following days using a centered moving average.
d)For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) 
as well as Monday and Tuesday.
e)For Friday, calculate the average sales on Thursday, Friday, and the weekend.
f) Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.*/



WITH base AS ( -- the aim of this cte is to filter data from 1999 and chose 48-51 weeks, also to sum sold sales
  SELECT
    	t.calendar_week_number, 		
    	t.time_id,
    	t.day_name,
    	SUM(s.amount_sold) AS sales  						-- total sales for that day
  FROM sales s
  INNER	JOIN times t ON s.time_id = t.time_id
  WHERE t.calendar_year = 1999 AND
  		t.calendar_week_number BETWEEN 48 AND 52			-- expanding to week 48 so that Monday of week 49 can see Sat/Sun(48) and Friday of 51 can see Sat/Sun of 52 week
  GROUP BY
    	t.calendar_week_number,
    	t.time_id,
    	t.day_name
)
SELECT
  b.calendar_week_number,
  b.time_id,
  b.day_name,
  b.sales,
  SUM(b.sales) OVER (PARTITION BY b.calendar_week_number ORDER BY b.time_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum, --running‐total / cumulative sum _within_ each week
  CASE 																							--choosing the correct precomputed avg based on the weekday
    WHEN b.day_name = 'Monday' THEN avg_mon
    WHEN b.day_name = 'Friday' THEN avg_fri
    ELSE avg_norm
  END AS centered_3_day_avg
FROM ( 
  SELECT
    calendar_week_number,
    time_id,
    day_name,
    sales,
    ROUND (AVG(sales) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS avg_norm,	-- 3-day “centered” (yesterday, today, tomorrow)
    ROUND (AVG(sales) OVER (ORDER BY time_id ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING), 2) AS avg_mon, 	-- 4-day window for Mondays (Sat, Sun, Mon, Tue)
    ROUND (AVG(sales) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING), 2) AS avg_fri 	-- 4-day window for Fridays (Thu, Fri, Sat, Sun)
  FROM base   																							-- selecting from previous cte which include data from the end of 48 week
) b
WHERE b.calendar_week_number BETWEEN 49 AND 51 															-- only showing weeks 49–51 in the final report
ORDER BY
  b.calendar_week_number,
  b.time_id;





/*TASK 3. Please provide 3 instances of utilizing window functions that include a frame clause, 
using RANGE, ROWS, and GROUPS modes. Additionally, explain the reason for choosing a specific frame 
type for each example. This can be presented as a single query or as three distinct queries.*/


SELECT
  s.cust_id,
  s.time_id  AS sale_date,
  s.amount_sold,
  SUM(amount_sold)
  OVER (
    ORDER BY s.cust_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_by_row,
  SUM(amount_sold)
  OVER (
    ORDER BY time_id
    GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
  ) AS total_prev_and_curr_date,
  SUM(amount_sold)
  OVER (
    PARTITION BY s.cust_id
    ORDER BY time_id
    RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW
  ) AS spend_last_7_days
FROM sales s
JOIN customers c ON s.cust_id = c.cust_id
ORDER BY
  s.cust_id ASC,
  s.time_id ASC;


/* ROWS - This simply accumulates every sale from the very first row through the current one, ignoring all
values. Business question: “What’s the cumulative sales figure up through each transaction?”

GROUPS - every row whose time_id (the sale date) is the same is treated as one “peer group,” and sum the 
entire group for today plus the entire group for yesterday. It is a good choice for this because it jumps in units of tied 
dates rather than raw row counts or date intervals. It can be usef for usiness question likes this: “How do today’s sales compare to yesterday’s in aggregate?”

RANGE - this treats dates as a value continuum, summing only those sales whose time_id falls within the last six days plus today. 
RANGE perfectly expresses true calendar windows without worrying about how many rows each day has.
Business question: Which customers have spent the most in the past week? */



