-- Q1: Find customers who have made at least one booking in the last month and their booking details
SELECT 
    c.customer_id, 
    c.name AS customer_name, 
    c.email,  
    b.booking_id, 
    b.flight_id, 
    b.seat_id, 
    b.booking_date_and_time,  
    b.price  
FROM 
    airport_lab.bookings b
JOIN 
    airport_lab.customers c
    ON b.customer_id = c.customer_id    -- Joining bookings and customers by customer_id
WHERE 
    b.booking_date_and_time >= CURRENT_DATE - INTERVAL '1 MONTH' -- Bookings made in the last month
ORDER BY 
    b.booking_date_and_time DESC; -- Order by most recent booking

    
    
-- Q2: List all flights with delayed or canceled status, including flight crew and aircraft details
SELECT 
    f.flight_number, 
    fs.flight_status_type AS status, 
    f.scheduled_departure_date, 
    f.scheduled_departure_time, 
    a.aircraft_type, 
    a.aircraft_company,   
    a.aircraft_capacity   
FROM 
    airport_lab.flight_data f
JOIN 
    airport_lab.flight_statuses fs 
    ON f.flight_status_id = fs.flight_status_id 
JOIN 
    airport_lab.aircrafts a 
    ON f.aircraft_registration_number = a.aircraft_registration_number -- Joining flights and aircrafts by registration number
WHERE 
    fs.flight_status_type IN ('Delayed', 'Cancelled');        -- Filter for delayed or canceled flights

    
    
-- Q3: Get the total number of miles accumulated by a frequent flyer along with their upcoming bookings
WITH customer_miles AS (
    SELECT 
        c.customer_id,   
        c.name AS customer_name,   
        COALESCE(SUM(b.bonus_miles), 0) AS total_bonus_miles  -- Total miles accumulated by the customer
    FROM 
        airport_lab.customers c
    LEFT JOIN 
        airport_lab.bookings b 
        ON c.customer_id = b.customer_id -- Joining customers and bookings
    GROUP BY 
        c.customer_id, c.name
    HAVING 
        COUNT(b.booking_id) > 2  -- frequent flyers (more than 2 bookings)
),
next_booking AS (
    SELECT 
        b.customer_id,  
        MIN(b.booking_date_and_time) AS next_booking_date  
    FROM 
        airport_lab.bookings b
    WHERE 
        b.booking_date_and_time > NOW() -- Upcoming bookings only
    GROUP BY 
        b.customer_id
)
SELECT 
    cm.customer_id,  
    cm.total_bonus_miles, 
    nb.next_booking_date  
FROM 
    customer_miles cm
LEFT JOIN 
    next_booking nb 
    ON cm.customer_id = nb.customer_id -- Joining frequent flyer miles with their next booking
ORDER BY 
    cm.total_bonus_miles DESC, nb.next_booking_date ASC;    -- Order by total miles and next booking date

    
-- Q4: Find flights departing in the next 7 days operated by a specific aircraft model but not yet fully booked
SELECT 
    fd.flight_number,
    fd.scheduled_departure_date, 
    fd.scheduled_departure_time, 
    a.aircraft_type,
    fd.available_seating
FROM 
    airport_lab.flight_data fd
JOIN 
    airport_lab.aircrafts a 
    ON fd.aircraft_registration_number = a.aircraft_registration_number -- join flight data and aircrafts
WHERE 
    fd.scheduled_departure_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days' -- Flights in the next 7 days
    AND a.aircraft_type = 'Airbus A320'          -- Filter for Airbus A320
    AND fd.available_seating > 0      -- Ensure there are available seats
ORDER BY 
    fd.scheduled_departure_date, fd.scheduled_departure_time; -- Order by departure date and time
 
-- Q5: Generate a report of flights where maintenance schedules conflict with assigned aircraft
SELECT 
    fd.flight_id, 
    fd.flight_number,  
    fd.aircraft_registration_number,  
    fd.scheduled_departure_date + fd.scheduled_departure_time AS scheduled_departure_timestamp, -- Scheduled departure timestamp
    fd.number_of_passengers,
    me.maintenance_id,   
    me.maintenance_starttime,          -- Maintenance start time
    me.maintenance_starttime + me.duration AS maintenance_endtime -- Maintenance end time
FROM 
    airport_lab.flight_data fd
JOIN 
    airport_lab.maintenance_events me
ON 
    fd.aircraft_registration_number = me.aircraft_registration_number -- Join by aircraft registration number
WHERE 
    (fd.scheduled_departure_date + fd.scheduled_departure_time) BETWEEN me.maintenance_starttime 
   AND (me.maintenance_starttime + me.duration) -- Check for overlapping schedules
ORDER BY 
    fd.scheduled_departure_date, fd.scheduled_departure_time;
    
    
