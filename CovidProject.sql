--Countries with highest HDI during covid

SELECT location, date, Max(human_development_index) AS Hightest_HDI
FROM CovidProject..CovidVacHDI$
WHERE continent is not null
GROUP BY location, date
ORDER BY 3 DESC
--Comparing HDI with total_vaccinations

SELECT date, location, human_development_index, total_vaccinations
GROUP BY date, location

--Since Norway has the highest HDI, I am seeing the percentage of total death per day

SELECT date, location, population, (total_deaths/population)*100 as DeathPercentage
FROM CovidProject..CovidDeaths$
WHERE location like '%Norway%' AND
         total_deaths is NOT NULL

--Seeing the date that Norway received the most deaths

SELECT Top 1 date, total_deaths, (total_deaths/population)*100 as DeathPercentage
FROM CovidProject..CovidDeaths$
WHERE location like '%Norway%' 
ORDER BY 3 DESC

--Seeing Norway's total deaths within the period

SELECT SUM(Cast(total_deaths as float)) as Total_deaths
FROM CovidProject..CovidDeaths$
WHERE location like '%Norway%' 

--Calculating percenage of people fully vaccinated

SELECT DISTINCT dea.date, vac.location, dea.population,  vac.people_fully_vaccinated, (vac.people_fully_vaccinated/dea.population)*100 as PercentofFully_Vaccinated
FROM CovidProject..CovidDeaths$ dea
JOIN CovidProject..CovidVacHDI$ vac
on dea.date = vac.date
and dea.location = vac.location
WHERE vac.location like '%Norway%' AND
    people_fully_vaccinated is NOT NULL
--GROUP BY vac.location, dea.date, vac.people_fully_vaccinated, dea.population

--Roll the amount of fully vaccinated

Select dea.location, dea.date, dea.population, vac.people_fully_vaccinated,
Sum(Cast(vac.people_fully_vaccinated as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..CovidVacHDI$ vac
 on dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
And dea.location like '%Norway%'
And vac.people_fully_vaccinated is not null
Order By 2

--Using CTE

WITH People_Vaccinated (location, date, population, people_fully_vaccinate, rolling_people_vaccinated) as
(
Select dea.location, dea.date, dea.population, vac.people_fully_vaccinated,
Sum(Convert(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY cast(dea.date as datetime)) as rolling_people_vaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..CovidVacHDI$ vac
 on dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
AND dea.location like '%Norway%'
And vac.people_fully_vaccinated is not null
)

SELECT *, (rolling_people_vaccinated/population)*100 as Percent_Fully_Vaccinated
FROM People_Vaccinated


--Create Temp Table

DROP TABLE if exists #Percent_People_Vaccinated
CREATE TABLE #Percent_People_Vaccinated
(
location nvarchar(255),
date datetime,
population numeric,
people_fully_vaccinated numeric,
rolling_people_vaccinated numeric,
)
INSERT INTO #Percent_People_Vaccinated
Select dea.location, dea.date, dea.population, vac.people_fully_vaccinated,
Sum(Convert(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.population ORDER BY  cast(dea.date as datetime)) as rolling_people_vaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..CovidVacHDI$ vac
 on dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
And dea.location like '%Norway%'
And vac.people_fully_vaccinated is not null


SELECT *, (rolling_people_vaccinated/population)*100 as Percent_Fully_Vaccinated
FROM #Percent_People_Vaccinated

--Create View
CREATE VIEW Percent_People_Vaccinated 
AS
Select dea.location, dea.date, dea.population, vac.people_fully_vaccinated,
Sum(Convert(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.population ORDER BY  cast(dea.date as datetime)) as rolling_people_vaccinated
From CovidProject..coviddeaths$ dea
Join CovidProject..CovidVacHDI$ vac
 on dea.location = vac.location
 and dea.date = vac.date
Where dea.continent is not null
And dea.location like '%Norway%'
And vac.people_fully_vaccinated is not null

SELECT *
FROM Percent_People_Vaccinated