/*
TASK2 : Covid 19 Data Exploration 
*/

-- Death of young people between the age of 25-44
SELECT
  region,
  sex,
  agegroup,
  date,
  deaths
FROM
  scs_be_detailed_mortality
WHERE
  deaths IS NOT NULL
  AND agegroup = '25-44';

-- Deaths by Age Group:
SELECT
  agegroup,
  SUM(deaths) as total_deaths
FROM
  scs_be_detailed_mortality
WHERE
  deaths IS NOT NULL
  AND agegroup IS NOT NULL -- Exclude rows where agegroup is null
GROUP BY
  agegroup;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT
  country_region,
  cases,
  deaths,
  date,
  -- Using a CASE statement to calculate Death Percentage, avoiding division by zero
  CASE WHEN cases > 0 THEN (deaths / cases) * 100 ELSE NULL END AS Death_Percentage
FROM
  ecdc_global
WHERE
  country_region LIKE '%Austria'
  AND continentexp IS NOT NULL
  AND cases > 0 
  AND deaths > 0; -- Filters out rows where both cases and deaths are zero 


-- Total Cases vs Population
-- Shows what percentage of the population is infected with Covid
SELECT
  country_region,
  date,
  population,
  cases,
  -- Using NULLIF to avoid division by zero
  (cases / NULLIF(population, 0)) * 100 as Percent_Population_Infected
FROM
  ecdc_global
WHERE
  cases > 0; -- Exclude rows where cases are zero 
  
-- Mortality Rate over Time
-- Shows how the percentage of deaths relative to cases changes over different dates.
-- Useful for tracking the impact of COVID-19 and allocating healthcare resources.
SELECT
  date,
  SUM(deaths) as total_deaths,
  SUM(cases) as total_cases,
  -- Using NULLIF to avoid division by zero
  (SUM(deaths) / NULLIF(SUM(cases), 0)) * 100 as mortality_rate
FROM
  ecdc_global
WHERE
  continentexp IS NOT NULL
GROUP BY
  date
HAVING
  SUM(cases) > 0 AND
  SUM(deaths) > 0 -- Exclude rows where total cases and deaths are zero
ORDER BY
  date;

-- Top 5 Countries by Mortality Rate:
SELECT
  country_region,
  SUM(deaths) as total_deaths,
  SUM(cases) as total_cases,
  (SUM(deaths) / NULLIF(SUM(cases), 0)) * 100 as mortality_rate-- Using NULLIF to avoid division by zero
FROM
  ecdc_global
WHERE
  continentexp IS NOT NULL
GROUP BY
  country_region
ORDER BY
  mortality_rate DESC
LIMIT 5;

-- Vaccination Coverage
-- Shows the progress of COVID-19 vaccination by tracking the number of people partially and fully vaccinated over time.
-- Useful for monitoring vaccination efforts and understanding the coverage in different countries.
SELECT
  date,
  country_region,
  total_vaccinations,
  people_vaccinated,
  people_fully_vaccinated
FROM
  owid_vaccinations
WHERE
  country_region IS NOT NULL
  AND people_vaccinated IS NOT NULL
  AND people_vaccinated > 0
  AND people_fully_vaccinated IS NOT NULL
  AND people_fully_vaccinated > 0
ORDER BY
  date;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT
  dea.country_region,
  dea.continentexp,
  dea.date,
  dea.population,
  vac.people_vaccinated,
  vac.people_fully_vaccinated,
  COALESCE(vac.people_vaccinated, 0) as people_vaccinated_nonull,
  COALESCE(vac.people_fully_vaccinated, 0) as people_fully_vaccinated_nonull,
  (COALESCE(vac.people_vaccinated, 0) + COALESCE(vac.people_fully_vaccinated, 0)) as total_vaccinated,
  (total_vaccinated / NULLIF(dea.population, 0)) * 100 as PercentPopulationVaccinated
FROM
  ecdc_global dea
JOIN
  OWID_VACCINATIONS vac
  ON dea.country_region = vac.country_region
  AND dea.date = vac.date
WHERE
  dea.country_region IS NOT NULL;
 --- AND vac.people_vaccinated IS NOT NULL
 --- AND vac.people_fully_vaccinated IS NOT NULL;


-- Joining kff with Economic Data

SELECT
  c.COUNTRY,
  c.GDPCAP,
  c.DATE
FROM economic_data.public.global_economy c
LEFT JOIN kff_us_state_mitigations r
ON c.COUNTRY = r.COUNTRY_REGION
AND c.DATE >= r.LAST_UPDATED_DATE;

--- Joining nyt with Economic Data


SELECT
    nyt.STATE,
    ge.CODE,
    ge.DATE,
    ge.GDPCAP
FROM
    nyt_us_reopen_status nyt
JOIN
    economic_data.public.global_economy ge ON nyt.STATE = ge.COUNTRY
WHERE
    nyt.STATE IS NOT NULL;

