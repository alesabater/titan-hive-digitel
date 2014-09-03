#En hive console
add jar /usr/lib/hive/lib/hive-contrib-0.11.0.1.3.2.0-111.jar;
CREATE TEMPORARY FUNCTION rowSequence AS 'org.apache.hadoop.hive.contrib.udf.UDFRowSequence';

--SELECT COUNT(*) FROM vertex_temp1; = 14749


DROP TABLE audit_status_notnulls;
CREATE TABLE datos_digitel.audit_status_notnulls AS
SELECT * FROM datos_digitel.audit_status_sinnulls 
WHERE 
actiontime <> '' AND actiontime IS NOT NULL 
AND statechange <> '' AND statechange IS NOT NULL
AND firstoccurrence <> '' AND firstoccurrence IS NOT NULL
AND lastoccurrence <> '' AND lastoccurrence IS NOT NULL
AND internallast <> '' AND internallast IS NOT NULL
AND alertkey <> '' AND alertkey IS NOT NULL
AND provider <> '' AND provider IS NOT NULL
AND UPPER(provider) IN ('ERICSSON','NOKIA','HUAWEI','ZTE','DIGITEL412')
AND severity IN (0,1,2,3,4,5);

SELECT count(*) from audit_status_notnulls; 


-- vertices con la cantidad de repeticiones
DROP TABLE datos_digitel.vertex_temp2;

CREATE TABLE datos_digitel.vertex_temp2
AS
SELECT mq.vertex AS vertex_name, SUM(mq.vertex_count) AS vertex_count, mq.provider AS vertex_provider
FROM (  SELECT CASE WHEN (graph1.elementparent IS NULL) THEN 'NULL_NODE' WHEN (graph1.elementparent = '') THEN 'EMPTY_NODE' ELSE graph1.elementparent END AS vertex,
                count(graph1.elementparent) AS vertex_count,
                graph1.provider AS provider
        FROM audit_status_notnulls graph1
        GROUP BY graph1.elementparent, graph1.provider
        UNION ALL
        SELECT CASE WHEN (graph2.elementname IS NULL) THEN 'NULL_NODE' WHEN (graph2.elementname = '') THEN 'EMPTY_NODE' ELSE graph2.elementname END AS vertex,
        count(graph2.elementname) AS vertex_count,
        graph2.provider AS provider
        FROM audit_status_notnulls graph2
        GROUP BY graph2.elementname, graph2.provider
) mq GROUP BY mq.vertex, mq.provider;
--SELECT COUNT(*) FROM vertex_temp2; = 15924 


DROP TABLE datos_digitel.vertex_temp3;

CREATE TABLE datos_digitel.vertex_temp3
AS
SELECT DISTINCT mq.vertex as vertex_name
FROM (
    SELECT CASE WHEN (graph1.elementparent IS NULL) THEN 'NULL_NODE'
                WHEN (graph1.elementparent = '') THEN 'EMPTY_NODE'
                ELSE graph1.elementparent END AS vertex
                FROM audit_status_notnulls graph1
    UNION ALL
    SELECT CASE WHEN (graph2.elementname IS NULL) THEN 'NULL_NODE'
                WHEN (graph2.elementname = '') THEN 'EMPTY_NODE'
                ELSE graph2.elementname END AS vertex
                FROM audit_status_notnulls graph2
) mq ORDER BY vertex_name;
--SELECT COUNT(*) FROM vertex_temp3; = 15766 

-- Vertices con la informaciÃ³n del proveedor
DROP TABLE datos_digitel.vertex;


CREATE TABLE datos_digitel.vertex
AS
SELECT rowSequence() AS vertex_id, n.vertex_name, n.vertex_count AS vertex_count
FROM datos_digitel.vertex_temp2 n;
--SELECT COUNT(*) FROM vertex; = 15766 


DROP TABLE datos_digitel.vertex;
CREATE TABLE datos_digitel.vertex
AS
SELECT n.ID AS vertex_id, n.ELEMENT As vertex_name, n.CUENTA AS vertex_count, n.PROVIDER AS vertex_provider
FROM datos_digitel.vertex_temp5 n;
--SELECT COUNT(*) FROM vertex; = 15766 

