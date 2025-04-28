/*3. Create a physical database with a separate database and schema and give it an appropriate domain-related name.
Create relationships between tables using primary and foreign keys.
Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example
*/

--creating tables for our museum_management database

-- Table: museum
CREATE TABLE IF NOT EXISTS museum.museum (
    museum_id SERIAL PRIMARY KEY,
    museum_name VARCHAR(255),
    museum_address VARCHAR(255),
    museum_phone VARCHAR(20),
    museum_email VARCHAR(100),
    museum_website VARCHAR(100)
);

-- Table: budget
CREATE TABLE IF NOT EXISTS museum.budget (
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
CREATE TABLE IF NOT EXISTS museum.employee (
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
CREATE TABLE IF NOT EXISTS museum.object (
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
CREATE TABLE IF NOT EXISTS museum.object_loan (
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
CREATE TABLE IF NOT EXISTS museum.object_borrow (
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
CREATE TABLE IF NOT EXISTS museum.storage (
    storage_id SERIAL PRIMARY KEY,
    object_id INT,
    storage_location VARCHAR(255),
    storage_condition TEXT,
    storage_date DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: display
CREATE TABLE IF NOT EXISTS museum.display (
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
CREATE TABLE IF NOT EXISTS museum.event (
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
CREATE TABLE IF NOT EXISTS museum.employee_event (
    employee_id INT,
    event_id INT,
    PRIMARY KEY (employee_id, event_id)
);

-- Table: visitor
CREATE TABLE IF NOT EXISTS museum.visitor (
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
CREATE TABLE IF NOT EXISTS museum.ticket (
    ticket_id SERIAL PRIMARY KEY,
    visitor_id INT,
    ticket_purchase_date DATE,
    ticket_type VARCHAR(100),
    ticket_price DECIMAL(8,2),
    ticket_payment_method VARCHAR(100)
);


-- adding constraints 
--------------------- /
--FOREIGN KEYS		  /
----------------------/


DO $$
BEGIN
    -- Budget 
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_budget_museum' 
                   AND table_name = 'budget'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.budget
        ADD CONSTRAINT fk_budget_museum
        FOREIGN KEY (museum_id) REFERENCES museum(museum_id);
    END IF;
END $$;


DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_budget_approver' 
                   AND table_name = 'budget'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.budget
        ADD CONSTRAINT fk_budget_approver
        FOREIGN KEY (approver_id) REFERENCES museum.employee(employee_id);
    END IF;
END $$;

DO $$
BEGIN
    -- Employee 
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_employee_museum' 
                   AND table_name = 'employee'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.employee
        ADD CONSTRAINT fk_employee_museum
        FOREIGN KEY (museum_id) REFERENCES museum(museum_id);
    END IF;
END $$;

    -- Object 
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_object_museum' 
                   AND table_name = 'object'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.object
        ADD CONSTRAINT fk_object_museum
        FOREIGN KEY (museum_id) REFERENCES museum(museum_id);
    END IF;
END $$;


    -- Object_loan
DO $$
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_objectloan_registrar' 
                   AND table_name = 'object_loan'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.object_loan
        ADD CONSTRAINT fk_objectloan_registrar
        FOREIGN KEY (registrar_id) REFERENCES museum.employee(employee_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_objectloan_object' 
                   AND table_name = 'object_loan'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.object_loan
        ADD CONSTRAINT fk_objectloan_object
        FOREIGN KEY (object_id) REFERENCES museum.object(object_id);
    END IF;
END $$;

DO $$
BEGIN    -- Object_borrow 
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_objectborrow_registrar' 
                   AND table_name = 'object_borrow'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.object_borrow
        ADD CONSTRAINT fk_objectborrow_registrar
        FOREIGN KEY (registrar_id) REFERENCES museum.employee(employee_id);
    END IF;
END $$;

DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_objectborrow_object' 
                   AND table_name = 'object_borrow'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.object_borrow
        ADD CONSTRAINT fk_objectborrow_object
        FOREIGN KEY (object_id) REFERENCES museum.object(object_id);
    END IF;
END $$;

    -- Storage 
DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_storage_object' 
                   AND table_name = 'storage'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.storage
        ADD CONSTRAINT fk_storage_object
        FOREIGN KEY (object_id) REFERENCES museum.object(object_id);
    END IF;
END $$;

    -- Display
DO $$
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_display_object' 
                   AND table_name = 'display'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.display
        ADD CONSTRAINT fk_display_object
        FOREIGN KEY (object_id) REFERENCES museum.object(object_id);
    END IF;
END $$;


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_display_event' 
                   AND table_name = 'display'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.display
        ADD CONSTRAINT fk_display_event
        FOREIGN KEY (event_id) REFERENCES museum.event(event_id);
    END IF;
END $$;

    -- Employee_event
DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_employeeevent_employee' 
                   AND table_name = 'employee_event'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.employee_event
        ADD CONSTRAINT fk_employeeevent_employee
        FOREIGN KEY (employee_id) REFERENCES museum.employee(employee_id);
    END IF;
END $$;

DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_employeeevent_event' 
                   AND table_name = 'employee_event'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.employee_event
        ADD CONSTRAINT fk_employeeevent_event
        FOREIGN KEY (event_id) REFERENCES museum.event(event_id);
    END IF;
END $$;

    -- Visitor 

DO $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_visitor_museum' 
                   AND table_name = 'visitor'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.visitor
        ADD CONSTRAINT fk_visitor_museum
        FOREIGN KEY (museum_id) REFERENCES museum(museum_id);
    END IF;
END $$;

    -- Ticket 
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_ticket_visitor' 
                   AND table_name = 'ticket'
                   AND table_schema = 'museum') THEN
        ALTER TABLE museum.ticket
        ADD CONSTRAINT fk_ticket_visitor
        FOREIGN KEY (visitor_id) REFERENCES museum.visitor(visitor_id);
    END IF;
END $$;



--------------------- /
--OTHER CONSTRAINTS	  /
----------------------/


-- Set NOT NULL for museum table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'museum'
          AND column_name = 'museum_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.museum
        ALTER COLUMN museum_name SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'museum'
          AND column_name = 'museum_address'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.museum
        ALTER COLUMN museum_address SET NOT NULL;
    END IF;

	IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'museum'
          AND column_name = 'museum_phone'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.museum
        ALTER COLUMN museum_phone SET NOT NULL;
    END IF;


	IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'museum'
          AND column_name = 'museum_email'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.museum
        ALTER COLUMN museum_email SET NOT NULL;
    END IF;
	
END $$;

-- Set NOT NULL for budget table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'budget'
          AND column_name = 'budget_amount'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.budget
        ALTER COLUMN budget_amount SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'budget'
          AND column_name = 'budget_expenses'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.budget
        ALTER COLUMN budget_expenses SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'budget'
          AND column_name = 'budget_fiscal_year'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.budget
        ALTER COLUMN budget_fiscal_year SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'budget'
          AND column_name = 'budget_purpose'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.budget
        ALTER COLUMN budget_purpose SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for employee table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'employee_full_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.employee
        ALTER COLUMN employee_full_name SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'employee_position'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.employee
        ALTER COLUMN employee_position SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'employee_department'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.employee
        ALTER COLUMN employee_department SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'employee_hiring_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.employee
        ALTER COLUMN employee_hiring_date SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'employee_salary'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.employee
        ALTER COLUMN employee_salary SET NOT NULL;
    END IF;
END $$;


-- Set NOT NULL for object table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object'
          AND column_name = 'object_title'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.object
        ALTER COLUMN object_title SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object'
          AND column_name = 'object_type'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.object
        ALTER COLUMN object_type SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for object_loan table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object_loan'
          AND column_name = 'object_loan_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.object_loan
        ALTER COLUMN object_loan_date SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for object_borrow table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object_borrow'
          AND column_name = 'object_borrow_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.object_borrow
        ALTER COLUMN object_borrow_date SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for storage table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'storage'
          AND column_name = 'storage_location'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.storage
        ALTER COLUMN storage_location SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for display table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'display'
          AND column_name = 'display_start'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.display
        ALTER COLUMN display_start SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'display'
          AND column_name = 'display_end'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.display
        ALTER COLUMN display_end SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for event table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'event'
          AND column_name = 'event_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.event
        ALTER COLUMN event_name SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for visitor table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'visitor'
          AND column_name = 'visitor_type'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.visitor
        ALTER COLUMN visitor_type SET NOT NULL;
    END IF;
END $$;

-- Set NOT NULL for ticket table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'ticket'
          AND column_name = 'ticket_purchase_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.ticket
        ALTER COLUMN ticket_purchase_date SET NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'ticket'
          AND column_name = 'ticket_price'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE museum.ticket
        ALTER COLUMN ticket_price SET NOT NULL;
    END IF;
END $$;



DO $$
BEGIN
    -- CHECK constraint: budget_amount >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_budget_amount_positive'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.budget
        ADD CONSTRAINT chk_budget_amount_positive
        CHECK (budget_amount > 0);
    END IF;

    -- CHECK constraint: budget_expenses >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_budget_expenses_positive'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.budget
        ADD CONSTRAINT chk_budget_expenses_positive
        CHECK (budget_expenses > 0);
    END IF;

    -- CHECK constraint: event_start_date > '2024-01-01'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_event_start_after_2024'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.event
        ADD CONSTRAINT chk_event_start_after_2024
        CHECK (event_start_date > TIMESTAMP '2024-01-01 00:00:00');
    END IF;


    -- CHECK constraint: object_type must be a specific set
DO $$
BEGIN
	IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_object_type_valid'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.object
        ADD CONSTRAINT chk_object_type_valid
        CHECK (object_type IN ('Painting', 'Sculpture', 'Document', 'Artifact', 'Exhibit', 'Installation', 'Model', 'Technology Exhibit', 'Other'));
    END IF;
END $$


    -- CHECK constraint: ticket_price >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_ticket_price_positive'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.ticket
        ADD CONSTRAINT chk_ticket_price_positive
        CHECK (ticket_price >= 0); --price can be null when it is free to visit museum
    END IF;

    -- CHECK constraint: visitor_type must be specific set
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_visitor_type_valid'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.visitor
        ADD CONSTRAINT chk_visitor_type_valid
        CHECK (visitor_type IN ('Individual', 'Group', 'School'));
    END IF;

    -- CHECK constraint: employee_salary >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_employee_salary_positive'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.employee
        ADD CONSTRAINT chk_employee_salary_positive
        CHECK (employee_salary >= 0);
    END IF;
END $$;


DO $$
BEGIN
    -- Default for ticket.ticket_purchase_date
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'ticket'
          AND column_name = 'ticket_purchase_date'
          AND column_default IS NULL
    ) THEN
        ALTER TABLE museum.ticket
        ALTER COLUMN ticket_purchase_date SET DEFAULT CURRENT_DATE;
    END IF;

    -- Default for display.display_status
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'display'
          AND column_name = 'display_status'
          AND column_default IS NULL
    ) THEN
        ALTER TABLE museum.display
        ALTER COLUMN display_status SET DEFAULT 'planned';
    END IF;

    -- Default for visitor.visitor_educator_required
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'visitor'
          AND column_name = 'visitor_educator_required'
          AND column_default IS NULL
    ) THEN
        ALTER TABLE museum.visitor
        ALTER COLUMN visitor_educator_required SET DEFAULT FALSE;
    END IF;

    -- Default for storage.storage_date
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'storage'
          AND column_name = 'storage_date'
          AND column_default IS NULL
    ) THEN
        ALTER TABLE museum.storage
        ALTER COLUMN storage_date SET DEFAULT CURRENT_DATE;
    END IF;
END $$;

-- Add UNIQUE constraint for museum.museum_email so that even each museum branch would have unique email.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_type = 'UNIQUE'
          AND constraint_name = 'uq_museum_email'
          AND constraint_schema = 'museum'
    ) THEN
        ALTER TABLE museum.museum
        ADD CONSTRAINT uq_museum_email
        UNIQUE (museum_email);
    END IF;
END $$;


--------------------------------/
								/
--Inserting values into tables  /
								/
--------------------------------/


-- Insert data into museum 

								
	-- Inserting museums 
INSERT INTO museum.museum (museum_name, museum_address, museum_phone, museum_email, museum_website)
SELECT 
    INITCAP(TRIM(vals.museum_name)), -- 
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
        (' Riverstone Children''s Exploration Museum ', ' Adventure Road 12, Alytus ', '+37061111116', ' kids@riverstonemuseum.lt ', ' www.riverstonemuseum.lt '),
        (' Northern Lights Maritime Museum ', ' Harbor Lane 15, Palanga ', '+37061111117', ' info@northernlightsmaritime.lt ', ' www.northernlightsmaritime.lt '),
        (' Crystal Heritage Geological Museum ', ' Stone Square 8, Utena ', '+37061111118', ' geology@crystalheritage.lt ', ' www.crystalheritage.lt '),
        (' Skyview Aerospace and Aviation Center ', ' Flight Path 4, Marijampole ', '+37061111119', ' contact@skyviewaviation.lt ', ' www.skyviewaviation.lt '),
        (' Global Cultures and World Traditions Museum ', ' World Plaza 1, Telsiai ', '+37061111120', ' culture@globalcultures.lt ', ' www.globalcultures.lt ')
) AS vals(museum_name, museum_address, museum_phone, museum_email, museum_website)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.museum m
    WHERE m.museum_name = INITCAP(TRIM(vals.museum_name)) 
);
							
								
-- Inserting data into employee with random names and dynamic museum_id, 3 employees for each museum


-- Insert employees with proper TRIM, salary range, end dates
INSERT INTO museum.employee (museum_id, employee_full_name, employee_position, employee_department, employee_hiring_date, employee_end_date, employee_salary)
SELECT 
    vals.museum_id,
    UPPER(TRIM(vals.employee_full_name)),
    INITCAP(TRIM(vals.employee_position)),
    INITCAP(TRIM(vals.employee_department)),
    vals.employee_hiring_date,
    vals.employee_end_date,
    vals.employee_salary
FROM (
    VALUES 
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))), 'Sophia Brown', 'Director', 'Management', DATE '2024-01-05', NULL, 3700),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))), 'James Miller', 'Curator', 'Modern Art', DATE '2024-01-10', NULL, 3100),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))), 'Ella Davis', 'Archivist', 'Collections', DATE '2024-01-15', NULL, 2800),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))), 'Mason Wilson', 'Director', 'Management', DATE '2024-01-07', NULL, 3600),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))), 'Avery Moore', 'Science Curator', 'Discovery', DATE '2024-01-14', DATE '2024-04-01', 3000),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))), 'Lucas Taylor', 'Lab Technician', 'Research', DATE '2024-01-20', NULL, 2500),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))), 'Harper Anderson', 'Researcher', 'Nature Studies', DATE '2024-01-08', NULL, 2700),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))), 'Ethan Thomas', 'Guide', 'Visitor Tours', DATE '2024-01-17', NULL, 1900),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))), 'Chloe White', 'Curator', 'Exhibitions', DATE '2024-01-21', NULL, 3000),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))), 'Jack Harris', 'Tech Specialist', 'Innovation Lab', DATE '2024-01-09', NULL, 2800),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))), 'Lily Martin', 'Engineer', 'Technical Department', DATE '2024-01-18', NULL, 2900),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))), 'Owen Thompson', 'Exhibit Developer', 'Tech Exhibits', DATE '2024-01-22', NULL, 2700),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))), 'Isabella Garcia', 'Archivist', 'Historical Archives', DATE '2024-01-06', NULL, 2600),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))), 'Noah Martinez', 'Curator', 'Historic Exhibitions', DATE '2024-01-13', DATE '2024-04-01', 3100),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))), 'Aria Robinson', 'Guide', 'Educational Tours', DATE '2024-01-19', NULL, 2100),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))), 'William Clark', 'Children Program Manager', 'Education', DATE '2024-01-11', NULL, 2400),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))), 'Mila Lewis', 'Coordinator', 'Public Events', DATE '2024-01-16', NULL, 2200),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))), 'Elijah Lee', 'Storyteller', 'Kids Entertainment', DATE '2024-01-23', NULL, 2000),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))), 'Logan Walker', 'Diver', 'Aquarium Maintenance', DATE '2024-01-12', NULL, 2600),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))), 'Emily Allen', 'Marine Researcher', 'Marine Studies', DATE '2024-01-19', NULL, 3100),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))), 'Henry Young', 'Curator', 'Sea Exhibitions', DATE '2024-01-25', NULL, 3000),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))), 'Abigail King', 'Geologist', 'Research', DATE '2024-01-15', NULL, 2700),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))), 'Carter Wright', 'Mineralogist', 'Geology Exhibits', DATE '2024-01-22', NULL, 2800),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))), 'Ella Scott', 'Exhibit Manager', 'Collections', DATE '2024-01-29', NULL, 2500),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))), 'Sebastian Adams', 'Engineer', 'Flight Technology', DATE '2024-01-08', NULL, 3400),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))), 'Scarlett Baker', 'Flight Historian', 'Exhibits', DATE '2024-01-17', NULL, 3200),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))), 'Nathan Evans', 'Technician', 'Maintenance', DATE '2024-01-24', NULL, 3000),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))), 'Penelope Hill', 'Anthropologist', 'Research Department', DATE '2024-01-10', NULL, 2700),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))), 'Christopher Green', 'Curator', 'World Exhibits', DATE '2024-01-18', NULL, 3100),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))), 'Zoey Carter', 'Coordinator', 'Events', DATE '2024-01-26', DATE '2024-04-01', 2800)
) AS vals(museum_id, employee_full_name, employee_position, employee_department, employee_hiring_date, employee_end_date, employee_salary)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.employee e
    WHERE e.employee_full_name = vals.employee_full_name
);


