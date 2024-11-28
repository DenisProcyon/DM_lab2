from postgres_orm import PostgresORM

HOST = ""
PORT = ""
USERNAME = ""
PASSWORD = ""
DB_NAME = ""
SCHEMA_NAME = ""

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