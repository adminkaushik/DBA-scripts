connect system/&&2@&&1

spool redoCalculator_&&1
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 9999
SET LINESIZE 132
SET TRIMSPOOL ON
SET SPACE 3
COL SYS_TIME NEW_VALUE SPTIME
COL SYS_DATE NEW_VALUE SPDATE
REM
REM *****************************************
REM

--Timestamp with database logged onto
SELECT
   TO_CHAR(SYSDATE,'DD-MON-YY') SYS_DATE,
   TO_CHAR(SYSDATE,'HH24:MI:SS') SYS_TIME,
   name "DATABASE"
FROM dual, v$database
/

PROMPT
PROMPT

--Current Redo Log Size
select distinct (bytes/1024/1024) as Current_Redo_Log_Size_MB from v$log;

PROMPT
PROMPT

--Current AVG Per Day Logs
select ROUND(Current_AVG_PerDayLogs) as AVG_PerDayLogs_Rounded_90days from
(SELECT AVG(Count(1)) as Current_AVG_PerDayLogs
   FROM v$log_history
   where First_Time > sysdate - 90
   GROUP BY To_Char(First_Time,'YYYY-MM-DD')
   ORDER BY 1 DESC
)
;

PROMPT

--calculate redo size to get 36 redo logs a day
select AVG/36 as SizeForRedoMBFo36PerDay FROM
(
	(select AVG(Daily_Avg_Mb) as AVG from 
		(SELECT A.*,(Round(A.Count#*B.AVG#/1024/1024)) Daily_Avg_Mb FROM
			(SELECT To_Char(First_Time,'YYYY-MM-DD') DAY,Count(1) Count#,Min(RECID) Min#,Max(RECID) Max#
			FROM v$log_history
                        where First_Time > sysdate - 90
			GROUP BY To_Char(First_Time,'YYYY-MM-DD')
			ORDER BY 1 DESC
			) A,
			(SELECT Avg(BYTES) AVG#, Count(1) Count#, Max(BYTES) Max_Bytes, Min(BYTES) Min_Bytes
			FROM v$log
			) B
		)
	)
)
;

--detailed list of day to day archiving of logs
SELECT A.*,
Round(A.Count#*B.AVG#/1024/1024) Daily_Avg_Mb
FROM
	(SELECT To_Char(First_Time,'YYYY-MM-DD') DAY,Count(1) Count#,Min(RECID) Min#,Max(RECID) Max#
	FROM v$log_history
	where First_Time > sysdate - 90
	GROUP BY To_Char(First_Time,'YYYY-MM-DD')
	ORDER BY 1 DESC
	) A,
	(SELECT Avg(BYTES) AVG#, Count(1) Count#, Max(BYTES) Max_Bytes, Min(BYTES) Min_Bytes
	FROM v$log
	) B
;


spool off
undefine PerDay;
exit;