--inserting data into budget table

-- Insert budgets linked dynamically to museum and employee
INSERT INTO museum.budget (museum_id, approver_id, budget_amount, budget_expenses, budget_fiscal_year, budget_purpose)
SELECT 
    vals.museum_id,
    vals.approver_id,
    vals.budget_amount,
    vals.budget_expenses,
    vals.budget_fiscal_year,
    vals.budget_purpose
FROM (
    VALUES 
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))) LIMIT 1),
            150000.00, 60000.00, DATE '2025-01-01', 'Modern Art Exhibition Funding'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))) LIMIT 1),
            120000.00, 50000.00, DATE '2024-01-01', 'Science Innovation Labs'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))) LIMIT 1),
            110000.00, 45000.00, DATE '2024-01-01', 'Nature Conservation Projects'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))) LIMIT 1),
            130000.00, 60000.00, DATE '2025-01-01', 'New Tech Exhibitions'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))) LIMIT 1),
            100000.00, 40000.00, DATE '2024-01-01', 'Historic Preservation Projects'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))) LIMIT 1),
            95000.00, 35000.00, DATE '2025-01-01', 'Children''s Interactive Zones'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))) LIMIT 1),
            125000.00, 55000.00, DATE '2024-01-01', 'Sea Life Exhibits Expansion'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))) LIMIT 1),
            105000.00, 43000.00, DATE '2024-01-01', 'Geology Field Research'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))) LIMIT 1),
            135000.00, 58000.00, DATE '2025-01-01', 'Flight Simulation Projects'
        ),
        (
            (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))),
            (SELECT employee_id FROM museum.employee WHERE museum_id = (SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))) LIMIT 1),
            115000.00, 47000.00, DATE '2024-01-01', 'Cultural Exchange Exhibitions'
        )
) AS vals(museum_id, approver_id, budget_amount, budget_expenses, budget_fiscal_year, budget_purpose)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.budget b
    WHERE b.museum_id = vals.museum_id
      AND b.budget_fiscal_year = vals.budget_fiscal_year
);


