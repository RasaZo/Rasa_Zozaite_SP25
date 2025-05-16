/*3. Create a physical database with a separate database and schema and give it an appropriate domain-related name.
Create relationships between tables using primary and foreign keys.
Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example
*/

--creating database and schema

DROP DATABASE IF EXISTS museum_management;
CREATE DATABASE museum_management;

CREATE SCHEMA IF NOT EXISTS information;
SET search_path TO information;

--creating tables for our museum_management database

-- Table: museum
CREATE TABLE IF NOT EXISTS information.museum (
    museum_id SERIAL PRIMARY KEY,
    museum_name VARCHAR(255),
    museum_address VARCHAR(255),
    museum_phone VARCHAR(20),
    museum_email VARCHAR(100),
    museum_website VARCHAR(100)
);

-- Table: budget
CREATE TABLE IF NOT EXISTS information.budget (
    budget_id SERIAL PRIMARY KEY,
    museum_id INT,
    approver_id INT,
    budget_amount DECIMAL(12,2),
    budget_expenses DECIMAL(12,2),
    budget_fiscal_year DATE,
    budget_purpose VARCHAR(255),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: employee
CREATE TABLE IF NOT EXISTS information.employee (
    employee_id SERIAL PRIMARY KEY,
    museum_id INT,
    employee_full_name VARCHAR(255),
    employee_position VARCHAR(100),
    employee_department VARCHAR(100),
    employee_hiring_date DATE,
    employee_end_date DATE,
    employee_salary DECIMAL(10,2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: object
CREATE TABLE IF NOT EXISTS information.object (
    object_id SERIAL PRIMARY KEY,
    museum_id INT,
    object_title VARCHAR(255),
    object_description TEXT,
    object_type VARCHAR(100),
    object_creation_date DATE,
    object_author VARCHAR(255),
    object_digital_archive_url VARCHAR(500),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: object_loan
CREATE TABLE IF NOT EXISTS information.object_loan (
    object_loan_id SERIAL PRIMARY KEY,
    registrar_id INT,
    object_id INT,
    object_loan_date DATE,
    object_loan_return DATE,
    object_loan_institution VARCHAR(255),
    object_loan_status VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: object_borrow
CREATE TABLE IF NOT EXISTS information.object_borrow (
    object_borrow_id SERIAL PRIMARY KEY,
    registrar_id INT,
    object_id INT,
    object_borrow_date DATE,
    object_borrow_end DATE,
    object_borrow_institution VARCHAR(255),
    object_borrow_status VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: storage
CREATE TABLE IF NOT EXISTS information.storage (
    storage_id SERIAL PRIMARY KEY,
    object_id INT,
    storage_location VARCHAR(255),
    storage_condition TEXT,
    storage_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: display
CREATE TABLE IF NOT EXISTS information.display (
    display_id SERIAL PRIMARY KEY,
    object_id INT,
    event_id INT,
    display_start DATE,
    display_end DATE,
    display_status VARCHAR(100),
    display_location VARCHAR(255),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: event
CREATE TABLE IF NOT EXISTS information.event (
    event_id SERIAL PRIMARY KEY,
    organizer_id INT,
    event_name VARCHAR(255),
    event_type VARCHAR(100),
    event_description TEXT,
    event_start_date TIMESTAMP,
    event_end_date TIMESTAMP,
    event_location VARCHAR(255),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: employee_event (junction table)
CREATE TABLE IF NOT EXISTS information.employee_event (
    employee_id INT,
    event_id INT,
    PRIMARY KEY (employee_id, event_id)
);

-- Table: visitor
CREATE TABLE IF NOT EXISTS information.visitor (
    visitor_id SERIAL PRIMARY KEY,
    museum_id INT,
    visitor_full_name VARCHAR(255),
    visitor_email VARCHAR(255),
    visitor_phone VARCHAR(100),
    visitor_type VARCHAR(100),
    visitor_group_name VARCHAR(100),
    visitor_number_of_visitors INT,
    visitor_educator_required BOOLEAN,
    visitor_notes TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Table: ticket
CREATE TABLE IF NOT EXISTS information.ticket (
    ticket_id SERIAL PRIMARY KEY,
    visitor_id INT,
    ticket_purchase_date DATE,
    ticket_type VARCHAR(100),
    ticket_price DECIMAL(8,2),
    ticket_payment_method VARCHAR(100)
);


-- adding constraints to the tables

-- Museum --
ALTER TABLE information.museum
  	DROP CONSTRAINT IF EXISTS uq_museum_email,
  	ADD CONSTRAINT uq_museum_email UNIQUE (museum_email),
  	ALTER COLUMN museum_name    SET NOT NULL,
  	ALTER COLUMN museum_address SET NOT NULL,
  	ALTER COLUMN museum_phone   SET NOT NULL,
 	ALTER COLUMN museum_email   SET NOT NULL;


-- Budget --
ALTER TABLE information.budget
  DROP CONSTRAINT IF EXISTS fk_budget_museum,
  ADD CONSTRAINT fk_budget_museum FOREIGN KEY (museum_id)   REFERENCES information.museum(museum_id),
  DROP CONSTRAINT IF EXISTS fk_budget_approver,
  ADD CONSTRAINT fk_budget_approver FOREIGN KEY (approver_id) REFERENCES information.employee(employee_id),
  DROP CONSTRAINT IF EXISTS chk_budget_amount_positive,
  ADD CONSTRAINT chk_budget_amount_positive CHECK (budget_amount >= 0),
  DROP CONSTRAINT IF EXISTS chk_budget_expenses_positive,
  ADD CONSTRAINT chk_budget_expenses_positive CHECK (budget_expenses >= 0),
  DROP CONSTRAINT IF EXISTS uq_budget_museum_year,
  ADD CONSTRAINT  uq_budget_museum_year UNIQUE (museum_id, budget_fiscal_year),
  ALTER COLUMN museum_id          SET NOT NULL,
  ALTER COLUMN approver_id        SET NOT NULL,
  ALTER COLUMN budget_amount      SET NOT NULL,
  ALTER COLUMN budget_expenses    SET NOT NULL,
  ALTER COLUMN budget_fiscal_year SET NOT NULL,
  ALTER COLUMN budget_purpose     SET NOT NULL,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

-- Employee --
ALTER TABLE information.employee
  DROP CONSTRAINT IF EXISTS fk_employee_museum,
  ADD CONSTRAINT fk_employee_museum FOREIGN KEY (museum_id) REFERENCES information.museum(museum_id),
  DROP CONSTRAINT IF EXISTS uq_employee_museum_fullname,
  ADD CONSTRAINT uq_employee_museum_fullname UNIQUE (museum_id, employee_full_name),
  DROP CONSTRAINT IF EXISTS chk_employee_salary_positive,
  ADD CONSTRAINT chk_employee_salary_positive CHECK (employee_salary >= 0),
  ALTER COLUMN museum_id            SET NOT NULL,
  ALTER COLUMN employee_full_name   SET NOT NULL,
  ALTER COLUMN employee_position    SET NOT NULL,
  ALTER COLUMN employee_department  SET NOT NULL,
  ALTER COLUMN employee_hiring_date SET NOT NULL,
  ALTER COLUMN employee_salary      SET NOT NULL,
  ALTER COLUMN last_updated 		SET DEFAULT CURRENT_TIMESTAMP;

-- Object --
ALTER TABLE information.object
  DROP CONSTRAINT IF EXISTS fk_object_museum,
  ADD CONSTRAINT fk_object_museum FOREIGN KEY (museum_id) REFERENCES information.museum(museum_id),
  DROP CONSTRAINT IF EXISTS uq_object_title_museum,
  ADD CONSTRAINT uq_object_title_museum UNIQUE (museum_id, object_title),
  DROP CONSTRAINT IF EXISTS chk_object_type_valid,
  ADD CONSTRAINT chk_object_type_valid CHECK (object_type IN ('Painting','Sculpture','Document','Artifact','Exhibit','Installation','Model','Technology Exhibit','Other')),
  ALTER COLUMN object_title SET NOT NULL,
  ALTER COLUMN object_type  SET NOT NULL,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

-- Object Loan --
ALTER TABLE information.object_loan
  DROP CONSTRAINT IF EXISTS fk_objectloan_registrar,
  ADD CONSTRAINT     fk_objectloan_registrar    FOREIGN KEY (registrar_id) REFERENCES information.employee(employee_id),
  DROP CONSTRAINT IF EXISTS fk_objectloan_object,
  ADD CONSTRAINT     fk_objectloan_object       FOREIGN KEY (object_id)    REFERENCES information.object(object_id),
  DROP CONSTRAINT IF EXISTS uq_objectloan_unique,
  ADD CONSTRAINT uq_objectloan_unique UNIQUE (object_id, registrar_id, object_loan_date),
  ALTER COLUMN object_loan_date SET NOT NULL,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

--  Object Borrow --
ALTER TABLE information.object_borrow
  DROP CONSTRAINT IF EXISTS fk_objectborrow_registrar,
  ADD CONSTRAINT fk_objectborrow_registrar FOREIGN KEY (registrar_id) REFERENCES information.employee(employee_id),
  DROP CONSTRAINT IF EXISTS fk_objectborrow_object,
  ADD CONSTRAINT fk_objectborrow_object FOREIGN KEY (object_id) REFERENCES information.object(object_id),
  DROP CONSTRAINT IF EXISTS uq_objectborrow_unique,
  ADD CONSTRAINT uq_objectborrow_unique UNIQUE (object_id, registrar_id, object_borrow_date),
  ALTER COLUMN object_borrow_date SET NOT NULL,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

--  Storage --
ALTER TABLE information.storage
  DROP CONSTRAINT IF EXISTS fk_storage_object,
  ADD CONSTRAINT fk_storage_object FOREIGN KEY (object_id) REFERENCES information.object(object_id),
  DROP CONSTRAINT IF EXISTS uq_storage_object_date,
  ADD CONSTRAINT uq_storage_object_date UNIQUE (object_id, storage_date),
  ALTER COLUMN storage_location SET NOT NULL,
  ALTER COLUMN storage_date SET DEFAULT CURRENT_DATE,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

--  Display --
ALTER TABLE information.display
  DROP CONSTRAINT IF EXISTS fk_display_object,
  ADD CONSTRAINT fk_display_object FOREIGN KEY (object_id) REFERENCES information.object(object_id),
  DROP CONSTRAINT IF EXISTS fk_display_event,
  ADD CONSTRAINT fk_display_event FOREIGN KEY (event_id) REFERENCES information.event(event_id),
  DROP CONSTRAINT IF EXISTS uq_display_object_event,
  ADD CONSTRAINT uq_display_object_event UNIQUE (object_id, event_id),
  ALTER COLUMN display_start  SET NOT NULL,
  ALTER COLUMN display_end    SET NOT NULL,
  ALTER COLUMN display_status SET DEFAULT 'planned',
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

--  Event --
ALTER TABLE information.event
  DROP CONSTRAINT IF EXISTS fk_event_organizer,
  ADD CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) REFERENCES information.employee(employee_id),
  DROP CONSTRAINT IF EXISTS chk_event_start_after_2024,
  ADD CONSTRAINT chk_event_start_after_2024 CHECK (event_start_date > TIMESTAMP '2024-01-01 00:00:00'),
  DROP CONSTRAINT IF EXISTS uq_event_name_start,
  ADD CONSTRAINT uq_event_name_start UNIQUE (event_name, event_start_date),
  ALTER COLUMN event_name SET NOT NULL,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

-- Employee_Event (junction) --
ALTER TABLE information.employee_event
  DROP CONSTRAINT IF EXISTS fk_employeeevent_employee,
  ADD CONSTRAINT fk_employeeevent_employee FOREIGN KEY (employee_id) REFERENCES information.employee(employee_id),
  DROP CONSTRAINT IF EXISTS fk_employeeevent_event,
  ADD CONSTRAINT fk_employeeevent_event FOREIGN KEY (event_id)    REFERENCES information.event(event_id),
  ALTER COLUMN employee_id SET NOT NULL,
  ALTER COLUMN event_id    SET NOT NULL;


-- Visitor --
ALTER TABLE information.visitor
  DROP CONSTRAINT IF EXISTS fk_visitor_museum,
  ADD CONSTRAINT fk_visitor_museum          FOREIGN KEY (museum_id)   REFERENCES information.museum(museum_id),
  DROP CONSTRAINT IF EXISTS chk_visitor_type_valid,
  ADD CONSTRAINT  chk_visitor_type_valid     CHECK (visitor_type IN ('Individual','Group','School')),
  ALTER COLUMN visitor_type  SET NOT NULL,
  ALTER COLUMN visitor_educator_required SET DEFAULT FALSE,
  ALTER COLUMN last_updated SET DEFAULT CURRENT_TIMESTAMP;

-- Ticket --
ALTER TABLE information.ticket
  DROP CONSTRAINT IF EXISTS fk_ticket_visitor,
  ADD CONSTRAINT     fk_ticket_visitor FOREIGN KEY (visitor_id)  REFERENCES information.visitor(visitor_id),
  DROP CONSTRAINT IF EXISTS chk_ticket_price_positive,
  ADD CONSTRAINT     chk_ticket_price_positive  CHECK (ticket_price >= 0),
  ALTER COLUMN ticket_purchase_date SET NOT NULL,
  ALTER COLUMN ticket_price         SET NOT NULL,
  ALTER COLUMN ticket_purchase_date SET DEFAULT CURRENT_DATE;





								
--Inserting values into tables  								
--museum--
INSERT INTO information.museum (museum_name, museum_address, museum_phone, museum_email, museum_website)
SELECT 
    INITCAP(TRIM(vals.museum_name)), 
    INITCAP(TRIM(vals.museum_address)),
    TRIM(vals.museum_phone),
    LOWER(TRIM(vals.museum_email)),
    LOWER(TRIM(vals.museum_website))
FROM (
    VALUES 
        (' Aurora Museum of Modern Art ', ' Art Street 5, Vilnius ', '+37061111111', ' info@auroramodernart.lt ', ' www.auroramodernart.lt '),
        (' Horizon Science Discovery Center ', ' Discovery Blvd 10, Kaunas ', '+37061111112', ' contact@horizonscience.lt ', ' www.horizonscience.lt '),
        (' Green Valley Natural History Museum ', ' Nature Ave 3, Klaipeda ', '+37061111113', ' info@greenvalleynature.lt ', ' www.greenvalleynature.lt '),
        (' Baltic Innovation and Technology Museum ', ' Tech Park 7, Siauliai ', '+37061111114', ' support@baltictechmuseum.lt ', ' www.baltictechmuseum.lt '),
        (' Echoes of the Past History Museum ', ' Legacy St. 9, Panevezys ', '+37061111115', ' history@echoesofthepast.lt ', ' www.echoesofthepast.lt '),
        (' Riverstone Children''s Exploration Museum ', ' Adventure Road 12, Alytus ', '+37061111116', ' kids@riverstonemuseum.lt ', ' www.riverstonemuseum.lt ')
) AS vals(museum_name, museum_address, museum_phone, museum_email, museum_website)
WHERE NOT EXISTS (
    SELECT 1 FROM information.museum m 
    WHERE m.museum_name = INITCAP(TRIM(vals.museum_name))
);


--employee--
INSERT INTO information.employee (
    museum_id, employee_full_name, employee_position, employee_department, 
    employee_hiring_date, employee_end_date, employee_salary
)
SELECT 
    vals.museum_id,
    INITCAP(TRIM(vals.employee_full_name)),
    INITCAP(TRIM(vals.employee_position)),
    INITCAP(TRIM(vals.employee_department)),
    vals.employee_hiring_date,
    vals.employee_end_date::date,
    vals.employee_salary
FROM (
    VALUES 
        (1, ' Alice Johnson ', ' Curator ', ' Art ', DATE '2018-03-15', NULL::date, 4500.00),
        (2, ' Bob Smith ', ' Director ', ' Management ', DATE '2016-07-01', NULL::date, 7000.00),
        (3, ' Carol White ', ' Educator ', ' Education ', DATE '2019-05-20', NULL::date, 3500.00),
        (4, ' David Brown ', ' Technician ', ' Technology ', DATE '2020-02-10', NULL::date, 4000.00),
        (5, ' Emily Green ', ' Archivist ', ' History ', DATE '2017-09-12', NULL::date, 3800.00),
        (6, ' Frank Black ', ' Guide ', ' Visitor Services ', DATE '2021-01-25', NULL::date, 3000.00)
) AS vals(museum_id, employee_full_name, employee_position, employee_department, employee_hiring_date, employee_end_date, employee_salary)
WHERE NOT EXISTS (
    SELECT 1 FROM information.employee e 
    WHERE e.employee_full_name = INITCAP(TRIM(vals.employee_full_name))
);


--budget--
INSERT INTO information.budget (
    museum_id, approver_id, budget_amount, budget_expenses, 
    budget_fiscal_year, budget_purpose)
SELECT 
    vals.museum_id,
    vals.approver_id,
    vals.budget_amount,
    vals.budget_expenses,
    vals.budget_fiscal_year,
    INITCAP(TRIM(vals.budget_purpose))
FROM ( VALUES 
        (1, 1, 150000.00, 60000.00, DATE '2025-01-01', 'Modern Art Exhibition Funding'),
        (2, 2, 120000.00, 50000.00, DATE '2024-01-01', 'Science Innovation Labs'),
        (3, 3, 110000.00, 45000.00, DATE '2024-01-01', 'Nature Conservation Projects'),
        (4, 4, 130000.00, 60000.00, DATE '2025-01-01', 'New Tech Exhibitions'),
        (5, 5, 100000.00, 40000.00, DATE '2024-01-01', 'Historic Preservation Projects'),
        (6, 6, 95000.00, 35000.00, DATE '2025-01-01', 'Children''s Interactive Zones')
) AS vals(museum_id, approver_id, budget_amount, budget_expenses, budget_fiscal_year, budget_purpose)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.budget b 
    WHERE b.museum_id = vals.museum_id 
      AND b.budget_fiscal_year = vals.budget_fiscal_year
);


--OBJECT--
INSERT INTO information.object (
    museum_id, object_title, object_description, object_type, 
    object_creation_date, object_author, object_digital_archive_url
)
SELECT 
    vals.museum_id,
    INITCAP(TRIM(vals.object_title)),
    TRIM(vals.object_description),
    vals.object_type,
    vals.object_creation_date,
    INITCAP(TRIM(vals.object_author)),
    TRIM(vals.object_digital_archive_url)
FROM (
    VALUES 
        (1, 'Sunset Over Vilnius', 'A painting capturing the twilight skyline of Vilnius.', 'Painting', DATE '1990-06-15', 'Jonas Petraitis', 'https://archive.auroramodernart.lt/sunset-over-vilnius'),
        (2, 'Steam Engine Model', 'A working model of a 19th-century steam engine.', 'Model', DATE '1880-03-10', 'Unknown', 'https://archive.horizonscience.lt/steam-engine'),
        (3, 'Woolly Mammoth Tooth', 'Fossilized tooth of a woolly mammoth.', 'Artifact', DATE '0001-01-01', 'Prehistoric', 'https://archive.greenvalleynature.lt/mammoth-tooth'),
        (4, 'AI Companion Robot', 'Prototype robot designed for elder care.', 'Technology Exhibit', DATE '2022-11-20', 'InnoTech Labs', 'https://archive.baltictechmuseum.lt/ai-companion'),
        (5, 'Battlefield Map 1812', 'Historical map used in the Napoleonic Wars.', 'Document', DATE '1812-07-01', 'Military Cartographers', 'https://archive.echoesofthepast.lt/battlefield-map'),
        (6, 'Dinosaur Nest Replica', 'A life-size reconstruction of a dinosaur nest.', 'Exhibit', DATE '2021-04-12', 'Team PaleoArt', 'https://archive.riverstonemuseum.lt/dino-nest')
) AS vals(museum_id, object_title, object_description, object_type, object_creation_date, object_author, object_digital_archive_url)
WHERE NOT EXISTS (
    SELECT 1 FROM information.object o 
    WHERE o.object_title = INITCAP(TRIM(vals.object_title)) AND o.museum_id = vals.museum_id
);

--EVENT--
INSERT INTO information.event (
    organizer_id, event_name, event_type, event_description, 
    event_start_date, event_end_date, event_location
)
SELECT 
    vals.organizer_id,
    INITCAP(TRIM(vals.event_name)),
    INITCAP(TRIM(vals.event_type)),
    TRIM(vals.event_description),
    vals.event_start_date,
    vals.event_end_date,
    INITCAP(TRIM(vals.event_location))
FROM (
    VALUES 
        (1, 'Modern Landscapes Exhibition', 'Exhibition', 'Showcasing modern interpretations of landscapes.', TIMESTAMP '2024-06-01 10:00:00', TIMESTAMP '2024-08-30 18:00:00', 'Gallery A'),
        (2, 'Tech and Future', 'Conference', 'Annual technology innovations showcase.', TIMESTAMP '2024-09-10 09:00:00', TIMESTAMP '2024-09-12 17:00:00', 'Main Hall'),
        (3, 'Jurassic Journeys', 'Educational Program', 'Interactive event for children exploring prehistoric times.', TIMESTAMP '2024-07-05 10:00:00', TIMESTAMP '2024-07-10 16:00:00', 'Children Wing'),
        (4, 'Robots of Tomorrow', 'Workshop', 'Hands-on sessions building basic robots.', TIMESTAMP '2024-08-01 11:00:00', TIMESTAMP '2024-08-03 15:00:00', 'Lab 1'),
        (5, 'History Revealed', 'Lecture', 'A deep dive into lesser-known historical facts.', TIMESTAMP '2024-10-15 14:00:00', TIMESTAMP '2024-10-15 16:00:00', 'Auditorium B'),
        (6, 'Explore the Senses', 'Experience Tour', 'A multi-sensory tour designed for kids.', TIMESTAMP '2024-05-20 09:30:00', TIMESTAMP '2024-05-25 17:00:00', 'Exploration Zone')
) AS vals(organizer_id, event_name, event_type, event_description, event_start_date, event_end_date, event_location)
WHERE NOT EXISTS (
    SELECT 1 FROM information.event e 
    WHERE e.event_name = INITCAP(TRIM(vals.event_name)) AND e.event_start_date = vals.event_start_date
);

--VISITOR--
INSERT INTO information.visitor (
    museum_id, visitor_full_name, visitor_email, visitor_phone, 
    visitor_type, visitor_group_name, visitor_number_of_visitors, 
    visitor_educator_required, visitor_notes
)
SELECT 
    vals.museum_id,
    INITCAP(TRIM(vals.visitor_full_name)),
    LOWER(TRIM(vals.visitor_email)),
    TRIM(vals.visitor_phone),
    INITCAP(TRIM(vals.visitor_type)),
    INITCAP(TRIM(vals.visitor_group_name)),
    vals.visitor_number_of_visitors,
    vals.visitor_educator_required,
    TRIM(vals.visitor_notes)
FROM (
    VALUES 
        (1, 'John Doe', 'john.doe@example.com', '+37061111101', 'Individual', NULL, 1, FALSE, 'First-time visitor.'),
        (2, 'Bright Minds School', 'contact@brightminds.edu', '+37061111102', 'School', 'Bright Minds', 30, TRUE, 'Needs educational tour.'),
        (3, 'Family Group', 'family@example.com', '+37061111103', 'Group', 'Doe Family', 5, FALSE, 'Family weekend visit.'),
        (4, 'Tech Explorers', 'info@techexplorers.com', '+37061111104', 'Group', 'Tech Explorers', 15, FALSE, 'Interested in technology exhibits.'),
        (5, 'Anna Smith', 'anna.smith@example.com', '+37061111105', 'Individual', NULL, 1, FALSE, 'Requested wheelchair access.'),
        (6, 'Future Leaders Academy', 'leaders@academy.edu', '+37061111106', 'School', 'Future Leaders', 25, TRUE, 'Requires science lab visit.')
) AS vals(museum_id, visitor_full_name, visitor_email, visitor_phone, visitor_type, visitor_group_name, visitor_number_of_visitors, visitor_educator_required, visitor_notes)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.visitor v 
    WHERE v.visitor_full_name = INITCAP(TRIM(vals.visitor_full_name))
);


--TICKET--
INSERT INTO information.ticket (
    visitor_id, ticket_purchase_date, ticket_type, ticket_price, ticket_payment_method
)
SELECT 
    vals.visitor_id,
    vals.ticket_purchase_date,
    INITCAP(TRIM(vals.ticket_type)),
    vals.ticket_price,
    INITCAP(TRIM(vals.ticket_payment_method))
FROM (
    VALUES 
        (1, DATE '2024-05-10', 'Standard', 15.00, 'Card'),
        (2, DATE '2024-05-12', 'Group', 100.00, 'Bank Transfer'),
        (3, DATE '2024-05-11', 'Family', 50.00, 'Cash'),
        (4, DATE '2024-05-13', 'Group', 75.00, 'Card'),
        (5, DATE '2024-05-14', 'Standard', 15.00, 'Cash'),
        (6, DATE '2024-05-15', 'School', 120.00, 'Bank Transfer')
) AS vals(visitor_id, ticket_purchase_date, ticket_type, ticket_price, ticket_payment_method)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.ticket t 
    WHERE t.visitor_id = vals.visitor_id 
      AND t.ticket_purchase_date = vals.ticket_purchase_date
);


--EVENT_EMPLOYEE--
INSERT INTO information.employee_event (employee_id, event_id)
SELECT 
    vals.employee_id, 
    vals.event_id
FROM (
    VALUES 
        (1, 1),
        (2, 2),
        (3, 3),
        (4, 4),
        (5, 5),
        (6, 6)
) AS vals(employee_id, event_id)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.employee_event ee 
    WHERE ee.employee_id = vals.employee_id 
      AND ee.event_id = vals.event_id
);


--OBJECT LOAN--
INSERT INTO information.object_loan (
    registrar_id, object_id, object_loan_date, object_loan_return, 
    object_loan_institution, object_loan_status
)
SELECT 
    vals.registrar_id,
    vals.object_id,
    vals.object_loan_date,
    vals.object_loan_return,
    INITCAP(TRIM(vals.object_loan_institution)),
    INITCAP(TRIM(vals.object_loan_status))
FROM (
    VALUES 
        (1, 1, DATE '2024-03-01', DATE '2024-06-01', 'Louvre Museum', 'Returned'),
        (2, 2, DATE '2024-04-15', DATE '2024-07-15', 'British Museum', 'Active'),
        (3, 3, DATE '2024-01-20', DATE '2024-04-20', 'Natural History Museum', 'Returned'),
        (4, 4, DATE '2024-02-10', DATE '2024-05-10', 'MIT Technology Center', 'Active'),
        (5, 5, DATE '2024-03-25', DATE '2024-06-25', 'War History Museum', 'Active'),
        (6, 6, DATE '2024-04-05', DATE '2024-07-05', 'Children Discovery Museum', 'Planned')
) AS vals(registrar_id, object_id, object_loan_date, object_loan_return, object_loan_institution, object_loan_status)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.object_loan ol 
    WHERE ol.object_id = vals.object_id 
      AND ol.object_loan_date = vals.object_loan_date
);



--OBJECT_BORROW--
INSERT INTO information.object_borrow (
    registrar_id, object_id, object_borrow_date, object_borrow_end, 
    object_borrow_institution, object_borrow_status
)
SELECT 
    vals.registrar_id,
    vals.object_id,
    vals.object_borrow_date,
    vals.object_borrow_end,
    INITCAP(TRIM(vals.object_borrow_institution)),
    INITCAP(TRIM(vals.object_borrow_status))
FROM (
    VALUES 
        (1, 1, DATE '2024-05-01', DATE '2024-08-01', 'Berlin Art House', 'Active'),
        (2, 2, DATE '2024-04-10', DATE '2024-07-10', 'Tokyo Tech Expo', 'Planned'),
        (3, 3, DATE '2024-03-15', DATE '2024-06-15', 'Copenhagen History Center', 'Returned'),
        (4, 4, DATE '2024-02-01', DATE '2024-05-01', 'Silicon Valley Museum', 'Active'),
        (5, 5, DATE '2024-03-20', DATE '2024-06-20', 'Paris Heritage Center', 'Planned'),
        (6, 6, DATE '2024-05-05', DATE '2024-08-05', 'London Science World', 'Active')
) AS vals(registrar_id, object_id, object_borrow_date, object_borrow_end, object_borrow_institution, object_borrow_status)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.object_borrow ob 
    WHERE ob.object_id = vals.object_id 
      AND ob.object_borrow_date = vals.object_borrow_date
);


--STORAGE--
INSERT INTO information.storage (
    object_id, storage_location, storage_condition, storage_date
)
SELECT 
    vals.object_id,
    INITCAP(TRIM(vals.storage_location)),
    TRIM(vals.storage_condition),
    vals.storage_date
FROM (
    VALUES 
        (1, 'Vault A1', 'Excellent', DATE '2024-01-15'),
        (2, 'Lab Storage B3', 'Good', DATE '2024-02-10'),
        (3, 'Fossil Room C2', 'Fair', DATE '2024-03-05'),
        (4, 'Tech Locker D5', 'Excellent', DATE '2024-01-25'),
        (5, 'Archives E7', 'Good', DATE '2024-02-20'),
        (6, 'Kids Section Storage', 'Excellent', DATE '2024-03-15')
) AS vals(object_id, storage_location, storage_condition, storage_date)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.storage s 
    WHERE s.object_id = vals.object_id 
      AND s.storage_date = vals.storage_date
);


--DISPLAY--
INSERT INTO information.display (
    object_id, event_id, display_start, display_end, display_status, display_location
)
SELECT 
    vals.object_id,
    vals.event_id,
    vals.display_start,
    vals.display_end,
    INITCAP(TRIM(vals.display_status)),
    INITCAP(TRIM(vals.display_location))
FROM (
    VALUES 
        (1, 1, DATE '2024-06-01', DATE '2024-08-31', 'Active', 'Main Gallery'),
        (2, 2, DATE '2024-09-10', DATE '2024-09-12', 'Planned', 'Tech Hall'),
        (3, 3, DATE '2024-07-05', DATE '2024-07-10', 'Active', 'Nature Exhibit'),
        (4, 4, DATE '2024-08-01', DATE '2024-08-03', 'Planned', 'Innovation Lab'),
        (5, 5, DATE '2024-10-15', DATE '2024-10-15', 'Planned', 'History Room'),
        (6, 6, DATE '2024-05-20', DATE '2024-05-25', 'Active', 'Children Zone')
) AS vals(object_id, event_id, display_start, display_end, display_status, display_location)
WHERE NOT EXISTS (
    SELECT 1 
    FROM information.display d 
    WHERE d.object_id = vals.object_id 
      AND d.event_id = vals.event_id
);


-- adding record_ts

--Ensure a record_ts timestamp exists on every table
ALTER TABLE information.museum         ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.employee       ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.budget         ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.object         ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.object_loan    ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.object_borrow  ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.storage        ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.display        ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.visitor        ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.ticket         ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.event          ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();
ALTER TABLE information.employee_event ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT NOW();


/*5.1. Create a function that updates data in one of your tables. This function should take the following input arguments:
The primary key value of the row you want to update The name of the column you want to update
The new value you want to set for the specified column This function should be designed to modify the specified row in the table, 
updating the specified column with the new value.*/



DROP FUNCTION IF EXISTS information.safe_update_employee_column(INT, TEXT, ANYELEMENT);
CREATE OR REPLACE FUNCTION information.safe_update_employee_column(  
    p_employee_id INT,    
    p_column_name TEXT,  
    p_new_value ANYELEMENT    
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    sql_query TEXT;
    column_exists BOOLEAN;
    updated_rows INTEGER;
    id_count INTEGER;
    name_count INTEGER;
BEGIN
    -- Defensive Check: Ensure p_employee_id exists uniquely
    SELECT COUNT(*) 
    INTO id_count 
    FROM information.employee 
    WHERE employee_id = p_employee_id;

    IF id_count = 0 THEN
        RAISE EXCEPTION 'No employee found with employee_id = %.', p_employee_id;
    ELSIF id_count > 1 THEN
        RAISE EXCEPTION 'Ambiguous employee_id provided: % matches found. Expected exactly one.', id_count;
    END IF;

    -- Check if the column exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'information'
          AND table_name = 'employee'
          AND column_name = p_column_name
    ) INTO column_exists;

    IF NOT column_exists THEN
        RAISE EXCEPTION 'Column "%" does not exist in information.employee!', p_column_name;
    END IF;

    -- Defensive Check for Duplicate Names
    IF p_column_name = 'employee_full_name' THEN
        SELECT COUNT(*)
        INTO name_count
        FROM information.employee
        WHERE employee_full_name = p_new_value;

        IF name_count > 1 THEN
            RAISE NOTICE 'Warning: % employees already have the name "%".', name_count, p_new_value;
        END IF;
    END IF;

    -- Build and execute dynamic SQL
    sql_query := FORMAT('UPDATE information.employee SET %I = $1 WHERE employee_id = $2', p_column_name);

    EXECUTE sql_query USING p_new_value, p_employee_id;

    GET DIAGNOSTICS updated_rows = ROW_COUNT;

    IF updated_rows = 0 THEN
        RAISE EXCEPTION 'No update performed. Employee with ID = % not found.', p_employee_id;
    END IF;

    RAISE NOTICE 'Successfully updated employee_id = %, column % set to %.', p_employee_id, p_column_name, p_new_value;
END;
$$;



--checking is notice is raised when adding duplicate name
SELECT information.safe_update_employee_column(
    3,
    'employee_full_name',
    'Carol White'::TEXT
);
--Warning: 2 employees already have the name "Carol White".


-- checking function how it works

--  Successful update (existing employee_id, correct column)
SELECT information.safe_update_employee_column(
    (SELECT employee_id FROM information.employee ORDER BY employee_id LIMIT 1),
    'employee_salary',
    4800.00::NUMERIC
);

--updating employee position succesfully
SELECT information.safe_update_employee_column(
    (SELECT employee_id FROM information.employee WHERE employee_full_name = 'Carol White'),
    'employee_position',
    'Chief Curator'::TEXT
);


-- . Trying to update a non-existing employee_id
SELECT information.safe_update_employee_column(
    (SELECT employee_id FROM information.employee ORDER BY employee_id LIMIT 1) + 10000,
    'employee_salary',
    5000.00::NUMERIC
);
--No employee found with employee_id = 10001

--  Trying to update a non-existing column
SELECT information.safe_update_employee_column(
    (SELECT employee_id FROM information.employee ORDER BY employee_id LIMIT 1),
    'employee_house',
    'games'::TEXT
);
--ERROR: Column "employee_house" does not exist in museum.employee


-- Successful update with LIMIT 1 to ensure single row
SELECT information.safe_update_employee_column(
    (SELECT employee_id FROM information.employee ORDER BY employee_id LIMIT 1),
    'employee_salary',
    4800.00::NUMERIC
);

SELECT information.safe_update_employee_column(
    7,  -- employee_id = 3 (Alice Johnson)
    'employee_full_name',
    'Carol White'::TEXT  -- Attempting to set a name that already exists multiple times
);






/*5. 2 Create a function that adds a new transaction to your transaction table.
You can define the input arguments and output format.
Make sure all transaction attributes can be set with the function (via their natural keys).
The function does not need to return a value but should confirm the successful insertion of the 
new transaction.*/
/* I think that ticket table is best for a transaction.
My logic: a family, group  might have a one email or even phone number. Also
I want to keep in mind that the same person can visit the same museum several times, 
so email and phone repeat in the same column but be asossiated with different id as person different times visit museum,
so it is seems logical to associate phone number or email (id's are not natural keys, sometimes
names can be the same, but different persons, so there are many situations).
I think that it is small probability that in the same day one person with the same email/ phone number would visit the same museum.
So the purpose of the function is to connect each new ticket to the right visitor, and prevent me from ever creating a ticket for a visit that doesn’t exist */


DROP FUNCTION IF EXISTS information.add_ticket_by_phone(TEXT, TEXT, NUMERIC, TEXT, DATE);
CREATE OR REPLACE FUNCTION information.add_ticket_by_phone(
    p_visitor_phone         TEXT,
    p_ticket_type           TEXT,
    p_ticket_price          NUMERIC(8,2),
    p_ticket_payment_method TEXT,
    p_ticket_purchase_date  DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_visitor_id INT;
BEGIN
    SELECT visitor_id
    INTO v_visitor_id
    FROM information.visitor
    WHERE TRIM(visitor_phone) = TRIM(p_visitor_phone);

    IF v_visitor_id IS NULL THEN
        RAISE EXCEPTION 
            'No visitor found for phone "%".', 
            p_visitor_phone;
    END IF;

    -- Inserting the ticket
    INSERT INTO information.ticket (
        visitor_id,
        ticket_purchase_date,
        ticket_type,
        ticket_price,
        ticket_payment_method
    ) VALUES (
        v_visitor_id,
        p_ticket_purchase_date,
        INITCAP(TRIM(p_ticket_type)),
        p_ticket_price,
        INITCAP(TRIM(p_ticket_payment_method))
    );

    RAISE NOTICE 
        '✓ Ticket inserted for % on %', 
        p_visitor_phone, p_ticket_purchase_date;
END;
$$;


-- when visitor doesnt exist
SELECT information.add_ticket_by_phone(
    '+37069999999',      -- This phone number doesn’t exist
    'Standard',
    15.00,
    'Card',
    CURRENT_DATE
);
--ERROR: No visitor found for phone "+37069999999".


--adding ticket for a new visitor
SELECT information.add_ticket_by_phone(
    '+37061111101',      
    'Standard',         
    20.00,               
    'Card',              
    CURRENT_DATE         
);
--Ticket inserted for +37061111101 on 2025-05-13

--when trying to insert ticket for same visitor_id, same date
SELECT information.add_ticket_by_phone(
    '+37061111101',      
    'Standard',         
    20.00,               
    'Card',              
    CURRENT_DATE         
);--inserts same visitor but a new ticket_id





/*6. Create a view that presents analytics for the most recently added quarter in your database. 
Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.*/

DROP VIEW IF EXISTS information.quarterly_ticket_analytics;
CREATE OR REPLACE VIEW information.quarterly_ticket_analytics	AS
WITH latest_quarter AS (
  SELECT date_trunc('quarter', MAX(ticket_purchase_date))	AS q_start
  FROM information.ticket
)
	SELECT
  		to_char(l.q_start, 'YYYY "Q"Q')	AS quarter_label,   -- e.g. “2025 Q2”
  		t.ticket_type,                             			-- e.g. “Adult”, “Child”
  		COUNT(*)           				AS tickets_sold,    -- number of tickets
  		SUM(t.ticket_price)				AS total_revenue,   -- revenue in that quarter
  		ROUND(AVG(t.ticket_price),2)	AS avg_price  		-- avg price, 2-decimals
	FROM information.ticket t
	INNER	JOIN latest_quarter l 		ON date_trunc('quarter', t.ticket_purchase_date) = l.q_start
	GROUP BY 
		l.q_start,
		quarter_label,
		t.ticket_type
	ORDER BY 
		t.ticket_type;

--cheking view
SELECT * 
FROM information.quarterly_ticket_analytics;



/*7. Create a read-only role for the manager. 
 This role should have permission to perform SELECT queries on the database tables, 
 and also be able to log in. Please ensure that you adhere to best practices for database 
 security when defining this role.*/
/*I named a role junior manager because I think that junior can not make changes in database without senior, so if manager can only read, 
so maybe it means that he is junior or just hired. Also it makes distinct from other managers as "manager" is very general term.*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_catalog.pg_roles
     WHERE rolname = 'junior_manager'
  ) THEN
    CREATE ROLE junior_manager
      WITH LOGIN
           PASSWORD 'managermuseumreadonly'
           NOSUPERUSER
           NOCREATEDB
           NOCREATEROLE
           NOINHERIT
           NOREPLICATION;
  END IF;
END
$$;


 
-- allowing the role to connect and use the museum schema
GRANT CONNECT ON DATABASE museum_management TO junior_manager;  
--gives the junior_manager role the right to see and reference objects in the museum schema
GRANT USAGE ON SCHEMA information TO junior_manager;
--  granting read‐only on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA information TO junior_manager;
-- Making sure any future tables are also readable
ALTER DEFAULT PRIVILEGES
  IN SCHEMA information
  GRANT SELECT ON TABLES TO junior_manager;

-- Should return one row with rolname = 'junior_manager'
SELECT 
  rolname,
  rolcanlogin,
  rolsuper,
  rolcreatedb,
  rolcreaterole
FROM pg_roles
WHERE rolname = 'junior_manager';

--if can connect - true
SELECT 
  has_database_privilege('junior_manager', current_database(), 'CONNECT')
    AS can_connect;

--  checking if role exists - exists
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname = 'junior_manager'; 

-- checking if can connect - can
SELECT has_database_privilege('junior_manager', current_database(), 'CONNECT') AS can_connect;

-- checking if has schema usage
SELECT has_schema_privilege('junior_manager', 'information', 'USAGE') AS has_usage_on_museum;

-- checking if have table SELECT privileges
SELECT table_name,
       has_table_privilege('junior_manager', format('information.%I',table_name), 'SELECT') AS can_select
FROM information_schema.tables
WHERE table_schema='information' AND table_type='BASE TABLE'
ORDER BY table_name;

--setting role to junior_manager
SET ROLE junior_manager;

-- trying simple SELECT
SELECT * 
FROM information.museum 
LIMIT 5; -- shows results
--trying to update 
UPDATE information.museum
   SET museum_address = '123 Test Street'
 WHERE museum_id = 1; 

--ERROR: permission denied for table museum

--coming back to role
RESET ROLE;


