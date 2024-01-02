/* 
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

--Data we will be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in the United States

SELECT location, date, total_cases, total_deaths, (CONVERT(decimal, total_deaths)/NULLIF(CONVERT(decimal, total_cases),0))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like 'United States'
ORDER BY 2

-- Total Cases vs Population
-- Shows what percentage of population contracted COVID
SELECT location, date, total_cases, population, (CONVERT(decimal, total_cases)/NULLIF(CONVERT(decimal, population),0))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
ORDER BY 1, 2

--Countries with Highest Infection Rate compared to Population

SELECT location, population,MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(decimal, total_cases)/NULLIF(CONVERT(decimal, population),0))*100) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Countries with Highest Death Rate per Population

SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--Lets break this down by continent

--Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global Numbers

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null


--Looking at the total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE

WITH PopvsVax(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVax
ORDER BY 1,2,3

--Using Temp Table

DROP TABLE IF exists #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
INTO #PercentPopulationVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

DROP TABLE #PercentPopulationVaccinated

--Creating view to store data for later

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated