/*
T1

To implement such trigger, we need to compare aircraft registration numbers from flight_data table
and aircarft from maintance event. Using BETWEEN with start time of mainternace event and its duration,
we can check whether it overlaps with departure time of a flight
*/

-- deleting trigger and function if it exists
DROP TRIGGER IF EXISTS check_aircraft_maintenance ON airport_lab.flight_data ;
DROP FUNCTION IF EXISTS check_maintenance_schedule;

CREATE OR REPLACE FUNCTION check_maintenance_schedule()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM airport_lab.maintenance_events
        WHERE NEW.aircraft_registration_number = maintenance_events.aircraft_registration_number
          -- checking if it oveplaps
          AND (NEW.scheduled_departure_date + NEW.scheduled_departure_time) BETWEEN maintenance_events.maintenance_starttime
                                                                               AND (maintenance_events.maintenance_starttime + maintenance_events.duration)
    ) THEN
--raising an exception 
        RAISE EXCEPTION 'Aircraft % is scheduled for maintenance during the flight period.',
                        NEW.aircraft_registration_number;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger to check before inserting
CREATE TRIGGER check_aircraft_maintenance
BEFORE INSERT OR UPDATE
ON airport_lab.flight_data 
FOR EACH ROW
EXECUTE FUNCTION check_maintenance_schedule();


/*
T2

To implement this trigger, we can firstly check if any feedbacks which are present in table are old enough to also be deleted and 
placed in archive Then, we check if feedback which is trying to be inserted is old enough to be placed in archive straight away, if it is 
moved to archive, warning is raised
*/

-- deleting trigger and function if it exists
DROP TRIGGER IF EXISTS archive_old_feedback_trigger ON airport_lab.customer_feedback_and_survey;
DROP FUNCTION IF EXISTS archive_old_feedback;

-- creating function 
CREATE OR REPLACE FUNCTION archive_old_feedback()
RETURNS TRIGGER AS $$
BEGIN
    -- inserting to arhive
    INSERT INTO airport_lab.feedback_archive (customer_id, customer_feedback_and_survey_data, archived_at)
    SELECT 
        customer_id, 
        customer_feedback_and_survey_data, 
        NOW()
    FROM 
        airport_lab.customer_feedback_and_survey
    WHERE 
        (customer_feedback_and_survey_data->>'survey_date')::DATE < NOW() - INTERVAL '2 years';

    -- deleting existing old feedbacks
    DELETE FROM airport_lab.customer_feedback_and_survey
    WHERE 
        (customer_feedback_and_survey_data->>'survey_date')::DATE < NOW() - INTERVAL '2 years';

    -- checking if new feedback is old enough to move it to archive
    IF (NEW.customer_feedback_and_survey_data->>'survey_date')::DATE < NOW() - INTERVAL '2 years' THEN
        INSERT INTO airport_lab.feedback_archive (customer_id, customer_feedback_and_survey_data, archived_at)
        VALUES (
            NEW.customer_id,
            NEW.customer_feedback_and_survey_data,
            NOW()
        );
        
        -- logging the info about miving feedback to archive
        RAISE NOTICE 'Feedback from customer % has been archived because it is older than 2 years', NEW.customer_id;

        -- not inserting since it's old
        RETURN NULL;
    END IF;

    -- if "fresh", insert to table
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- creating trigger that will run before inserting
CREATE TRIGGER archive_old_feedback_trigger
BEFORE INSERT
ON airport_lab.customer_feedback_and_survey
FOR EACH ROW
EXECUTE FUNCTION archive_old_feedback();

