
DROP TABLE IF EXISTS airport_lab.customers CASCADE;
CREATE TABLE airport_lab.customers 
(
    customer_id SERIAL PRIMARY KEY,
    name varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    phone_number varchar(255) NOT NULL,
    address varchar(255) NOT NULL
);

DROP TABLE IF EXISTS airport_lab.aircrafts CASCADE;
CREATE TABLE airport_lab.aircrafts (
    aircraft_registration_number SERIAL PRIMARY KEY,
    aircraft_type varchar(255) NOT NULL,
    aircraft_company varchar(255) NOT NULL,
    aircraft_capacity int NOT NULL
);   

DROP TABLE IF EXISTS airport_lab.airports CASCADE;
CREATE TABLE airport_lab.airports (
    airport_id varchar(3) NOT NULL PRIMARY KEY,
    airport_name varchar(255) NOT NULL,
    airport_city varchar(255) NOT NULL,
    airport_country varchar(255) NOT NULL
);   

DROP TABLE IF EXISTS airport_lab.airlines CASCADE;
CREATE TABLE airport_lab.airlines (
    airline_id SERIAL PRIMARY KEY,
    airline_name varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.flights CASCADE;
CREATE TABLE airport_lab.flights (
    flight_number varchar(6) NOT NULL PRIMARY KEY,
    origin varchar(3) NOT NULL,
    destination varchar(3) NOT NULL,
    airline_id INT NOT NULL,
    flight_length INTERVAL NOT NULL,
    CONSTRAINT fk_origin_airport
        FOREIGN KEY (origin) REFERENCES airport_lab.airports (airport_id),
    CONSTRAINT fk_destination_airport
        FOREIGN KEY (destination) REFERENCES airport_lab.airports (airport_id),
    CONSTRAINT fk_airline_id
        FOREIGN KEY (airline_id) REFERENCES airport_lab.airlines (airline_id)
); 

DROP TABLE IF EXISTS airport_lab.problems CASCADE;
CREATE TABLE airport_lab.problems (
    problem_id SERIAL PRIMARY KEY,
    problem_type varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.flight_statuses CASCADE;
CREATE TABLE airport_lab.flight_statuses (
    flight_status_id SERIAL PRIMARY KEY,
    flight_status_type varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.flight_data CASCADE;
CREATE TABLE airport_lab.flight_data (
    flight_id SERIAL PRIMARY KEY,
    flight_number varchar(6) NOT NULL,
    aircraft_registration_number INT NOT NULL,
    flight_status_id INT NOT NULL,
    problem_id INT NOT NULL,
    number_of_passengers int NOT NULL,
    number_of_cabin_crew int NOT NULL,
    number_of_flight_crew int NOT NULL,
    available_seating int NOT NULL,
    scheduled_departure_date DATE NOT NULL,
    scheduled_departure_time TIME NOT NULL,
    CONSTRAINT fk_flight_number
        FOREIGN KEY (flight_number) REFERENCES airport_lab.flights (flight_number),
    CONSTRAINT fk_aircraft_registration_number
        FOREIGN KEY (aircraft_registration_number) REFERENCES airport_lab.aircrafts (aircraft_registration_number),
    CONSTRAINT fk_flight_status_id
        FOREIGN KEY (flight_status_id) REFERENCES airport_lab.flight_statuses (flight_status_id),
    CONSTRAINT fk_problem_id
        FOREIGN KEY (problem_id) REFERENCES airport_lab.problems (problem_id)
); 


DROP TABLE IF EXISTS airport_lab.seat_classes CASCADE;
CREATE TABLE airport_lab.seat_classes 
(
    seat_number varchar(3) NOT NULL PRIMARY KEY, --1a to 40f
    seat_class varchar(33) NOT NULL, --rows 1 - 3 are business and rows 4 - 40 are economy
    CONSTRAINT fk_seat_number
        FOREIGN KEY (seat_number) REFERENCES airport_lab.seat_classes (seat_number)
);


DROP TABLE IF EXISTS airport_lab.seats CASCADE;
CREATE TABLE airport_lab.seats 
(
    seat_id SERIAL PRIMARY KEY,
    seat_number varchar(3) NOT NULL, -- foreign key
    seat_status varchar(33) NOT NULL, --available or occupied
    flight_id INT NOT null, -- foreign_key
    CONSTRAINT fk_flight_id
        FOREIGN KEY (flight_id) REFERENCES airport_lab.flight_data (flight_id),
    CONSTRAINT fk_seat_number
        FOREIGN KEY (seat_number) REFERENCES airport_lab.seat_classes (seat_number)
);

DROP TABLE IF EXISTS airport_lab.bookings CASCADE;
CREATE TABLE airport_lab.bookings (
    booking_id SERIAL PRIMARY KEY,
    flight_id INT NOT NULL,
    customer_id INT NOT NULL,
    seat_id INT NOT NULL,
    price NUMERIC(7,2) NOT NULL,
    payment_status BOOLEAN NOT NULL,
    booking_date_and_time TIMESTAMP NOT NULL,
    bonus_miles NUMERIC(7,2) GENERATED ALWAYS AS (price * 0.05) STORED, 
    CONSTRAINT fk_flight_id
        FOREIGN KEY (flight_id) REFERENCES airport_lab.flight_data (flight_id),
    CONSTRAINT fk_customer_id
        FOREIGN KEY (customer_id) REFERENCES airport_lab.customers (customer_id),
    CONSTRAINT fk_seat_id
        FOREIGN KEY (seat_id) REFERENCES airport_lab.seats (seat_id)
);

DROP TABLE IF EXISTS airport_lab.subsystems CASCADE;
CREATE TABLE airport_lab.subsystems (
    subsystem_id SERIAL PRIMARY KEY,
    subsystem_type varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.maintenance_types CASCADE;
CREATE TABLE airport_lab.maintenance_types (
    maintenance_type_id SERIAL PRIMARY KEY,
    maintenance_type_name varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.maintenance_events CASCADE;
CREATE TABLE airport_lab.maintenance_events (
    maintenance_id SERIAL PRIMARY KEY,
    aircraft_registration_number INT NOT NULL,
    maintenance_starttime TIMESTAMP NOT NULL,
    duration INTERVAL NOT NULL,
    airport_id VARCHAR(3) NOT NULL,
    subsystem_id INT NOT NULL,
    maintenance_type_id INT NOT NULL,
    CONSTRAINT fk_aircraft_registration_number
        FOREIGN KEY (aircraft_registration_number) REFERENCES airport_lab.aircrafts (aircraft_registration_number),
    CONSTRAINT fk_airport_id
        FOREIGN KEY (airport_id) REFERENCES airport_lab.airports (airport_id),
    CONSTRAINT fk_subsystem_id
        FOREIGN KEY (subsystem_id) REFERENCES airport_lab.subsystems (subsystem_id),
    CONSTRAINT fk_maintenance_type_id
        FOREIGN KEY (maintenance_type_id) REFERENCES airport_lab.maintenance_types (maintenance_type_id)
); 

DROP TABLE IF EXISTS airport_lab.aircraft_slots CASCADE;
CREATE TABLE airport_lab.aircraft_slots (
    aircraft_slot_id SERIAL PRIMARY KEY,
    aircraft_registration_number INT NOT NULL,
    slot_start TIMESTAMP NOT NULL,
    slot_end TIMESTAMP NOT NULL,
    slot_type VARCHAR(255) NOT NULL,
    slot_scheduled BOOLEAN NOT NULL,
    maintenance_id INT NOT NULL,
    CONSTRAINT fk_aircraft_registration_number
        FOREIGN KEY (aircraft_registration_number) REFERENCES airport_lab.aircrafts (aircraft_registration_number),
    CONSTRAINT fk_maintenance_id
        FOREIGN KEY (maintenance_id) REFERENCES airport_lab.maintenance_events (maintenance_id)
); 

DROP TABLE IF EXISTS airport_lab.reporteurs CASCADE;
CREATE TABLE airport_lab.reporteurs (
    reporteur_id SERIAL PRIMARY KEY,
    reporteur_class varchar(255) NOT NULL,
    reporteur_name varchar(255) NOT NULL
); 

DROP TABLE IF EXISTS airport_lab.work_orders CASCADE;
CREATE TABLE airport_lab.work_orders (
    work_order_id SERIAL PRIMARY KEY,
    aircraft_registration_number INT NOT NULL,
    maintenance_id INT NOT NULL,
    airport_id VARCHAR(3) NOT NULL,
    execution_date TIMESTAMP NOT NULL,
    scheduled BOOLEAN NOT NULL,
    forecasted_date TIMESTAMP NOT NULL,
    forecasted_manhours NUMERIC(7,2) NOT NULL,
    frequency INT NOT NULL,
    reporteur_id INT NOT NULL,
    due_date TIMESTAMP NOT NULL,
    reporting_date TIMESTAMP NOT NULL,
    CONSTRAINT fk_aircraft_registration_number
        FOREIGN KEY (aircraft_registration_number) REFERENCES airport_lab.aircrafts (aircraft_registration_number),
    CONSTRAINT fk_maintenance_id
        FOREIGN KEY (maintenance_id) REFERENCES airport_lab.maintenance_events (maintenance_id),
    CONSTRAINT fk_airport_id
        FOREIGN KEY (airport_id) REFERENCES airport_lab.airports (airport_id),
    CONSTRAINT fk_reporteur_id
        FOREIGN KEY (reporteur_id) REFERENCES airport_lab.reporteurs (reporteur_id)
); 

DROP TABLE IF EXISTS airport_lab.customer_preferences;
CREATE TABLE airport_lab.customer_preferences
(
    customer_id INT,
    customer_preferences_data JSON,
    CONSTRAINT fk_customer_references_customer_id 
        FOREIGN KEY (customer_id) REFERENCES airport_lab.customers(customer_id)
);

DROP TABLE IF EXISTS airport_lab.aircraft_maintenance_logs;
CREATE TABLE airport_lab.aircraft_maintenance_logs
(
    maintenance_id INT,
    aircraft_maintenance_logs_data JSON,
    CONSTRAINT fk_maintenance_references_maintenance_id
        FOREIGN KEY (maintenance_id) REFERENCES airport_lab.maintenance_events(maintenance_id)
);

DROP TABLE IF EXISTS airport_lab.customer_feedback_and_survey;
CREATE TABLE airport_lab.customer_feedback_and_survey
(
    customer_id INT,
    customer_feedback_and_survey_data JSON,
    CONSTRAINT fk_customer_references_customer_id 
        FOREIGN KEY (customer_id) REFERENCES airport_lab.customers(customer_id)
);

DROP TABLE IF EXISTS airport_lab.feedback_archive;
CREATE TABLE airport_lab.feedback_archive (
	customer_id INT NOT NULL,
    CONSTRAINT fk_customer_id
        FOREIGN KEY (customer_id) REFERENCES airport_lab.customers (customer_id),
    customer_feedback_and_survey_data JSONB NOT NULL,
    archived_at TIMESTAMP DEFAULT NOW()
);