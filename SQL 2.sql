--Part 2

--Q1
---Q1a
select empfname as name, empsalary as salary, xemp.empno
into #xemp
from xemp
where (rtrim(right(empfname,1))='d' or empfname like '%a%') and deptname in ('Management','Marketing','Purchasing') --- Ends with d or has an a + works in the right department
and bossno is not null ---Boss exists
order by name;

---Q1b
update #xemp
set  salary = salary * 1.05
where salary >= 25000;

---Q1c
select *
from #xemp

---Q1d
delete from #xemp
where salary <= 25000;

---Q1e
drop table #xemp

--Q2
---a
select distinct i.itemname
from xitem i
inner join xsale as s on i.itemname=s.itemname
where itemcolor='brown' and deptname in (select deptname
										from xdept
										where deptfloor=2);

---b
select distinct i.itemname
from xitem as i
where itemcolor='brown' and itemname in (select s.itemname
										from xsale as s
										where s.deptname in (select d.deptname
															from xdept as d
															where d.deptfloor=2));

---c
select distinct i.itemname
from xitem i
where i.itemcolor = 'brown' and exists (select *
										from xsale as s
										where s.itemname = i.itemname and exists (select *
																					from xdept as d
																					where d.deptname = s.deptname AND d.deptfloor = 2));

--Q3
select distinct d.deptname
from xdept as d
inner join xsale as s on d.deptname=s.deptname
where d.deptname not in (select s.deptname
						from xsale as s
						where s.itemname='compass');

--Q4
select distinct e.*, i.*
from xemp as  e, xitem as i
inner join xsale as s on i.itemname = s.itemname
inner join xdept as d on s.deptname = d.deptname
inner join xdel as del on i.itemname = del.itemname and d.deptname = del.deptname
inner join xspl as spl on del.splno = spl.splno
where e.deptname = 'marketing' and i.itemname = 'compass';

--Q5
---a
select 1 as id, avg_salary=(sum(empsalary)/count(empsalary))
into #avg_marketing_table
from xemp
where deptname='marketing'

---b
select 1 as id, avg_salary=(sum(empsalary)/count(empsalary))
into #avg_purchasing_table
from xemp
where deptname='purchasing'

---
select dif_salary=(m.avg_salary - p.avg_salary)
from #avg_marketing_table as m
inner join #avg_purchasing_table as p on m.id=p.id
---d
select dif_salary=(m.avg_salary - p.avg_salary)
into #dif_salary_table
from #avg_marketing_table as m
inner join #avg_purchasing_table as p on m.id=p.id

---e
drop table #avg_purchasing_table, #avg_marketing_table, #dif_salary_table

--Q6
---a
select empsalary
from xemp
where empno=(select bossno
			from xemp
			where empno=(select bossno
						from xemp
						where empfname='Nancy'));

---b
select empfname
from xemp
where bossno=(select empno
				from xemp
				where empfname='Andrew');

---c
select distinct e1.empfname as employees, e1.deptname as employee_department , e2.empfname as managers, e2.deptname as manager_department
from xemp as e1, xemp as e2
where e2.empno=e1.bossno and e1.deptname<>e2.deptname
order by e2.empfname, e1.empfname

---d
select distinct e1.empno as number, e1.empfname as employee, salary_difference=(e1.empsalary - e2.empsalary)
from xemp as e1, xemp as e2
where e2.empno=e1.bossno and (e1.empsalary - e2.empsalary)>0

---e
select distinct e1.empfname as name, e1.empsalary as salary, e2.empfname as manager
from xemp as e1, xemp as e2
where e1.deptname='accounting' and e1.bossno=e2.empno and e1.empsalary>20000;



select empfname as manager
from xemp
where empno in (select bossno
				from xemp
				where deptname='accounting');

--Q7
select sp.splname as suppliers, count(distinct dl.itemname) as total
from xspl as sp
inner join xdel as dl on sp.splno=dl.splno
group by sp.splname
having count(distinct dl.itemname)>4
order by count(distinct dl.itemname) desc

--Q8
select d.deptname, count(s.itemname) as total
from xdept as d
inner join xsale as s on d.deptname=s.deptname
where d.deptfloor in (1,2)
group by d.deptname
having count(s.itemname)>4

--Q9
---a
select e1.empno as number, e1.empfname as name, count(e2.empfname) as direct_employees
from xemp as e1
inner join xemp as e2 on e1.empno=e2.bossno
group by e1.empfname, e1.empno
order by e1.empno, name

---b
select e1.empno as number, e1.empfname as name, count(e2.empfname) as direct_employees
from xemp as e1
inner join xemp as e2 on e1.empno=e2.bossno
group by e1.empfname, e1.empno
having count(e2.empfname)=(select top(1) count(e2.empfname)
							from xemp as e1
							inner join xemp as e2 on e1.empno=e2.bossno
							group by e1.empfname, e1.empno
							order by count(e2.empfname) asc)

