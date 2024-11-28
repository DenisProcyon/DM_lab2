# DM_Lab2

This project implements schema population for a PostgreSQL database using the `PostgresORM` class. Each method of the class corresponds to a table in the schema. To ensure all conditions are covered, the `get_table_entries` method is also provided.

## Key Notes
1. **`seat_classes` Table Population**:  
   The `__fill_seat_classes()` method is used to populate the `seat_classes` table. It is implemented to create only two rows of seats for each aircraft to optimize execution time.

2. **Frequent Flyers Data**:  
   The `fill_frequent_flyers()` method has been updated compared to the implementation in Lab 1 to cover additional test cases for specific scenarios.

---

## Usage

### Prerequisites
1. Set up a schema.
2. Credentials provided in Google Classroom.

### Example Code
```python
from postgres_orm import PostgresORM

# Credentials for database connection (proveided in google classroom)
HOST = "<host>"
PORT = "<port>"
USERNAME = "<username>"
PASSWORD = "<password>"
DB_NAME = "<database_name>"
SCHEMA_NAME = "<schema_name>"

# Initialize ORM instance
orm = PostgresORM(
    host=HOST,
    port=PORT,
    username=USERNAME,
    password=PASSWORD,
    db_name=DB_NAME,
    schema_name=SCHEMA_NAME
)

# Specify the order of table population
filling_order = (
    "table_1",
    "table_2",
    ...,
    "table_n",
)

# Populate each table in the specified order
for table in filling_order:
    result = orm.fill_table(table=table, fillings=100)
