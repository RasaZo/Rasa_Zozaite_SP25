ALTER SEQUENCE film_film_id_seq RESTART WITH 1001; -- just to be sure that id numbering starts at 1001
SELECT last_value FROM film_film_id_seq; -- to check last id's value



/*Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
*/

INSERT INTO public.film (
    film_id, title, 
    description, 
    release_year, 
    language_id, 
    original_language_id, 
    rental_duration,
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    last_update, 
    special_features, 
    fulltext
)
SELECT 
    nextval('film_film_id_seq'),
    'Fight Club',
    'An insomniac office worker and a carefree soap salesman form an underground fight club that evolves into something much more.', 
    1999,
    (SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1), -- fetching language_id
    (SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1),  -- info for original_language_id since we know what is original language
    1, --rental_duration
    4.99, --rental_rate
    139, --film duration
    19.99, -- replacement cost
    'R'::mpaa_rating, now(), --rating
    '{Deleted Scenes}', 
    to_tsvector('english', 'Fight Club Brad Pitt Edward Norton Helena Bonham Carter')
WHERE NOT EXISTS (
    SELECT title 
    FROM public.film 
    WHERE title = 'Fight Club' AND release_year = 1999
);




INSERT INTO public.film 
		(film_id, title, 
		description, 
		release_year, 
		language_id, 
		original_language_id, 
		rental_duration, 
		rental_rate, 
		length, 
		replacement_cost, 
		rating, 
		last_update, 
		special_features, 
		fulltext)
SELECT nextval('film_film_id_seq'),
       'Schindler''s List',
       'Oskar Schindler becomes an unlikely humanitarian amid the barbaric Nazi reign when he turns his factory into a refuge for Jews.',
       1993,
       (SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1), 
       (SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1), ---- original_language_id 
	   2,----rental_duration
	   9.99, 
	   195, 
	   19.99, 
	   'R'::mpaa_rating, 
	   now(),
       '{Behind the Scenes, Deleted Scenes}',
       to_tsvector('english', 'Schindler''s List Oskar Schindler Jews Holocaust Nazi')
WHERE NOT EXISTS 
	(SELECT title 
	FROM public.film 
	WHERE title = 'Schindler''s List' AND release_year = 1993
)
RETURNING film_id;



INSERT INTO public.film 
		(film_id, 
		title, 
		description, 
		release_year, 
		language_id, 
		original_language_id, 
		rental_duration, 
		rental_rate, 
		length, 
		replacement_cost, 
		rating, 
		last_update, 
		special_features, 
		fulltext)
SELECT nextval('film_film_id_seq'), 
		'The Matrix', 'A computer hacker learns about the true nature of reality and his role in the war against its controllers.',
		1999,
		(SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1), 
		(SELECT language_id FROM public.language WHERE LOWER(name) = 'english' LIMIT 1),
		3, ----rental_duration
		19.99, 
		136, 
		19.99, 
		'R'::mpaa_rating, NOW(), 
		'{Behind the Scenes, Deleted Scenes, Director Commentary}', 
		to_tsvector('english', 'The Matrix Keanu Reeves Laurence Fishburne Carrie-Anne Moss Hugo Weaving')
WHERE NOT EXISTS 
	(SELECT title 
	FROM public.film 
	WHERE title = 'The Matrix' AND release_year = 1999
)
RETURNING film_id;



--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total). 

INSERT INTO public.actor 
		(first_name, 
		last_name, 
		last_update)
SELECT 
		first_name,
		last_name,
		last_update  FROM (  --This creates a temporary table-like structure with new actor data
    VALUES 
        ('Brad', 'Pitt', current_timestamp),
        ('Edward', 'Norton', current_timestamp),
        ('Liam', 'Neeson', current_timestamp),
        ('Ralph ', 'Fiennes', current_timestamp),
        ('Keanu', 'Reeves', current_timestamp),
        ('Laurence', 'Fishburne', current_timestamp)
) AS new_actors (first_name, last_name, last_update)
WHERE NOT EXISTS (   --prevents inserting duplicate actors,  if a match is found, the new record is skipped
    SELECT 
    	first_name, 
    	last_name 
    FROM actor a 
    WHERE a.first_name = new_actors.first_name 
    AND a.last_name = new_actors.last_name
)
RETURNING actor_id, first_name, last_name; --id is automatically handled by program


