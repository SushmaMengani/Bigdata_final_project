 /*MATCH_RECOGNIZE is a clause in SQL which is used for sequence pattern recognition within a dataset.*/.

 /*Query identifies sequences where the number of cases & deaths are increasead. 
 useful for identifying periods where both cases and deaths are raised in a specific geographical regions.*/

SELECT *
FROM NYT_US_COVID19
MATCH_RECOGNIZE (
  PARTITION BY COUNTY, STATE
  ORDER BY DATE
  --  measures to capture the first and last occurrences of CASES and DEATHS in each sequence
  MEASURES
    FIRST(CASES) AS start_cases,
    LAST(CASES) AS end_cases,
    FIRST(DEATHS) AS start_deaths,
    LAST(DEATHS) AS end_deaths
  ONE ROW PER MATCH
  -- this patern recognizes sequences of increasing CASES followed by increasing DEATHS
  PATTERN (incr_cases+ incr_deaths+)
  -- conditions to increment the measures based on the previous value in the sequence
  DEFINE
    incr_cases AS (CASES > LAG(CASES, 1, CASES)),
    incr_deaths AS (DEATHS > LAG(DEATHS, 1, DEATHS))
) AS mr;


/*This query capture sequences of changing positive, negative, and inconclusive results within specific regions, it provides how testing trends varies in different geographical areas.*/
 
SELECT *
FROM CDC_TESTING
MATCH_RECOGNIZE (
  PARTITION BY ISO3166_1, ISO3166_2
  ORDER BY DATE
  -- Defining measures to capture the first and last occurrences of POSITIVE, NEGATIVE, and INCONCLUSIVE
  MEASURES
    FIRST(POSITIVE) AS start_positive,
    LAST(POSITIVE) AS end_positive,
    FIRST(NEGATIVE) AS start_negative,
    LAST(NEGATIVE) AS end_negative,
    FIRST(INCONCLUSIVE) AS start_inconclusive,
    LAST(INCONCLUSIVE) AS end_inconclusive
  -- Specifing to output that only one row for each match
  ONE ROW PER MATCH
  -- Pattern to recognize sequences of increasing POSITIVE, NEGATIVE, and INCONCLUSIVE
  PATTERN (incr_positive+ incr_negative+ incr_inconclusive+)
  -- conditions to increment the measures based on the previous value in the sequence
  DEFINE
    incr_positive AS (POSITIVE > LAG(POSITIVE, 1, 0)),
    incr_negative AS (NEGATIVE > LAG(NEGATIVE, 1, 0)),
    incr_inconclusive AS (INCONCLUSIVE > LAG(INCONCLUSIVE, 1, 0))
) AS mr
-- Filter out matches where all measures are NULL
WHERE 
  start_positive IS NOT NULL 
  OR start_negative IS NOT NULL 
  OR start_inconclusive IS NOT NULL;

/*This query gives a sequences where both deaths and confirmed cases suddenly increased in country regions*/


SELECT *
FROM JHU_DASHBOARD_COVID_19_GLOBAL
MATCH_RECOGNIZE (
  PARTITION BY COUNTRY_REGION
  ORDER BY DATE
  -- first, last occurrences of DEATHS, CONFIRMED, and MORTALITY_RATE in each sequence
  MEASURES
    FIRST(DEATHS) AS start_deaths,
    LAST(DEATHS) AS end_deaths,
    FIRST(CONFIRMED) AS start_confirmed,
    LAST(CONFIRMED) AS end_confirmed,
    FIRST(MORTALITY_RATE) AS start_mortality_rate,
    LAST(MORTALITY_RATE) AS end_mortality_rate
  ONE ROW PER MATCH
 -- recognizes the sequences of increasing DEATHS and CONFIRMED
  PATTERN (incr_deaths+ incr_confirmed+)
  DEFINE
    incr_deaths AS (DEATHS > LAG(DEATHS, 1, DEATHS) AND DEATHS IS NOT NULL),
    incr_confirmed AS (CONFIRMED > LAG(CONFIRMED, 1, CONFIRMED) AND CONFIRMED IS NOT NULL AND MORTALITY_RATE IS NOT NULL)
) AS mr
WHERE 
    start_deaths IS NOT NULL 
    AND start_confirmed IS NOT NULL 
    AND start_mortality_rate IS NOT NULL; -- Excliuding the Null values

