--1. Create table ‘table_to_delete’ and fill it with the following query:
CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
               
--2. Lookup how much space this table consumes with the following query:
SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';


/*
#|oid  |table_schema|table_name     |row_estimate|total_bytes|index_bytes|toast_bytes|table_bytes|total |index  |toast     |table |
-+-----+------------+---------------+------------+-----------+-----------+-----------+-----------+------+-------+----------+------+
1|16869|public      |table_to_delete|        -1.0|  602505216|          0|       8192|  602497024|575 MB|0 bytes|8192 bytes|575 MB|
 
Duration of operation 7.175s
 */

--3. Issue the following DELETE operation on ‘table_to_delete’:


DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; 

/*a) Note how much time it takes to perform this DELETE statement;
Duration of operation - 7.706s

b) Lookup how much space this table consumes after previous DELETE;

#|oid  |table_schema|table_name     |row_estimate|total_bytes|index_bytes|toast_bytes|table_bytes|total |index  |toast     |table |
-+-----+------------+---------------+------------+-----------+-----------+-----------+-----------+------+-------+----------+------+
1|16869|public      |table_to_delete|   9999700.0|  602611712|          0|       8192|  602603520|575 MB|0 bytes|8192 bytes|575 MB| */



--c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 

VACUUM FULL VERBOSE table_to_delete;


/*Duration of operation 2.537s
  
d) Check space consumption of the table once again and make conclusions

#|oid  |table_schema|table_name     |row_estimate|total_bytes|index_bytes|toast_bytes|table_bytes|total |index  |toast     |table |
-+-----+------------+---------------+------------+-----------+-----------+-----------+-----------+------+-------+----------+------+
1|16869|public      |table_to_delete|   6666667.0|  401580032|          0|       8192|  401571840|383 MB|0 bytes|8192 bytes|383 MB| 

Before VACUUM operation  - table is 575 MB
After VACUUM operation was performed - 383 MB.
So, we can that vacuum operation helped to reduce the table size by 192 MB and was very efficient.



--e) Recreate ‘table_to_delete’ table;*/

CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x;


--4. Issue the following TRUNCATE operation:

TRUNCATE table_to_delete;

/*a) Note how much time it takes to perform this TRUNCATE statement.
Duration of operation - 0.035s

b) Compare with previous results and make conclusion.

TRUNCATE operation is much more faster than DELETE by more than 7 s. 
DELETE - 7.706s
TRUNCATE - 0.035s


c) Check space consumption of the table once again and make conclusions;

#|oid  |table_schema|table_name     |row_estimate|total_bytes|index_bytes|toast_bytes|table_bytes|total     |index  |toast     |table  |
-+-----+------------+---------------+------------+-----------+-----------+-----------+-----------+----------+-------+----------+-------+
1|16869|public      |table_to_delete|        -1.0|       8192|          0|       8192|          0|8192 bytes|0 bytes|8192 bytes|0 bytes|


After table creation it took 575 MB. After DELETE operation was initiated,total_bytes increased from 602,505,216 to 602,611,712.
table_bytes increased from 602,497,024 to 602,603,520.
The table was 575 MB before the DELETE operation and remained 575 MB after the function. So not much space was cleared.
However, after VACUUM operation was initiated, table size was reduced to 383 MB.
When TRUNCATE operation was initiated, the table size became 0 bytes. It was a great demonstration of how different operations can impact
the sizes of the table. The most efficient way to delete table data was TRUNCATE, but DELETE serves a purpose when there is a need to delete specific rows.
