
# TASK2 Snowflake connector 


import snowflake.connector

# Snowflake account details
account_name = 'elugxls-ox45694'
username = 'SUSHMAMENGANI'
password = 'Srinidhi7'
warehouse = 'COMPUTE_WH'
database = 'COVID19_EPIDEMIOLOGICAL_DATA'
schema = 'public'

# Establish a connection
conn = snowflake.connector.connect(
    user=username,
    password=password,
    account=account_name,
    warehouse=warehouse,
    database=database,
    schema=schema
)

# Create a cursor object
cursor = conn.cursor()

# Execute a simple query for checking 
cursor.execute("""
  SELECT
    agegroup,
    SUM(deaths) as total_deaths
  FROM
    scs_be_detailed_mortality
  WHERE
    deaths IS NOT NULL
    AND agegroup IS NOT NULL
  GROUP BY
    agegroup
""")

# Fetch the result
result = cursor.fetchone()
print("Age Group:", result[0])
print("Total Deaths:", result[1])

# Close the cursor and connection
cursor.close()
conn.close()
