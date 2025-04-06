
/*Part 1: Write SQL queries to retrieve the following data
1a)All animation movies released between 2017 and 2019 with rate more than 1, alphabetical*/

SELECT	
	f.title,
	f.release_year,
	f.rental_rate,
	f.rating
FROM public.film f
WHERE 	
	f.rental_rate > 1		AND --to filter results to only include movies with a rental rate greater than 1
	f.release_year BETWEEN 2017 	AND 2019
	AND film_id IN (
		SELECT	film_id 
		FROM public.film_category fc
		INNER	JOIN public.category c ON fc.category_id = c.category_id --to ensure that only films that belong to the 'Animation' category are selected
		WHERE 	LOWER(c.name) = 'animation'
) --to ensure that only animation movies are selected by checking if the film_id exists in the film_category table
ORDER BY 
	f.title ASC;


--1b)The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
--It's better to use the table inventory to join the table rental and the table store

SELECT	
	CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS full_address, -- to combine two columns into one
    	SUM(p.amount) AS revenue -- calculate total revenue
FROM public.inventory i
INNER	JOIN public.rental  r	ON i.inventory_id = r.inventory_id  --ensures that all records from the table are included
INNER	JOIN public.payment p	ON r.rental_id = p.rental_id 
INNER	JOIN public.store   st	ON i.store_id  = st.store_id -- Get the store associated with the staff who processed the payment and dont lose valid payments when the is no assigned store
INNER	JOIN public.address a	ON st.address_id  = a.address_id --ensures that payments still count towards revenue, even if the store’s address is null
WHERE 	p.payment_date >= '2017-04-01' --since it is written that calculate revenue after march 2017, I decide that it is from the start of april
GROUP BY 
	a.address, a.address2;  


--1c)Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)


SELECT	
	a.first_name,
	a.last_name,
	COUNT(f.film_id) AS number_of_movies 
FROM public.film f
INNER	JOIN public.film_actor fa	ON f.film_id = fa.film_id --to match films with actors only those who acted in films
INNER	JOIN public.actor a		ON fa.actor_id = a.actor_id --get actors details
WHERE	f.release_year > 2015
GROUP BY 
	a.actor_id,
	a.first_name,
	a.last_name
ORDER BY 
	number_of_movies DESC, 
	a.last_name ASC
LIMIT	5;


/*1d)Number of Drama, Travel, Documentary per year 
(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)*/


SELECT	
	f.release_year,
	-- Count films for each specific category
	COUNT(CASE WHEN LOWER(c.name) = 'drama' 	THEN 1 END) AS number_of_drama_movies, 
    	COUNT(CASE WHEN LOWER(c.name) = 'travel' 	THEN 1 END) AS	number_of_travel_movies,
    	COUNT(CASE WHEN LOWER(c.name) = 'documentary' 	THEN 1 END) AS number_of_documentary_movies
FROM public.film f
LEFT 	JOIN public.film_category fc	ON f.film_id = fc.film_id   -- include all films, even those without a category
LEFT 	JOIN public.category c 		ON fc.category_id = c.category_id -- get the name of each category
GROUP BY 
	f.release_year
ORDER BY 
	f.release_year DESC;



/*Part 2: Solve the following problems using SQL
Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance.
Assumptions: 
staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
if staff processed the payment then he works in the same store; 
take into account only payment_date*/

WITH revenue_per_staff AS (  --used cte for to calculate revenue per staff member for the year 2017
    SELECT	s.staff_id,
        	s.first_name,
        	s.last_name,
        	s.store_id,
        	SUM(p.amount) 		AS total_revenue,
        	MAX(p.payment_date) 	AS last_payment_date --retrieves the most recent payment date (MAX function) for each staff member from the payment table
    FROM public.staff s
    LEFT 	JOIN public.payment p ON s.staff_id = p.staff_id -- to match staff members with their payments and to make sure that all staff members are included in the results, regardless of whether they had payments in 2017
    WHERE 	EXTRACT(YEAR FROM p.payment_date) = 2017 --to filter rows to only include payments made in the year 2017
    GROUP BY 
    		s.staff_id, 
    		s.first_name, 
    		s.last_name, 
    		s.store_id
) 
SELECT	first_name,
    	last_name,
    	store_id,
    	total_revenue
FROM revenue_per_staff
ORDER BY 
	total_revenue DESC
