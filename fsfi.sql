REM     This script measures the fragmentation of free space
REM     in all of the tablespaces in the database and scores them
REM     according to an arbitrary index for comparison
REM     
REM                       largest extent                  100
REM     FSFI = 100 * sqrt(------------------) * (-------------------------------)
REM                      sum of all extents      sqrt(sqrt((number of extents)))
REM     "Tablespaces with an FSFI value greater than 30 may need free space manually coalesced."
REM     FSFI - Free Space Fragmentation index
REM     The largest possible FSFI (for an ideal single-file tablespace) is 100
REM     As the number of extents increases, the FSFI rating drops slowly. As the size of
REM     the largest extent drops, however, the FSFI rating drops rapidly.


select          tablespace_name
, file_id
,          sqrt(max(blocks)/sum(blocks)) *
          (100/sqrt(sqrt(count(blocks)))) fsfi
from          dba_free_space
group by     tablespace_name, file_id
order by     1,2;

 SELECT
 tablespace_name, 
 count(*) free_chunks,
 decode(round((max(bytes) / 1024000),2),
 null,0,
 round((max(bytes) / 1024000),2)) largest_chunk,
 nvl(round(sqrt(max(blocks)/sum(blocks))*(100/sqrt(sqrt(count(blocks)) )),2),0) fragmentation_index
 FROM
 sys.dba_free_space 
 group by 
 tablespace_name
 order by 2 desc, 1;