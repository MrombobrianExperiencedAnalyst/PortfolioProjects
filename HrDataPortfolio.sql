CREATE DATABASE hr;
use hr;

select *
from hr_data;

select termdate
from hr_data
order by termdate desc;

update hr_data
set termdate = format(convert(datetime, left(termdate, 19), 120), 'yyyy-MM-dd');

alter table hr_data
add new_termdate date;

-- copy converted time values from termdate to new_termdate

update hr_data
set new_termdate = case
	when termdate is not null and isdate(termdate) = 1 then cast (termdate as datetime ) else null end;

-- create a new column "age"
alter table hr_data
add age nvarchar(50);

--populate new column with age
update hr_data
set age = DATEDIFF(year, birthdate, getdate());

select age 
from hr_data


-- QUESTIONS TO ANSWER FROM THE DATA

-- 1) What's the age distribution in the company?

-- age distribution

select 
 min(age) as youngest,
 max(age) as oldest
from hr_data


select age_group,
count(*) as count
from
(select 
 case
 when age <= 22 and age <= 30 then '22 to 30'
 when age <= 31 and age <= 40 then '31 to 40'
  when age <= 41 and age <= 50 then '41 to 50'
  else '50+'
  end as age_group
from hr_data
where new_termdate is null
) as subquery
group by age_group
order by age_group;


-- Age group by gender
select age_group,
gender,
count(*) as count
from
(select 
 case
 when age <= 22 and age <= 30 then '22 to 30'
 when age <= 31 and age <= 40 then '31 to 40'
  when age <= 41 and age <= 50 then '41 to 50'
  else '50+'
  end as age_group,
  gender
from hr_data
where new_termdate is null
) as subquery
group by age_group, gender
order by age_group, gender;



-- 2) What's the gender breakdown in the company?

select 
gender, 
count(gender) as count
from hr_data
where new_termdate is null
group by gender
order by gender asc;


-- 3) How does gender vary across departments and job titles?

select 
department, 
gender,
count(gender) as count
from hr_data
where new_termdate is null
group by department, gender
order by department, gender asc;

-- job titles
select 
department, jobtitle,
gender,
count(gender) as count
from hr_data
where new_termdate is null
group by department, jobtitle, gender
order by department, jobtitle, gender asc;





-- 4) What's the race distribution in the company?

select
race, 
count(*) as count
from 
hr_data
where new_termdate is null
group by race
order by count desc;





-- 5) What's the average length of employment in the company?

select 
avg(DATEDIFF(year, hire_date, new_termdate)) as tenure
from hr_data
where new_termdate is not null and new_termdate <= getdate();


-- 6) Which department has the highest turnover rate?
-- get total count
-- get terminated count
-- terminated count/total count
select 
department,
total_count,
terminated_count,
round((terminated_count/cast(total_count as float)), 2)* 100 as turnover_rate
from
	(select 
	department, 
	count(*) as total_count,
	sum(case
		when new_termdate is not null and new_termdate <= getdate() then 1 else 0
		end
	) as terminated_count
	from hr_data
	group by department 
) as subquery
order by turnover_rate desc;


-- 7) What is the tenure distribution for each department?


select 
department,
avg(DATEDIFF(year, hire_date, new_termdate)) as tenure
from hr_data
where new_termdate is not null and new_termdate <= getdate()
group by department
order by tenure desc;




-- 8) How many employees work remotely for each department?

select 
 location,
count(*) as count
from hr_data
where new_termdate is null
group by location;


-- 9) What's the distribution of employees across different states?

select 
 location_state,
 count(*) as count
from hr_data
where new_termdate is null
group by location_state
order by count desc;



-- 10) How are job title distributed in the company?

select 
 jobtitle,
 count(*) as count
from hr_data
where new_termdate is null
group by jobtitle
order by count desc;



-- 11) How have employee hire counts varied over time?
-- calculate hires
-- calculate terminations
-- (hires-terminations)/hires percent hire change
select 
 hire_year,
 hires,
 terminations,
 hires - terminations  as net_change,
(round(cast(hires - terminations as float)/hires, 2))* 100 as percent_hire_change
 from 
	(select 
	 year(hire_date) as hire_year,
	 count(*) as hires,
	 sum( case 
			when new_termdate is not null and new_termdate <= getdate() then 1 else 0
			end 
			) as terminations
	from hr_data
	group by year(hire_date)
	) as subquery
order by percent_hire_change asc;
