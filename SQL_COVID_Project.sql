SELECT *
FROM PortfolioProject..covid_deaths$
WHERE continent is not null
ORDER BY 3,4

/*SELECT *
FROM PortfolioProject..covid_vaccinations$
ORDER BY 3,4*/

--Select data to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..covid_deaths$
ORDER BY 1, 2


--Looking at total cases vs total deaths
--Shows likelihood of dying from COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..covid_deaths$
WHERE location like '%states%'
ORDER BY 1, 2


--Looking at Total Cases vs Population
--Shows percentage of popluation has COIVD
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PositiveCases
FROM PortfolioProject..covid_deaths$
WHERE location like '%states%'
ORDER BY 1, 2

--Looking at highest infection rate vs population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentAsPopulationInfected
FROM PortfolioProject..covid_deaths$
--WHERE location like '%states%'
GROUP BY population, location
ORDER BY PercentAsPopulationInfected DESC

--Showing cuntries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..covid_deaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Looking at deaths by continent
--Showing Continents with highest death counts
--*note- Continent Column is missing country data (ex, North America is missing Canada)

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..covid_deaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Global Numbers

SELECT Sum(new_cases) as total_cases, SUM(CAST(new_deaths AS INT))as total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..covid_deaths$
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2


--Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingCountVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

--Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingCountVaccinated)
AS

(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingCountVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (RollingCountVaccinated/population)*100 AS VacPercentage
FROM PopvsVac


-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100 AS VacPercentage
FROM #PercentPopulationVaccinated


--Creating View to store data for Later Visualization

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..covid_deaths$ dea
JOIN PortfolioProject..covid_vaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3


SELECT *
FROM PercentPopulationVaccinated