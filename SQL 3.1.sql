-- Question 19:
-- a
select cluster_id, count(npl_publn_id) as n_pubs
from Patstat_golden_set
group by cluster_id
order by n_pubs desc
-- b
-- Here we use a subquery to count all the publications to use them as divider in calculation of the probability
select cluster_id, count(npl_publn_id) as n_pubs, ((count(*) * 100.0) / (select count(*) as total_pubs from Patstat_golden_set)) as probability
from Patstat_golden_set
group by cluster_id
order by n_pubs desc
-- c
select cluster_id, count(npl_publn_id) as n_pubs, ((count(*) * 100.0) / (select count(*) as total_pubs from Patstat_golden_set)) as probability
into #result
from Patstat_golden_set
group by cluster_id
order by n_pubs desc
-- d
-- We add the column normalized_n_pubs to table #result and specify its type to be float
alter table #result
add nomalized_n_pubs float
-- We use a subqueries to update this value 
update #result
set nomalized_n_pubs = (n_pubs - (select avg(n_pubs) from #result)) / (select stdev(n_pubs) from #result)
-- e
drop table #result