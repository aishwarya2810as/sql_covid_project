-- Query 1: Select all columns from CovidDeaths and order by 3rd and 4th columns
SELECT *
FROM pro..CovidDeaths
WHERE continent is not null
ORDER BY 3, 4;

-- Query 2: Calculate death percentage and order by location and date
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM pro..CovidDeaths
ORDER BY location, date;

-- Total cases vs total deaths
-- Shows the likelihood of dying if you contracted COVID-19 in your country
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS PercentInfected
FROM pro..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, date;

-- Looking at total cases vs population
-- Shows what percentage of the population has gotten COVID-19
SELECT 
    location, 
    date, 
    total_cases, 
    population,
    (total_cases / NULLIF(population, 0)) * 100 AS InfectionRate, 
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM pro..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, date;


--looking at countries with highest infection rate compared to population
SELECT 
    location,
    population,
    MAX((total_cases / NULLIF(population, 0)) * 100) AS InfectionCount, 
    MAX((CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100) AS PercentPopulationInfected
FROM pro..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;
--BREAKING THING BY CONTINENTS
SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) AS TotaldeathCount
FROM pro..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotaldeathCount DESC;

--COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION
SELECT
    location,
    MAX(CAST(total_deaths AS INT)) AS TotaldeathCount
FROM pro..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotaldeathCount DESC;

--SHOWING CONTINENTS WITH THE HIGGEST DEATH COUNTS PER POPULATION


--GLOBAL NUMBERS 

SELECT 
  date,
  SUM(new_cases) as total_cases,
  SUM(CAST(new_deaths as int)) as total_deaths,
  -- Calculate the death percentage for each date
  -- Handle division by zero if there are no new cases on a date
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE (SUM(CAST(new_deaths AS int)) * 100.0) / SUM(new_cases)
  END AS DeathPercentage
FROM pro..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY date;
--looking at total population vs vaccination

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int))OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated

FROM pro..CovidDeaths dea
JOIN pro..CovidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH popvsvac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int))OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated

FROM pro..CovidDeaths dea
JOIN pro..CovidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
Select *,(RollingPeopleVaccinated/population)*100
From popvsvac

--temp table
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int))OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated

FROM pro..CovidDeaths dea
JOIN pro..CovidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
Select *,(RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

--new temp table 
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int))OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated

FROM pro..CovidDeaths dea
JOIN pro..CovidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
Select *,(RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

--creating view to store data for visulization later
create view PercentPopulationVaccinated as
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int))OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated

FROM pro..CovidDeaths dea
JOIN pro..CovidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent IS NOT NULL