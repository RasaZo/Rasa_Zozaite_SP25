/*I created a database and connection in pgAdmin4 and named the database "political_campaign_2025" because I believe it will be easier to 
find if there are multiple databases for different political campaigns across different years.
I also named the schema "management" because it's clear and helps avoid any confusion with the database name 
"political_campaign_2025" or the table name "campaign", reducing redundancy in this case. */


-- to drop the database if it already exists (for rerunnable code)
DROP DATABASE IF EXISTS political_campaign_2025;

-- to create a new database
CREATE DATABASE political_campaign_2025;

-- to drop the schema if it exists
DROP SCHEMA IF EXISTS management CASCADE;

-- to create a schema for organizing our tables
CREATE SCHEMA IF NOT EXISTS management;

-- to set search path to use our schema by default
SET search_path TO management;





--Firs of all, I created all tables.

/*In this table and others we have a foreign key, but relationship will be established later with ALTER TABLE. 
This way I wont receive error about non existing table and there will be no need to check table creation order (if one table have a foreign key, 
that means you need to create first the table wich hold foreign key as primary and so on.
IF NOT EXISTS helps to avoid errors if the table already exists and script can be run multiple times without error. If the table already exists, 
the database simply skips the creation rather than throwing an error. */


--------------------------------------------------------------------------------------------------------------------
/*CHANGES 

I made one big change here. Because FK campaign_staff_id in campaign table and FK campaign_id in campaign_staff table 
creates a circular reference it can cause problems when initially populating the database, I won't be able to 
since none of the references can accept nulls and you can’t insert one record without having another on the other table
so I decided to remove campaign_staff_id from management.campaign table*/
---------------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS management.campaign (
    campaign_id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(100),
    campaign_start_date DATE,
    campaign_end_date DATE
);


CREATE TABLE IF NOT EXISTS management.event (
    event_id SERIAL PRIMARY KEY,
    event_type VARCHAR(100),
    event_date TIMESTAMP,
    event_location VARCHAR(255),
    event_budget NUMERIC(10,2),
    event_description TEXT,
    event_status VARCHAR(50),
    event_contact_person VARCHAR(100)
) ;


CREATE TABLE IF NOT EXISTS management.social_media (
    social_media_id SERIAL PRIMARY KEY,
    social_media_activity_type VARCHAR(100),
    social_media_platform VARCHAR(100),
    social_media_content TEXT,
    social_media_post_date TIMESTAMP, 
    social_media_impressions NUMERIC(10,2), 
    social_media_engagement NUMERIC(10,2) 
);


CREATE TABLE IF NOT EXISTS management.campaign_public (
    campaign_id INT,
    social_media_id INT,
    event_id INT
);



CREATE TABLE IF NOT EXISTS management.campaign_staff (
    campaign_staff_id SERIAL PRIMARY KEY,
    employee_id INT,
    campaign_id INT,
    campaign_staff_role VARCHAR(100)
);


CREATE TABLE IF NOT EXISTS management.employee (
    employee_id SERIAL PRIMARY KEY,
    employee_first_name VARCHAR(50), 
    employee_last_name VARCHAR(50),
    employee_position VARCHAR(100),
    employee_hire_date DATE ,
    employee_salary NUMERIC(10,2)
);


CREATE TABLE IF NOT EXISTS management.supervisor_volunteer (
    supervisor_volunteer_id SERIAL PRIMARY KEY,
    employee_id	INT,	
    volunteer_id INT,	
    supervisor_volunteer_full_name VARCHAR(100),
    supervisor_volunteer_phone_number VARCHAR(20),
    supervisor_volunteer_email VARCHAR(100),
    supervisor_volunteer_address TEXT
);


CREATE TABLE IF NOT EXISTS management.volunteer (
    volunteer_id SERIAL PRIMARY KEY,
    volunteer_full_name VARCHAR(100),
    volunteer_availability BOOLEAN DEFAULT TRUE,
    volunteer_email VARCHAR(100),
    volunteer_phone_number VARCHAR(20),
    volunteer_address TEXT
);

CREATE TABLE IF NOT EXISTS management.donation (
    donation_id SERIAL PRIMARY KEY,
    donor_id INT,
    donation_date DATE,
    donation_amount NUMERIC(10,2), -- CHECK: cannot be negative
    donation_purpose TEXT 
);

