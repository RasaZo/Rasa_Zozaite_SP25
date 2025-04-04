ALTER SEQUENCE film_film_id_seq RESTART WITH 1001; -- just to be sure that id numbering starts at 1001
SELECT last_value FROM film_film_id_seq; -- to check last id's value


/*Choose your top-3 favorite movies and add them to the 'film' table (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
*/

INSERT INTO film (film_id, title, description, release_year, language_id, 
                         original_language_id, rental_duration, rental_rate, length, 
                         replacement_cost, rating, last_update, special_features, fulltext)
SELECT 
    nextval('film_film_id_seq'), --provides fixed values for the new film entry id
    'Fight Club',
    'An insomniac office worker and a carefree soap salesman form an underground fight club that evolves into something much more.', 
    1999, 1, NULL, 1, 4.99, 139, 19.99, 'R'::mpaa_rating, now(), 
    '{Behind the Scenes, Deleted Scenes}', 
    to_tsvector('english', 'Fight Club Edward Norton Brad Pitt Helena Bonham Carter') --generates a full-text search vector.
WHERE NOT EXISTS (
    SELECT title FROM public.film WHERE title = 'Fight Club'
) --Ensures the script is rerunnable and does not insert duplicates.
RETURNING film_id;



INSERT INTO film (film_id, title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext)
SELECT nextval('film_film_id_seq'),
       'Schindler''s List',
       'Oskar Schindler becomes an unlikely humanitarian amid the barbaric Nazi reign when he turns his factory into a refuge for Jews.',
       1993, 1, NULL, 2, 9.99, 195, 19.99, 'R'::mpaa_rating, now(),
       '{Behind the Scenes, Deleted Scenes}',
       to_tsvector('english', 'Schindler''s List Oskar Schindler Jews Holocaust Nazi')
WHERE NOT EXISTS 
	(SELECT title FROM film WHERE title = 'Schindler''s List')
RETURNING film_id;



INSERT INTO film (film_id, title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext)
SELECT nextval('film_film_id_seq'), 
		'The Matrix', 'A computer hacker learns about the true nature of reality and his role in the war against its controllers.',
		1999, 1, NULL, 3, 19.99, 136, 19.99, 'R', NOW(), 
		'{Behind the Scenes, Deleted Scenes, Director Commentary}', 
		to_tsvector('english', 'The Matrix Keanu Reeves Laurence Fishburne Carrie-Anne Moss Hugo Weaving')
WHERE NOT EXISTS 
	(SELECT title FROM film WHERE title = 'The Matrix')
RETURNING film_id;




--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total). 

INSERT INTO actor (first_name, last_name, last_update)
SELECT first_name,last_name,last_update  FROM (  --This creates a temporary table-like structure with new actor data
    VALUES 
        ('Brad', 'Pitt', current_timestamp),
        ('Edward', 'Norton', current_timestamp),
        ('Liam', 'Neeson', current_timestamp),
        ('Ralph ', 'Fiennes', current_timestamp),
        ('Keanu', 'Reeves', current_timestamp),
        ('Laurence', 'Fishburne', current_timestamp)
) AS new_actors (first_name, last_name, last_update)
WHERE NOT EXISTS (   --prevents inserting duplicate actors,  if a match is found, the new record is skipped
    SELECT first_name, last_name FROM actor a 
    WHERE a.first_name = new_actors.first_name 
    AND a.last_name = new_actors.last_name
)
RETURNING actor_id, first_name, last_name; --id is automatically handled by program


INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_timestamp 
FROM (
    VALUES 
        ('Brad', 'Pitt', 'Fight Club'),
        ('Edward', 'Norton', 'Fight Club'),
        ('Liam', 'Neeson', 'Schindler''s List'),
        ('Ralph ', 'Fiennes', 'Schindler''s List'),
        ('Keanu', 'Reeves', 'The Matrix'),
        ('Laurence', 'Fishburne', 'The Matrix')
) AS new_data (first_name, last_name, film_title) ----creates an inline temporary table (new_data) with three columns
FULL JOIN actor a ON a.first_name = new_data.first_name AND a.last_name = new_data.last_name --in order to retrieve the actor_id for each matching actor
FULL JOIN film f ON f.title = new_data.film_title --in order to retrieve the film_id for each matching fil
ON CONFLICT (actor_id, film_id) DO NOTHING --in order to prevent duplicate entries
RETURNING actor_id, film_id; -- to check output

--Add your favorite movies to any store's inventory.


INSERT INTO inventory (film_id, store_id, last_update)
SELECT film_id, 1, NOW() 
FROM film 
WHERE title IN ('Fight Club', 'Schindler''s List', 'The Matrix') --to filter only these three movies
RETURNING film_id, store_id; -- to check returning values


/*Alter any existing customer in the database with at least 43 rental and 43 payment records. 
Change their personal data to yours (first name, last name, address, etc.). */

-- So first, we need to find a customer with a least 43 rental and 43 payment records 
SELECT c.customer_id 
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id -- in order to add table with a rental time and ensure that only customers who meet both conditions are included
INNER JOIN payment p ON c.customer_id = p.customer_id -- in order to add table with payments 
GROUP BY c.customer_id 
HAVING COUNT(DISTINCT r.rental_id) >= 43 AND 
COUNT(DISTINCT p.payment_id) >= 43;  --Filters customers who have at least 43 rentals and 43 payments

-- So we have many customers who likes movies, so we just pick the first one and update information

UPDATE customer
SET first_name = 'Rasa',
    last_name = 'Zozaite',
    email = 'rasazozaite@gmail.com', -- filling with my info
    address_id = (SELECT address_id FROM address ORDER BY RANDOM() LIMIT 1), -- Selects any existing address randomly 
    last_update = NOW()
WHERE customer_id = (  --in order to fin a specific customer ID that meets certain conditions
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1 
)
RETURNING customer_id, first_name, last_name, email, address_id, last_update;




--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
--Not finished

-- in order to drop the existing foreign key constraint
ALTER TABLE payment_p2017_01 
DROP CONSTRAINT payment_p2017_01_rental_id_fkey;

-- to add the new foreign key constraint with ON DELETE CASCADE
ALTER TABLE payment_p2017_01 
ADD CONSTRAINT payment_p2017_01_rental_id_fkey 
FOREIGN KEY (rental_id) 
REFERENCES rental(rental_id) 
ON DELETE CASCADE;

--to delete from the rental table
DELETE FROM rental 
WHERE customer_id IN (
    SELECT customer_id FROM customer 
    WHERE first_name = 'Rasa' AND last_name = 'Zozaite'
);


-- in order to delete payments related to me
DELETE FROM payment 
WHERE customer_id = (SELECT customer_id FROM customer 
                     WHERE first_name = 'Rasa' AND last_name = 'Zozaite');




/*Rent you favorite movies from the store they are in and pay for them 
(add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a new partition 
(see the scripts to install the training database ) or add records for the first half of 2017)*/

CREATE TABLE payment_2025 PARTITION OF public.payment
FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');


--not finished:( 

















