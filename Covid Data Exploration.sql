SELECT * 
FROM CovidDeaths

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

--Total cases vs total deaths in the US
--Percentage of people that died from covid

SELECT Location, date, total_cases,total_deaths, ROUND((total_deaths/total_cases), 3)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Population in the US
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases,  ROUND((total_cases/population), 3)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY location, date

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionRate,  ROUND(Max((total_cases/population)), 3)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Rate per Population

SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathRate DESC

-- Showing continents with the highest death rate per population

SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathRate
From CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathRate DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, ROUND(SUM(CAST(new_deaths AS INT))/SUM(New_Cases), 3)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY total_cases, total_deaths

-- Percentage of Population that has recieved at least one Covid Vaccine

SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) OVER (PARTITION BY CovidDeaths.Location ORDER BY CovidDeaths.location, CovidDeaths.Date) AS RollingVaccinations
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.CONTINENT IS NOT NULL 
ORDER by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
AS
(
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) OVER (PARTITION BY CovidDeaths.Location ORDER BY CovidDeaths.location, CovidDeaths.Date) AS RollingVaccinations
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.CONTINENT IS NOT NULL 
)
SELECT *, (RollingVaccinations/Population)*100 AS VaccinationPercentage
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) OVER (PARTITION BY CovidDeaths.Location ORDER BY CovidDeaths.location, CovidDeaths.Date) AS RollingVaccinations
FROM dbo.CovidDeaths
JOIN dbo.CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
	WHERE CovidDeaths.CONTINENT IS NOT NULL 
SELECT *, (RollingVaccinations/Population)*100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated

---- Views for visualizations ----

CREATE VIEW PopulationVaccinationPercentage AS
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, CovidVaccinations.new_vaccinations
, SUM(CONVERT(INT,CovidVaccinations.new_vaccinations)) OVER (PARTITION BY CovidDeaths.Location ORDER BY CovidDeaths.location, CovidDeaths.Date) AS RollingVaccinations
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
	WHERE CovidDeaths.CONTINENT IS NOT NULL 

CREATE VIEW ContinentDeathRate AS
SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathRate
From CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent


CREATE VIEW USAInfectionRate AS
SELECT Location, date, Population, total_cases,  ROUND((total_cases/population), 3)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL


CREATE VIEW USADeathRate AS
SELECT Location, date, total_cases,total_deaths, ROUND((total_deaths/total_cases), 3)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL


CREATE VIEW ContinentInfectionRate AS
SELECT Location, Population, MAX(total_cases) AS HighestInfectionRate,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

CREATE VIEW CountryDeathRate AS
SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