CREATE TABLE IF NOT EXISTS management.donor (
    donor_id SERIAL PRIMARY KEY,
    donor_first_name VARCHAR(50),
    donor_last_name VARCHAR(50),
    donor_email VARCHAR(100),
    donor_phone VARCHAR(20),
    donor_address TEXT,
    donor_anonymity BOOLEAN DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS management.finance (
    finance_id SERIAL PRIMARY KEY,
    campaign_id INT,
    donation_id INT,
    finance_collected_amount NUMERIC(10,2),
    finance_expense_amount NUMERIC(10,2),
    finance_remaining_amount NUMERIC(10,2) 
);


CREATE TABLE IF NOT EXISTS management.campaign_data (
    campaign_id INT,
    research_id INT,
    survey_id INT
);


CREATE TABLE IF NOT EXISTS management.research (
    research_id SERIAL PRIMARY KEY,
    research_type VARCHAR(100),
    research_topic VARCHAR(255),
    research_collection_date TIMESTAMP,
    research_data_sensitivity BOOLEAN,
    research_source_documents TEXT
);


CREATE TABLE IF NOT EXISTS management.survey (
    survey_id SERIAL PRIMARY KEY,
    survey_result_id INT,
    survey_title VARCHAR(150)
);


CREATE TABLE IF NOT EXISTS management.survey_result (
    survey_result_id SERIAL PRIMARY KEY,
    survey_result_question TEXT,
    survey_result_answer TEXT,
    survey_result_place VARCHAR(100) ,
    survey_result_date DATE
);


/*Inserting constraints. I decided to do this part in blocks, where I first apply foreign key constraints and
all other constraints. I though that this way I won't forget to add one of the most important constraint and it is easier for me to check
where foreign key constraint was added, if I didn't missed a table */

/*DO blocks are useful because they allow  to check conditions before making schema changes and
entire DO block executes as a single transaction, ensuring all operations within it either succeed 
together or fail together*/

--------------------- /
--FOREIGN KEYS		  /
----------------------/

DO $$
BEGIN


-- Foreign keys for management.campaign_data
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_data_campaign' 
                   AND table_name = 'campaign_data'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_data
        ADD CONSTRAINT fk_campaign_data_campaign
        FOREIGN KEY (campaign_id) REFERENCES management.campaign(campaign_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_data_research' 
                   AND table_name = 'campaign_data'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_data
        ADD CONSTRAINT fk_campaign_data_research
        FOREIGN KEY (research_id) REFERENCES management.research(research_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_data_survey' 
                   AND table_name = 'campaign_data'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_data
        ADD CONSTRAINT fk_campaign_data_survey
        FOREIGN KEY (survey_id) REFERENCES management.survey(survey_id);
    END IF;


  -- Foreign keys for management.campaign_public
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_public_campaign' 
                   AND table_name = 'campaign_public'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_public
        ADD CONSTRAINT fk_campaign_public_campaign
        FOREIGN KEY (campaign_id) REFERENCES management.campaign(campaign_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_public_social_media' 
                   AND table_name = 'campaign_public'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_public
        ADD CONSTRAINT fk_campaign_public_social_media
        FOREIGN KEY (social_media_id) REFERENCES management.social_media(social_media_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_public_event' 
                   AND table_name = 'campaign_public'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_public
        ADD CONSTRAINT fk_campaign_public_event
        FOREIGN KEY (event_id) REFERENCES management.event(event_id);
    END IF;


    -- Foreign keys for management.campaign_staff
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_staff_employee' 
                   AND table_name = 'campaign_staff'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_staff
        ADD CONSTRAINT fk_campaign_staff_employee
        FOREIGN KEY (employee_id) REFERENCES management.employee(employee_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_campaign_staff_campaign' 
                   AND table_name = 'campaign_staff'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.campaign_staff
        ADD CONSTRAINT fk_campaign_staff_campaign
        FOREIGN KEY (campaign_id) REFERENCES management.campaign(campaign_id);
    END IF;

-- Foreign key for management.donation
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_donation_donor' 
                   AND table_name = 'donation'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.donation
        ADD CONSTRAINT fk_donation_donor
        FOREIGN KEY (donor_id) REFERENCES management.donor(donor_id);
    END IF;
  
-- Foreign keys for management.finance
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_finance_campaign' 
                   AND table_name = 'finance'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.finance
        ADD CONSTRAINT fk_finance_campaign
        FOREIGN KEY (campaign_id) REFERENCES management.campaign(campaign_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_finance_donation' 
                   AND table_name = 'finance'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.finance
        ADD CONSTRAINT fk_finance_donation
        FOREIGN KEY (donation_id) REFERENCES management.donation(donation_id);
    END IF;

 -- Foreign keys for management.supervisor_volunteer
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_supervisor_volunteer_employee' 
                   AND table_name = 'supervisor_volunteer'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT fk_supervisor_volunteer_employee
        FOREIGN KEY (employee_id) REFERENCES management.employee(employee_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_supervisor_volunteer_volunteer' 
                   AND table_name = 'supervisor_volunteer'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT fk_supervisor_volunteer_volunteer
        FOREIGN KEY (volunteer_id) REFERENCES management.volunteer(volunteer_id);
    END IF;


 -- Foreign keys for management.survey
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_survey_survey_result' 
                   AND table_name = 'survey'
                   AND table_schema = 'management') THEN
        ALTER TABLE management.survey
        ADD CONSTRAINT fk_survey_survey_result
        FOREIGN KEY (survey_result_id) REFERENCES management.survey_result(survey_result_id);
    END IF;   


END $$;

-----------------------------------------------------------------------------------------------------------
--Other Constraints

-- Constraints for table management.campaign
DO $$
BEGIN
-- --Not null
-- checking if this constraint exists in table campaign, column campaign_id and setting to default constraint not null
	IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign'
          AND column_name = 'campaign_id'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.campaign
        ALTER COLUMN campaign_id SET NOT NULL;
    END IF;

--I dont want campaign_name empty, so I set it not null
	IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign'
          AND column_name = 'campaign_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.campaign
        ALTER COLUMN campaign_name SET NOT NULL;
    END IF;
	
-- Campaign must have a start date so setting not null
	IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign'
          AND column_name = 'campaign_start_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.campaign
        ALTER COLUMN campaign_start_date SET NOT NULL;
    END IF;

-- CHECK constraint on date that it would be > 2000-01-01

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_campaign_start_date'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.campaign
        ADD CONSTRAINT chk_campaign_start_date
        CHECK (campaign_start_date > DATE '2000-01-01');
    END IF;

--for checking that campaign ending date later than start date because not ot oviolate logic that end must be after the start
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_campaign_end_date'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.campaign
        ADD CONSTRAINT chk_campaign_end_date
        CHECK (campaign_end_date > campaign_start_date);
    END IF;

-- Unique constraint for campaign name (I want same name for the same campaign_id for a clarity)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'uq_campaign_name'
        AND table_name = 'campaign'
        AND table_schema = 'management'
    ) THEN
        ALTER TABLE management.campaign
        ADD CONSTRAINT uq_campaign_name UNIQUE (campaign_name);
    END IF;
END $$;




--Constraints for EVENT table
DO $$
BEGIN
    -- NOT NULL constraint so event type would have a type, this is more optional, but would help to organise events by type if needed.
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_type'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_type SET NOT NULL;
    END IF;

--date can not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_date SET NOT NULL;
    END IF;

-- must to have a location
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_location'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_location SET NOT NULL;
    END IF;
--budget can not be null because campaign can not run without a budget
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_budget'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_budget SET NOT NULL;
    END IF;
-- I added this one, because i think it is important to know event status.
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_status'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_status SET NOT NULL;
    END IF;
-- definetely can not be null, because it is important to know who contact
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'event'
          AND column_name = 'event_contact_person'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.event
        ALTER COLUMN event_contact_person SET NOT NULL;
    END IF;

-- CHECK constraint: event_date > 2000-01-01
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_event_date_after_2000'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.event
        ADD CONSTRAINT chk_event_date_after_2000
        CHECK (event_date > TIMESTAMP '2000-01-01 00:00:00');
    END IF;

-- CHECK constraint: event_budget >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_event_budget_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.event
        ADD CONSTRAINT chk_event_budget_non_negative
        CHECK (event_budget >= 0);
    END IF;

-- CHECK constraint: event_status IN (...)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_event_status_valid'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.event
        ADD CONSTRAINT chk_event_status_valid
        CHECK (event_status IN ('Scheduled', 'Completed', 'Cancelled'));
    END IF;

END $$;

-- table socia_media constraints

DO $$
BEGIN
    -- Ensure social_media_activity_type is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'social_media_activity_type'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.social_media
        ALTER COLUMN social_media_activity_type SET NOT NULL;
    END IF;

    -- Ensure social_media_platform is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'social_media_platform'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.social_media
        ALTER COLUMN social_media_platform SET NOT NULL;
    END IF;

    -- Ensure social_media_post_date is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'social_media_post_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.social_media
        ALTER COLUMN social_media_post_date SET NOT NULL;
    END IF;

    -- Ensure social_media_impressions is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'social_media_impressions'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.social_media
        ALTER COLUMN social_media_impressions SET NOT NULL;
    END IF;

    -- Ensure social_media_engagement is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'social_media_engagement'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.social_media
        ALTER COLUMN social_media_engagement SET NOT NULL;
    END IF;

    -- CHECK: social_media_post_date should be after 2000-01-01
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_social_media_post_date_after_2000'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.social_media
        ADD CONSTRAINT chk_social_media_post_date_after_2000
        CHECK (social_media_post_date > TIMESTAMP '2000-01-01 00:00:00');
    END IF;

    -- CHECK: social_media_impressions >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_social_media_impressions_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.social_media
        ADD CONSTRAINT chk_social_media_impressions_non_negative
        CHECK (social_media_impressions >= 0);
    END IF;

    -- CHECK: social_media_engagement >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_social_media_engagement_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.social_media
        ADD CONSTRAINT chk_social_media_engagement_non_negative
        CHECK (social_media_engagement >= 0);
    END IF;

END $$;


--Constraints for management.employee
DO $$
BEGIN

    -- First name should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'employee_first_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.employee
        ALTER COLUMN employee_first_name SET NOT NULL;
    END IF;

    -- Last name should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'employee_last_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.employee
        ALTER COLUMN employee_last_name SET NOT NULL;
    END IF;

    -- Position should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'employee_position'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.employee
        ALTER COLUMN employee_position SET NOT NULL;
    END IF;

    -- Hire date should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'employee_hire_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.employee
        ALTER COLUMN employee_hire_date SET NOT NULL;
    END IF;

    -- Salary should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'employee_salary'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.employee
        ALTER COLUMN employee_salary SET NOT NULL;
    END IF;

    -- Salary must be non-negative
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_employee_salary_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.employee
        ADD CONSTRAINT chk_employee_salary_non_negative
        CHECK (employee_salary >= 0);
    END IF;

END $$;

-- Constraints for supervisor_volunteer 

DO $$
BEGIN
-- Full name should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND column_name = 'supervisor_volunteer_full_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ALTER COLUMN supervisor_volunteer_full_name SET NOT NULL;
    END IF;

-- Phone number should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND column_name = 'supervisor_volunteer_phone_number'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ALTER COLUMN supervisor_volunteer_phone_number SET NOT NULL;
    END IF;

-- Email should not be null
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND column_name = 'supervisor_volunteer_email'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ALTER COLUMN supervisor_volunteer_email SET NOT NULL;
    END IF;

-- Email should be unique
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND constraint_type = 'UNIQUE'
          AND constraint_name = 'uq_supervisor_volunteer_email'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT uq_supervisor_volunteer_email
        UNIQUE (supervisor_volunteer_email);
    END IF;

END $$;


DO $$
BEGIN
    -- Set NOT NULL for full name if currently nullable
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND column_name = 'supervisor_volunteer_full_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ALTER COLUMN supervisor_volunteer_full_name SET NOT NULL;
    END IF;

   --instead of unique supervisor name, adding unique employee and volunteer id's
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND constraint_type = 'UNIQUE'
          AND constraint_name = 'unique_emp_vol_id'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT unique_emp_vol_id UNIQUE (employee_id, volunteer_id); 
    END IF;
END $$;


    -- Add UNIQUE constraint for email
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu 
            ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_schema = 'management'
          AND tc.table_name = 'supervisor_volunteer'
          AND tc.constraint_type = 'UNIQUE'
          AND ccu.column_name = 'supervisor_volunteer_email'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT unique_email UNIQUE (supervisor_volunteer_email);
    END IF;

    -- Add UNIQUE constraint for phone number
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu 
            ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_schema = 'management'
          AND tc.table_name = 'supervisor_volunteer'
          AND tc.constraint_type = 'UNIQUE'
          AND ccu.column_name = 'supervisor_volunteer_phone_number'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ADD CONSTRAINT unique_phone_number UNIQUE (supervisor_volunteer_phone_number);
    END IF;
END $$;



--Constraints for research table


DO $$
BEGIN

-- research_type NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'research'
          AND column_name = 'research_type'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.research
        ALTER COLUMN research_type SET NOT NULL;
    END IF;

-- research_topic NOT NULL because it is important to know topic
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'research'
          AND column_name = 'research_topic'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.research
        ALTER COLUMN research_topic SET NOT NULL;
    END IF;

-- research_collection_date NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'research'
          AND column_name = 'research_collection_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.research
        ALTER COLUMN research_collection_date SET NOT NULL;
    END IF;

-- CHECK constraint: research_collection_date > 2000-01-01
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_research_collection_date_after_2000'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.research
        ADD CONSTRAINT chk_research_collection_date_after_2000
        CHECK (research_collection_date > TIMESTAMP '2000-01-01 00:00:00');
      END IF;

END $$;




--Constraints for table survey_result

DO $$
BEGIN

    -- survey_result_question NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_question'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_question SET NOT NULL;
    END IF;

-- survey_result_place NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_place'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_place SET NOT NULL;
    END IF;

-- survey_result_date NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_date SET NOT NULL;
    END IF;

-- CHECK: survey_result_date > 2000-01-01
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_survey_result_date_after_2000'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.survey_result
        ADD CONSTRAINT chk_survey_result_date_after_2000
        CHECK (survey_result_date > DATE '2000-01-01');
      END IF;

END $$;

--Constraints for donor table

DO $$
BEGIN

-- donor_first_name NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND column_name = 'donor_first_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donor
        ALTER COLUMN donor_first_name SET NOT NULL;
    END IF;

-- donor_last_name NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND column_name = 'donor_last_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donor
        ALTER COLUMN donor_last_name SET NOT NULL;
    END IF;

-- donor_email NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND column_name = 'donor_email'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donor
        ALTER COLUMN donor_email SET NOT NULL;
    END IF;

-- donor_email UNIQUE
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND constraint_type = 'UNIQUE'
          AND constraint_name = 'uq_donor_email'
    ) THEN
        ALTER TABLE management.donor
        ADD CONSTRAINT uq_donor_email
        UNIQUE (donor_email);
      END IF;
---- Ensure donor_anonymity has default FALSE (not anonymous)
	IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND column_name = 'donor_anonymity'
          AND column_default IS DISTINCT FROM 'false' -- compare as text
    ) THEN
        ALTER TABLE management.donor
        ALTER COLUMN donor_anonymity SET DEFAULT FALSE;
    END IF;

-- Ensure value is either TRUE or FALSE
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_donor_anonymity_valid'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.donor
        ADD CONSTRAINT chk_donor_anonymity_valid
        CHECK (donor_anonymity IN (TRUE, FALSE));
    END IF;

END $$;


--constraints for volunteer table
DO $$
BEGIN

-- volunteer_full_name NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'volunteer_full_name'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.volunteer
        ALTER COLUMN volunteer_full_name SET NOT NULL;
    END IF;

-- volunteer_email NOT NULL because it is important to knwo how to contact a volunteer
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'volunteer_email'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.volunteer
        ALTER COLUMN volunteer_email SET NOT NULL;
    END IF;

--volunteer_phone number not null because of contacting

IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'volunteer_phone_number'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.volunteer
        ALTER COLUMN volunteer_phone_number SET NOT NULL;
    END IF;

-- volunteer_email UNIQUE
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND constraint_type = 'UNIQUE'
          AND constraint_name = 'uq_volunteer_email'
    ) THEN
        ALTER TABLE management.volunteer
        ADD CONSTRAINT uq_volunteer_email
        UNIQUE (volunteer_email);
    END IF;

-- volunteer_availability NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'volunteer_availability'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.volunteer
        ALTER COLUMN volunteer_availability SET NOT NULL;
    END IF;

-- re-asserting default TRUE for availability if needed
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'volunteer_availability'
          AND column_default IS DISTINCT FROM 'true'
    ) THEN
        ALTER TABLE management.volunteer
        ALTER COLUMN volunteer_availability SET DEFAULT TRUE;
    END IF;

-- CHECK availability is either TRUE or FALSE
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_schema = 'management'
          AND constraint_name = 'chk_volunteer_availability_valid'
    ) THEN
        ALTER TABLE management.volunteer
        ADD CONSTRAINT chk_volunteer_availability_valid
        CHECK (volunteer_availability IN (TRUE, FALSE));
    END IF;

END $$;

--campaign staff table constraints
DO $$
BEGIN
    -- campaign_staff_role NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign_staff'
          AND column_name = 'campaign_staff_role'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.campaign_staff
        ALTER COLUMN campaign_staff_role SET NOT NULL;
    END IF;
END $$;

-- donation table constraints
DO $$
BEGIN
-- donation_date NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donation'
          AND column_name = 'donation_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donation
        ALTER COLUMN donation_date SET NOT NULL;
    END IF;

-- donation_amount NOT NULL because logically you can not donate zero money to campaign and call it donation
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donation'
          AND column_name = 'donation_amount'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donation
        ALTER COLUMN donation_amount SET NOT NULL;
    END IF;

-- CHECK: donation_amount >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_donation_amount_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.donation
        ADD CONSTRAINT chk_donation_amount_non_negative
        CHECK (donation_amount >= 0);
    END IF;

-- Ensure donation_date is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donation'
          AND column_name = 'donation_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.donation
        ALTER COLUMN donation_date SET NOT NULL;
    END IF;

-- Ensure donation_date has default value CURRENT_DATE
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donation'
          AND column_name = 'donation_date'
          AND (column_default IS NULL OR column_default IS DISTINCT FROM 'CURRENT_DATE'::text)
    ) THEN
        ALTER TABLE management.donation
        ALTER COLUMN donation_date SET DEFAULT CURRENT_DATE;
    END IF;

