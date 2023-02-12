/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
use portfolio_project;

Select *
From portfolioproject
Where continent is not null 
order by 3,4;

select count(*) from portfolioproject;

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject
Where continent is not null 
order by 1,2

/* Total deaths vs total cases*/
/* showhing what percentage of total_cases died with infection*/

select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject
Where continent like '%asia%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select  Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Portfolioproject
order by 1,2


/*Countries with Highest Infection Rate compared to Population*/

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject
Where location like '%africa%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From portfolioproject
Group by Location
order by TotalDeathCount desc;

select Continent, location, max(total_deaths) as TotalDeathCount
from portfolioproject
group by continent
order by TotalDeathCount desc;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From portfolioproject
where continent is not null
/*Where location like '%brazil%'*/
Group by continent
order by TotalDeathCount desc;

Select continent, count(Total_deaths) as TotalDeathCount
From portfolioproject
where continent is not null
/*Where location like '%brazil%'*/
Group by continent
order by TotalDeathCount desc

/*GLOBAL NUMBERS*/
/*Lest us first see the data type of new_deaths column first */

select column_name, data_type
from information_schema.columns
where table_name = 'Portfolioproject'
and column_name = 'new_deaths';

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(New_Cases))*100 as DeathPercentage
From Portfolioproject
where continent is not null 
Group By date
order by 1,2

Select continent,  date, location, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
From Portfolioproject
where continent is not null
Group By continent, date, location
order by continent, date;


  /*join two tables
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine*/

/* Let us use window function*/

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population)*100 as PercentageVaccinated
FROM PortfolioProject dea
JOIN covidvaccnations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY CONTINENT DESC;


-- /*Using CTE to perform Calculation on Partition By in previous query*/

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated, PercentageOfVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
(SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population)*100 AS PercentageOfVaccinated
FROM PortfolioProject dea
JOIN covidvaccnations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *
FROM PopvsVac
ORDER BY 2,3;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
(SUM(vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

/* Some different culculations*/
Select * from covidvaccnations
order by location , date;
Select * from covidvaccnations
where total_vaccinations is not null
order by date, location desc;

/* Now we will find percentage of vaccinated_people over total_vaccinations*/

select dea.continent, dea.location, vac.date, sum(dea.total_deaths), sum(dea.population),sum(total_vaccinations) as TotalVaccination, sum(people_vaccinated) as TotalVaccinated,
 (sum(people_vaccinated)/sum(total_vaccinations))*100 as PercentageOfVaccinatedPeoples
 from covidvaccnations
 where total_vaccinations is not null
 and people_vaccinated is not null
 group by location, date
 order by location, date desc;
 
 select dea.continent, dea.location, vac.date, 
 sum(dea.total_deaths) as TotalDeaths, sum(dea.population) as TotalPopulation, 
 (sum(dea.total_deaths)/sum(dea.population))*100 as DeathPercentage,
 sum(total_vaccinations) as TotalVaccination, sum(people_vaccinated) as TotalVaccinated,
 (sum(people_vaccinated)/sum(total_vaccinations))*100 as PercentageOfVaccinatedPeoples
 from portfolioproject dea join covidvaccnations vac
 on dea.date = vac.date
 where total_vaccinations is not null
 and dea.location like '%e%%e%'
 and people_vaccinated is not null
 group by continent, location, date
 order by continent, location, date desc;
 
 select total_deaths, people_Vaccinated from portfolioproject dea
 join covidvaccnations vac
 on dea.date = vac.date
 where total_deaths is not null
 and people_vaccinated is not null
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



