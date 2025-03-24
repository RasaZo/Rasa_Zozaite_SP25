
/*Part 1: Write SQL queries to retrieve the following data
1a)All animation movies released between 2017 and 2019 with rate more than 1, alphabetical*/

SELECT	f.title,
    	f.release_year,
    	f.rental_rate,
    	f.rating
FROM film f
WHERE rental_rate > 1 AND --to filter results to only include movies with a rental rate greater than 1
release_year BETWEEN 2017 AND 2019
AND film_id IN (
	SELECT film_id FROM film_category fc
	INNER JOIN category c ON fc.category_id = c.category_id --to ensure that only films that belong to the 'Animation' category are selected
	WHERE c.name = 'Animation') --to ensure that only animation movies are selected by checking if the film_id exists in the film_category table
ORDER BY title ASC;


--1b)The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)


SELECT	CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS full_address, -- to combine two columns into one
    	SUM(p.amount) AS revenue -- calculate total revenue
FROM payment p
LEFT JOIN staff s ON s.staff_id = p.staff_id  --ensures that all records from the left table are included, even if there is no match in the right table
LEFT JOIN store st ON s.store_id = st.store_id -- Get the store associated with the staff who processed the payment and dont lose valid payments when the is no assigned store
LEFT JOIN address a ON st.address_id = a.address_id --ensures that payments still count towards revenue, even if the store’s address is null
WHERE p.payment_date >= '2017-04-01'
GROUP BY a.address, a.address2; 


--1c)Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)


SELECT	a.first_name,
		a.last_name,
		COUNT(f.film_id) AS number_of_movies 
FROM film f
INNER JOIN film_actor fa ON f.film_id = fa.film_id --to keep actors who have really acted in movies released after 2015
INNER JOIN actor a ON fa.actor_id = a.actor_id --if to consider films that have actors assigned
WHERE f.release_year > 2015
GROUP BY a.actor_id,
		 a.first_name,
		 a.last_name
ORDER BY number_of_movies DESC, a.last_name ASC
LIMIT 5;


/*1d)Number of Drama, Travel, Documentary per year 
(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)*/


SELECT	f.release_year,
		COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_drama_movies,  --CASE WHEN function helps to count films only for the specific category and handles null values
    	COUNT(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
    	COUNT(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id   --ensures all films are included, even if they don't belong to a category
LEFT JOIN category c ON fc.category_id = c.category_id --to retrieve the category name for each film
GROUP BY f.release_year
ORDER BY f.release_year DESC;



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
        	SUM(p.amount) AS total_revenue,
        	MAX(p.payment_date) AS last_payment_date --retrieves the most recent payment date (MAX function) for each staff member from the payment table
    FROM staff s
    LEFT JOIN payment p ON s.staff_id = p.staff_id -- to match staff members with their payments and to make sure that all staff members are included in the results, regardless of whether they had payments in 2017
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017 --to filter rows to only include payments made in the year 2017
    GROUP BY s.staff_id, s.first_name, s.last_name, s.store_id
) 
SELECT	first_name,
    	last_name,
    	store_id,
    	total_revenue
FROM revenue_per_staff
ORDER BY total_revenue DESC
LIMIT 3;



/*2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture Association film rating system*/


SELECT	f.title AS film_title,
		COUNT (DISTINCT r.rental_id) AS number_of_rentals, --the unique rental transactions
		CASE 
        	WHEN f.rating = 'G' THEN '0+'
        	WHEN f.rating = 'PG' THEN '8+'
        	WHEN f.rating = 'PG-13' THEN '13+'
        	WHEN f.rating = 'R' THEN '17+'
	        WHEN f.rating = 'NC-17' THEN '18+'
    	    ELSE 'Unknown'
    	END AS expected_age --to find and rename collumn according to the conditions.
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id --to ensure all films are included, even if they have no inventory records (they might be damaged and not in the inventory).
LEFT JOIN rental r ON i.inventory_id = r.inventory_id -- in order to include all films and inventory items, even if they have never been rented
GROUP BY f.title, f.rating 
ORDER BY number_of_rentals DESC, f.title DESC
LIMIT 5;



/*Part 3. Which actors/actresses didn't act for a longer period of time than the others?

V1: gap between the latest release_year and current year per each actor;
In order to do task, I think, we need to subtract lastest year of acting from current year.*/

SELECT	CONCAT(a.first_name, ' ', COALESCE(a.last_name, '')) AS actor_name, -- Combine first and last names
    	MAX(f.release_year) AS latest_film_acted,  -- Most recent year the actor acted
    	MIN(f.release_year) AS first_film_acted,   -- Earliest year the actor acted
    (	MAX(f.release_year) - MIN(f.release_year)) AS total_gap -- Gap between the first and last film
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id --if I use inner join, then actors who haven't acted in films would be exlcluded.
LEFT JOIN film f ON fa.film_id = f.film_id -- to ensure all actors are included, even if no matching film exists.
GROUP BY actor_name
ORDER BY total_gap ASC; -- Order by the smallest gap first




/*V2: gaps between sequential films per each actor;
I understood task as I need to find what is gap between two films of the same actor when he acted*/

--cte1 The aim of this cte is to get actor's id, name and film release year 
WITH actor_acting_years AS (
    SELECT	a.actor_id,
        	CONCAT(a.first_name, ' ', COALESCE(a.last_name, '')) AS actor_name,
        	f.release_year AS acting_film
    FROM actor a
    LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id  --to match actors to the films they acted in
    LEFT JOIN film f ON fa.film_id = f.film_id --to retrieve details of the films the actor acted in.
),
--cte2 is needed to calculate gaps between film years. Joins actor_acting_years to itself (a self-join). This pairs each film year (a1) with all subsequent film years (a2) for the same actor.
film_gaps AS (
    SELECT	a1.actor_id,
        	a1.actor_name,
        	a1.acting_film AS film_year,
        	a2.acting_film AS next_film_year,
        	a2.acting_film - a1.acting_film AS year_gap
    FROM actor_acting_years a1
    JOIN actor_acting_years a2 ON a1.actor_id = a2.actor_id AND a2.acting_film > a1.acting_film -- condition that later films are included in pairing
),
--cte3 is for finding gap year for each film
smallest_gaps AS (
    SELECT	actor_id,
        	film_year,
       	 	MIN(year_gap) AS smallest_gap -- to find the smallest gap (year_gap) between the current film and any subsequent films.
    FROM film_gaps
    GROUP BY actor_id, film_year
)
SELECT	fg.actor_id,
    	fg.actor_name,
    	fg.film_year,
    	fg.next_film_year,
    	fg.year_gap -- to retrieve the gap between the current and next film year
FROM film_gaps fg
INNER JOIN smallest_gaps sg ON fg.actor_id = sg.actor_id AND -- to match the same actor
fg.film_year = sg.film_year AND --to match the same year
fg.year_gap = sg.smallest_gap --to ensure that only rows with the smallest gap are included in the result
ORDER BY fg.actor_id, fg.film_year;