-- La tabla para bayes
DROP TABLE datos_digitel.edges_temp1;
CREATE TABLE datos_digitel.edges_temp1
AS

SELECT 
    firstoccurrence,elementname, (MAX(unix_timestamp(actiontime))-MIN(unix_timestamp(actiontime)))/60 AS fail_time, count(eventid) AS total
FROM datos_digitel.audit_status_notnulls
GROUP BY firstoccurrence, lastoccurrence, elementname
LIMIT 100;




DROP TABLE datos_digitel.edges;
CREATE TABLE datos_digitel.edges
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  1 AS weight,
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name);

DROP TABLE datos_digitel.edges_final_agosto;
CREATE TABLE datos_digitel.edges_final_agosto
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)>=19;


DROP TABLE datos_digitel.edges_final_agosto_distinct;
CREATE TABLE datos_digitel.edges_final_agosto_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_final_agosto
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_19;
CREATE TABLE datos_digitel.edges_agosto_19
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=19;


DROP TABLE datos_digitel.edges_agosto_19_dintinct;
CREATE TABLE datos_digitel.edges_agosto_19_dintinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_19
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_20;
CREATE TABLE datos_digitel.edges_agosto_20
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=20;


DROP TABLE datos_digitel.edges_agosto_20_distinct;
CREATE TABLE datos_digitel.edges_agosto_20_distinct
AS
SELECT
  *,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_20
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_21;
CREATE TABLE datos_digitel.edges_agosto_21
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=21;


DROP TABLE datos_digitel.edges_agosto_21_dintinct;
CREATE TABLE datos_digitel.edges_agosto_21_dintinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_21
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;

DROP TABLE datos_digitel.edges_agosto_22;
CREATE TABLE datos_digitel.edges_agosto_22
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=22;


DROP TABLE datos_digitel.edges_agosto_22_dintinct;
CREATE TABLE datos_digitel.edges_agosto_22_dintinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_22
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_23;
CREATE TABLE datos_digitel.edges_agosto_23
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=23;


DROP TABLE datos_digitel.edges_agosto_23_dintinct;
CREATE TABLE datos_digitel.edges_agosto_23_dintinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_23
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;

DROP TABLE datos_digitel.edges_agosto_24;
CREATE TABLE datos_digitel.edges_agosto_24
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=24;


DROP TABLE datos_digitel.edges_agosto_24_distinct;
CREATE TABLE datos_digitel.edges_agosto_24_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_24
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_25;
CREATE TABLE datos_digitel.edges_agosto_25
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=25;


DROP TABLE datos_digitel.edges_agosto_25_distinct;
CREATE TABLE datos_digitel.edges_agosto_25_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_25
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_26;
CREATE TABLE datos_digitel.edges_agosto_26
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=26;


DROP TABLE datos_digitel.edges_agosto_26_distinct;
CREATE TABLE datos_digitel.edges_agosto_26_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_26
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;

//


DROP TABLE datos_digitel.edges_agosto_27;
CREATE TABLE datos_digitel.edges_agosto_27
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=27;


DROP TABLE datos_digitel.edges_agosto_27_distinct;
CREATE TABLE datos_digitel.edges_agosto_27_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_27
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;



DROP TABLE datos_digitel.edges_agosto_28;
CREATE TABLE datos_digitel.edges_agosto_28
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=28;


DROP TABLE datos_digitel.edges_agosto_28_distinct;
CREATE TABLE datos_digitel.edges_agosto_28_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_28
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_29;
CREATE TABLE datos_digitel.edges_agosto_29
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=29;


DROP TABLE datos_digitel.edges_agosto_29_distinct;
CREATE TABLE datos_digitel.edges_agosto_29_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_29
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_30;
CREATE TABLE datos_digitel.edges_agosto_30
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=30;


DROP TABLE datos_digitel.edges_agosto_30_distinct;
CREATE TABLE datos_digitel.edges_agosto_30_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_30
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


