/* 
Covid 19 Data Exploration

Analysis performed by - Syed Sarfaraz Ahmed

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views & Converting-Casting Data Types
*/

-- Viewing the datasets
SELECT * FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL

SELECT * FROM Project_Portfolio.dbo.CovidVaccinations
WHERE continent IS NOT NULL

-- Selecting the data which is required for analysis

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL

-- Looking at Total cases vs Total Deaths
-- This is performed in order to check the likelyhoof of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, CONVERT(DECIMAL(18, 2), (CONVERT(DECIMAL(18, 2), total_deaths) / CONVERT(DECIMAL(18, 2), total_cases)))*100 AS Death_Percentage
FROM Project_Portfolio.dbo.CovidDeaths
WHERE Location like '%India%' AND continent IS NOT NULL


-- Looking at Total Cases vs Population
-- Show what percentage of population got infected with covid Covid

SELECT Location, date, total_cases, Population, CONVERT(DECIMAL(18, 2), (CONVERT(DECIMAL(18, 2), total_cases) / CONVERT(DECIMAL(18, 2), Population)))*100 AS AffectedPopulationPercentage
FROM Project_Portfolio.dbo.CovidDeaths
WHERE Location like '%India%' AND continent IS NOT NULL

-- Country with highest infection rate with respective to their population

SELECT Location, Population, MAX(total_cases) as HighestInfectedCount, MAX((CONVERT(DECIMAL(18, 2), total_cases) / CONVERT(DECIMAL(18, 2), Population)))*100 AS AffectedPopulationPercentage
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY AffectedPopulationPercentage DESC

-- Countries with Highest Death Count Per Population

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Countries with highest death rate

SELECT Location, Population, MAX(total_deaths) as HighestDeathCount, MAX((CONVERT(DECIMAL(18, 2), total_deaths) / CONVERT(DECIMAL(18, 2), Population)))*100 AS DeathRate
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY DeathRate DESC


-- BREAKING THINGS DOWN BY CONTINENT 

-- Lets search the highest death count by continent

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global Numbers

SELECT date, SUM(CAST(new_cases as int)) AS TotalCasesPerDay, SUM(CAST(new_deaths AS int)) AS TotalDeathsPerDay,
CONVERT(DECIMAL(18, 6), (CONVERT(DECIMAL(18, 6), SUM(CAST(new_deaths AS int))) / CONVERT(DECIMAL(18, 6), SUM(CAST(new_cases AS int)))))*100 AS DeathPercentPerDay
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

SELECT SUM(CAST(new_cases as int)) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths,
CONVERT(DECIMAL(18, 6), (CONVERT(DECIMAL(18, 6), SUM(CAST(new_deaths AS int))) / CONVERT(DECIMAL(18, 6), SUM(CAST(new_cases AS int)))))*100 AS DeathPercentage
FROM Project_Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL


-- Joining both the tables

SELECT * 
FROM Project_Portfolio.dbo.CovidDeaths CD 
JOIN Project_Portfolio.dbo.CovidVaccinations CV
	ON CD.location = CV.location 
	AND CD.date = CV.date

-- Total Population vs vaccinations
-- Shows Percentage of population that has received atleast one Covid Vaccine

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.location ORDER BY CD.location,
CD.date) AS CountOfPeopleVaccinated
FROM Project_Portfolio.dbo.CovidDeaths CD 
JOIN Project_Portfolio.dbo.CovidVaccinations CV
	ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE to perform further calculation on partition by in Previous query

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, CountofPeopleVaccinated) 
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.Location ORDER BY CD.location,
CD.Date) AS CountOfPeopleVaccinated
FROM Project_Portfolio.dbo.CovidDeaths CD 
JOIN Project_Portfolio.dbo.CovidVaccinations CV
	ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3
)
-- SELECT *, (CountofPeopleVaccinated/population)*100 AS PercentofCPV 
SELECT *, CONVERT(DECIMAL(18, 6), (CONVERT(DECIMAL(18, 6), CountofPeopleVaccinated) / CONVERT(DECIMAL(18, 6), CAST(population AS int))))*100 AS DeathPercentage
FROM PopVsVac


-- Temp Table (Alternate for CTE's shows how to perform calculation on partition by in previous query)
-- Use DROP TABLE IF EXISTS tablename before create table if there is any requirement of alterations in the table


CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CountofPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.Location ORDER BY CD.location,
CD.Date) AS CountOfPeopleVaccinated
FROM Project_Portfolio.dbo.CovidDeaths CD 
JOIN Project_Portfolio.dbo.CovidVaccinations CV
	ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, CONVERT(DECIMAL(18, 6), (CONVERT(DECIMAL(18, 6), CountofPeopleVaccinated) / CONVERT(DECIMAL(18, 6), CAST(population AS int))))*100 AS DeathPercentage
FROM #PercentPopulationVaccinated ORDER BY 2,3


-- Creating Views to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.Location ORDER BY CD.location,
CD.Date) AS CountOfPeopleVaccinated
FROM Project_Portfolio.dbo.CovidDeaths CD 
JOIN Project_Portfolio.dbo.CovidVaccinations CV
	ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

