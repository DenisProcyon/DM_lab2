-- JQ1
/*
To find customers who prefer extra legroom and have submitted feedback with
a service rating lower than 3, we need to implement a query that, firstly,
extracts json data from customer_preferneces_data table as well as from
customer_feedback_and_survey table and secondly, joins customers table,
preferences table and feedback table on ID of a customer. Then, we need to
provide a condition to filter the result by value from extra_legroom field and
service field respectively for two tables stated above.

*/
 
SELECT 
    c.customer_id,
    c.name,
    c.email,
    cp.customer_preferences_data->'seating'->>'extra_legroom' AS prefers_extra_legroom,
    (cf.customer_feedback_and_survey_data->'topics'->>'service')::int AS service_rating
FROM airport_lab.customers c
JOIN airport_lab.customer_preferences cp ON c.customer_id = cp.customer_id -- join customers with their seating preferences
JOIN airport_lab.customer_feedback_and_survey cf ON c.customer_id = cf.customer_id -- join with feedback
WHERE 
    cp.customer_preferences_data->'seating'->>'extra_legroom' = 'true'
    AND (cf.customer_feedback_and_survey_data->'topics'->>'service')::int < 3; -- filter for less than 3
   
-- JQ2
/*
To implement this query, we need firstly, to get all the ME that happened in last 6 month (using INTERVAL).
Secondly, we will join this retrieved table with flight_data on column of aircraft_registration_number.
After, by flught_id got from flight_data table we will join it with customer feedback table
on a column of flight_id and get those (since task itself does not state it) with those feedbacks 
that have rating lower than 3 and show flight, its problem and the data from customer feedback
*/
WITH recent_maintenance_issues AS (
    -- retrieve maintenance events within the last 6 months
    SELECT 
        me.aircraft_registration_number, -- aircraft registration number
        me.maintenance_starttime, -- start time of maintenance
        p.problem_type -- type of the maintenance issue
    FROM  airport_lab.maintenance_events me
    JOIN airport_lab.problems p ON me.maintenance_type_id = p.problem_id -- links maintenance events to their problem types
    WHERE 
        me.maintenance_starttime >= NOW() - INTERVAL '6 months' -- filters maintenance events within the last 6 months
),
flights_with_issues AS (
    -- find flights using aircraft that had maintenance issues
    SELECT 
        fd.flight_id,
        fd.flight_number, 
        fd.aircraft_registration_number, 
        fd.scheduled_departure_date,
        rmi.problem_type 
    FROM airport_lab.flight_data fd
    JOIN recent_maintenance_issues rmi ON fd.aircraft_registration_number = rmi.aircraft_registration_number -- match flights to aircraft with issues
),
feedback_with_flights AS (
    -- combine flights with customer feedback for comfort ratings
    SELECT 
        fwi.flight_number, 
        fwi.scheduled_departure_date, 
        fwi.problem_type, 
        (cfs.customer_feedback_and_survey_data->>'rating')::INTEGER AS rating, -- general feedback 
        (cfs.customer_feedback_and_survey_data->'topics'->>'comfort')::INTEGER AS comfort_rating -- extract comfort rating from feedback
    FROM flights_with_issues fwi
    JOIN airport_lab.bookings b ON fwi.flight_id = b.flight_id -- join flights with bookings
    JOIN airport_lab.customer_feedback_and_survey cfs ON b.customer_id = cfs.customer_id -- join bookings to customer feedback
    WHERE 
        (cfs.customer_feedback_and_survey_data->'topics'->>'comfort')::INTEGER <= 3 -- filters poor comfort rating
)
-- flight details with customer feedback
SELECT 
    flight_number,
    scheduled_departure_date, 
    problem_type,
    comfort_rating,
    rating 
FROM 
    feedback_with_flights
ORDER BY 
    scheduled_departure_date DESC; --  most recent flights

-- JQ3
/*
The implementation of this query can be compared with JQ1. First, we need to
join three tabled by customer_id field for 3 tables, being customers, customer_preferences
and customer_feedback_and_survey. After, we need to get those customers
who are not in customer_feedback_and_survey table and in the same time in
customer_preferences_data table with specific value in meal field. 
*/
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.phone_number, 
    cp.customer_preferences_data, 
    cfs.customer_id as customer_id_from_feedback_table 
FROM airport_lab.customers c
JOIN airport_lab.customer_preferences cp ON c.customer_id = cp.customer_id -- join customers with  preferences
LEFT JOIN  airport_lab.customer_feedback_and_survey cfs ON c.customer_id = cfs.customer_id -- join customers with feedback (
WHERE cfs.customer_id IS NULL -- filters no feedback
    AND (cp.customer_preferences_data->>'meal') = 'vegetarian' -- filter fit customers with vegetarian meal
    AND (cp.customer_preferences_data->'seating'->>'seat_near_exit')::BOOLEAN = true; -- filter customers who prefer seating near exit


-- JQ4
/*
To implement this query, we need to firstlt get all the feeback with a rating of 5,
secondly, to get the preferences of those 5 star rating customer and join them by customer id.
Then, we will use COUNT() finction on their meal prederence (since it is not INTEGER) and sum up all the 
prefernces wich are integer.
*/
WITH five_star_feedback AS (
    SELECT 
        cfs.customer_id,
        (cfs.customer_feedback_and_survey_data->>'rating')::INTEGER AS rating -- customer rating
    FROM airport_lab.customer_feedback_and_survey cfs
    WHERE (cfs.customer_feedback_and_survey_data->>'rating')::INTEGER = 5 -- filters feedback with 5 rating
),
prefs_data AS (
    SELECT 
        cp.customer_preferences_data->>'meal' AS meal_preference, 
        cp.customer_preferences_data->'seating'->>'aisle' AS prefers_aisle,
        cp.customer_preferences_data->'seating'->>'extra_legroom' AS prefers_extra_legroom, 
        cp.customer_preferences_data->'seating'->>'seat_near_exit' AS prefers_seat_near_exit 
    FROM airport_lab.customer_preferences cp
    JOIN five_star_feedback fsf ON cp.customer_id = fsf.customer_id -- join preference to customers with 5 feedback
),
prefs AS (
    SELECT
        meal_preference, -- meal preference
        COUNT(*) AS meal_count, -- total count of each meal preference
        SUM(CASE WHEN prefers_aisle::BOOLEAN THEN 1 ELSE 0 END) AS aisle_count, -- total count of aisle seat preference
        SUM(CASE WHEN prefers_extra_legroom::BOOLEAN THEN 1 ELSE 0 END) AS extra_legroom_count, -- total count of legroom preference
        SUM(CASE WHEN prefers_seat_near_exit::BOOLEAN THEN 1 ELSE 0 END) AS seat_near_exit_count -- total count of seat near exit preference
    FROM 
        prefs_data
    GROUP BY 
        meal_preference -- group by meal preference
)
SELECT 
    meal_preference
    meal_count,
    aisle_count,
    extra_legroom_count,
    seat_near_exit_count
FROM 
    prefs
ORDER BY 
    meal_count DESC, 
    aisle_count DESC, 
    extra_legroom_count DESC, 
    seat_near_exit_count DESC; 