END $$;



--table finance 
DO $$
BEGIN
 -- finance_collected_amount NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'finance_collected_amount'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.finance
        ALTER COLUMN finance_collected_amount SET NOT NULL;
    END IF;

-- finance_expense_amount NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'finance_expense_amount'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.finance
        ALTER COLUMN finance_expense_amount SET NOT NULL;
    END IF;

-- finance_remaining_amount NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'finance_remaining_amount'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.finance
        ALTER COLUMN finance_remaining_amount SET NOT NULL;
    END IF;

-- CHECK: collected, expense, remaining >= 0
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_finance_amounts_non_negative'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.finance
        ADD CONSTRAINT chk_finance_amounts_non_negative
        CHECK (
            finance_collected_amount >= 0 AND
            finance_expense_amount >= 0 AND
            finance_remaining_amount >= 0
        );
    END IF;

-- Check if the finance_remaining amount column exists (if not, add it)
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'finance_remaining_amount'
    ) THEN
-- Add the finance_remaining_amount column with generated expression
        ALTER TABLE management.finance
        ADD COLUMN finance_remaining_amount NUMERIC(10,2) 
        GENERATED ALWAYS AS (finance_budget - finance_allocated_amount) STORED;
    END IF;

END $$;


--constraints for table survey

DO $$
BEGIN
-- survey_title NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey'
          AND column_name = 'survey_title'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey
        ALTER COLUMN survey_title SET NOT NULL;
    END IF;

