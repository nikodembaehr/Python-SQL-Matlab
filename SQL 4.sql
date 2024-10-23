CREATE TABLE g17school ( 
    school_name VARCHAR(50) PRIMARY KEY,
    school_address VARCHAR(100),
    school_size INT,
    school_tel INT,
    year_built INT
)

create table g17teacher (
    Employee_numb int IDENTITY(1,1),
    school_name nchar(255) not null,
    Supervisor int,
    Subject_spec nchar(255),
    Teacher_name nchar(255),
    Age int,
    Year_enter_sys int,
    primary key (Employee_numb)
)

create table g17admin (
    Employee_numb int not null,
    school_name nchar(255) not null,
    Admin_name nchar(255),
    Tel_numb nchar(255),
    Office int,
    Position nchar(255),
    primary key (Employee_numb)
)

create table g17teach_worked (
    Employee_numb int not null,
    school_name nchar(255) not null,
    started int,
    topsalary money,
    primary key (Employee_numb)
)

create table g17students (
    stn int not null IDENTITY(1,1),
    school_name nchar(255) not null,
    Student_name nchar(255),
    Age int,
    Home_address nchar(255),
    grade int,
    Email nchar(255),
    primary key (stn)
)

create table g17rec (
    stn int not null,
    school_name nchar(255) not null,

    Employee_numb nchar(255),
    subj_numb int,
    grade int,
    yr int,
    primary key (stn)
)

create table g17subj (
    subj_numb int not null IDENTITY(1,1),
    Employee_numb int not null,
    subj_name nchar(255),
    Grade_lev int,
    year_intro int,
    primary key (subj_numb)
)

create table g17uni (
    uni_name nchar(255) not null,
    uni_Address nchar(255),
    website nchar(255),
    yr_founded int,
    primary key (uni_name)
)

create table g17teachedu (
    uni_name nchar(255) not null,
    Employee_numb int not null,
    Teacher_name nchar(255),
    Deg nchar(255),
    yr_gradu int
)

insert into g17Teachers
values 
(  'Tilburg', 2 , 'Math','Edward', 35, 2001),
(  'Rot', 2 , 'Eng','Peter', 55, 2001 ),
(  'Ams', 2 , 'Lit','Hue', 88, 2009 );

insert into g17school
values 
(  'Tilburg', 'im street 1' , 90 , 11122323, 1992),
(  'Rot' , 'im street 2',100, 56456823, 1763 ),
(  'Ams' , 'im street 3',50, 45677634, 1649 );

insert into g17admin
values 
( 2, 'Tilburg', 'Peter' , 123434 , 2 , 'president');

insert into g17teach_worked
values 
( 2, 'Tilburg', 1982 , 700 ),
( 1, 'Tilburg', 1982 , 800 ),
( 3, 'Tilburg', 2009 , 10000 );

insert into g17students
values 
('Tilburg','Dans',21,'Im way',3,'d@days.com'),
('Tilburg','Rai',21,'Im way 3',3,'r@days.com'),
('Ams','Petr',18,'Im way 89',3,'Pe@days.com');

insert into g17rec
values 
(1,'Tilburg',1, 1, 3, 2009),
(2,'Tilburg',2,2,3,2005),
(3,'Ams',1,2,1,1999);

insert into g17uni
values 
('', 'Str1', 'highuni.edu',1420),
('Low', 'Str5', 'low.edu',1999),
('Mid', 'Str90', '90mid.edu',2008);

insert into g17teachedu
values 
('High', 1, 'Jane','Math',1908),
('Low', 2, 'Opa','phys',1999),
('Mid', 3, 'Gorge','geo',2008);

select *
from g17Teachers

select Teacher_name
from g17Teachers
where Supervisor=2

#seeing the information of the university where teacher with employee number 2 attended 
select *
from g17uni
where uni_name=(select uni_name
from g17teachedu
where Employee_numb=2
)

drop table g17teach_worked
drop table g17uni
drop table g17Teachers
drop table g17teachedu
drop table g17subj
drop table g17students
drop table g17school
drop table g17admin
drop table g17rec



