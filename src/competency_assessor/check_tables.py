import psycopg2

# Connect to the database
conn = psycopg2.connect("postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment")
cursor = conn.cursor()

# Get all tables
cursor.execute("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

tables = cursor.fetchall()
print("Tables in database:")
for table in tables:
    print(f"  - {table[0]}")

cursor.close()
conn.close()