-- survey_title UNIQUE
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'management'
          AND table_name = 'survey'
          AND constraint_type = 'UNIQUE'
          AND constraint_name = 'uq_survey_title'
    ) THEN
        ALTER TABLE management.survey
        ADD CONSTRAINT uq_survey_title
        UNIQUE (survey_title);
    END IF;
END $$;


--table survey_result constraints
DO $$
BEGIN
    -- survey_result_question NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_question'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_question SET NOT NULL;
    END IF;

    -- survey_result_answer NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_answer'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_answer SET NOT NULL;
    END IF;

-- survey_result_place NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_place'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_place SET NOT NULL;
    END IF;

-- survey_result_date NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'survey_result_date'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE management.survey_result
        ALTER COLUMN survey_result_date SET NOT NULL;
    END IF;

-- CHECK: survey_result_date > '2000-01-01'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'chk_survey_result_date_valid'
          AND constraint_schema = 'management'
    ) THEN
        ALTER TABLE management.survey_result
        ADD CONSTRAINT chk_survey_result_date_valid
        CHECK (survey_result_date > DATE '2000-01-01');
    END IF;

END $$;



--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--Inserting values into tables


-- inserting data into campaign table
INSERT INTO management.campaign (campaign_name, campaign_start_date, campaign_end_date)
SELECT vals.campaign_name, vals.campaign_start_date, vals.campaign_end_date
FROM (
    VALUES 
        ('Go, Greens, Go!', DATE '2021-04-01', DATE '2021-07-01'),
        ('Let’s win', DATE '2020-03-08', DATE '2020-06-01'),
        ('Equality for All', DATE '2025-03-01', DATE '2025-08-01'),
        ('Digital Awareness Campaign', DATE '2025-01-20', DATE '2025-05-30'),
        ('Vote Ready 2025', DATE '2025-02-15', DATE '2025-06-30')
) AS vals(campaign_name, campaign_start_date, campaign_end_date)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.campaign c
    WHERE c.campaign_name = vals.campaign_name
);