-- Insert objects linked to each museum
INSERT INTO museum.object (museum_id, object_title, object_description, object_type, object_creation_date, object_author, object_digital_archive_url)
SELECT 
    vals.museum_id,
    INITCAP(TRIM(vals.object_title)),
    vals.object_description,
    INITCAP(TRIM(vals.object_type)),
    vals.object_creation_date,
    INITCAP(TRIM(vals.object_author)),
    vals.object_digital_archive_url
FROM (
    VALUES 
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))), 'Sunrise Over the Valley', 'A bright modernist painting', 'Painting', DATE '2019-05-20', 'Alex Monroe', 'https://digitalarchive.lt/object1'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Aurora Museum of Modern Art'))), 'Shattered Glass', 'Contemporary sculpture with abstract design', 'Sculpture', DATE '2020-09-12', 'Liam Rivers', 'https://digitalarchive.lt/object2'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))), 'Solar System Exhibit', 'Interactive model of the solar system', 'Installation', DATE '2022-01-10', 'Science Team', 'https://digitalarchive.lt/object3'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Horizon Science Discovery Center'))), 'DNA Exploration Model', 'Educational molecular structure model', 'Sculpture', DATE '2021-07-05', 'Dr. Sarah Lopez', 'https://digitalarchive.lt/object4'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))), 'Woolly Mammoth Skeleton', 'Preserved prehistoric mammoth remains', 'Exhibit', DATE '2018-11-15', 'Natural History Division', 'https://digitalarchive.lt/object5'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Green Valley Natural History Museum'))), 'Amazon Rainforest Diorama', 'Large rainforest ecological model', 'Sculpture', DATE '2020-02-25', 'Team Green Earth', 'https://digitalarchive.lt/object6'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))), 'Early Computers Display', 'Collection of first-generation computers', 'Technology Exhibit', DATE '2015-06-20', 'Tech Team', 'https://digitalarchive.lt/object7'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Baltic Innovation and Technology Museum'))), 'AI Timeline', 'Visual history of Artificial Intelligence', 'Installation', DATE '2021-09-18', 'Innovation Lab', 'https://digitalarchive.lt/object8'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))), 'Ancient Coin Collection', 'Coins from different historical periods', 'Artifact', DATE '2017-04-10', 'History Department', 'https://digitalarchive.lt/object9'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Echoes of the Past History Museum'))), 'Medieval Armor Set', 'Knights armor reconstructed from the 13th century', 'Exhibit', DATE '2019-03-30', 'Restoration Team', 'https://digitalarchive.lt/object10'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))), 'Magic Tree Play Area', 'Large educational play tree model', 'Installation', DATE '2022-06-12', 'Kids Design Team', 'https://digitalarchive.lt/object11'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Riverstone Children''s Exploration Museum'))), 'Puzzle Wall', 'Giant interactive puzzle exhibit', 'Exhibit', DATE '2023-01-18', 'Education Team', 'https://digitalarchive.lt/object12'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))), 'Historic Ship Models', 'Collection of detailed ship models', 'Exhibit', DATE '2016-07-05', 'Maritime Team', 'https://digitalarchive.lt/object13'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Northern Lights Maritime Museum'))), 'Navigation Instruments', 'Old compasses and sextants', 'Artifact', DATE '2017-09-14', 'Sea Heritage Group', 'https://digitalarchive.lt/object14'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))), 'Amethyst Crystal Formation', 'Large natural amethyst sample', 'Artifact', DATE '2020-10-20', 'Geology Team', 'https://digitalarchive.lt/object15'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Crystal Heritage Geological Museum'))), 'Volcanic Rock Samples', 'Lava and rock collection from volcanic sites', 'Artifact', DATE '2019-05-02', 'Earth Sciences Division', 'https://digitalarchive.lt/object16'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))), 'Apollo Space Capsule Model', 'Replica of Apollo mission capsule', 'Exhibit', DATE '2018-03-12', 'Aviation Team', 'https://digitalarchive.lt/object17'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Skyview Aerospace and Aviation Center'))), 'Early Flight Exhibit', 'Wright Brothers flight simulation', 'Exhibit', DATE '2021-11-04', 'Flight Lab', 'https://digitalarchive.lt/object18'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))), 'Traditional Costumes Display', 'Costumes from different global cultures', 'Exhibit', DATE '2022-03-20', 'Anthropology Group', 'https://digitalarchive.lt/object19'),
        ((SELECT museum_id FROM museum WHERE museum_name = INITCAP(TRIM('Global Cultures and World Traditions Museum'))), 'World Music Instruments', 'Various musical instruments worldwide', 'Artifact', DATE '2020-08-10', 'Culture Department', 'https://digitalarchive.lt/object20')
) AS vals(museum_id, object_title, object_description, object_type, object_creation_date, object_author, object_digital_archive_url)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.object o
    WHERE o.object_title = INITCAP(TRIM(vals.object_title))
);