INSERT INTO public.film_actor 
	(actor_id, 
	film_id,
	last_update)
SELECT 
    a.actor_id,
    f.film_id,
    current_timestamp 
FROM (
    VALUES 
        ('Brad', 'Pitt', 'Fight Club'),
        ('Edward', 'Norton', 'Fight Club'),
        ('Liam', 'Neeson', 'Schindler''s List'),
        ('Ralph', 'Fiennes', 'Schindler''s List'),
        ('Keanu', 'Reeves', 'The Matrix'),
        ('Laurence', 'Fishburne', 'The Matrix')
) AS new_data (first_name, last_name, film_title)
INNER JOIN public.actor a 
	ON TRIM(LOWER(a.first_name)) = TRIM(LOWER(new_data.first_name)) AND  --names might have an accidental space at the start or end. Using TRIM() ensures I am comparing the cleaned-up versions
	TRIM(LOWER(a.last_name)) = TRIM(LOWER(new_data.last_name))
INNER JOIN public.film f 
	ON TRIM(LOWER(f.title)) = TRIM(LOWER(new_data.film_title))
	ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING actor_id, film_id;


--Add your favorite movies to any store's inventory.


INSERT INTO public.inventory 
		(film_id, 
		store_id, 
		last_update)
SELECT 
		f.film_id,
	    s.store_id,
    NOW()
FROM public.film f
INNER	JOIN (
		SELECT store_id 
		FROM public.store 
		WHERE store_id = 1
) s 	ON TRUE -- in order to avoid hardcoding, we join store table, assign alias s and ON TRUE we show joining every film to this one store row.  It’s like attaching store_id = 1 to each film.
WHERE LOWER(f.title) IN (   --this filters only the films with titles matching (case-insensitively)
    	'fight club',
    	'schindler''s list',
    	'the matrix'
)
AND NOT EXISTS ( --checks and prevents inserting duplicates
    	SELECT i.film_id  
    	FROM public.inventory i 
    	WHERE i.film_id = f.film_id 
     	AND i.store_id = s.store_id
)
RETURNING 
		film_id, 
		store_id;



/*Alter any existing customer in the database with at least 43 rental and 43 payment records. 
Change their personal data to yours (first name, last name, address, etc.). 
You can use any existing address from the "address" table. 
Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.*/

-- So first, we need to find a customer with a least 43 rental and 43 payment records 
SELECT 
		c.customer_id, 
		first_name, 
		last_name 
FROM public.customer c
INNER	JOIN public.rental r	ON c.customer_id = r.customer_id -- in order to add table with a rental time and ensure that only customers who meet both conditions are included
INNER	JOIN public.payment p	ON c.customer_id = p.customer_id -- in order to add table with payments 
GROUP BY 
		c.customer_id 
HAVING COUNT(DISTINCT r.rental_id) >= 43 AND 
COUNT(DISTINCT p.payment_id) >= 43;  --Filters customers who have at least 43 rentals and 43 payments



/* we have many customers who like movies, so we just pick the first one customer with customer_id=1 
 and update information.*/

--adding my first name, last name, address, etc.

WITH my_address AS (
    SELECT address_id 
    FROM public.address 
    WHERE LOWER(address) = '1913 hanoi way'  -- picked existing address
    LIMIT 1
),
target_customer AS (
    SELECT	
    		c.customer_id, 
    		a.address_id AS new_address_id
    FROM customer c
    CROSS	JOIN my_address a --I only need row matching to my address
/*the WHERE clause ensures the UPDATE only happens if the customer's first name, last name, email, 
 or address doesn't already match my values*/   
    WHERE c.customer_id = 1 
      AND (
           c.first_name != 'Rasa' OR 
           c.last_name != 'Zozaite' OR 
           c.email != 'rasazozaite@gmail.com' OR 
           c.address_id != a.address_id
      )
)
UPDATE public.customer
SET 
    first_name = 'Rasa',
    last_name = 'Zozaite',
    email = 'rasazozaite@gmail.com',
    address_id = target_customer.new_address_id,
    last_update = NOW()
FROM target_customer
WHERE public.customer.customer_id = target_customer.customer_id
RETURNING 
	customer.customer_id, 
	first_name, last_name, 
	email, 
	address_id, 
	last_update;