--Q10
---a
-- Step a: Store result in a temporary table
select empfname as name, empsalary
into #xemp
from xemp
where empsalary > (select max(empsalary)
					from xemp
					where deptname = 'clothes')
order by empsalary asc;


---b
select name, empsalary, 
       rank() over (order by empsalary desc) as salary_rank
into #xemp_ranking
from #xemp;


---c
select name, empsalary, salary_rank
from #xemp_ranking
where salary_rank <= 3
order by salary_rank;

--- d
drop table if exists #xemp;
drop table if exists #xemp_ranking;


--Q11
---a
select deptname
from xdept
where deptname in (select deptname
					from xemp
					group by deptname
					having avg(empsalary) > 10000)	and deptname in (select deptname
																		from xsale s
																		join xitem i on s.itemname = i.itemname
																		where i.itemname in ('compass', 'elephant polo stick'));

---b
select deptname
from (select deptname
		from xemp
		group by deptname
		having avg(empsalary) > 10000) as dept_salaries

intersect

select deptname
from xsale s
join xitem i on s.itemname = i.itemname
where i.itemname in ('compass', 'elephant polo stick');

--Q12
---a
select splname as suppliers
from xspl
where splno not in (select splno
					from xdel
					where itemname='stetson');

---b
select distinct sp.splname as suppliers
from xspl sp
left join xdel del on sp.splno = del.splno and del.itemname = 'stetson'
where del.splno is null;


--Q13
---a
create function getfirstword (@input varchar(200))
returns varchar(50)
as
begin
    declare @result varchar(50);
    set @result = substring(@input, 1, charindex(' ', @input + ' ') - 1);
    return @result;
end;
go 


select *, dbo.getfirstword(itemname) as itemname_firstword
from xitem;
---b
create function getfirstword (@itemname nvarchar(255))
returns nvarchar(255)
as
begin
    return left(@itemname, charindex(' ', @itemname + ' ') - 1);
end;

---c
--- "How can I write a SQL query that lists all columns from the 'xitem' table, together with a new column 'itemname_firstword', which extracts only the first word from the 'itemname' column?"

--Q14
---a
select top(1) deptname, avg(empsalary) as average_salary
from xemp as e
group by deptname
order by avg(empsalary)

---b
select top(1) deptname, avg(empsalary) as average_salary
from xemp as e
group by deptname
order by avg(empsalary) desc

---c
select top(1) deptname, avg(empsalary) as average_salary
into #result
from xemp
group by deptname
order by avg(empsalary) desc;

insert into #result (deptname, average_salary)
select top(1) deptname, avg(empsalary) as average_salary
from xemp
group by deptname
order by avg(empsalary);

---d
drop table if exists #result


--Q15
---a
select i.itemname
from xitem as i
inner join xdel as d on i.itemname = d.itemname
where d.splno = (select sp.splno
				from xspl as sp
				where sp.splname = 'Nepalese Corp.')

union

select i.itemname
from xitem as i
inner join xsale as s on i.itemname = s.itemname
where s.deptname = 'Clothes';

---b
select distinct i.itemname
from xitem as i
left join xdel as d on i.itemname = d.itemname
left join xsale as s on i.itemname = s.itemname
where (d.splno = (select sp.splno
					from xspl as sp
					where sp.splname = 'Nepalese Corp.') or s.deptname = 'Clothes');


--Q16
---a
select distinct del.itemname
from xdel as del
where del.splno=(select sp.splno
					from xspl as sp
					where sp.splname='Nepalese Corp.') 
					
except

select distinct del.itemname
from xdel as del
where del.deptname='Clothes' and del.splno=(select sp.splno
											from xspl as sp
											where sp.splname='Nepalese Corp.')

---b
select distinct del.itemname
from xdel as del
where del.deptname<>'Clothes' and del.splno=(select sp.splno
											from xspl as sp
											where sp.splname='Nepalese Corp.') 

--Q17
select
  case
    when not exists (select 1
					from xsale as s
					inner join xdept as d on s.deptname = d.deptname
					inner join xitem as i on s.itemname = i.itemname
					where i.itemtype = 'c' and d.deptfloor <> 3 ) then 1  -- if this department does not exists return 1
    else 0 
  end as departments;

--Q18
---a
select i.itemname as i_itemname, i.itemtype, i.itemcolor, s.itemname as s_itemname, s.saleno, s.saleqty, s.deptname
into #cartesian_temp
from xsale as s
cross join xitem as i;

---b
select distinct *
into #unique_records
from #cartesian_temp;

---c
select *
into #duplicate_records
from #cartesian_temp
except
select *
from #unique_records;


select *
from #cartesian_temp

select *
from #unique_records

select *
from #duplicate_records

---d
drop table if exists #cartesian_temp;
drop table if exists #unique_records;
drop table if exists #duplicate_records;
