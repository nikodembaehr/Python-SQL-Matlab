--Part 2
--q1
--q1a
select empfname, empsalary
into #xemp
from xemp
where (empfname like '%a%' or empfname like '%d') and (deptname in ('Marketing', 'Management','Accounting'))
order by empfname
--q1b
UPDATE #xemp
SET empsalary = empsalary * 1.1
WHERE empsalary > 25000;
--q1c
select *
from #xemp
--d
drop table #xemp




--q2
--q2a
SELECT xitem.*, xsale.saleno, xsale.saleqty, xsale.deptname 
INTO #cartesian_temp
FROM xsale
CROSS JOIN xitem;

--q2b
DELETE FROM #cartesian_temp
WHERE itemcolor = 'bamboo' OR deptname = 'books';

--q2c
SELECT * 
FROM #cartesian_temp;

--q2d
DROP TABLE #cartesian_temp;




--q3
--q3a

select distinct itemname
from xsale
where (itemname in (select itemname
from xitem
where itemcolor = 'green' ) ) and
(deptname in (select deptname
from xdept
where deptfloor != '1'));
--q3b chat gpt

SELECT DISTINCT xs.itemname
FROM xsale xs
WHERE EXISTS (
    SELECT 1
    FROM xitem xi
    WHERE xi.itemname = xs.itemname
      AND xi.itemcolor = 'green'
) AND EXISTS (
    SELECT 1
    FROM xdept xd
    WHERE xd.deptname = xs.deptname
      AND xd.deptfloor != '1'
);

  
--q3c
select distinct itemname
from xitem
inner join xdept 
on ((xdept.deptfloor not in ('1')) and (itemcolor='Green') );


--q4 
--q4a
select avg(empsalary) as avg_salary, 1 as id
into #avg_marketing_table
from xemp
where deptname like 'Marketing'
--q4b
select avg(empsalary) as avg_salary, 1 as id
into #avg_purchasing_table
from xemp
where deptname like 'Purchasing'

select *
from #avg_purchasing_table

select *
from #avg_marketing_table

SELECT
    ABS(m.avg_salary - p.avg_salary) AS dif_salary
INTO #dif_salary_table
FROM
    #avg_marketing_table m
JOIN
    #avg_purchasing_table p
ON
    m.id = p.id;

select * 
from #dif_salary_table

drop table #dif_salary_table
drop table #avg_marketing_table
drop table #avg_purchasing_table;





--q5 
--q5a
SELECT *
into #alice
from xemp
where empfname = 'Alice';

select xemp.empfname
from xemp , #alice
where xemp.bossno = #alice.empno
order by xemp.empfname

drop table #alice
--q5b

select *
into #nancy
from xemp
where empfname = 'Nancy'

select xemp.*
into #boss
from xemp , #nancy
where xemp.empno = #nancy.bossno

SELECT x.empsalary
from #boss as b , xemp as x
where x.empno = b.bossno

drop table #nancy
drop table #boss

--q5c 


SELECT 
    e.empfname AS "Employee",
    emp_dept.deptname AS "Employee Department",
    m.empfname AS "Manager",
    mgr_dept.deptname AS "Manager Department"
FROM 
    xemp AS e
JOIN 
    xdept AS emp_dept ON e.deptname = emp_dept.deptname
JOIN 
    xemp AS m ON e.bossno = m.empno
JOIN 
    xdept AS mgr_dept ON m.deptname = mgr_dept.deptname
WHERE 
    e.deptname != m.deptname;

--q5d
SELECT
e.empno , e.empfname as "Employee" , e.empsalary - m.empsalary as "diffrence"
from 
xemp as e
JOIN 
    xemp AS m ON e.bossno = m.empno
WHERE
e.empsalary> m.empsalary;

--q5e
select
e.empfname as "Employee" , e.empsalary as "salary" , m.empfname as "manager"
from 
xemp as e
JOIN
xemp as m on e.bossno = m.empno
where e.deptname = 'Accounting' and e.empsalary > 20000;





--q6
select xdel.*, xspl.splname
into #itemcount
from xdel
left join xspl on xspl.splno = xdel.splno;

select splno, splname, count(distinct itemname) as total
from #itemcount
group by splno, splname
having  count(distinct itemname) >= 6
order by count(distinct itemname) asc;

drop table #itemcount;



--q7
select distinct e.* , i.*
from xemp as e
JOIN xdept as d 
on e.empno = d.empno
JOIN xsale as s
on d.deptname = s.deptname
join xitem as i 
on s.itemname = i.itemname
join xdel as del 
on i.itemname = del.itemname
join xspl as p
on del.splno = p.splno
where i.itemname = 'Compass' and e.deptname = 'Marketing';