LIMIT	3;



/*2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture Association film rating system*/


SELECT	
	f.title 			AS film_title,
	COUNT (DISTINCT r.rental_id)	AS number_of_rentals, --the unique rental transactions
	CASE 
        	WHEN f.rating = 'G' 	THEN '0+'
        	WHEN f.rating = 'PG' 	THEN '8+'
        	WHEN f.rating = 'PG-13' THEN '13+'
        	WHEN f.rating = 'R' 	THEN '17+'
	       	WHEN f.rating = 'NC-17' THEN '18+'
    	 	ELSE 'Unknown'
    	END AS expected_age --to find and rename collumn according to the conditions.
FROM public.film f
LEFT 	JOIN public.inventory i ON f.film_id = i.film_id --to ensure all films are included, even if they have no inventory records (they might be damaged and not in the inventory).
LEFT 	JOIN public.rental r 	ON i.inventory_id = r.inventory_id -- in order to include all films and inventory items, even if they have never been rented
GROUP BY 
	f.title, f.rating 
ORDER BY 
	number_of_rentals DESC, 
	f.title DESC
LIMIT	5;



/*Part 3. Which actors/actresses didn't act for a longer period of time than the others?

V1: gap between the latest release_year and current year per each actor;*/


SELECT	
	a.actor_id, 
	TRIM(CONCAT(a.first_name, ' ', COALESCE(a.last_name, '')))	AS actor_name,
	MAX(f.release_year) 						AS latest_film_acted,
	EXTRACT(YEAR FROM CURRENT_DATE)::int - MAX(f.release_year)	AS years_since_latest_film --in order to calculated how many years passed since the last film 
FROM public.actor a
LEFT 	JOIN public.film_actor fa	ON a.actor_id = fa.actor_id
LEFT 	JOIN public.film f 		ON fa.film_id = f.film_id
GROUP BY 
	a.actor_id, 
	a.first_name, 
	a.last_name
ORDER BY 
	years_since_latest_film DESC NULLS LAST,--to show actors with longest inactivity first and place those who never acted at the end
	a.actor_id ASC;
--So Humphrey Garla is an actor who didn't act the longest.





/*V2: Which actors/actresses didn't act for a longer period of time than the others: gaps between sequential films per each actor; 
I understood task as I need to find what is the largest gap between two films of the same actor when he acted*/

--  Get actor's id, name and film release year
WITH actor_acting_years AS (
    SELECT DISTINCT
        	a.actor_id,
        	CONCAT(a.first_name, ' ', COALESCE(a.last_name, '')) AS actor_name,
        	f.release_year AS acting_film
    FROM public.actor a
    LEFT	JOIN public.film_actor fa 	ON a.actor_id = fa.actor_id
    LEFT	JOIN public.film f 		ON fa.film_id = f.film_id
),
--  Create pairs of films, but only match each film with its immediate next film
consecutive_film_gaps AS (
    SELECT
        	a1.actor_id,
        	a1.actor_name,
        	a1.acting_film		AS film_year,
        	MIN(a2.acting_film) 	AS next_film_year
    FROM actor_acting_years a1
    INNER	JOIN actor_acting_years a2 	ON  --if an actor has only one film, they won't have gaps to calculate, so it is desirable pairs where both films exist
        	a1.actor_id = a2.actor_id 	AND
        	a2.acting_film > a1.acting_film
    GROUP BY
        	a1.actor_id,
        	a1.actor_name,
        	a1.acting_film
),
--  Calculate the gap between consecutive films
film_gaps AS (
    SELECT
        actor_id,
        actor_name,
        film_year,
        next_film_year,
        next_film_year - film_year AS year_gap
    FROM consecutive_film_gaps
),
--  Find the maximum gap for each actor
actor_max_gaps AS (
    SELECT
        actor_id,
        actor_name,
        MAX(year_gap) AS max_gap
    FROM film_gaps
    GROUP BY 
    	actor_id, actor_name
)
--  Get actors with their maximum gaps
SELECT
    	fg.actor_id,
    	fg.actor_name,
    	fg.film_year,
    	fg.next_film_year,
    	fg.year_gap
FROM film_gaps fg
INNER	JOIN actor_max_gaps amg 	ON
    	fg.actor_id = amg.actor_id 	AND
    	fg.year_gap = amg.max_gap
ORDER BY 
	fg.year_gap DESC;


