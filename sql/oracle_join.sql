\pset border 1
\pset linestyle ascii
\set VERBOSITY terse
SET client_min_messages = INFO;

/* analyze table for reliable output */

ANALYZE typetest1;

/*
 * Cases that should be pushed down.
 */
-- inner join two tables
SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.c = t2.c ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.c = t2.c;
SELECT length(t1.lb), length(t2.lc) FROM typetest1 t1 JOIN typetest1 t2 ON (t1.id + t2.id = 2) ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT length(t1.lb), length(t2.lc) FROM typetest1 t1 JOIN typetest1 t2 ON (t1.id + t2.id = 2);
-- inner join two tables with ORDER BY clause, but ORDER BY does not get pushed down */
SELECT t1.id, t2.id FROM typetest1 t1 JOIN typetest1 t2 USING (ts, num) ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 JOIN typetest1 t2 USING (ts, num) ORDER BY t1.id, t2.id;
-- natural join two tables
SELECT id FROM typetest1 NATURAL JOIN shorty ORDER BY id;
EXPLAIN (COSTS off) SELECT id FROM typetest1 NATURAL JOIN shorty;
-- table with column that does not exist in Oracle (should become NULL)
SELECT t1.id, t2.x FROM typetest1 t1 JOIN longy t2 ON t1.c = t2.c ORDER BY t1.id, t2.x;
EXPLAIN (COSTS off) SELECT t1.id, t2.x FROM typetest1 t1 JOIN longy t2 ON t1.c = t2.c;
-- left outer join two tables
SELECT t1.id, t2.id FROM typetest1 t1 LEFT JOIN typetest1 t2 ON t1.d = t2.d ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 LEFT JOIN typetest1 t2 ON t1.d = t2.d;
-- right outer join two tables
SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN typetest1 t2 ON t1.d = t2.d ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN typetest1 t2 ON t1.d = t2.d;
-- full outer join two tables
SELECT t1.id, t2.id FROM typetest1 t1 FULL JOIN typetest1 t2 ON t1.d = t2.d ORDER BY t1.id, t2.id;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 FULL JOIN typetest1 t2 ON t1.d = t2.d;
-- joins with filter conditions 
---- inner join with WHERE clause
SELECT t1.id, t2.id FROM typetest1 t1 INNER JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
EXPLAIN (VERBOSE, COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 INNER JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
---- left outer join with WHERE clause
SELECT t1.id, t2.id FROM typetest1 t1 LEFT JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
EXPLAIN (VERBOSE, COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 LEFT JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
---- right outer join with WHERE clause
SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
EXPLAIN (VERBOSE, COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
---- full outer join with WHERE clause
SELECT t1.id, t2.id FROM typetest1 t1 FULL JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;
EXPLAIN (VERBOSE, COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 FULL JOIN typetest1 t2 ON t1.d = t2.d WHERE t1.id > 1 ORDER BY t1.id, t2.id;


/*
 * Cases that should not be pushed down.
 */

-- join expression cannot be pushed down
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.lc = t2.lc;
-- only one join condition cannot be pushed down
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 JOIN typetest1 t2 ON t1.vc = t2.vc AND t1.lb = t2.lb;
-- condition on one table needs to be evaluated locally
EXPLAIN (COSTS off) SELECT max(t1.id), min(t2.id) FROM typetest1 t1 JOIN typetest1 t2 ON t1.fl = t2.fl WHERE t1.vc || 'x' = 'shortx';
EXPLAIN (COSTS off) SELECT t1.c, t2.nc FROM typetest1 t1 JOIN (SELECT * FROM typetest1) t2 ON (t1.id = t2.id AND t1.c >= t2.c);
EXPLAIN (COSTS off) SELECT t1.c, t2.nc FROM typetest1 t1 LEFT JOIN (SELECT * FROM typetest1) t2 ON (t1.id = t2.id AND t1.c >= t2.c);
-- subquery with where clause cannnot be pushed down in full outer join query
EXPLAIN (COSTS off) SELECT t1.c, t2.nc FROM typetest1 t1 FULL JOIN (SELECT * FROM typetest1 WHERE id > 1) t2 USING (id);
-- left outer join with placeholdear, not pushed down
EXPLAIN (COSTS off) SELECT t1.id, sq1.x, sq1.y
FROM typetest1 t1 LEFT OUTER JOIN (SELECT id AS x, 99 AS y FROM typetest1 t2) sq1 on t1.id = sq1.x WHERE 1 = (SELECT 1 FROM typetest1 t3 WHERE sq1.y IS NOT NULL LIMIT 1);
-- inner join with placeholder, not pushed down
EXPLAIN (COSTS off)
SELECT subq2.c3
FROM typetest1
RIGHT JOIN (SELECT c AS c1 FROM typetest1) AS subq1
ON TRUE
LEFT JOIN  (SELECT ref1.nc AS c2, 10 AS c3 FROM typetest1 AS ref1
             INNER JOIN typetest1 AS ref2
             ON ref1.fl = ref2.fl
) AS subq2
ON subq1.c1 = subq2.c2;
-- inner rel is false, not pushed down 
EXPLAIN (COSTS off) SELECT 1 FROM (SELECT 1 FROM typetest1 WHERE false) AS subq1 RIGHT JOIN typetest1 AS ref1 ON NULL;
-- semi-join, not pushed down 
EXPLAIN (COSTS off) SELECT t1.id FROM typetest1 t1 WHERE EXISTS (SELECT 1 FROM typetest1 t2 WHERE t1.d = t2.d);
-- anti-join, not pushed down
EXPLAIN (COSTS off) SELECT t1.id FROM typetest1 t1 WHERE NOT EXISTS (SELECT 1 FROM typetest1 t2 WHERE t1.d = t2.d);
-- cross join, not pushed down 
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 CROSS JOIN typetest1 t2;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 INNER JOIN typetest1 t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 LEFT  JOIN typetest1 t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN typetest1 t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 FULL  JOIN typetest1 t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 CROSS JOIN (SELECT * FROM typetest1 WHERE vc = 'short') t2;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 INNER JOIN (SELECT * FROM typetest1 WHERE vc = 'short') t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 LEFT  JOIN (SELECT * FROM typetest1 WHERE vc = 'short') t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 RIGHT JOIN (SELECT * FROM typetest1 WHERE vc = 'short') t2 ON true;
EXPLAIN (COSTS off) SELECT t1.id, t2.id FROM typetest1 t1 FULL  JOIN (SELECT * FROM typetest1 WHERE vc = 'short') t2 ON true;
-- UPDATE statement, not pushed down
EXPLAIN (COSTS off) UPDATE typetest1 t1 SET c = NULL FROM typetest1 t2 WHERE t1.vc = t2.vc AND t2.num = 3.14159;
-- only part of a three-way join will be pushed down
EXPLAIN (COSTS off) SELECT t1.id, t3.id
   FROM typetest1 t1
      JOIN typetest1 t2 USING (nvc)
      JOIN typetest1 t3 ON t2.db = t3.db;

/*
 * Cost estimates.
 */

/* delete statistics */
DELETE FROM pg_statistic WHERE starelid = 'typetest1'::regclass;
UPDATE pg_class SET relpages = 0, reltuples = 0.0 WHERE oid = 'typetest1'::regclass;
/* default costs */
EXPLAIN SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.c = t2.c;
/* gather statistics */
ANALYZE typetest1;
/* costs with statistics */
EXPLAIN SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.c = t2.c;
EXPLAIN SELECT t1.id, t2.id FROM typetest1 t1, typetest1 t2 WHERE t1.c <> t2.c;
