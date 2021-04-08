DECLARE @Midnight AS DATETIME = '2018-09-30 00:00:00'


SELECT command AS 'Database Command', 
	   LEFT(CAST(start_time AS TIME), 8) AS 'Time Command Executed',
	   LEFT(CAST(DATEADD(MILLISECOND, estimated_completion_time, GETDATE()) AS TIME), 8) AS 'Completion Time',
	   LEFT(CAST(DATEADD(MILLISECOND, estimated_completion_time, @Midnight) AS TIME), 8) AS 'Time Left',
	   CONCAT(percent_complete, '%') AS 'Percent Complete'

FROM sys.dm_exec_requests 

WHERE command = 'RESTORE DATABASE'


RAISERROR('', 0, 1) WITH NOWAIT
WAITFOR DELAY '00:00:10'
GO 5000