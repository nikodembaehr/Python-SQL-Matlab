--a
select cluster_id, count(*) AS n_pubs
from  patstat_golden_set
group by cluster_id
order by n_pubs DESC;


--b


SELECT cluster_id, COUNT(*) AS n_pubs, COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS probability
FROM patstat_golden_set
GROUP BY cluster_id
ORDER BY n_pubs DESC;
--C
SELECT cluster_id, COUNT(*) AS n_pubs, COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS probability
into #result
FROM patstat_golden_set
GROUP BY cluster_id
ORDER BY n_pubs DESC;
--d

ALTER TABLE #result
ADD nomalized_n_pub float;

SELECT cluster_id, (n_pubs - AVG(n_pubs) OVER()) / STDEV(n_pubs) OVER() AS nomalized_n_pubs
into #temp
FROM #result;


UPDATE #result
SET nomalized_n_pub = #temp.nomalized_n_pubs
FROM #temp
WHERE #result.cluster_id = #temp.cluster_id;

SELECT *
from #result
order by n_pubs DESC;

drop table #temp 

--e 
drop table #result