-- Inserting object loans
-- Insert 6 sample object loans with dates from 2025
INSERT INTO museum.object_loan (registrar_id, object_id, object_loan_date, object_loan_return, object_loan_institution, object_loan_status)
SELECT
    vals.registrar_id,
    vals.object_id,
    vals.object_loan_date,
    vals.object_loan_return,
    INITCAP(TRIM(vals.object_loan_institution)),
    INITCAP(TRIM(vals.object_loan_status))
FROM (
    VALUES
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Sunrise Over the Valley'))), DATE '2025-01-10', DATE '2025-07-10', 'National Art Museum', 'Active'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Ancient Coin Collection'))), DATE '2025-02-15', DATE '2025-08-15', 'History Research Institute', 'Planned'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Apollo Space Capsule Model'))), DATE '2025-03-05', DATE '2025-09-05', 'Space Exploration Center', 'Active'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Magic Tree Play Area'))), DATE '2025-04-01', DATE '2025-10-01', 'Children Creativity Center', 'Active'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Historic Ship Models'))), DATE '2025-05-15', DATE '2025-11-15', 'Maritime Heritage Trust', 'Planned'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Traditional Costumes Display'))), DATE '2025-06-20', DATE '2025-12-20', 'World Cultural Forum', 'Active')
) AS vals(registrar_id, object_id, object_loan_date, object_loan_return, object_loan_institution, object_loan_status)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.object_loan ol
    WHERE ol.object_id = vals.object_id
);


