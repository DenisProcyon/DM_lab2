/*
T1 

For testing purposes, we need to create new maintenance ID 
(and airport because of reference of ME) that will overlap
with deparute time of particular flight
*/
-- insert airport for testing
INSERT INTO airport_lab.airports (
	airport_id,
	airport_name,
	airport_city,
	airport_country
) VALUES (
    'AAA',
    'TEST',
    'TEST',
    'TEST'
)

-- insert maintenance event for testing
INSERT INTO airport_lab.maintenance_events (
    maintenance_id,
    aircraft_registration_number,
    maintenance_starttime,
    duration,
    airport_id,
    maintenance_type_id,
    subsystem_id
) VALUES (
    1000,
    76,
    '2024-01-27 08:00:00',
    INTERVAL '2 hours', 
    'AAA',
    1, 
    1 
);

-- insert flight that overlaps with the maintenance period
INSERT INTO airport_lab.flight_data (
    flight_id,
    flight_number,
    aircraft_registration_number,
    flight_status_id,
    problem_id,
    number_of_passengers,
    number_of_cabin_crew,
    number_of_flight_crew,
    available_seating,
    scheduled_departure_date,
    scheduled_departure_time
) VALUES (
    1000,
    'TST123',
    76,
    1,
    1,
    180,
    8,
    4,
    60,
    '2024-01-27',
    '08:30:00'
);

/*
T2

For testing purposes, we are creating two types of feedbacks, one of which will be
inserted into main feedback table, and second one will be inserted to archive
*/
-- adding old feedback that will be moved to archive
INSERT INTO airport_lab.customer_feedback_and_survey (customer_id, customer_feedback_and_survey_data)
VALUES 
(1, '{"survey_date": "2020-01-01", "rating": 3, "comments": "Satisfactory"}');

-- adding new and fresh feedback that will be saved to main feedback table
INSERT INTO airport_lab.customer_feedback_and_survey (customer_id, customer_feedback_and_survey_data)
VALUES 
(1, '{"survey_date": "2024-01-01", "rating": 5, "comments": "Excellent"}');