-- inserting values into event table
INSERT INTO management.event (
    event_type, event_date, event_location, event_budget,
    event_description, event_status, event_contact_person
)
SELECT vals.event_type, vals.event_date, vals.event_location, vals.event_budget,
       vals.event_description, vals.event_status, vals.event_contact_person
FROM (
    VALUES
        ('Town Hall Meeting', TIMESTAMP '2023-10-01 10:00:00', 'City Community Center', 5000.00, 'A public meeting for discussing community concerns.', 'Scheduled', 'Alice Johnson'),
        ('Volunteer Drive', TIMESTAMP '2024-03-15 09:00:00', 'Downtown Square', 1500.00, 'Recruiting local volunteers for outreach.', 'Completed', 'Brian Lee'),
        ('Tech Awareness Seminar', TIMESTAMP '2025-01-20 14:00:00', 'Tech Hub Auditorium', 3000.00, 'Educating citizens on digital tools.', 'Scheduled', 'Claire Kim'),
        ('Fundraising Gala', TIMESTAMP '2025-02-10 19:00:00', 'Grand Hotel Ballroom', 10000.00, 'Formal event to raise campaign funds.', 'Scheduled', 'Daniel Smith'),
        ('Environmental Workshop', TIMESTAMP '2024-11-05 11:00:00', 'Green Earth Center', 2000.00, 'Workshop on sustainability practices.', 'Cancelled', 'Eva Green')
) AS vals(
    event_type, event_date, event_location, event_budget,
    event_description, event_status, event_contact_person
)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.event e
    WHERE e.event_type = vals.event_type
      AND e.event_date = vals.event_date
);


-- Employee table 
INSERT INTO management.employee (employee_first_name, employee_last_name, employee_position, employee_hire_date, employee_salary)
SELECT vals.first_name, vals.last_name, vals.position, vals.hire_date, vals.salary
FROM (
    VALUES
        ('John', 'Smith', 'Campaign Manager', DATE '2024-11-01', 85000.00),
        ('Sarah', 'Johnson', 'Field Director', DATE '2024-11-15', 65000.00),
        ('Michael', 'Williams', 'Communications Director', DATE '2024-12-01', 70000.00),
        ('Jessica', 'Brown', 'Finance Director', DATE '2024-12-10', 72000.00),
        ('David', 'Miller', 'Volunteer Coordinator', DATE '2025-01-05', 55000.00),
        ('Emily', 'Davis', 'Social Media Manager', DATE '2025-01-15', 58000.00),
        ('Robert', 'Wilson', 'Policy Advisor', DATE '2025-01-20', 75000.00),
        ('Lisa', 'Anderson', 'Event Coordinator', DATE '2025-02-01', 52000.00)
) AS vals(first_name, last_name, position, hire_date, salary)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.employee e
    WHERE e.employee_first_name = vals.first_name
    AND e.employee_last_name = vals.last_name
);


-- Social Media table
INSERT INTO management.social_media (
    social_media_activity_type, 
    social_media_platform, 
    social_media_content, 
    social_media_post_date, 
    social_media_impressions, 
    social_media_engagement
)
SELECT vals.activity_type, vals.platform, vals.content, vals.post_date, vals.impressions, vals.engagement
FROM (
    VALUES
    ('Campaign Launch', 'Twitter', 'Excited to announce our campaign for a better future! #Campaign2025', TIMESTAMP '2025-02-01 10:00:00', 15000.00, 3200.00),
    ('Policy Video', 'Facebook', 'Watch our candidate explain our environmental policy initiatives', TIMESTAMP '2025-02-15 14:30:00', 22000.00, 5100.00),
    ('Live Q&A', 'Instagram', 'Join us for a live session answering your questions about our platform', TIMESTAMP '2025-03-01 18:00:00', 18500.00, 4300.00),
    ('Volunteer Call', 'LinkedIn', 'We need dedicated volunteers to help with our campaign efforts', TIMESTAMP '2025-03-15 09:00:00', 8500.00, 1200.00),
    ('Event Promotion', 'Twitter', 'Don''t miss our town hall meeting this Saturday! #EngagedCommunity', TIMESTAMP '2025-04-10 12:00:00', 12500.00, 2800.00)
) AS vals(activity_type, platform, content, post_date, impressions, engagement)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.social_media sm
    WHERE sm.social_media_platform = vals.platform
    AND sm.social_media_post_date = vals.post_date
);