-- 6 sample object_borrow table with dates from 2025
INSERT INTO museum.object_borrow (registrar_id, object_id, object_borrow_date, object_borrow_end, object_borrow_institution, object_borrow_status)
SELECT
    vals.registrar_id,
    vals.object_id,
    vals.object_borrow_date,
    vals.object_borrow_end,
    INITCAP(TRIM(vals.object_borrow_institution)),
    INITCAP(TRIM(vals.object_borrow_status))
FROM (
    VALUES
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('World Music Instruments'))), DATE '2025-01-05', DATE '2025-07-05', 'Cultural Exchange Center', 'Active'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Volcanic Rock Samples'))), DATE '2025-02-10', DATE '2025-08-10', 'Geology Institute', 'Planned'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Solar System Exhibit'))), DATE '2025-03-01', DATE '2025-09-01', 'Astronomy Museum', 'Returned'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Navigation Instruments'))), DATE '2025-04-15', DATE '2025-10-15', 'Navigation History Foundation', 'Active'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('AI Timeline'))), DATE '2025-05-18', DATE '2025-11-18', 'Innovation Research Center', 'Planned'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Amazon Rainforest Diorama'))), DATE '2025-06-25', DATE '2025-12-25', 'Rainforest Ecology Center', 'Active')
) AS vals(registrar_id, object_id, object_borrow_date, object_borrow_end, object_borrow_institution, object_borrow_status)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.object_borrow ob
    WHERE ob.object_id = vals.object_id
);



-- Inserting 10 sample visitors
INSERT INTO museum.visitor (
    museum_id,
    visitor_full_name,
    visitor_email,
    visitor_phone,
    visitor_type,
    visitor_group_name,
    visitor_number_of_visitors,
    visitor_educator_required,
    visitor_notes
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
    vals.visitor_notes
FROM (
    VALUES 
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Alice Johnson', 'alice.johnson@example.com', '+37061111221', 'Individual', NULL, 1, FALSE, 'Interested in modern art.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Greenwood High School', 'contact@greenwoodhigh.lt', '+37061111222', 'School', 'Greenwood High', 30, TRUE, 'Annual school trip.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Michael Smith', 'michael.smith@example.com', '+37061111223', 'Individual', NULL, 1, FALSE, 'First time visiting.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Culture Explorers', 'info@cultureexplorers.org', '+37061111224', 'Group', 'Culture Explorers', 12, TRUE, 'Group tour focused on history.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Olivia Brown', 'olivia.brown@example.com', '+37061111225', 'Individual', NULL, 1, FALSE, 'Interested in science exhibitions.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Sunrise Elementary', 'admin@sunriseelem.lt', '+37061111226', 'School', 'Sunrise Elementary', 25, TRUE, 'Educational field trip.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'William Garcia', 'william.garcia@example.com', '+37061111227', 'Individual', NULL, 1, FALSE, 'Interested in aviation exhibits.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Art Lovers Group', 'contact@artloversgroup.com', '+37061111228', 'Group', 'Art Lovers', 8, FALSE, 'Group of art enthusiasts.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Sophia Martinez', 'sophia.martinez@example.com', '+37061111229', 'Individual', NULL, 1, FALSE, 'Came for geology exhibitions.'),
        ((SELECT museum_id FROM museum.museum ORDER BY random() LIMIT 1), 'Tech Innovators', 'team@techinnovators.org', '+37061111230', 'Group', 'Tech Innovators', 15, FALSE, 'Technology professionals visiting tech museum.')
) AS vals(
    museum_id,
    visitor_full_name,
    visitor_email,
    visitor_phone,
    visitor_type,
    visitor_group_name,
    visitor_number_of_visitors,
    visitor_educator_required,
    visitor_notes
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.visitor v
    WHERE v.visitor_email = LOWER(TRIM(vals.visitor_email))
);