--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory' (rentals and payment tables)

-- first deleting payments made by me in order to avoid error violation of foreign key
WITH me AS ( --defining my identity with cte
  SELECT	
		customer_id
  FROM public.customer
  WHERE first_name = 'Rasa' AND
  		last_name = 'Zozaite'
)
DELETE FROM payment
WHERE 	customer_id IN (SELECT customer_id FROM me);


-- Deleting from rental table my info
WITH me AS (
  SELECT	
		customer_id
  FROM customer
  WHERE first_name = 'Rasa' AND
  		last_name = 'Zozaite'
)
DELETE FROM rental
WHERE	customer_id IN (SELECT customer_id FROM me);




/*Rent you favorite movies from the store they are in and pay for them 
(add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a new partition 
(see the scripts to install the training database ) or add records for the first half of 2017)*/

CREATE TABLE IF NOT EXISTS payment_2025 PARTITION OF public.payment
FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');

--cte, gathering information from inventory and store tables, film_id = 1001
WITH rental_info AS (
    SELECT 
         	i.inventory_id	AS inv_id,
         	c.customer_id	AS cust_id,
         	s.store_id
    FROM public.inventory i
    INNER	JOIN public.store s		ON s.store_id = i.store_id
    INNER 	JOIN public.customer c	ON c.customer_id = 1	AND --we need exactly mathing values
    		LOWER(c.first_name) = 'rasa'					AND 
    		LOWER(c.last_name) = 'zozaite'
    WHERE i.film_id = 1001
    LIMIT 1
)
INSERT INTO public.rental ( --inserting information 
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update
)
SELECT
    '2025-03-29'::timestamp,          -- rental_date
    rental_info.inv_id,               -- inventory_id from the CTE
    rental_info.cust_id,              -- customer_id from the CTE
    '2025-03-31'::timestamp,          -- return_date as I imagine
    rental_info.store_id,       -- staff_id dynamically selected from the store
    NOW()                            -- last_update
FROM rental_info
WHERE NOT EXISTS (
    SELECT rental_id 
    FROM public.rental
    WHERE rental_date = '2025-03-29'::timestamp
      AND inventory_id = rental_info.inv_id
      AND customer_id = rental_info.cust_id
)
RETURNING rental_id, customer_id, rental_date;



--info for another film_id 1002
WITH rental_info AS (
    SELECT 
         	i.inventory_id	AS inv_id,
         	c.customer_id	AS cust_id,
         	s.store_id
    FROM public.inventory i
    INNER	JOIN public.store s		ON s.store_id = i.store_id
    INNER 	JOIN public.customer c	ON c.customer_id = 1	AND --we need exactly mathing values
    		LOWER(c.first_name) = 'rasa'					AND 
    		LOWER(c.last_name) = 'zozaite'
    WHERE i.film_id = 1002
    LIMIT 1
)
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update
)
SELECT
    '2025-01-10'::timestamp,          -- rental_date
    rental_info.inv_id,               -- inventory_id from the CTE
    rental_info.cust_id,              -- customer_id from the CTE
    '2025-01-18'::timestamp,          -- return_date as I imagine
    rental_info.store_id,       -- staff_id dynamically selected from the store
    NOW()                            -- last_update
FROM rental_info
WHERE NOT EXISTS (
    SELECT rental_id 
    FROM public.rental
    WHERE rental_date = '2025-01-10'::timestamp
      AND inventory_id = rental_info.inv_id
      AND customer_id = rental_info.cust_id
)
RETURNING rental_id, customer_id, rental_date;


--info for another film_id 1003
WITH rental_info AS (
    SELECT 
         	i.inventory_id	AS inv_id,
         	c.customer_id	AS cust_id,
         	s.store_id
    FROM public.inventory i
    INNER	JOIN public.store s		ON s.store_id = i.store_id
    INNER 	JOIN public.customer c	ON c.customer_id = 1	AND --we need exactly mathing values
    		LOWER(c.first_name) = 'rasa'					AND 
    		LOWER(c.last_name) = 'zozaite'
    WHERE i.film_id = 1003
    LIMIT 1
)
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update
)
SELECT
    '2025-02-04'::timestamp,          -- rental_date
    rental_info.inv_id,               -- inventory_id from the CTE
    rental_info.cust_id,              -- customer_id from the CTE
    '2025-03-01'::timestamp,          -- return_date as I imagine
    rental_info.store_id,       -- staff_id dynamically selected from the store
    NOW()                            -- last_update
