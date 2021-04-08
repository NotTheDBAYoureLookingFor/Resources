SET NOCOUNT ON

DECLARE @Midnight AS DATETIME = '00:00:00'

SELECT ER.session_id AS SPID,
	   CAST( DB_NAME(ER.database_id) AS VARCHAR) AS 'Database Name',
	   ER.command AS 'Database Command', 
	   LEFT(CAST(ER.start_time AS TIME), 8) AS 'Time Command Executed',
	   LEFT(CAST(DATEADD(MILLISECOND, ER.estimated_completion_time, GETDATE()) AS TIME), 8) AS 'Completion Time',
	   LEFT(CAST(DATEADD(MILLISECOND, ER.estimated_completion_time, @Midnight) AS TIME), 8) AS 'Time Left',
	   LEFT(CAST(DATEADD(SECOND, DATEDIFF(SECOND, ER.start_time, GETDATE()), @Midnight) AS TIME), 8) AS 'Time Elapsed',
	   CONCAT(ROUND(ER.percent_complete, 2), '%') AS 'Percent Complete'
	   
FROM sys.dm_exec_requests AS ER

WHERE ER.command IN ('DBCC TABLE CHECK', 
					 'RESTORE DATABASE', 
					 'BACKUP DATABASE', 
					 'BACKUP LOG', 
					 'RESTORE HEADERONLY', 
					 'RESTORE LOG')

RAISERROR('', 0, 1) WITH NOWAIT
WAITFOR DELAY '00:00:10'
GO 5000