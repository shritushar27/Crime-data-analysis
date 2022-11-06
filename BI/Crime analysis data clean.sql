--creating DIM_STATE

create table DIM_STATE (
STATE_ID int identity(1,1) primary key,
STATE_NAME varchar(50)
)

--Inserting DIM_STATE

insert into DIM_STATE(STATE_NAME) select state_ut from [dbo].[crime_by_district] group by STATE_UT;

--removing unwanted data

delete from DIM_STATE where state_id = 24

delete from DIM_STATE where state_id = 13

--creating DIM_DISTRICT

create table DIM_DISTRICT(
DISTRICT_ID int,
DISTRICT_NAME varchar(50),
STATE_ID int FOREIGN KEY REFERENCES DIM_STATE(STATE_ID)
)

--inserting DIM_DISTRICT

insert into DIM_DISTRICT (DISTRICT_ID, DISTRICT_Name, STATE_ID)
select  DENSE_RANK() over(order by district, state_ut) as district_id, district,state_id from [dbo].[crime_by_district]
join DIM_STATE on [dbo].[crime_by_district].STATE_UT = DIM_STATE.STATE_NAME where district != 'TOTAL'

--creating FACT_STATE

create table FACT_STATE (state_id int, year int, count_Murder int, count_Assault_on_women int, count_Kidnapping int,
count_Dacoity int, count_Robbery int, count_Arson int, count_Hurt int, count_POA int, count_PCR int,
count_Other_Crimes int
)

--inserting FACT_STATE

insert into FACT_STATE
select f1.state_id, f2.Year, sum(f2.Murder), sum( f2.Assault_on_women), sum(f2.Kidnapping_and_Abduction), sum(f2.Dacoity), sum(f2.Robbery), sum(f2.Arson),
sum(f2.Hurt), sum(f2.Prevention_of_atrocities_POA_Act), sum(f2.Protection_of_Civil_Rights_PCR_Act), sum(f2.Other_Crimes_Against_SCs) from DIM_STATE as f1 inner join
[dbo].[crime_by_district] as f2 on f1.state_name = f2.state_ut group by f1.State_Id, f2.year

--creating FACT_DISTRICT

create table FACT_DISTRICT (state_id int, district_id int ,year int, count_Murder int, count_Assault_on_women int, count_Kidnapping int,
count_Dacoity int, count_Robbery int, count_Arson int, count_Hurt int, count_POA int, count_PCR int,
count_Other_Crimes int
)

--Inserting FACT_DISTRICT

insert into FACT_DISTRICT
select s1.state_id,s1.District_Id,s2.year,s2.[Murder],s2.[Assault_on_women], s2.[Kidnapping_and_Abduction],
s2.[Dacoity],s2.[Robbery],s2.[Arson],s2.[Hurt],s2.[Prevention_of_atrocities_POA_Act],
s2.[Protection_of_Civil_Rights_PCR_Act], s2.[Other_Crimes_Against_SCs]
from DIM_DISTRICT as s1 inner join [dbo].[crime_by_district] as s2 on s1.District_Name = s2.DISTRICT
group by District_Id,State_Id,Year,Murder,Assault_on_women,Kidnapping_and_Abduction,Dacoity,Robbery,Arson,
Hurt,Prevention_of_atrocities_POA_Act,Protection_of_Civil_Rights_PCR_Act,Other_Crimes_Against_SCs

--creating table TOTAL_CRIME_BY_DISTRICT

create table Total_crimes_by_district(
Total_crimes_by_district int,
district_id int,
state_id int,
)

--inserting data 

insert into Total_crimes_by_district
select sum(count_Murder) + sum(count_Assault_on_women) + sum(count_Kidnapping) + sum(count_Dacoity) + sum(count_Robbery) +
sum(count_Arson) + sum(count_Hurt) + sum(count_POA) + sum(count_PCR) + sum(count_Other_Crimes) as Total_crimes_by_district,
district_id, state_id 
from fact_district group by district_id, state_id order by  state_id

--creating min and max crime table for district 

create table min_crime(
min_total_crime int,
state_id int,
)

create table max_crime(
max_total_crime int,
state_id int,
)

--inserting data

insert into min_crime
select min(Total_crimes_by_district) as min_total_crime, state_id from Total_crimes_by_district group by state_id 
order by state_id


insert into max_crime
select max(Total_crimes_by_district) as max_total_crime, state_id from Total_crimes_by_district group by state_id 
order by state_id

--query for BI for creating table for question 3-4

select f1.district_id, f2.min_total_crime from Total_crimes_by_district as f1 inner join min_crime as f2
on f1.state_id = f2.state_id where f1.Total_crimes_by_district = f2.min_total_crime

select f1.district_id, f2.max_total_crime from Total_crimes_by_district as f1 inner join max_crime as f2
on f1.state_id = f2.state_id where f1.Total_crimes_by_district = f2.max_total_crime and f2.max_total_crime >= 30

--creating some calculated tables 
--creating avg crime by district table

create table avg_crime(
Total_crimes_by_state int, 
state_id int,
state_name varchar(50),
)

--inserting data

insert into avg_crime
select sum(f1.count_Murder) + sum(f1.count_Assault_on_women) + sum(f1.count_Kidnapping) + sum(f1.count_Dacoity) + sum(f1.count_Robbery) +
sum(f1.count_Arson) + sum(f1.count_Hurt) + sum(f1.count_POA) + sum(f1.count_PCR) + sum(f1.count_Other_Crimes) as Total_crimes_by_state, f1.state_id, f2.state_name 
from FACT_STATE as f1 inner join DIM_STATE as f2 on f2.STATE_ID = f1.state_id
group by f1.state_id, f2.STATE_NAME order by f1.state_id asc

--query for BI for creating table for question 1-2

select state_name,state_id,Total_crimes_by_state from avg_crime where Total_crimes_by_state < (select AVG(Total_crimes_by_state) from avg_crime)

select state_name,state_id,Total_crimes_by_state from avg_crime where Total_crimes_by_state > (select AVG(Total_crimes_by_state) from avg_crime)


