/*Task 1. Create a view.
Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue 
for the current quarter and year. The view should only display categories with at least one sale in the current quarter.
Note: when the next quarter begins, it will be considered as the current quarter.*/


CREATE VIEW sales_revenue_by_category_qtr AS --this creates a view
--creating cte
WITH film_amount AS ( 
    SELECT
        	i.inventory_id, 
        	i.film_id,
        	DATE_PART('year', p.payment_date)		AS sales_year,
        	DATE_PART('quarter', p.payment_date)	AS sales_quarter,--extracts the quarter
        	SUM(p.amount) 							AS total_amount --calculates total payment (sales) for that inventory item
    FROM public.inventory i
    LEFT	JOIN public.rental r	ON r.inventory_id = i.inventory_id --to ensure all inventory items are included, even if they don't have rentals nan payments
    LEFT	JOIN public.payment p	ON r.rental_id = p.rental_id
    WHERE 	DATE_PART('year', p.payment_date)	= DATE_PART('year', CURRENT_DATE) AND --in order to filter records to only include payments made in the current year and quarter
      	 	DATE_PART('quarter', p.payment_date)= DATE_PART('quarter', CURRENT_DATE)
    GROUP BY 
        	i.inventory_id, 
        	i.film_id,
        	sales_year,
        	sales_quarter
)
	SELECT 
    	c.name 					AS category,
    	fa.sales_year,
    	fa.sales_quarter,
    	SUM(fa.total_amount)	AS total_sales_revenue
FROM film_amount fa
INNER	JOIN public.film f 				ON f.film_id = fa.film_id
INNER	JOIN public.film_category fc	ON f.film_id = fc.film_id
INNER	JOIN public.category c			ON fc.category_id = c.category_id
GROUP BY 
    	c.name,
    	fa.sales_year,
    	fa.sales_quarter
HAVING SUM(fa.total_amount) > 0 --in order to ensure that only categories with at least one sale are included
ORDER BY 
    	total_sales_revenue DESC;


/*Task 2. Create a query language functions. 
Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing 
the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.*/

	
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr( -- creating function with two parameters
	p_year INT, --the sales year to filter by
    p_quarter INT --the quarte
)
RETURNS TABLE ( --function returns a result like table with 4 columns
    category TEXT, --film category name
    sales_year INT, -- year of sale
    sales_quarter INT, --quarter of sale
    total_sales_revenue NUMERIC --total revenue for that category
) AS $$ --in order to mark the beginning of the SQL code body 
WITH film_amount AS ( --cte film amout in order to calculate total payment amount for each film in each inventory item
    SELECT
        	i.inventory_id, 
        	i.film_id,
        	DATE_PART('year', p.payment_date)		AS sales_year,
        	DATE_PART('quarter', p.payment_date)	AS sales_quarter,
        	SUM(p.amount) 							AS total_amount
    FROM public.inventory i
    LEFT	JOIN public.rental r		ON r.inventory_id = i.inventory_id --used to keep all inventory items even if they don’t have rentals or payments.
    LEFT	JOIN public.payment p 		ON r.rental_id = p.rental_id
    WHERE 	DATE_PART('year', p.payment_date) = p_year
      AND 	DATE_PART('quarter', p.payment_date) = p_quarter
    GROUP BY 
        	i.inventory_id, 
       		i.film_id,
        	sales_year,
        	sales_quarter
)
SELECT -- in order to get the category name and the total revenue grouped by year/quarter
   		c.name,
   		fa.sales_year,
    	fa.sales_quarter,
    	SUM(fa.total_amount) AS total_sales_revenue
FROM film_amount fa
INNER 	JOIN public.film f 				ON f.film_id = fa.film_id
INNER 	JOIN public.film_category fc	ON f.film_id = fc.film_id
INNER 	JOIN public.category c 			ON fc.category_id = c.category_id
GROUP BY 
   		c.name,
    	fa.sales_year,
    	fa.sales_quarter
HAVING SUM(fa.total_amount) > 0 --to ensure that only categories with at least one sale are included
ORDER BY 
    	total_sales_revenue DESC;
$$ LANGUAGE SQL; --closes the function and specifies it's written in plain SQL


DROP FUNCTION public.get_sales_revenue_by_category_qtr(int4, int4); -- for testing and using I need to debug and frop function

SELECT * FROM get_sales_revenue_by_category_qtr(2025,2); -- for testing how function works



