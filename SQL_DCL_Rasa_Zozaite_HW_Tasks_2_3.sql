--1. Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.

--creating the user with a password
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

-- allowing the user to connect to the dvdrental database
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- making sure the user cannot use the public schema (no USAGE privilege)
REVOKE ALL ON SCHEMA public FROM rentaluser;

-- 2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
--granting permission to run SELECT on customer table
GRANT SELECT ON TABLE customer TO rentaluser;

--testing if it works
SELECT 
	customer.customer_id, 
	customer.first_name, 
	customer.last_name  
FROM public.customer
ORDER BY customer_id ASC; --not necessary line but just for order



--3. Create a new user group called "rental" and add "rentaluser" to the group.
-- creating the group 
CREATE ROLE rental;

-- adding rentaluser to the group
GRANT rental TO rentaluser;

--granting permissions to rental
GRANT INSERT, UPDATE ON TABLE rental TO rental;



/* 4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update 
one existing row in the "rental" table under that role. 
Inserting new row under the role rental. 
Because I do not have rights to get information from other tables (like staff_id) I had to write values manually*/

INSERT INTO public.rental (
	rental_id,
	rental_date, 
	inventory_id, 
	customer_id, 
	return_date,
	staff_id, 
	last_update)
VALUES (
	32298,
	'2025-04-08', 
	18,
	1,
	'2025-04-12',
	4,
	CURRENT_TIMESTAMP
);


/* 5. Revoke the "rental" group's INSERT permission for the "rental" table. 
 *Try to insert new rows into the "rental" table make sure this action is denied.*/


--setting role to superuser, because rental itself can not revoke insert
SET ROLE postgres;

--revoking insert
REVOKE INSERT ON TABLE rental FROM rental;


--checking  privilegies
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'rental' AND grantee = 'rental'; -- now rental has left with UPDATE privilege

--switching to user rental
SET ROLE rental;

--testing
INSERT INTO public.rental (
	rental_id,
	rental_date, 
	inventory_id, 
	customer_id, 
	return_date,
	staff_id, 
	last_update)
VALUES (
	32300,
	'2025-04-09',
	1,
	1,
	'2025-04-14',
	1, 
	CURRENT_TIMESTAMP);

-- SQL Error [42501]: ERROR: permission denied for table rental Error position:


/* 6.Create a personalized role for any customer already existing in the dvd_rental database. 
The name of the role name must be client_{first_name}_{last_name} (omit curly brackets).
The customer's payment and rental history must not be empty.*/

-- I chose the customer whose ID was 2

--checking payment and rental history of customer_id 2 if history is not empty

SELECT *
FROM payment p 
JOIN rental r ON p.customer_id = r.customer_id
WHERE p.customer_id = 2;

--creating a role

CREATE ROLE client_patricia_johnson;



/*Task 3. Implement row-level security
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
Write a query to make sure this user sees only their own data.*/

--first I need to enable rls

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;


-- creating rental table policy
CREATE POLICY rental_policy_client_patricia_johnson --this creates a row-level security policy named
ON rental                                            --applying the policy to the rental table
FOR SELECT TO client_patricia_johnson -- the policy applies to SELECT queries only so the client can only select and see her information
USING (customer_id = 2); --this role can only see rows where customer_id = 2

-- creating payment table policy
CREATE POLICY payment_policy_client_patricia_johnson
ON payment
FOR SELECT TO client_patricia_johnson
USING (customer_id = 2); 

--granting SELECT access to both tables

GRANT SELECT ON rental TO client_patricia_johnson;
GRANT SELECT ON payment TO client_patricia_johnson;


--testing if I can see only patricia_johnson's (customer_id = 2) information

SET ROLE client_patricia_johnson;

SELECT * FROM rental;
SELECT * FROM payment;









