USE master
GO

CREATE OR ALTER PROCEDURE dbo.IndexCreationStats
AS

--  Get the execution results for all index creation SPIDS 
--  Stored in temp table due to odd results when limiting [physical_operator_name] in the WHERE clause
SELECT [physical_operator_name],
	   QP.[row_count],
       QP.[estimate_row_count],
       QP.last_active_time, 
	   QP.first_active_time,
       QP.[close_time],
	   QP.[first_row_time],
	   SPIDs.session_id

INTO #Aggregations

FROM sys.dm_exec_query_profiles AS QP

	INNER JOIN sys.dm_exec_requests AS SPIDs
		ON QP.session_id = SPIDs.session_id

WHERE SPIDS.command IN ( 'CREATE INDEX','ALTER INDEX','ALTER TABLE' )


--  Remove lines we dont need
--  Necessary as mentioned above
DELETE FROM #Aggregations
WHERE [physical_operator_name] NOT IN (N'Table Scan', N'Clustered Index Scan', N'Index Scan', N'Sort')


--  Aggregate results up to SPID level
SELECT session_id,
	   SUM(A.row_count) AS [RowsProcessed],
            SUM(A.[estimate_row_count]) AS [TotalRows],
			SUM(A.[estimate_row_count]) - SUM(A.row_count) AS RowsLeft,
            MAX(A.last_active_time) - MIN(A.first_active_time) AS [ElapsedMS],
            MAX(CASE WHEN A.row_count > 0 AND A.row_count < A.estimate_row_count 
					 THEN [physical_operator_name]
					 ELSE NULL
					 END) AS [CurrentStep]
INTO #Aggregations2			
FROM #Aggregations AS A
GROUP BY A.session_id


--  Format the results and display
SELECT session_id AS 'SPID',
	   [CurrentStep] AS 'Current Step',
       FORMAT( [TotalRows], '#,##0' ) AS 'Total Rows',
       FORMAT( [RowsProcessed], '#,##0' ) AS 'Rows Processed',
       FORMAT( [RowsLeft], '#,##0' ) AS 'Rows Left',
       CAST((([RowsProcessed] * 1.0) / [TotalRows]) * 100 AS DECIMAL(5,2)) AS 'Percent Complete'

FROM #Aggregations2


--  Clean up after ourselves
DROP TABLE #Aggregations, #Aggregations2