-- Inserting 10 sample tickets linked to visitors
INSERT INTO museum.ticket (
    visitor_id,
    ticket_purchase_date,
    ticket_type,
    ticket_price,
    ticket_payment_method
)
SELECT
    vals.visitor_id,
    vals.ticket_purchase_date,
    INITCAP(TRIM(vals.ticket_type)),
    vals.ticket_price,
    INITCAP(TRIM(vals.ticket_payment_method))
FROM (
    VALUES 
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 0), DATE '2025-01-10', 'Adult', 12.50, 'Credit Card'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 1), DATE '2025-01-15', 'School Group', 100.00, 'Bank Transfer'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 2), DATE '2025-01-18', 'Adult', 12.50, 'Cash'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 3), DATE '2025-01-20', 'Group', 60.00, 'Credit Card'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 4), DATE '2025-01-25', 'Adult', 12.50, 'Online Payment'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 5), DATE '2025-01-30', 'School Group', 90.00, 'Bank Transfer'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 6), DATE '2025-02-02', 'Adult', 12.50, 'Credit Card'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 7), DATE '2025-02-05', 'Group', 55.00, 'Cash'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 8), DATE '2025-02-10', 'Adult', 12.50, 'Online Payment'),
        ((SELECT visitor_id FROM museum.visitor ORDER BY visitor_id ASC LIMIT 1 OFFSET 9), DATE '2025-02-15', 'Group', 70.00, 'Credit Card')
) AS vals(
    visitor_id,
    ticket_purchase_date,
    ticket_type,
    ticket_price,
    ticket_payment_method
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.ticket t
    WHERE t.visitor_id = vals.visitor_id
);



-- Insert 10 sample storage records
INSERT INTO museum.storage (
    object_id,
    storage_location,
    storage_condition,
    storage_date
)
SELECT 
    vals.object_id,
    INITCAP(TRIM(vals.storage_location)),
    INITCAP(TRIM(vals.storage_condition)),
    vals.storage_date
FROM (
    VALUES 
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Sunrise Over the Valley'))), 'Vault A1', 'Excellent', DATE '2025-01-02'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Ancient Coin Collection'))), 'Vault B2', 'Good', DATE '2025-01-05'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Apollo Space Capsule Model'))), 'Storage Room 1', 'Good', DATE '2025-01-10'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Magic Tree Play Area'))), 'Storage Area C3', 'Excellent', DATE '2025-01-12'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Historic Ship Models'))), 'Marine Storage D4', 'Good', DATE '2025-01-14'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Traditional Costumes Display'))), 'Textile Storage E5', 'Excellent', DATE '2025-01-18'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('World Music Instruments'))), 'Vault C1', 'Good', DATE '2025-01-20'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Amazon Rainforest Diorama'))), 'Ecology Storage F6', 'Needs Repair', DATE '2025-01-25'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Navigation Instruments'))), 'Navigation Storage G7', 'Good', DATE '2025-01-28'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Volcanic Rock Samples'))), 'Geology Vault H8', 'Excellent', DATE '2025-01-30')
) AS vals(
    object_id,
    storage_location,
    storage_condition,
    storage_date
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.storage s
    WHERE s.object_id = vals.object_id
);


-- Insert 7 sample events
INSERT INTO museum.event (
    organizer_id,
    event_name,
    event_type,
    event_description,
    event_start_date,
    event_end_date,
    event_location
)
SELECT 
    vals.organizer_id,
    INITCAP(TRIM(vals.event_name)),
    INITCAP(TRIM(vals.event_type)),
    vals.event_description,
    vals.event_start_date,
    vals.event_end_date,
    INITCAP(TRIM(vals.event_location))
FROM (
    VALUES 
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Winter Art Exhibition', 'Exhibition', 'An exhibition featuring winter-themed modern art.', TIMESTAMP '2025-01-10 10:00:00', TIMESTAMP '2025-02-10 18:00:00', 'Main Exhibition Hall'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'History Alive Week', 'Festival', 'Week-long festival with historical reenactments and lectures.', TIMESTAMP '2025-02-15 09:00:00', TIMESTAMP '2025-02-22 17:00:00', 'History Wing'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Innovation Tech Fair', 'Exhibition', 'Presentation of modern technological innovations.', TIMESTAMP '2025-03-01 10:00:00', TIMESTAMP '2025-03-20 18:00:00', 'Tech Pavilion'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Maritime Wonders', 'Exhibition', 'Celebrating marine navigation and history.', TIMESTAMP '2025-04-05 10:00:00', TIMESTAMP '2025-04-25 18:00:00', 'Maritime Center'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Cultural Heritage Festival', 'Festival', 'A showcase of global cultural traditions.', TIMESTAMP '2025-05-01 09:00:00', TIMESTAMP '2025-05-10 17:00:00', 'Outdoor Plaza'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Children Science Adventure', 'Exhibition', 'Interactive science exhibition for children.', TIMESTAMP '2025-06-05 09:30:00', TIMESTAMP '2025-06-20 16:00:00', 'Discovery Hall'),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), 'Aviation History Day', 'Special Event', 'Celebrating milestones in aviation history.', TIMESTAMP '2025-07-15 09:00:00', TIMESTAMP '2025-07-15 18:00:00', 'Aviation Hangar')
) AS vals(
    organizer_id,
    event_name,
    event_type,
    event_description,
    event_start_date,
    event_end_date,
    event_location
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.event e
    WHERE e.event_name = INITCAP(TRIM(vals.event_name))
);


-- Insert employee-event assignments
INSERT INTO museum.employee_event (
    employee_id,
    event_id
)
SELECT
    vals.employee_id,
    vals.event_id