FROM rental_info
WHERE NOT EXISTS ( --preventing duplicates
    SELECT rental_id 
    FROM public.rental
    WHERE rental_date = '2025-02-04'::timestamp
      AND inventory_id = rental_info.inv_id
      AND customer_id = rental_info.cust_id
)
RETURNING rental_id, customer_id, rental_date;


--inserting payment for renting films


--gathering information from rental, film and inventory tables by joining tables for the film film_id = 1001 , Fight Club
WITH payment_info AS (
    SELECT 
         	f.film_id,
         	f.rental_rate	AS amount_film,
         	r.rental_id		AS rent_id,
         	r.customer_id	AS cust_id,
         	r.staff_id		AS rental_staff_id
    FROM public.film f
    INNER	JOIN public.inventory i ON f.film_id = i.film_id
    INNER	JOIN rental r 			ON i.inventory_id = r.inventory_id 
    WHERE 	r.rental_id = 32295
)
INSERT INTO public.payment ( 
    	customer_id,
    	staff_id,
    	rental_id,
    	amount,
    	payment_date
)
	SELECT           --inserting values
    		pi.cust_id,
   			pi.rental_staff_id,
    		pi.rent_id,
    		pi.amount_film,
    		'2025-03-29'::timestamp  -- I assume I pay the same day I rent a movie
FROM payment_info pi
WHERE NOT EXISTS (
    SELECT 	payment_id 
    FROM public.payment p
    WHERE 	p.rental_id = pi.rent_id AND
    		p.customer_id = pi.cust_id
)
RETURNING payment_id, rental_id, amount, payment_date;


--gathering information from rental, film and inventory tables by joining tables for film_id 1002, Schindler's List
WITH payment_info AS (
    SELECT 
         	f.film_id,
         	f.rental_rate	AS amount_film,
         	r.rental_id		AS rent_id,
         	r.customer_id	AS cust_id,
         	r.staff_id		AS rental_staff_id
    FROM public.film f
    INNER	JOIN public.inventory i ON f.film_id = i.film_id
    INNER	JOIN rental r 			ON i.inventory_id = r.inventory_id 
    WHERE 	r.rental_id = 32296
)
INSERT INTO public.payment ( 
    	customer_id,
    	staff_id,
    	rental_id,
    	amount,
    	payment_date
)
	SELECT           --inserting values
    		pi.cust_id,
   			pi.rental_staff_id,
    		pi.rent_id,
    		pi.amount_film,
    		'2025-01-10'::timestamp  -- I assume I pay the same day I rent a movie
FROM payment_info pi
WHERE NOT EXISTS (
    SELECT 	payment_id 
    FROM public.payment p
    WHERE 	p.rental_id = pi.rent_id AND
    		p.customer_id = pi.cust_id
)
RETURNING payment_id, rental_id, amount, payment_date;


--gathering information from rental, film and inventory tables by joining tables for the film film_id = 1003 , The Matrix

WITH payment_info AS (
    SELECT 
         	f.film_id,
         	f.rental_rate	AS amount_film,
         	r.rental_id		AS rent_id,
         	r.customer_id	AS cust_id,
         	r.staff_id		AS rental_staff_id
    FROM public.film f
    INNER	JOIN public.inventory i ON f.film_id = i.film_id
    INNER	JOIN rental r 			ON i.inventory_id = r.inventory_id 
    WHERE 	r.rental_id = 32297
)
INSERT INTO public.payment ( 
    	customer_id,
    	staff_id,
    	rental_id,
    	amount,
    	payment_date
)
	SELECT           --inserting values
    		pi.cust_id,
   			pi.rental_staff_id,
    		pi.rent_id,
    		pi.amount_film,
    		'2025-02-04'::timestamp  -- Naturally I would pay the same day I rent a movie
FROM payment_info pi
WHERE NOT EXISTS (
    SELECT 	payment_id 
    FROM public.payment p
    WHERE 	p.rental_id = pi.rent_id AND
    		p.customer_id = pi.cust_id
)
RETURNING payment_id, rental_id, amount, payment_date;