-- Volunteer table 
INSERT INTO management.volunteer (
    volunteer_full_name, 
    volunteer_availability, 
    volunteer_email, 
    volunteer_phone_number, 
    volunteer_address
)
SELECT vals.full_name, vals.availability, vals.email, vals.phone, vals.address
FROM (
    VALUES
        ('Thomas Parker', TRUE, 'tparker@email.com', '555-123-4567', '123 Main St, Anytown'),
        ('Maria Rodriguez', TRUE, 'mrodriguez@email.com', '555-234-5678', '456 Oak Ave, Anytown'),
        ('James Wilson', FALSE, 'jwilson@email.com', '555-345-6789', '789 Pine Rd, Anytown'),
        ('Sophia Lee', TRUE, 'slee@email.com', '555-456-7890', '321 Maple Dr, Anytown'),
        ('Benjamin Davis', TRUE, 'bdavis@email.com', '555-567-8901', '654 Cedar Ln, Anytown'),
        ('Olivia Martinez', FALSE, 'omartinez@email.com', '555-678-9012', '987 Birch St, Anytown')
) AS vals(full_name, availability, email, phone, address)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.volunteer v
    WHERE v.volunteer_email = vals.email
);

-- Donor table (no dependencies)
INSERT INTO management.donor (
    donor_first_name, 
    donor_last_name, 
    donor_email, 
    donor_phone, 
    donor_address, 
    donor_anonymity
)
SELECT vals.first_name, vals.last_name, vals.email, vals.phone, vals.address, vals.anonymity
FROM (
    VALUES
        ('Richard', 'Thompson', 'rthompson@email.com', '555-111-2222', '123 Wealth Ave, Richtown', FALSE),
        ('Elizabeth', 'Campbell', 'ecampbell@email.com', '555-222-3333', '456 Fortune St, Richtown', FALSE),
        ('William', 'Hughes', 'whughes@email.com', '555-333-4444', '789 Success Rd, Richtown', TRUE),
        ('Jennifer', 'Morgan', 'jmorgan@email.com', '555-444-5555', '321 Prosperity Dr, Richtown', FALSE),
        ('Christopher', 'Baker', 'cbaker@email.com', '555-555-6666', '654 Abundance Ln, Richtown', TRUE),
        ('Margaret', 'Evans', 'mevans@email.com', '555-666-7777', '987 Luxury St, Richtown', FALSE)
) AS vals(first_name, last_name, email, phone, address, anonymity)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.donor d
    WHERE d.donor_email = vals.email
);

-- Survey Result table 
INSERT INTO management.survey_result (
    survey_result_question, 
    survey_result_answer, 
    survey_result_place, 
    survey_result_date
)
SELECT vals.question, vals.answer, vals.place, vals.date
FROM (
    VALUES
        ('What is your top policy concern?', 'Healthcare', 'Rivergate Mall', DATE '2025-02-09'),
        ('How likely are you to vote in the upcoming election?', 'Very likely', 'Sunrise Promenade', DATE '2025-02-12'),
        ('Which candidate quality matters most to you?', 'Integrity', 'Greenwood Galleria', DATE '2025-02-14'),
        ('What is your opinion on climate policy?', 'Very important', 'Bayfront Plaza', DATE '2025-02-18'),
        ('How would you rate the current administration?', 'Somewhat favorable', 'Lakeside Commons', DATE '2025-02-20'),
        ('Which issue should receive more attention?', 'Education', 'Greenwood Galleria', DATE '2025-02-22')
) AS vals(question, answer, place, date)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.survey_result sr
    WHERE sr.survey_result_question = vals.question
      AND sr.survey_result_answer = vals.answer
      AND sr.survey_result_place = vals.place
      AND sr.survey_result_date = vals.date
);



-- Research table 
INSERT INTO management.research (
    research_type, 
    research_topic, 
    research_collection_date, 
    research_data_sensitivity, 
    research_source_documents
)
SELECT vals.type, vals.topic, vals.collection_date, vals.sensitivity, vals.source
FROM (
    VALUES
        ('Demographic', 'Voter demographics in target districts', TIMESTAMP '2025-01-20 00:00:00', FALSE, 'Census data, voting records'),
        ('Issue-based', 'Public opinion on healthcare reform', TIMESTAMP '2025-02-05 00:00:00', FALSE, 'Public polls, focus group transcripts'),
        ('Opposition', 'Analysis of opponent messaging strategies', TIMESTAMP '2025-02-15 00:00:00', TRUE, 'Campaign speeches, media analysis'),
        ('Economic', 'Impact of proposed tax policies', TIMESTAMP '2025-03-01 00:00:00', FALSE, 'Economic reports, expert interviews'),
        ('Media', 'Media coverage analysis by outlet', TIMESTAMP '2025-03-15 00:00:00', FALSE, 'News articles, TV transcripts')
) AS vals(type, topic, collection_date, sensitivity, source)
WHERE NOT EXISTS (
    SELECT 1
    FROM management.research r
    WHERE r.research_topic = vals.topic
);


-- Survey table 
INSERT INTO management.survey (
    survey_result_id,
    survey_title,
    survey_date
)
SELECT sr.survey_result_id, vals.title, vals.date
FROM management.survey_result sr
INNER JOIN (
    VALUES
        ('Voter Priorities Survey', DATE '2025-02-10'),
        ('Voter Satisfaction Survey', DATE '2025-02-20')
) AS vals(title, date)
  ON sr.survey_result_date = vals.date
ON CONFLICT (survey_title) DO NOTHING;


-- Campaign Staff table (depends on employee and campaign)
-- Campaign Manager for 'Equality for All'
INSERT INTO management.campaign_staff (employee_id, campaign_id, campaign_staff_role)
SELECT e.employee_id, c.campaign_id, 'Campaign Manager'
FROM management.employee e
INNER JOIN management.campaign c ON c.campaign_name = 'Equality for All'
WHERE e.employee_position = 'Campaign Manager'
  AND NOT EXISTS (
    SELECT 1
    FROM management.campaign_staff cs
    WHERE cs.employee_id = e.employee_id
      AND cs.campaign_id = c.campaign_id
);

-- Field Director for 'Vote Ready 2025'
INSERT INTO management.campaign_staff (employee_id, campaign_id, campaign_staff_role)
SELECT e.employee_id, c.campaign_id, 'Field Director'
FROM management.employee e
INNER JOIN management.campaign c ON c.campaign_name = 'Vote Ready 2025'
WHERE e.employee_position = 'Field Director'
  AND NOT EXISTS (
    SELECT 1
    FROM management.campaign_staff cs
    WHERE cs.employee_id = e.employee_id
      AND cs.campaign_id = c.campaign_id
);