DROP TABLE datos_digitel.edges_agosto_31;
CREATE TABLE datos_digitel.edges_agosto_31
AS
SELECT 
  v1.vertex_id AS vertex_id_from, 
  v1.vertex_name AS vertex_name_from, 
  v2.vertex_id AS vertex_id_to, 
  v2.vertex_name AS vertex_name_to, 
  v1.vertex_count As vertex_count_from,
  v2.vertex_count As vertex_count_to,
  v1.vertex_provider As vertex_provider_from,
  v2.vertex_provider As vertex_provider_to,
  p.severity AS severity
FROM audit_status_notnulls p
LEFT OUTER JOIN vertex v1 ON (p.elementparent = v1.vertex_name) 
LEFT OUTER JOIN vertex v2 ON (p.elementname = v2.vertex_name)
WHERE month(p.actiontime)=8 AND day(p.actiontime)=31;


DROP TABLE datos_digitel.edges_agosto_31_distinct;
CREATE TABLE datos_digitel.edges_agosto_31_distinct
AS
SELECT
  vertex_id_from,
  vertex_id_to,
  severity,
  COUNT(*) AS instances_count
FROM datos_digitel.edges_agosto_31
GROUP BY vertex_id_from, vertex_id_to, severity
SORT BY vertex_id_from, vertex_id_to, severity;


SELECT COUNT(*) FROM datos_digitel.edges_agosto_19_dintinct-- = 7157
SELECT COUNT(*) FROM datos_digitel.edges_agosto_20_distinct-- = 7952
SELECT COUNT(*) FROM datos_digitel.edges_agosto_21_dintinct-- = 10277
SELECT COUNT(*) FROM datos_digitel.edges_agosto_22_dintinct-- = 8973
SELECT COUNT(*) FROM datos_digitel.edges_agosto_23_dintinct-- = 7065
SELECT COUNT(*) FROM datos_digitel.edges_agosto_24_distinct-- = 6081
SELECT COUNT(*) FROM datos_digitel.edges_agosto_25_distinct-- = 7674
SELECT COUNT(*) FROM datos_digitel.edges_agosto_26_distinct-- = 7083
SELECT COUNT(*) FROM datos_digitel.edges_agosto_27_distinct-- = 9961
SELECT COUNT(*) FROM datos_digitel.edges_agosto_28_distinct-- = 14047
SELECT COUNT(*) FROM datos_digitel.edges_agosto_29_distinct-- = 7794
SELECT COUNT(*) FROM datos_digitel.edges_agosto_30_distinct-- = 6758
SELECT COUNT(*) FROM datos_digitel.edges_agosto_31_distinct-- = 7035
SELECT COUNT(*) FROM datos_digitel.edges_final_agosto_distinct-- = 28644



SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_19_dintinct-- = 305154
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_20_distinct-- = 318718
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_21_dintinct-- = 374168
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_22_dintinct-- = 328007
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_23_dintinct-- = 291793
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_24_distinct-- = 241142
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_25_distinct-- = 247753
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_26_distinct-- = 288022
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_28_distinct-- = 373194
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_29_distinct-- = 280174
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_30_distinct-- = 280000
SELECT SUM(instances_count) FROM datos_digitel.edges_agosto_31_distinct-- = 193849



hive -e "SELECT * FROM datos_digitel.vertex"  > vertex.csv;
hive -e "SELECT * FROM datos_digitel.edges"  > edges.csv
hive -e "SELECT * FROM datos_digitel.edges_final_agosto_distinct"  > edges_final_agosto_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_19_dintinct"  > edges_agosto_19_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_20_distinct"  > edges_agosto_20_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_21_dintinct"  > edges_agosto_21_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_22_dintinct"  > edges_agosto_22_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_23_dintinct"  > edges_agosto_23_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_24_distinct"  > edges_agosto_24_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_25_distinct"  > edges_agosto_25_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_26_distinct"  > edges_agosto_26_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_27_distinct"  > edges_agosto_27_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_28_distinct"  > edges_agosto_28_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_29_distinct"  > edges_agosto_29_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_30_distinct"  > edges_agosto_30_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_agosto_31_distinct"  > edges_agosto_31_distinct.csv
hive -e "SELECT * FROM datos_digitel.edges_final_agosto_distinct"  > edges_final_agosto_distinct.csv