FROM (
    VALUES 
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Winter Art Exhibition')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Winter Art Exhibition')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('History Alive Week')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Innovation Tech Fair')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Innovation Tech Fair')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Maritime Wonders')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Maritime Wonders')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Cultural Heritage Festival')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Children Science Adventure')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Children Science Adventure')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Aviation History Day')))),
        ((SELECT employee_id FROM museum.employee ORDER BY random() LIMIT 1), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Aviation History Day'))))
) AS vals(
    employee_id,
    event_id
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.employee_event ee
    WHERE ee.employee_id = vals.employee_id
      AND ee.event_id = vals.event_id
);

-- Inserting 10 sample for display table
INSERT INTO museum.display (
    object_id,
    event_id,
    display_start,
    display_end,
    display_status,
    display_location
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
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Sunrise Over the Valley'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Winter Art Exhibition'))), DATE '2025-01-10', DATE '2025-02-10', 'Ongoing', 'Gallery A1'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Shattered Glass'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Winter Art Exhibition'))), DATE '2025-01-10', DATE '2025-02-10', 'Ongoing', 'Gallery A2'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Ancient Coin Collection'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('History Alive Week'))), DATE '2025-02-15', DATE '2025-02-22', 'Planned', 'History Hall B1'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Medieval Armor Set'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('History Alive Week'))), DATE '2025-02-15', DATE '2025-02-22', 'Planned', 'History Hall B2'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('AI Timeline'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Innovation Tech Fair'))), DATE '2025-03-01', DATE '2025-03-20', 'Planned', 'Tech Pavilion 1'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Early Computers Display'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Innovation Tech Fair'))), DATE '2025-03-01', DATE '2025-03-20', 'Planned', 'Tech Pavilion 2'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Historic Ship Models'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Maritime Wonders'))), DATE '2025-04-05', DATE '2025-04-25', 'Planned', 'Marine Hall D1'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Navigation Instruments'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Maritime Wonders'))), DATE '2025-04-05', DATE '2025-04-25', 'Planned', 'Marine Hall D2'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('Traditional Costumes Display'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Cultural Heritage Festival'))), DATE '2025-05-01', DATE '2025-05-10', 'Planned', 'Outdoor Pavilion'),
        ((SELECT object_id FROM museum.object WHERE object_title = INITCAP(TRIM('World Music Instruments'))), (SELECT event_id FROM museum.event WHERE event_name = INITCAP(TRIM('Cultural Heritage Festival'))), DATE '2025-05-01', DATE '2025-05-10', 'Planned', 'Outdoor Stage')
) AS vals(
    object_id,
    event_id,
    display_start,
    display_end,
    display_status,
    display_location
)
WHERE NOT EXISTS (
    SELECT 1
    FROM museum.display d
    WHERE d.object_id = vals.object_id
      AND d.event_id = vals.event_id
);


ALTER TABLE museum.visitor
  ADD CONSTRAINT uq_visitor_phone_date
    UNIQUE(visitor_phone, visitor_visit_date);


-----------------------------------------------------------

-- adding record_ts

-- Adding record_ts to museum.museum
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'museum'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.museum
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.employee
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.employee
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.budget
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'budget'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.budget
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.object
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.object
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.object_loan
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object_loan'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.object_loan
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.object_borrow
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'object_borrow'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.object_borrow
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.storage
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'storage'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.storage
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.display
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'display'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.display
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.visitor
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'visitor'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.visitor
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.ticket
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'ticket'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.ticket
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.event
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'event'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.event
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Adding record_ts to museum.employee_event (junction table)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee_event'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE museum.employee_event
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;



/*5.1. Create a function that updates data in one of your tables. 
This function should take the following input arguments:
The primary key value of the row you want to update
The name of the column you want to update
The new value you want to set for the specified column
This function should be designed to modify the specified row in the table, 
updating the specified column with the new value.*/


DROP FUNCTION IF EXISTS museum.safe_update_employee_column(INT, TEXT, ANYELEMENT);
CREATE OR REPLACE FUNCTION museum.safe_update_employee_column(  --in order to change employee table, because it can be very dinamic and change a lot
	p_employee_id INT,    --the ID of the employee you I to update
	p_column_name TEXT, --the name of the column I want to change
    p_new_value ANYELEMENT    --the new value to set.
)
RETURNS VOID  --No text result, because the exception is throwed instead
LANGUAGE plpgsql
AS $$
DECLARE
    sql_query TEXT; --A string to hold the dynamic SQL query
    column_exists BOOLEAN; --to check if the column actually exists, e.g. when column name is incorrect
	updated_rows INTEGER; 
BEGIN  --the start of the function's logic
    -- Checking if the column exists in the museum.employee table
    SELECT EXISTS (  --checking if the specified column name exists in the museum.employee table
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'museum'
          AND table_name = 'employee'
          AND column_name = p_column_name
    ) INTO column_exists;

		
    -- If column does not exist, raise an exception
    IF NOT column_exists THEN
        RAISE EXCEPTION 'Column "%" does not exist in museum.employee!', p_column_name;
    END IF;

--  Building the dynamic SQL
    sql_query := FORMAT('UPDATE museum.employee SET %I = $1 WHERE employee_id = $2', p_column_name);

	EXECUTE sql_query USING p_new_value, p_employee_id; --Executing the dynamic SQL

	GET DIAGNOSTICS updated_rows = ROW_COUNT; --Getting the number of affected rows

    -- If no rows updated, raise error
    IF updated_rows = 0 THEN
        RAISE EXCEPTION 'No employee found with employee_id = %.', p_employee_id;
    END IF;

    -- adding notice that column was updated
    RAISE NOTICE 'Successfully updated employee_id = %, column % set to %.', p_employee_id, p_column_name, p_new_value;
END;
$$;


-- checking function how it works

--  Successful update (existing employee_id, correct column)
SELECT museum.safe_update_employee_column(
    (SELECT employee_id FROM museum.employee ORDER BY employee_id LIMIT 1),
    'employee_salary',
    4800.00::NUMERIC
);