/* Task 3. Create procedure language functions
Create a function that takes a country as an input parameter and returns the most popular film in that 
specific country. The function should format the result set as follows:
Query (example):
select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
 */


-- I asumed that the most time rented film is the most popular in that country. Since country names
--are far away in another table I decide to make many joins.
	
-- Drop the function if it already exists. Used a lot while trying to write function. 
DROP FUNCTION IF EXISTS public.most_popular_films_by_countries(TEXT[]);


CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(
	countries TEXT[]) --parameter
RETURNS TABLE ( 
    Country TEXT,
    Film TEXT,
    Rating public."mpaa_rating",
    Language TEXT,
    Length SMALLINT,
    Release_year public."year"
) AS $$
BEGIN
    --checks if the input array is NULL or empty
    IF countries IS NULL OR array_length(countries, 1) = 0 THEN
        RAISE EXCEPTION 'Input array of countries cannot be null or empty';
    END IF;

    RETURN QUERY
    WITH film_rentals AS (
        SELECT 
            	co.country		AS country_name,
            	f.title			AS film_title,
            	f.rating		AS film_rating,
            	l.name::TEXT	AS film_language,
            	f.length 		AS film_length,
            	f.release_year 	AS film_release_year,
            	COUNT(*) 		AS rental_count
        FROM rental r
        INNER	JOIN customer cu       ON cu.customer_id = r.customer_id --using inner joins, because I want to only include rentals that are fully connected to a customer
        INNER	JOIN address a         ON a.address_id = cu.address_id
        INNER	JOIN city ci           ON ci.city_id = a.city_id
        INNER	JOIN country co        ON co.country_id = ci.country_id
        INNER 	JOIN inventory i       ON i.inventory_id = r.inventory_id
        INNER 	JOIN film f            ON f.film_id = i.film_id
        INNER 	JOIN language l        ON l.language_id = f.language_id
        WHERE 	LOWER(co.country) = ANY (
            SELECT LOWER(unnest(countries))
        )
          AND r.return_date IS NOT NULL --ensures only completed rentals
        GROUP BY co.country, 
				f.title, 
				f.rating, 
				l.name, 
				f.length, 
				f.release_year
)
    SELECT DISTINCT ON (country_name) --in order to use DISTINCT ON (country_name) to select only one row per country
        country_name AS Country,
        film_title AS Film,
        film_rating AS Rating,
        film_language AS Language,
        film_length AS Length,
        film_release_year AS Release_year
    FROM film_rentals
    ORDER BY country_name, rental_count DESC, film_length DESC, film_release_year DESC, film_title ASC;
END;
$$ LANGUAGE plpgsql;



	
-- to see specific countries
SELECT * FROM public.most_popular_films_by_countries(ARRAY['Lithuania', 'Latvia', 'Estonia']);

-- to see all countries

SELECT * 
FROM public.most_popular_films_by_countries(
    ARRAY(
        SELECT country FROM public.country
    )
);

/*Task 4. Create procedure language functions
Create a function that generates a list of movies available in stock based on a partial title match 
(e.g., movies containing the word 'love' in their title). 
columns: row_num, film title, language, customer name, rental date 
*/

/*First of all I checked what kind of tables I need in order to get information and then I joined then and then I noticed
that I need to use cte for a better readibility*/


DROP FUNCTION IF EXISTS public.films_in_stock_by_title(TEXT); --prevents errors on recreation.

CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(
	partial_title TEXT) -- parameter
RETURNS TABLE (
    row_num INT,
    film_title TEXT,
    language TEXT,
    last_customer_name TEXT,
    last_rental_date TIMESTAMP
) AS $$
DECLARE
    counter INT := 0;--for numbering the rows
    rec RECORD; --used to loop through the query results
    result_found BOOLEAN := FALSE; --to check if anything matched the search
