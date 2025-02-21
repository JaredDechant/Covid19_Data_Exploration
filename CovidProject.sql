SELECT *
FROM dbo.CovidDeaths;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
WHERE continent is not NULL
ORDER BY location,date;

--Percentage of deaths out of reported cases in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM dbo.CovidDeaths
WHERE location = 'United States'
AND continent is not NULL
ORDER BY location,date;

--Percentage of United States population infected
SELECT location, date, total_cases, population, (total_cases/population)*100 AS Percent_Pop_Infected
FROM dbo.CovidDeaths
WHERE location = 'United States'
AND continent is not NULL
ORDER BY location,date;

--Infection rate by country
CREATE VIEW CountryInfectionRate AS
SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population))*100 AS Percent_Pop_Infected
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY Percent_Pop_Infected DESC;

--Countries with highest death counts
CREATE VIEW CountryDeathCount AS
SELECT location, MAX(CAST(total_deaths as int)) AS total_death_count
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY total_death_count Desc;

-- Continents with highest death counts
CREATE VIEW ContinentDeathCount AS
SELECT continent, SUM(CAST(new_deaths as int)) AS total_death_count
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY total_death_count Desc;

--GLOBAL

--Global death percentage as of April 2021
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM dbo.CovidDeaths
WHERE continent is not NULL;

--Global death percentage by date
CREATE VIEW GlobalDeathPercentage AS
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date, total_cases;


--VACCINATIONS

SELECT dths.continent, dths.location, dths.date, dths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dths.location ORDER BY dths.location, dths.date) AS rolling_vaccinated 
FROM dbo.CovidDeaths AS dths
INNER JOIN dbo.CovidVaccinations AS vax
	ON dths.location = vax.location
	AND dths.date = vax.date
	WHERE dths.continent is not null
	ORDER BY dths.location, dths.date;


--CTE to get percent of populations vaccinated by date

WITH PopVac (continent, location, date, population, new_vaccinations, rolling_vaccinated) AS (
SELECT dths.continent, dths.location, dths.date, dths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dths.location ORDER BY dths.location, dths.date) AS rolling_vaccinated 
FROM dbo.CovidDeaths AS dths
INNER JOIN dbo.CovidVaccinations AS vax
	ON dths.location = vax.location
	AND dths.date = vax.date
	WHERE dths.continent is not null
	--ORDER BY dths.location, dths.date;
	)

SELECT *, (rolling_vaccinated/population)*100 AS vax_percentage
FROM PopVac;

--Temp Table
DROP TABLE if exists #PercentPopVax
CREATE TABLE #PercentPopVax (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_vaccinated numeric
	)

	INSERT INTO #PercentPopVax
	SELECT dths.continent, dths.location, dths.date, dths.population, vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dths.location ORDER BY dths.location, dths.date) AS rolling_vaccinated 
	FROM dbo.CovidDeaths AS dths
	INNER JOIN dbo.CovidVaccinations AS vax
		ON dths.location = vax.location
		AND dths.date = vax.date
		WHERE dths.continent is not null
		--ORDER BY dths.location, dths.date;
	

	SELECT *, (rolling_vaccinated/population)*100 AS vax_percentage
	FROM #PercentPopVax;

	--Creating views for later visualizations

	CREATE VIEW PercentPopVax AS
	SELECT dths.continent, dths.location, dths.date, dths.population, vax.new_vaccinations,
	SUM(CAST(vax.new_vaccinations as int)) OVER (PARTITION BY dths.location ORDER BY dths.location, dths.date) AS rolling_vaccinated 
	FROM dbo.CovidDeaths AS dths
	INNER JOIN dbo.CovidVaccinations AS vax
		ON dths.location = vax.location
		AND dths.date = vax.date
		WHERE dths.continent is not null;

SELECT *, (rolling_vaccinated/population)*100 AS vax_percentage
FROM PercentPopVax;