--updating employee position succesfully
SELECT museum.safe_update_employee_column(
    (SELECT employee_id FROM museum.employee WHERE employee_full_name = 'OWEN THOMPSON'),
    'employee_position',
    'Chief Curator'::TEXT
);


-- . Trying to update a non-existing employee_id
SELECT museum.safe_update_employee_column(
    (SELECT employee_id FROM museum.employee ORDER BY employee_id LIMIT 1) + 10000,
    'employee_salary',
    5000.00::NUMERIC
);
--No employee found with employee_id = 10001

--  Try updating a non-existing column
SELECT museum.safe_update_employee_column(
    (SELECT employee_id FROM museum.employee ORDER BY employee_id LIMIT 1),
    'employee_house',
    'games'::TEXT
);
--ERROR: Column "employee_house" does not exist in museum.employee




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
names can be the same, but different persons, so there are many situations) with the visit date.
I think that it is small probability that in the same day one person with the same email/ phone number would visit the same museum.
So the purpose of the function is to connect each new ticket to the right visitor, and prevent me from ever creating a ticket for a visit that doesn’t exist */

DROP FUNCTION IF EXISTS museum.add_ticket_by_phone(TEXT, DATE, TEXT, NUMERIC, TEXT, DATE);


-- Recreate, matching DATE(visitor_visit_date) to the input
CREATE OR REPLACE FUNCTION museum.add_ticket_by_phone(
    p_visitor_phone         TEXT,
    p_visitor_visit_date    DATE,
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
    -- look up the visit by phone + visit_date (date portion only)
    SELECT visitor_id
      INTO v_visitor_id
      FROM museum.visitor
     WHERE TRIM(visitor_phone)    = TRIM(p_visitor_phone)
       AND DATE(visitor_visit_date) = p_visitor_visit_date;

    IF v_visitor_id IS NULL THEN
        RAISE EXCEPTION 
          'No visit found for phone "%" on date %',
          p_visitor_phone, p_visitor_visit_date;
    END IF;

    -- insert the ticket
    INSERT INTO museum.ticket (
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
      p_visitor_phone, p_visitor_visit_date;
END;
$$;


-- assume +37061111223 visited on 2025-04-28
SELECT museum.add_ticket_by_phone(
  '+37061111223',
   DATE '2025-04-28',
  'Adult',       -- ticket_type
   12.99,        -- ticket_price
  'Credit Card'  -- payment_method
);
-- no error message

SELECT museum.add_ticket_by_phone(
  '+37061111223',
   DATE '2025-04-27',  -- no visit on this day
  'Adult',12.99,'Credit Card'
);
-- ERROR: No visit found for phone "+37061111223" on date 2025-04-27

SELECT museum.add_ticket_by_phone(
  '+37060000000',
   DATE '2025-04-28',
  'Adult',12.99,'Credit Card'
);
-- ERROR: No visit found for phone "+37060000000" on date 2025-04-28




/*6. Create a view that presents analytics for the most recently added quarter in your database. 
Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.*/
DROP VIEW IF EXISTS VIEW museum.quarterly_ticket_analytics;
CREATE OR REPLACE VIEW museum.quarterly_ticket_analytics	AS
WITH latest_quarter AS (
  -- finding the start of the latest quarter in your data
  SELECT date_trunc('quarter', MAX(ticket_purchase_date))	AS q_start
  FROM museum.ticket
)
	SELECT
  		to_char(l.q_start, 'YYYY "Q"Q')	AS quarter_label,   -- e.g. “2025 Q2”
  		t.ticket_type,                             			-- e.g. “Adult”, “Child”
  		COUNT(*)           				AS tickets_sold,    -- number of tickets
  		SUM(t.ticket_price)				AS total_revenue,   -- revenue in that quarter
  		ROUND(AVG(t.ticket_price),2)	AS avg_price  		-- avg price, 2-decimals
	FROM museum.ticket t
	INNER	JOIN latest_quarter l 		ON date_trunc('quarter', t.ticket_purchase_date) = l.q_start
	GROUP BY 
		l.q_start,
		quarter_label,
		t.ticket_type
	ORDER BY 
		t.ticket_type;

--cheking view
SELECT * 
FROM museum.quarterly_ticket_analytics;





/*7. Create a read-only role for the manager. 
 This role should have permission to perform SELECT queries on the database tables, 
 and also be able to log in. Please ensure that you adhere to best practices for database 
 security when defining this role.*/
/*I named a role junior manager because I think that junior can not make changes in database without senior, so if manager can only read, 
so maybe it means that he is junior or just hired. Also it makes distinct from other managers as "manager" is very general term.*/

CREATE ROLE junior_manager WITH PASSWORD 'managermuseumreadonly';
 
-- allowing the role to connect and use the museum schema
GRANT CONNECT ON DATABASE museum_management TO junior_manager;  
--gives the junior_manager role the right to see and reference objects in the museum schema
GRANT USAGE ON SCHEMA museum TO junior_manager;
--  granting read‐only on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA museum TO junior_manager;
-- Making sure any future tables are also readable
ALTER DEFAULT PRIVILEGES
  IN SCHEMA museum
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
SELECT has_schema_privilege('junior_manager', 'museum', 'USAGE') AS has_usage_on_museum;

-- checking if have table SELECT privileges
SELECT table_name,
       has_table_privilege('junior_manager', format('museum.%I',table_name), 'SELECT') AS can_select
FROM information_schema.tables
WHERE table_schema='museum' AND table_type='BASE TABLE'
ORDER BY table_name;

--setting role to junior_manager
SET ROLE junior_manager;

-- trying simple SELECT
SELECT * 
FROM museum.museum 
LIMIT 5; -- shows results
--trying to update 
UPDATE museum.museum
   SET museum_address = '123 Test Street'
 WHERE museum_id = 1; 
--ERROR: permission denied for table museum

--coming back to role
RESET ROLE;