BEGIN
    -- checks if imput is not empty, if empty then raise an error
    IF partial_title IS NULL OR TRIM(partial_title) = '' THEN
        RAISE EXCEPTION 'Partial title input cannot be null or empty';
    END IF;

    FOR rec IN --loop construct used to iterate over rows returned by a SQL query
        WITH latest_rental AS (
            SELECT r1.*
            FROM rental r1
            WHERE NOT EXISTS (
                SELECT r2.rental_id
                FROM rental r2
                WHERE 	r2.inventory_id = r1.inventory_id AND
                  		r2.rental_date > r1.rental_date
            )
        ),
        available_inventory AS (
            SELECT 
                	i.inventory_id,
                	i.film_id,
                	r.customer_id,
                	r.rental_date,
                	r.return_date
            FROM inventory i
            LEFT	JOIN latest_rental r 	ON i.inventory_id = r.inventory_id
            WHERE r.return_date IS NOT NULL OR r.inventory_id IS NULL
        )
        SELECT 
            	f.title											AS film_title,
            	l.name 											AS language,
            	TRIM(UPPER(c.first_name || ' ' || c.last_name)) AS last_customer_name,
            	ai.rental_date 									AS last_rental_date
        FROM available_inventory ai
        INNER	JOIN film f 	ON ai.film_id = f.film_id
        INNER	JOIN language l ON f.language_id = l.language_id
        LEFT	JOIN customer c ON ai.customer_id = c.customer_id
--this is a condition that filters film titles based on whether they contain the search keyword (partial_title). ILIKE is like a a case-insensitive version of LIKE
        WHERE f.title ILIKE '%' || partial_title || '%' 
        ORDER BY f.title
 --For each row returned from the query: marks that a result was found, increments counter, assigns values to output fields, returns the row using RETURN NEXT   
	LOOP
        result_found := TRUE;
        counter := counter + 1;

        row_num := counter;
        film_title := rec.film_title;
        language := rec.language;
        last_customer_name := rec.last_customer_name;
        last_rental_date := rec.last_rental_date;

        RETURN NEXT;
    END LOOP;

    -- If no matching results found, returns a placeholder row with a message saying no films matched
    IF NOT result_found THEN
        row_num := 1;
        film_title := 'No films in stock matching: ' || partial_title;
        language := NULL;
        last_customer_name := NULL;
        last_rental_date := NULL;

        RETURN NEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;



--checking how code works
SELECT * FROM public.films_in_stock_by_title('love');
SELECT * FROM public.films_in_stock_by_title('lietuva');



/*Task 5. Create procedure language functions
Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a new movie 
with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, 
the rental duration to three days, the replacement cost to 19.99. The release year and language are optional 
and by default should be current year and Klingon respectively. The function should also verify that the language 
exists in the 'language' table. Then, ensure that no such function has been created before; if so, replace it.*/


--P.S. While doing this task, this time I wrote  how I was approaching this task in order to learn better for myself and explain my logic.

/*First, I am going to add Kligon to language table, because there is no language named as Klingon.
If I will not insert Klingon into language table I will get error or null value in language column and I won't be able to set Klingon  as default language.*/

INSERT INTO public.language (name)
SELECT 'Klingon'
WHERE NOT EXISTS (
    SELECT language_id 
    FROM public.language WHERE TRIM(name) = 'Klingon'
)
RETURNING language_id, name, last_update;


--Next step: writing code for 'new_movie' function body. The task asked to insert information, so lets write code like I would insert information

INSERT INTO public.film (
	title,
	release_year,
    language_id,
    rental_duration,
    rental_rate,
    replacement_cost,
    last_update)
		
SELECT 
    'movie title',    -- title
    EXTRACT(YEAR FROM CURRENT_DATE)::INT,    -- release_year set to current year
    (SELECT language_id FROM language WHERE TRIM(name) = 'Klingon'), -- language_id
    3,         -- rental_duration
    4.99,      -- rental_rate
    19.99,     -- replacement_cost
    NOW()      -- last_update
WHERE NOT EXISTS (
    SELECT film_id FROM public.film WHERE title = 'movie title'
);
	



--Third step: function with one parameter

CREATE OR REPLACE FUNCTION new_movie(
    movie_title TEXT --parameter
)
RETURNS TABLE ( 
    title TEXT,
    release_year INT,
    language_id INT2,
    rental_duration INT2,
    rental_rate NUMERIC(4,2),
    replacement_cost NUMERIC(5,2),
    last_update TIMESTAMPTZ
) AS $$
DECLARE
    lang_id INT2;
