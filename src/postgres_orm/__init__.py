import psycopg2
from datetime import datetime, timedelta
from faker import Faker
import psycopg2._psycopg
from psycopg2.extras import Json

from random import random

class PostgresORM:
    def __init__(self, host: str, port: str, username: str, password: str, db_name: str, schema_name: str):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.db_name = db_name

        self.schema_name = schema_name

        self.connection = self.get_connection()
        if self.connection is None:
            raise ConnectionError(f'Can not connect to {self.db_name}')
    
        self.cursor = self.get_cursor()
        
        self.faker = Faker()

        self.filling_mapper = {
            table: getattr(self, f'_PostgresORM__fill_{table}')
            for table in self.get_tables()
        }

    def get_connection(self) -> psycopg2._psycopg.connection:
        try:
            connection = psycopg2.connect(
                dbname=self.db_name,
                user=self.username,
                password=self.password,
                host=self.host,
                port=self.port
            )
            print(f'Successfully connected to {self.db_name}')
            return connection
        except Exception as e:
            print(e)
            return None

    def get_cursor(self) -> psycopg2._psycopg.cursor:
        if self.connection:
            return self.connection.cursor()
        else:
            return None

    def get_tables(self) -> list[str]:
        try:
            self.cursor.execute(f"""SELECT table_name FROM information_schema.tables 
                               WHERE table_schema = '{self.schema_name}'""")
            
            return [table[0] for table in self.cursor.fetchall()]
        except Exception as e:
            print(f'Can not get tables from {self.db_name}')

    def get_table_entries(self, table: str, column: str) -> list[int]:
        query = f"SELECT {column} FROM {self.schema_name}.{table}"
        
        self.cursor.execute(query)
        
        results = self.cursor.fetchall()
        
        return [result[0] for result in results]

    def get_table_content(self, table: str) -> list[dict]:
        try:
            self.cursor.execute(f"SELECT * FROM {self.schema_name}.{table}")

            columns = [desc[0] for desc in self.cursor.description]

            return [dict(zip(columns, row)) for row in self.cursor.fetchall()]
        except Exception as e:
            print(f"Error retrieving data from {table}. Error - {e}")
            return []
        
    def __fill_feedback_archive(self, fillings: int) -> bool:
        pass
            
    def __fill_airlines(self, fillings: int) -> bool:
        try:
            for _ in range(fillings):
                airline_name = f'{self.faker.company()} Air'
                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.airlines (airline_name) VALUES (%s)',
                    (airline_name,)
                )
                self.connection.commit()
        except Exception as e: 
            print(e)

            return False
    
        return True
    
    def occupy_seats(self, seat_ids: list[int]) -> None:
        try:
            query = f"UPDATE {self.schema_name}.seats SET seat_status = 'Occupied' WHERE seat_id = ANY(%s)"
            
            self.cursor.execute(query, (seat_ids,))
            
            self.connection.commit()

            print(f"Successfully updated {len(seat_ids)} seats to 'Occupied' status.")
        except Exception as e:
            print(f"Failed to update seat status: {e}")

            return False
        
        return True
    
    def __fill_seat_classes(self, fillings: int) -> bool:
        try:
            rows = range(1, 42)
            seat_letters = ["A", "B", "C", "D", "E", "F"]

            for row in rows:
                for letter in seat_letters:
                    seat_number = f"{row}{letter}"
                    seat_class =  "Business" if row <= 3 else "First Class" if row <= 6 else "Economy"

                    self.cursor.execute(
                            f"INSERT INTO {self.schema_name}.seat_classes (seat_number, seat_class) VALUES (%s, %s)",
                            (seat_number, seat_class)
                        )
                    
                    self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True

    
    def __fill_seats(self, fillings: int) -> bool:
        try:
            flight_ids = self.get_table_entries("flight_data", "flight_id")
            seat_numbers = self.get_table_entries("seat_classes", "seat_number")

            for flight_id in flight_ids:
                for seat_number in seat_numbers:
                    seat_status = "Available"

                    self.cursor.execute(
                        f"INSERT INTO {self.schema_name}.seats (seat_number, seat_status, flight_id) VALUES (%s, %s, %s)",
                        (seat_number, seat_status, flight_id)
                    )

                    self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
        
    def __fill_customers(self, fillings: int) -> bool:
        try:
            for _ in range(fillings):
                name = self.faker.name()
                email = self.faker.email(domain="google.com")
                phone_number = self.faker.phone_number()
                address = self.faker.address()
                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.customers (name, email, phone_number, address) VALUES (%s, %s, %s, %s)',
                    (name, email, phone_number, address)
                )
                self.connection.commit()
        except Exception as e:
            print(e)

            return False
        
        return True
    
    def __fill_bookings(self, fillings: int) -> bool:
        occupied_seats = []
        try:
            for _ in range(fillings):
                customer_id = self.faker.random.choice(self.get_table_entries(table="customers", column="customer_id"))
                flight_id = self.faker.random.choice(self.get_table_entries(table="flight_data", column="flight_id"))

                seat = self.faker.random.choice(self.get_table_entries(table="seats", column="seat_id"))
                occupied_seats.append(seat)

                price = round(self.faker.random.uniform(50, 1000), 2)
                payment_status = self.faker.boolean()

                if self.faker.boolean(chance_of_getting_true=50):
                    booking_datetime = self.faker.date_time_between(start_date="-2y", end_date="now")
                else: 
                    booking_datetime = self.faker.date_time_between(start_date="now", end_date="+5d")

                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.bookings (flight_id, customer_id, seat_id, price, payment_status, booking_date_and_time) VALUES (%s, %s, %s, %s, %s, %s)',
                    (flight_id, customer_id, seat, price, payment_status, booking_datetime)
                )

                self.connection.commit()
        except Exception as e:
            print(f"Failed to fill bookings table: {e}")
            return False

        self.occupy_seats(occupied_seats)

        return True

    def __fill_work_orders(self, fillings: int) -> bool:
        try:
            aircraft_ids = self.get_table_entries("aircrafts", "aircraft_registration_number")
            maintenance_ids = self.get_table_entries("maintenance_events", "maintenance_id")
            airport_ids = self.get_table_entries("airports", "airport_id")
            reporteur_ids = self.get_table_entries("reporteurs", "reporteur_id")
            
            for _ in range(fillings):
                aircraft_id = self.faker.random.choice(aircraft_ids)
                maintenance_id = self.faker.random.choice(maintenance_ids)
                airport_id = self.faker.random.choice(airport_ids)
                reporteur_id = self.faker.random.choice(reporteur_ids)
                
                reporting_date = self.faker.date_between(start_date="-2y", end_date="today")
                forecasted_date = self.faker.date_between(start_date=reporting_date, end_date="+1y")
                due_date = self.faker.date_between(start_date=forecasted_date, end_date="+1y")
                execution_date = self.faker.date_between(start_date=reporting_date, end_date="+1y")
                
                scheduled = self.faker.boolean()
                forecasted_manhours = self.faker.random_number(fix_len=True, digits=1)
                frequency = self.faker.random_number(fix_len=True, digits=1)
                
                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.work_orders (aircraft_registration_number, maintenance_id, airport_id, execution_date, scheduled, forecasted_date, forecasted_manhours, frequency, reporteur_id, due_date, reporting_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                    (aircraft_id, maintenance_id, airport_id, execution_date, scheduled, forecasted_date, forecasted_manhours, frequency, reporteur_id, due_date, reporting_date)
                )
            
                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_aircrafts(self, fillings: int) -> bool:
        try:
            for _ in range(fillings):
                aircraft_type = self.faker.random.choice(['Boeing 737', 'Airbus A320', 'Boeing 777', 'Airbus A350'])
                aircraft_company = f'{self.faker.company()}'
                aircraft_capacity = 300 

                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.aircrafts (aircraft_type, aircraft_company, aircraft_capacity) VALUES (%s, %s, %s)',
                    (aircraft_type, aircraft_company, aircraft_capacity)
                )

                self.connection.commit() 
        except Exception as e:
            print(e)
            
            return False
    
        return True
    
    def __fill_airports(self, fillings: int = 100) -> bool:
        try:
            for _ in range(fillings): 
                airport_id = self.faker.bothify(text='???').upper()
                if airport_id in self.get_table_entries(table="airports", column="airport_id"):
                    continue
                airport_name = f'{self.faker.company()} Airport'
                airport_city = self.faker.city()
                airport_country = self.faker.country()

                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.airports (airport_id, airport_name, airport_city, airport_country) VALUES (%s, %s, %s, %s)',
                    (airport_id, airport_name, airport_city, airport_country)
                )

                self.connection.commit()  
        except Exception as e:
            print(f"Failed to fill airports table: {e}")
            
            return False

        return True
    
    def __fill_aircraft_slots(self, fillings: int) -> bool:
        try:
            aircraft_ids = self.get_table_entries("aircrafts", "aircraft_registration_number")
            maintenance_ids = self.get_table_entries("maintenance_events", "maintenance_id")
            slot_types = ["Maintenance", "Cleaning", "Inspection", "Repair"]
            scheduled_statuses = [True, False] 

            for _ in range(fillings):
                aircraft_registration_number = self.faker.random.choice(aircraft_ids)
                maintenance_id = self.faker.random.choice(maintenance_ids)
                slot_type = self.faker.random.choice(slot_types)
                slot_scheduled = self.faker.random.choice(scheduled_statuses)

                start_time = self.faker.date_time_between(start_date="-1y", end_date="now")
                end_time = start_time + self.faker.random_element(elements=[timedelta(hours=h) for h in range(1, 13)])

                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.aircraft_slots (aircraft_registration_number, slot_start, slot_end, slot_type, slot_scheduled, maintenance_id) VALUES (%s, %s, %s, %s, %s, %s)",
                    (aircraft_registration_number, start_time, end_time, slot_type, slot_scheduled, maintenance_id)
                )

                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_flights(self, fillings: int) -> bool:
        try: 
            airports = self.get_table_entries(table="airports", column="airport_id")
            airlines = self.get_table_entries(table="airlines", column="airline_id")
            for _ in range(int(fillings / 5)):
                flight_number = f'{self.faker.bothify(text="??").upper()}{self.faker.random_number(fix_len=True, digits=4)}'

                origin = self.faker.random.choice(airports)
                destination = self.faker.random.choice(airports)

                airline_id = self.faker.random.choice(airlines)
                
                hours = self.faker.random.randint(1, 10)
                minutes = self.faker.random.randint(0, 59)
                flight_length = f'{hours} hours {minutes} minutes'

                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.flights (flight_number, origin, destination, airline_id, flight_length) VALUES (%s, %s, %s, %s, %s)',
                    (flight_number, origin, destination, airline_id, flight_length)
                    )
            
                self.connection.commit()
        except Exception as e:
            print(f'An error occurred: {e}')

            return False
        
        return True
    
    def fill_frequent_flyers(self, fillings: int = 3) -> bool:
        try:
            aircraft_ids = self.get_table_entries("aircrafts", "aircraft_registration_number")
            airline_ids = self.get_table_entries("airlines", "airline_id")
            airports = self.get_table_entries("airports", "airport_id")

            if not aircraft_ids or not airline_ids:
                print("Some required data is missing in the database. Populate aircrafts and airlines tables first.")
                return False

            customer_ids = []
            for _ in range(15):
                customer_id = self.faker.random_number(digits=4)
                name = self.faker.name()
                email = self.faker.email()
                phone_number = self.faker.phone_number()
                address = self.faker.address()

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.customers (customer_id, name, email, phone_number, address)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (customer_id, name, email, phone_number, address)
                )
                self.connection.commit()
                customer_ids.append(customer_id)

            flight_numbers = []
            for i in range(fillings):
                flight_number = f'100{i}'
                origin = self.faker.random.choice(airports)
                destination = self.faker.random.choice(airports)
                airline_id = self.faker.random.choice(airline_ids)
                flight_length = f"{self.faker.random.choice([9, 10, 15])}:00:00"  

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.flights (flight_number, origin, destination, airline_id, flight_length)
                    VALUES (%s, %s, %s, %s, %s::INTERVAL)
                    """,
                    (flight_number, origin, destination, airline_id, flight_length)
                )
                self.connection.commit()
                flight_numbers.append(flight_number)

            flight_ids = []
            for flight_number in flight_numbers:
                flight_id = self.faker.random_number(digits=4)
                aircraft_reg = self.faker.random.choice(aircraft_ids)
                scheduled_date = self.faker.date_between(start_date="-3y", end_date="-1y")  
                scheduled_time = self.faker.time_object()
                number_of_passengers = self.faker.random.randint(50, 200)
                number_of_cabin_crew = self.faker.random.randint(2, 6)
                number_of_flight_crew = self.faker.random.randint(1, 2)
                available_seating = self.faker.random.randint(10, 50)

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.flight_data (
                        flight_id, flight_number, aircraft_registration_number, flight_status_id, 
                        problem_id, number_of_passengers, number_of_cabin_crew, number_of_flight_crew, 
                        available_seating, scheduled_departure_date, scheduled_departure_time
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        flight_id, flight_number, aircraft_reg, 1, 1, number_of_passengers,
                        number_of_cabin_crew, number_of_flight_crew, available_seating,
                        scheduled_date, scheduled_time
                    )
                )
                self.connection.commit()
                flight_ids.append(flight_id)

            for customer_id, flight_id in zip(customer_ids, flight_ids):
                booking_id = self.faker.random_number(digits=4)
                seat_id = self.faker.random.randint(1, 100) 
                price = round(self.faker.random.uniform(150, 500), 2)
                payment_status = True
                booking_date = self.faker.date_time_between(start_date="-3y", end_date="-1y") 

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.bookings (
                        booking_id, flight_id, customer_id, seat_id, price, payment_status, booking_date_and_time
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (booking_id, flight_id, customer_id, seat_id, price, payment_status, booking_date)
                )
                self.connection.commit()

            print(f"Successfully added {fillings} frequent flyers with associated flights and bookings.")
            return True
        except Exception as e:
            print(f"An error occurred while adding frequent flyers: {e}")
            return False
    
    def __fill_conflict(self):
        try:
            aircraft_ids = self.get_table_entries("aircrafts", "aircraft_registration_number")
            airport_ids = self.get_table_entries("airports", "airport_id")
            flight_numbers = self.get_table_entries("flights", "flight_number")
            maintenance_type_ids = self.get_table_entries("maintenance_types", "maintenance_type_id")
            subsystem_ids = self.get_table_entries("subsystems", "subsystem_id")

            for _ in range(20):
                flight_id = self.faker.random_number(digits=4) 
                flight_number = self.faker.random.choice(flight_numbers)
                aircraft_reg = self.faker.random.choice(aircraft_ids)
                scheduled_date = self.faker.date_between(start_date="today", end_date="+7d") 
                scheduled_time = self.faker.time_object() 
                number_of_passengers = self.faker.random.randint(50, 200)
                number_of_cabin_crew = self.faker.random.randint(2, 6)
                number_of_flight_crew = self.faker.random.randint(1, 2)
                available_seating = self.faker.random.randint(10, 50)

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.flight_data (
                        flight_id, flight_number, aircraft_registration_number, flight_status_id, 
                        problem_id, number_of_passengers, number_of_cabin_crew, number_of_flight_crew, 
                        available_seating, scheduled_departure_date, scheduled_departure_time
                    ) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        flight_id, flight_number, aircraft_reg, 1, 1, number_of_passengers, 
                        number_of_cabin_crew, number_of_flight_crew, available_seating, 
                        scheduled_date, scheduled_time
                    )
                )
                self.connection.commit()

                maintenance_id = self.faker.random_number(fix_len=True, digits=4) 
                maintenance_starttime = (
                    datetime.combine(scheduled_date, scheduled_time) - timedelta(hours=2)
                ).strftime('%Y-%m-%d %H:%M:%S') 
                duration_hours = self.faker.random.randint(1, 3) 
                duration = f"{duration_hours}:00:00"
                airport_id = self.faker.random.choice(airport_ids)
                maintenance_type_id = self.faker.random.choice(maintenance_type_ids)
                subsystem_id = self.faker.random.choice(subsystem_ids)

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.maintenance_events (
                        maintenance_id, aircraft_registration_number, maintenance_starttime, 
                        duration, airport_id, maintenance_type_id, subsystem_id
                    ) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        maintenance_id, aircraft_reg, maintenance_starttime, duration, 
                        airport_id, maintenance_type_id, subsystem_id
                    )
                )
                self.connection.commit()

            return True
        except Exception as e:
            print(f"An error occurred: {e}")
            return False
    
    def __fill_maintenance_events(self, fillings: int) -> bool:
        try:
            aircraft_ids = self.get_table_entries("aircrafts", "aircraft_registration_number")
            airport_ids = self.get_table_entries("airports", "airport_id")
            subsystem_ids = self.get_table_entries("subsystems", "subsystem_id")
            maintenance_type_ids = self.get_table_entries("maintenance_types", "maintenance_type_id")

            for _ in range(fillings):
                aircraft_reg = self.faker.random.choice(aircraft_ids)
                airport_id = self.faker.random.choice(airport_ids)
                subsystem_id = self.faker.random.choice(subsystem_ids)
                maintenance_type_id = self.faker.random.choice(maintenance_type_ids)

                maintenance_starttime = self.faker.date_time_between(start_date="-1y", end_date="now").strftime('%Y-%m-%d %H:%M:%S')

                duration_hours = self.faker.random.randint(1, 12)  
                duration = f"{duration_hours} hours" 

                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.maintenance_events (aircraft_registration_number, maintenance_starttime, duration, airport_id, subsystem_id, maintenance_type_id) VALUES (%s, %s, %s, %s, %s, %s)",
                    (aircraft_reg, maintenance_starttime, duration, airport_id, subsystem_id, maintenance_type_id)
                )

                self.connection.commit()

            self.__fill_conflict()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_subsystems(self, fillings: int) -> bool:
        try:
            subsystem_types = ["Engine", "Avionics", "Hydraulics", "Landing Gear", "Fuel System", "Electrical System"]
            for subsystem_type in subsystem_types:
                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.subsystems (subsystem_type) VALUES (%s)",
                    (subsystem_type,)
                )
                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False

        return True
    
    def __fill_maintenance_types(self, fillings: int) -> bool:
        try:
            maintenance_type_names = ["Routine Check", "Engine Repair", "Scheduled Maintenance", "Emergency Repair", "Software Update"]
            for mainenance_type in maintenance_type_names:
                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.maintenance_types (maintenance_type_name) VALUES (%s)",
                    (mainenance_type,)
                )
                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_reporteurs(self, fillings: int):
        try:
            for _ in range(fillings):
                reporteur_class = self.faker.random.choice(["Steward", "Pilot", "Mechanic"])
                reporteur_name = self.faker.name()

                self.cursor.execute(
                        f'INSERT INTO {self.schema_name}.reporteurs (reporteur_class, reporteur_name) VALUES (%s, %s)',
                        (reporteur_class, reporteur_name)
                    )
                
                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_reportuers(self, fillings: int):
        try:
            for _ in range(fillings):
                reporteur_class = self.faker.random.choice(["class1", "class2", "class3"])
                reporteur_name = self.faker.random.choice(["name1", "name2", "name3"])

                self.cursor.execute(
                        f'INSERT INTO {self.schema_name}.reporteurs (reporteur_class, reporteur_name) VALUES (%s, %s)',
                        (reporteur_class, reporteur_name)
                    )
                
                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __get_capacity_of_aircraft(self, aircraft: int) -> int:
        query = f"SELECT aircraft_capacity FROM {self.schema_name}.aircrafts WHERE aircraft_registration_number = %s"
        
        self.cursor.execute(query, (aircraft,))
        
        result = self.cursor.fetchone() 
        
        return result[0] if result else None
    
    def __fill_flight_data(self, fillings: int = 100) -> bool:
        pks = {
            "airlines": "airline_id",
            "flights": "flight_number",
            "airports": "airport_id",
            "flight_statuses": "flight_status_id",
            "aircrafts": "aircraft_registration_number",
            "problems": "problem_id"
        }
        pks_content = {}

        for table, column in pks.items():
            ids = self.get_table_entries(table, column)
            pks_content[column] = ids

        try:
            for _ in range(100):
                aircraft_reg = self.faker.random.choice(pks_content["aircraft_registration_number"])
                capacity_of_aircraft = self.__get_capacity_of_aircraft(aircraft=aircraft_reg)

                capacity_multiplier = 1 if self.faker.boolean(chance_of_getting_true=50) else 0.9
                number_of_passangers = int(capacity_multiplier * capacity_of_aircraft)
                number_of_cabin_crew = self.faker.random_number(fix_len=True, digits=1)
                number_of_flight_crew = self.faker.random_number(fix_len=True, digits=1)
                available_seating = capacity_of_aircraft - number_of_passangers

                scheduled_departure_date = self.faker.date_between(start_date="today", end_date="+1y")
                scheduled_departure_time = self.faker.time_object()
                
                fake_status_id_number = random()
                if fake_status_id_number >= 0.8: 
                    if fake_status_id_number <= 0.95:
                        fligt_status = pks_content["flight_status_id"][1]
                    else:
                        fligt_status = pks_content["flight_status_id"][2]
                else:
                    fligt_status = pks_content["flight_status_id"][0]

                if random() <= 0.8:
                    problem_id = pks_content["problem_id"][0]
                else:
                    problem_id = self.faker.random.choice(pks_content["problem_id"])

                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.flight_data (flight_number, aircraft_registration_number, flight_status_id, problem_id, number_of_passengers, number_of_cabin_crew, number_of_flight_crew, available_seating, scheduled_departure_date, scheduled_departure_time) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)',
                    (
                        self.faker.random.choice(pks_content["flight_number"]),
                        aircraft_reg,
                        fligt_status,
                        problem_id,
                        number_of_passangers,
                        number_of_cabin_crew,
                        number_of_flight_crew,
                        available_seating,
                        scheduled_departure_date,
                        scheduled_departure_time
                    )
                )

                self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_customer_preferences(self, fillings: int) -> bool:
        try:
            customer_ids = self.get_table_entries("customers", "customer_id")
            
            for i in range(fillings):
                customer_id = self.faker.random.choice(customer_ids)
                preferences = {
                    "meal": self.faker.random.choice(["vegetarian", "vegan", "gluten-free", "standard"]),
                    "seating": {
                        "aisle": self.faker.boolean(),
                        "extra_legroom": self.faker.boolean(),
                        "seat_near_exit": self.faker.boolean()
                    },
                    "notifications": {
                        "email": self.faker.boolean(),
                        "sms": self.faker.boolean()
                    }
                }
                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.customer_preferences (customer_id, customer_preferences_data) VALUES (%s, %s)",
                    (customer_id, Json(preferences))
                )
                self.connection.commit()
                print(f'{i+1} out of {fillings} for preferences table inserted')
        except Exception as e:
            print(f"Failed to fill customer_preferences table: {e}")
            return False
        
        return True
    
    def __get_maintenance_event_date(self, maintenance_id: int) -> str:
        try:
            self.cursor.execute(
                f"""
                SELECT maintenance_starttime 
                FROM {self.schema_name}.maintenance_events
                WHERE maintenance_id = %s
                """,
                (maintenance_id,)
            )
            
            result = self.cursor.fetchone()
            if result:
                return result[0].strftime("%Y-%m-%d") 
            else:
                raise ValueError(f"No maintenance event found with ID {maintenance_id}")
        except Exception as e:
            print(f"Failed to get maintenance event date: {e}")
            return None
    
    def __fill_aircraft_maintenance_logs(self, fillings: int) -> bool:
        try:
            maintenance_ids = self.get_table_entries("maintenance_events", "maintenance_id")

            for i in range(50):
                maintenance_id = self.faker.random.choice(maintenance_ids)
                maintenace_log_id = self.__get_maintenance_event_date(maintenance_id=maintenance_id)
                maintenance_log = {
                    "date": maintenace_log_id,
                    "check_type": self.faker.random.choice(["Full Inspection", "Routine Check", "Repair", "Emergency Check"]),
                    "components_checked": [
                        {
                            "name": self.faker.random.choice(["Engine", "Avionics", "Hydraulics", "Fuel System", "Electrical System"]),
                            "status": self.faker.random.choice(["Operational", "Requires Service", "Replaced"]),
                            "last_replaced": self.faker.date_between(start_date="-1y", end_date="today").strftime("%Y-%m-%d")
                        } for _ in range(self.faker.random.randint(1, 3))
                    ]
                }

                self.cursor.execute(
                    f"""
                    INSERT INTO {self.schema_name}.aircraft_maintenance_logs (
                        maintenance_id, aircraft_maintenance_logs_data
                    ) VALUES (%s, %s)
                    """,
                    (maintenance_id, psycopg2.extras.Json(maintenance_log))
                )
                self.connection.commit()
                print(f'{i+1} out of {fillings} for maintenance logs table inserted')
        except Exception as e:
            print(f"Failed to fill aircraft_maintenance_logs table: {e}")
            return False
        
        return True

    def __fill_customer_feedback_and_survey(self, fillings: int) -> bool:
        try:
            customer_ids = self.get_table_entries("customers", "customer_id")
            
            for i in range(fillings):
                customer_id = self.faker.random.choice(customer_ids)
                comment_chance = self.faker.boolean(chance_of_getting_true=50)
                feedback_survey = {
                    "survey_date": self.faker.date_between(start_date="-1y", end_date="today").strftime("%Y-%m-%d"),
                    "rating": self.faker.random.randint(1, 5),
                    "comments": self.faker.sentence(nb_words=10) if comment_chance else "No comments",
                    "topics": {
                        "comfort": self.faker.random.randint(1, 5),
                        "service": self.faker.random.randint(1, 5),
                        "cleanliness": self.faker.random.randint(1, 5),
                        "entertainment": self.faker.random.randint(1, 5)
                    }
                }
                self.cursor.execute(
                    f"INSERT INTO {self.schema_name}.customer_feedback_and_survey (customer_id, customer_feedback_and_survey_data) VALUES (%s, %s)",
                    (customer_id, Json(feedback_survey))
                )
                self.connection.commit()
                print(f'{i+1} out of {fillings} for feedback table inserted')
        except Exception as e:
            print(f"Failed to fill customer_feedback_and_survey table: {e}")
            return False
        
        return True
    
    def __fill_flight_statuses(self, fillings: int) -> bool:
        try:
            flight_statuses = [
                "Cancelled",
                "Delayed",
                "On-time"
            ]
            for status in flight_statuses:
                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.flight_statuses (flight_status_type) VALUES (%s)',
                    (status,)
                )

            self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def __fill_problems(self, fillings: int) -> bool:
        try:
            problem_types = [
                "Everything Ok",
                "Engine Failure",
                "Avionics Issue",
                "Fuel System Leak",
                "Hydraulic Failure",
                "Tire Damage",
                "Wing Deformity",
                "Sensor Malfunction",
                "Landing Gear Issue",
                "Cabin Pressure Problem",
                "Electrical System Issue"
            ]
            
            for problem_type in problem_types:
                self.cursor.execute(
                    f'INSERT INTO {self.schema_name}.problems (problem_type) VALUES (%s)',
                    (problem_type,)
                )

            self.connection.commit()
        except Exception as e:
            print(f"An error occurred: {e}")

            return False
        
        return True
    
    def fill_table(self, table: str, fillings: int = 100) -> bool:
        fill = self.filling_mapper[table](fillings)
        if fill:
            print(f'Successfully filled {table} with {fillings}')
        else:
            print(f'Can not fill {table}')