--q8 
select e.empno, e.empfname, count(b.empno) as direct_employees
into #man
from xemp as b
left join xemp as e
on b.bossno = e.empno
group by e.bossno, e.empno, e.empfname;
select *
from #man
where direct_employees = (select min(direct_employees) from #man);

drop table #man;



--q9 
--q9a
select empfname, empsalary
into #better_than_books
from xemp
where empsalary >=(select max(empsalary)
from xemp
where deptname like 'Books')
order by empsalary
--q9b
SELECT *, NULL AS salary_rank
INTO #ranked_temp_table
FROM #better_than_books
order by empsalary;

-- Add a salary ranking to the copied table using a CTE
;WITH CTE AS (
    SELECT *, DENSE_RANK() OVER (ORDER BY empsalary DESC) AS rank
    FROM #ranked_temp_table
)
UPDATE CTE
SET salary_rank = rank;

select *
from #ranked_temp_table
order by salary_rank
--q9c
select top 5 *
from #ranked_temp_table
order by salary_rank
--q9d
drop table #better_than_books
drop table #ranked_temp_table





--q10 
--q10a
select deptname
from xemp
group by deptname
having avg(empsalary)>15000
intersect
select deptname
from xsale
where itemname = 'Pith helmet' or itemname= 'sextant';

--q10b

select deptname
from xemp
group by deptname
having avg(empsalary)>15000
    and deptname in (select deptname
    from xsale
    where itemname in ('Pith helmet' , 'sextant'));

--q11
--q11a
select splname
from xspl
where splno  in (
        select splno
        from xdel
        where itemname not like 'Tent - 2 person')
        

--q11b
SELECT distinct xs.splname
FROM xspl AS xs
LEFT JOIN xdel AS xd ON xs.splno = xd.splno
WHERE xd.itemname NOT LIKE 'Tent - 2 person'; 





--q12 
CREATE FUNCTION getFirstWord (@itemname NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @first_word NVARCHAR(MAX)
    SET @first_word = CASE
        WHEN CHARINDEX(' ', @itemname) > 0 THEN
            SUBSTRING(@itemname, 1, CHARINDEX(' ', @itemname) - 1)
        ELSE
            @itemname
    END
    RETURN @first_word
END;



CREATE FUNCTION getFirstWordGPT(@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @firstWord NVARCHAR(MAX);
    
    SET @inputString = LTRIM(RTRIM(@inputString)); -- Trim leading and trailing spaces
    
    IF CHARINDEX(' ', @inputString) > 0
    BEGIN
        SET @firstWord = SUBSTRING(@inputString, 1, CHARINDEX(' ', @inputString) - 1);
    END
    ELSE
    BEGIN
        SET @firstWord = @inputString;
    END
    
    RETURN @firstWord;
END;

select xitem.*, dbo.getFirstWord(itemname) as itemname_firstword
from xitem

select xitem.*, dbo.getFirstWordGPT(itemname) as itemname_firstword

from xitem




--q13

select deptname , avg(empsalary) as "Average salary"
into #avgsal
from xemp
group by deptname

select *
from #avgsal
where [Average salary] = (select min("Average salary") from #avgsal);

drop table #avgsal;




--q14
--q14a
select itemname
from xdel
where deptname = 'Navigation'
union 
select itemname
from xdel
where splno in (select splno 
from xspl
where splname = 'All sports manufacturing');

--q14b
select distinct itemname
from xdel
where deptname = 'Navigation'
or
splno in (select splno 
from xspl
where splname = 'All sports manufacturing');



--q 15 
--q15a
select delno , itemname into #tab
from xdel
where splno in (select splno 
from xspl
where splname = 'All sports manufacturing')
except 
select delno , itemname
from xdel
where deptname = 'Navigation'
select itemname
from #tab;
drop table #tab



--q15b
select distinct itemname
from xdel
where
splno in (select splno 
from xspl
where splname = 'All sports manufacturing')
and
deptname != 'Navigation';





--Q16 
select xdel.itemname
into #exceptions
from xdel, xitem
where (deptname not in ( 
                select deptname
                from xdept
                where deptfloor!=3) and xitem.itemtype = 'C')

select *
from #exceptions

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'false, not all type C products are sold on the third floor'
        ELSE 'true, all type C products are sold on the third floor'
    END AS Result
from #exceptions


--ex 17
select  itemname
FROM xdel 
where deptname not in ( 'Accounting','Marketing', 'Management', 'Personnel', 'Purchasing')
group by itemname

having (select count(distinct deptname)
        from xdept
            where deptname not in ( 'Accounting', 'Marketing', 'Management', 'Personnel', 'Purchasing')) = count(distinct deptname);



--ex18  
select *
from xsale
full outer join xsale_copy 
on xsale.itemname = xsale_copy.itemname
where xsale.itemname is null or xsale_copy.itemname is null;