-- Communications Director for 'Digital Awareness Campaign'
INSERT INTO management.campaign_staff (employee_id, campaign_id, campaign_staff_role)
SELECT e.employee_id, c.campaign_id, 'Communications Director'
FROM management.employee e
INNER JOIN management.campaign c ON c.campaign_name = 'Digital Awareness Campaign'
WHERE e.employee_position = 'Communications Director'
  AND NOT EXISTS (
    SELECT 1
    FROM management.campaign_staff cs
    WHERE cs.employee_id = e.employee_id
      AND cs.campaign_id = c.campaign_id
);

-- Finance Director for 'Green Future'
INSERT INTO management.campaign_staff (employee_id, campaign_id, campaign_staff_role)
SELECT e.employee_id, c.campaign_id, 'Finance Director'
FROM management.employee e
INNER JOIN management.campaign c ON c.campaign_name = 'Green Future'
WHERE e.employee_position = 'Finance Director'
  AND NOT EXISTS (
    SELECT 1
    FROM management.campaign_staff cs
    WHERE cs.employee_id = e.employee_id
      AND cs.campaign_id = c.campaign_id
);

-- Volunteer Coordinator for 'Progress Coalition'
INSERT INTO management.campaign_staff (employee_id, campaign_id, campaign_staff_role)
SELECT e.employee_id, c.campaign_id, 'Volunteer Coordinator'
FROM management.employee e
INNER JOIN management.campaign c ON c.campaign_name = 'Progress Coalition'
WHERE e.employee_position = 'Volunteer Coordinator'
  AND NOT EXISTS (
    SELECT 1
    FROM management.campaign_staff cs
    WHERE cs.employee_id = e.employee_id
      AND cs.campaign_id = c.campaign_id
);


-- Supervisor Volunteer table (depends on employee and volunteer)
INSERT INTO management.supervisor_volunteer (
    employee_id, 
    volunteer_id, 
    supervisor_volunteer_full_name, 
    supervisor_volunteer_phone_number, 
    supervisor_volunteer_email, 
    supervisor_volunteer_address
)
SELECT 
    e.employee_id, 
    v.volunteer_id, 
    e.employee_first_name || ' ' || e.employee_last_name AS full_name,
    '555-' || LPAD(e.employee_id::text, 3, '0') || '-' || LPAD(v.volunteer_id::text, 3, '0') AS phone_number,
    LOWER(LEFT(e.employee_first_name, 1) || e.employee_last_name || v.volunteer_id) || '.supervisor@campaign.org' AS email,
    (100 + e.employee_id)::text || ' Supervisor St, Campaign HQ' AS address
FROM management.employee e
INNER JOIN management.volunteer v ON TRUE
WHERE e.employee_position = 'Volunteer Coordinator'
  AND NOT EXISTS (
      SELECT 1
      FROM management.supervisor_volunteer sv
      WHERE sv.employee_id = e.employee_id
        AND sv.volunteer_id = v.volunteer_id
  )
ON CONFLICT DO NOTHING;

-- even this employee is not a volunteer supervisor I added for the sake of condition two rows per table
INSERT INTO management.supervisor_volunteer (
    employee_id, 
    volunteer_id, 
    supervisor_volunteer_full_name, 
    supervisor_volunteer_phone_number, 
    supervisor_volunteer_email, 
    supervisor_volunteer_address
)
SELECT 
    1 AS employee_id,
    v.volunteer_id,
    'Lisa Anderson' AS full_name,
    '555-001-00' || v.volunteer_id,
    'landerson' || v.volunteer_id || '.supervisor@campaign.org',
    '101 Supervisor St, Campaign HQ'
FROM management.volunteer v
WHERE NOT EXISTS (
    SELECT 1
    FROM management.supervisor_volunteer sv
    WHERE sv.employee_id = 1
      AND sv.volunteer_id = v.volunteer_id
)
ON CONFLICT DO NOTHING;



-- Donation table (depends on donor)
-- Insert donation from Richard Thompson
INSERT INTO management.donation (
	donor_id,
	donation_date, 
	donation_amount,
	donation_purpose
)
SELECT d.donor_id, DATE '2025-02-15', 5000.00, 'General campaign fund'
FROM management.donor d
WHERE d.donor_email = 'rthompson@email.com'
  AND NOT EXISTS (
      SELECT 1
      FROM management.donation don
      WHERE don.donor_id = d.donor_id
        AND don.donation_amount = 5000.00
        AND don.donation_purpose = 'General campaign fund'
  );

-- Insert donation from Elizabeth Campbell
INSERT INTO management.donation (
	donor_id,
	donation_date, 
	donation_amount,
	donation_purpose
)
SELECT d.donor_id, DATE '2025-03-01', 10000.00, 'Media advertising'
FROM management.donor d
WHERE d.donor_email = 'ecampbell@email.com'
  AND NOT EXISTS (
      SELECT 1
      FROM management.donation don
      WHERE don.donor_id = d.donor_id
        AND don.donation_amount = 10000.00
        AND don.donation_purpose = 'Media advertising'
  );

-- Insert donation from William Hughes
INSERT INTO management.donation (
	donor_id,
	donation_date, 
	donation_amount,
	donation_purpose
)
SELECT d.donor_id, DATE '2025-03-15', 2500.00, 'Community outreach events'
FROM management.donor d
WHERE d.donor_email = 'whughes@email.com'
  AND NOT EXISTS (
      SELECT 1
      FROM management.donation don
      WHERE don.donor_id = d.donor_id
        AND don.donation_amount = 2500.00
        AND don.donation_purpose = 'Community outreach events'
  );

-- Insert donation from Jennifer Morgan
INSERT INTO management.donation (
	donor_id,
	donation_date, 
	donation_amount,
	donation_purpose
)
SELECT d.donor_id, DATE '2025-04-01', 7500.00, 'Digital marketing'
FROM management.donor d
WHERE d.donor_email = 'jmorgan@email.com'
  AND NOT EXISTS (
      SELECT 1
      FROM management.donation don
      WHERE don.donor_id = d.donor_id
        AND don.donation_amount = 7500.00
        AND don.donation_purpose = 'Digital marketing'
  );