-- Q6: Calculate the revenue and payment status for each flight
SELECT 
    fd.flight_id, 
    fd.flight_number, 
    SUM(CASE 
 WHEN b.payment_status THEN b.price -- Sum of paid bookings
 ELSE 0
        END) AS total_revenue, -- Total revenue from bookings
    COUNT(b.booking_id) AS total_bookings,  -- Total number of bookings
    SUM(CASE 
 WHEN b.payment_status THEN 1 -- Count paid bookings
 ELSE 0
        END) AS paid_bookings,  -- Total number of paid bookings
    SUM(CASE 
 WHEN NOT b.payment_status THEN 1  -- Count unpaid bookings
 ELSE 0
        END) AS unpaid_bookings -- Total number of unpaid bookings
FROM 
    airport_lab.flight_data fd
LEFT JOIN 
    airport_lab.bookings b 
    ON fd.flight_id = b.flight_id -- Join flight data and bookings by flight ID
GROUP BY 
    fd.flight_id, fd.flight_number -- Group by flight ID and flight number
ORDER BY 
    total_revenue DESC;    -- Order by total revenue in descending order

    
    
-- Q7: Find customers who have never booked a flight
SELECT 
    c.customer_id,
    c.name AS custoer_name,
    c.email  
FROM 
    airport_lab.customers c
LEFT JOIN 
    airport_lab.bookings b 
    ON c.customer_id = b.customer_id  -- Left join to include customers without bookings
WHERE 
    b.booking_id IS NULL;   -- Filter for customers which are not present in bookings

    
    
-- Q8: Get flights that are fully booked (i.e., no available seating)
SELECT 
    flight_id, 
    flight_number,
    aircraft_registration_number, 
    scheduled_departure_date,  
    scheduled_departure_time, 
    number_of_passengers, 
    available_seating 
FROM 
    airport_lab.flight_data
WHERE 
    available_seating = 0  -- Fully booked flights with no available seating since we hav esuch field
ORDER BY 
    scheduled_departure_date, scheduled_departure_time; -- order by departure date and time

 
-- Q9: Find frequent flyers who have flown the most hours but haven’t made any bookings in the past year
SELECT 
    c.customer_id,
    c.name AS customer_name, 
    SUM(EXTRACT(EPOCH FROM f.flight_length) / 3600) AS total_hours -- from interval to hours to order "frequent" flyers
FROM 
    airport_lab.customers c
JOIN 
    airport_lab.bookings b 
    ON c.customer_id = b.customer_id -- customers + booking
JOIN 
    airport_lab.flight_data fd 
    ON b.flight_id = fd.flight_id -- bookings + flight_data
JOIN 
    airport_lab.flights f 
    ON fd.flight_number = f.flight_number -- flight data + flights
WHERE 
    fd.scheduled_departure_date < CURRENT_DATE - INTERVAL '1 year' -- over a year ago
GROUP BY 
    c.customer_id, c.name
ORDER BY 
    total_hours DESC;
    
    
-- Q10: Get the total bookings and revenue generated per month
SELECT
    TO_CHAR(DATE_TRUNC('month', b.booking_date_and_time), 'Month') AS booking_month_name, -- transalate to name of the month
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.price) AS total_revenue   
FROM 
    airport_lab.bookings b
GROUP BY 
    booking_month_name
ORDER BY 
    MIN(b.booking_date_and_time); -- get the month

    
    
-- Q11: Get the top 5 most popular flight routes
SELECT 
    f.flight_number, 
    f.origin AS origin_airport,
    f.destination AS destination_airport, 
    COUNT(b.booking_id) AS total_bookings  
FROM 
    airport_lab.flights f
LEFT JOIN 
    airport_lab.bookings b 
    ON CAST(b.flight_id AS VARCHAR) = f.flight_number -- joining flights and bookings
GROUP BY 
    f.flight_number, f.origin, f.destination
ORDER BY 
    total_bookings DESC -- order by most popular routes
LIMIT 5;  -- limiting to top 5 routes



-- Q12: summarize total flying time to get frequent flyers and summarize their spent money from bookings table
select 
    c.customer_id,
    c.name AS customer_name,
    COUNT(b.booking_id) AS total_bookings,
    SUM(f.flight_length) AS total_flying_time,
    SUM(b.price) AS total_money_spent
FROM 
    airport_lab.customers c
JOIN 
    airport_lab.bookings b ON c.customer_id = b.customer_id -- joining bookings and customers by id
JOIN 
    airport_lab.flight_data fd ON b.flight_id = fd.flight_id -- joining on flight_data by flight id
JOIN 
    airport_lab.flights f ON fd.flight_number = f.flight_number -- finally, joining on flights
GROUP BY 
    c.customer_id, c.name
ORDER BY 
    total_flying_time DESC, total_money_spent DESC
limit 5; -- limiting by 5 with desc order to find "frequent" flyers
    
