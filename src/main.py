from postgres_orm import PostgresORM

HOST = "46.101.139.85"
PORT = "5432"
USERNAME = "postgres"
PASSWORD = "pass"
DB_NAME = "lab2"
SCHEMA_NAME = "airport_lab"

orm = PostgresORM(
    host=HOST,
    port=PORT,
    username=USERNAME,
    password=PASSWORD,
    db_name=DB_NAME,
    schema_name=SCHEMA_NAME
)

filling_order = (
    "customers",
    "airlines",
    "airports",
    "flights",
    "reporteurs",
    "aircrafts",
    "flight_statuses",
    "problems",
    "flight_data",
    "seat_classes",
    "seats",
    "bookings",
    "subsystems",
    "maintenance_types",
    "maintenance_events",
    "aircraft_slots",
    "work_orders",
    "customer_preferences",
    "aircraft_maintenance_logs",
    "customer_feedback_and_survey",
)

for table in filling_order:
    result = orm.fill_table(table=table, fillings=100)

orm.fill_frequent_flyers()