-- Insert donation from Christopher Baker
INSERT INTO management.donation (
	donor_id,
	donation_date, 
	donation_amount,
	donation_purpose
)
SELECT d.donor_id, DATE '2025-04-15', 15000.00, 'Television ads'
FROM management.donor d
WHERE d.donor_email = 'cbaker@email.com'
  AND NOT EXISTS (
      SELECT 1
      FROM management.donation don
      WHERE don.donor_id = d.donor_id
        AND don.donation_amount = 15000.00
        AND don.donation_purpose = 'Television ads'
  );


-- Finance table (depends on campaign and donation)
INSERT INTO management.finance (
    campaign_id, 
    donation_id, 
    finance_collected_amount, 
    finance_expense_amount, 
    finance_remaining_amount
)
SELECT c.campaign_id, d.donation_id, 
       d.donation_amount, 
       d.donation_amount * 0.7, -- Expense amount (70% of donation)
       d.donation_amount * 0.3  -- Remaining amount (30% of donation)
FROM management.campaign c
JOIN management.donation d ON 1=1
WHERE (c.campaign_name = 'Equality for All' AND d.donation_amount = 5000.00)
   OR (c.campaign_name = 'Digital Awareness Campaign' AND d.donation_amount = 10000.00)
   OR (c.campaign_name = 'Vote Ready 2025' AND d.donation_amount = 2500.00)
   OR (c.campaign_name = 'Green Future' AND d.donation_amount = 7500.00)
   OR (c.campaign_name = 'Progress Coalition' AND d.donation_amount = 15000.00)
AND NOT EXISTS (
    SELECT 1
    FROM management.finance f
    WHERE f.campaign_id = c.campaign_id
    AND f.donation_id = d.donation_id
);

-- Campaign campaign_data table (depends on campaign, research, and survey)

DO $$
BEGIN
    -- Check if the combination already exists
    IF NOT EXISTS (
        SELECT 1 FROM management.campaign_data cd
        JOIN management.campaign c ON cd.campaign_id = c.campaign_id
        JOIN management.research r ON cd.research_id = r.research_id
        JOIN management.survey s ON cd.survey_id = s.survey_id
        WHERE c.campaign_name = 'Equality for All'
        AND r.research_type = 'Demographic'
        AND s.survey_title = 'Voter Priorities Survey'
    ) THEN
        -- Insert only if the combination doesn't exist
        INSERT INTO management.campaign_data (campaign_id, research_id, survey_id)
        SELECT c.campaign_id, r.research_id, s.survey_id
        FROM management.campaign c, management.research r, management.survey s
        WHERE c.campaign_name = 'Equality for All'
        AND r.research_type = 'Demographic'
        AND s.survey_title = 'Voter Priorities Survey'
        LIMIT 1;
        
        RAISE NOTICE 'Record inserted successfully';
    ELSE
        RAISE NOTICE 'This combination already exists - no insertion needed';
    END IF;
END $$;

DO $$
DECLARE --This keyword begins the declaration section of the PL/pgSQL block, where you define variables.
    v_campaign_id INTEGER := 1; -- Declares a variable named v_campaign_id of type INTEGER, initializes it with the value 1
BEGIN
    -- Insert records that don't already exist
    INSERT INTO management.campaign_data (campaign_id, research_id, survey_id)
    SELECT v_campaign_id, r.research_id, s.survey_id
    FROM management.research r
    CROSS JOIN management.survey s --for each research record, we'll get a row for every survey record
    WHERE NOT EXISTS (
        SELECT 1 FROM management.campaign_data cd
        WHERE cd.campaign_id = v_campaign_id
        AND cd.research_id = r.research_id
        AND cd.survey_id = s.survey_id
    );
    
END $$;



-- Campaign public table (depends on campaign, social_media, and event)
INSERT INTO campaign_public (campaign_id, social_media_id, event_id)
SELECT c.campaign_id, s.social_media_id, e.event_id
FROM campaign c
JOIN social_media s ON s.social_media_activity_type = 'Policy Video'
JOIN event e ON e.event_type = 'Door-to-Door Campaign'
WHERE c.campaign_name = 'Vote Ready 2025'
  AND NOT EXISTS (
    SELECT 1 FROM campaign_public cp
    WHERE cp.campaign_id = c.campaign_id
      AND cp.social_media_id = s.social_media_id
      AND cp.event_id = e.event_id
  );


INSERT INTO campaign_public (campaign_id, social_media_id, event_id)
SELECT c.campaign_id, s.social_media_id, e.event_id
FROM campaign c
JOIN social_media s ON s.social_media_activity_type = 'Campaign Launch'
JOIN event e ON e.event_type = 'Youth Summit'
WHERE c.campaign_name = 'Equality for All'
  AND NOT EXISTS (
    SELECT 1 FROM campaign_public cp
    WHERE cp.campaign_id = c.campaign_id
      AND cp.social_media_id = s.social_media_id
      AND cp.event_id = e.event_id
  );



--survey table (depends on survey_result table)
INSERT INTO management.survey (
    survey_result_id,
    survey_title,
    survey_date
)
SELECT sr.survey_result_id, vals.title, vals.date
FROM management.survey_result sr
JOIN (
    VALUES
        ('Voter Priorities Survey', DATE '2025-02-10'),
        ('Voter Satisfaction Survey', DATE '2025-02-20')
) AS vals(title, date)
  ON sr.survey_result_date = vals.date
ON CONFLICT (survey_title) DO NOTHING;


------------------------------------------------------------------------------------------------------------------
-- adding record_ts

-- adding 'record_ts' column if not already exists to management.employee
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'employee'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.employee
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.volunteer
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'volunteer'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.volunteer
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.survey
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.survey
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.survey_result
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'survey_result'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.survey_result
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.supervisor_volunteer
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'supervisor_volunteer'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.supervisor_volunteer
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.campaign
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.campaign
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.research
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'research'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.research
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.campaign_data
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign_data'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.campaign_data
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- adding 'record_ts' to management.social_media
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'social_media'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.social_media
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to public.staff
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign_staff'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.campaign_staff
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to management.donation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donation'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.donation
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to management.donor
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'donor'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.donor
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to management.finance
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.finance
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;


-- Add 'record_ts' to management.event
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.finance
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to management.finance
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'finance'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.finance
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- Add 'record_ts' to management.campaign_public
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'management'
          AND table_name = 'campaign_public'
          AND column_name = 'record_ts'
    ) THEN
        ALTER TABLE management.campaign_public
        ADD COLUMN record_ts TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