BEGIN
    -- checking if the movie already exists
    IF EXISTS (
        SELECT title FROM film f WHERE f.title = movie_title
    ) THEN
        RAISE EXCEPTION 'Movie "%" already exists in film table.', movie_title;
    END IF;

    -- getting language_id for 'Klingon'
    SELECT l.language_id INTO lang_id
    FROM language l
    WHERE TRIM(l.name) = 'Klingon';

    -- error if language not found
    IF lang_id IS NULL THEN
        RAISE EXCEPTION 'Language "Klingon" not found in language table.';
    END IF;

    -- inserting and returning the inserted movie row
    RETURN QUERY
    WITH ins AS (
        INSERT INTO film (
            title,
            release_year,
            language_id,
            rental_duration,
            rental_rate,
            replacement_cost,
            last_update
        )
        SELECT
            movie_title,
            EXTRACT(YEAR FROM CURRENT_DATE)::INT,
            lang_id,
            3,
            4.99,
            19.99,
            NOW()
        WHERE NOT EXISTS (
            SELECT title FROM film f WHERE f.title = movie_title
        )
        RETURNING *
    )
    SELECT
        ins.title,
        ins.release_year::INT,
        ins.language_id,
        ins.rental_duration,
        ins.rental_rate,
        ins.replacement_cost,
        ins.last_update
    FROM ins;
END;
$$ LANGUAGE plpgsql;


--checking how it works
SELECT * FROM public.new_movie('Like a wolf');



-- creating and testing full function

DROP FUNCTION IF EXISTS new_movie2(TEXT,TEXT,public."year", INT,NUMERIC, NUMERIC,TIMESTAMPTZ); -- for testing reasons when I when  


/* Creating function with more than one parameter. I decided to try include more parameters because 
if I have a default values and I need to insert many movies, I only need to provide the movie_title and everything else will use default parameters unless overridden so less writing
and it is easier to insert different values via SELECT * FROM public.new_movie('movie_title')*/

CREATE OR REPLACE FUNCTION new_movie2(
	p_title TEXT, --p_title, p_language, etc. are input parameters and prefixed with p_ for clarity
	p_language TEXT DEFAULT 'Klingon',
	p_release_year public."year" DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::public."year",
	p_rental_duration INT DEFAULT 3,
	p_rental_rate NUMERIC(4,2) DEFAULT 4.99,
	p_replacement_cost NUMERIC(5,2) DEFAULT 19.99,
	p_last_update TIMESTAMPTZ DEFAULT NOW()
)
-- --This defines the structure of the returned row, using out_ prefixes to avoid ambiguity and will return a table-like result, with these exact columns and data types
RETURNS TABLE ( 
	out_title TEXT,
	out_release_year public."year",
	out_language_id INT2,
	out_rental_duration INT2,
	out_rental_rate NUMERIC(4,2),
	out_replacement_cost NUMERIC(5,2),
	out_last_update TIMESTAMPTZ
) AS $$
DECLARE ----defining variable  so that I don't have to write SELECT language_id FROM language WHERE TRIM(name) = 'Klingon' every time
lang_id INT2; -- variable name and is used to store the matched language’s ID
BEGIN
--checking if a movie with the same title already exists. If it does, throws an exception to prevent duplicates
IF EXISTS (SELECT title FROM film WHERE title = p_title) THEN
  RAISE EXCEPTION 'Movie "%" already exists in film table.', p_title;
END IF;

--Look up the language_id
SELECT language_id INTO lang_id
FROM language
WHERE TRIM(name) = TRIM(p_language);

-- checking if the language exists at all
IF lang_id IS NULL THEN
  RAISE EXCEPTION 'Language "%" not found in language table.', p_language;
END IF;

RETURN QUERY
INSERT INTO film (
  title,
  release_year,
  language_id,
  rental_duration,
  rental_rate,
  replacement_cost,
  last_update
)
--SELECT is pulling values from function parameters and a variable to insert into the table.
SELECT --
  p_title,
  p_release_year,
  lang_id,
  p_rental_duration,
  p_rental_rate,
  p_replacement_cost,
  p_last_update
WHERE NOT EXISTS (
  SELECT film_id
  FROM film
  WHERE title = p_title
)
RETURNING
  title 			AS out_title,
  release_year		AS out_release_year,
  language_id		AS out_language_id,
  rental_duration	AS out_rental_duration,
  rental_rate 		AS out_rental_rate,
  replacement_cost	AS out_replacement_cost,
  last_update 		AS out_last_update;
END;
$$ LANGUAGE plpgsql;



-- checking if code works as expected
SELECT * FROM public.new_movie2('Catch me');
SELECT * FROM public.new_movie2(
    p_title := 'Vacations in the moon',
    p_release_year := 2011,
    p_rental_duration := 7,
    p_rental_rate := 6.99,
    p_replacement_cost := 24.99
); 






  
