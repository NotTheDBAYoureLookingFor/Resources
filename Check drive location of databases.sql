SELECT D.name AS 'Database Name',
	   CASE WHEN MF.type = 0 THEN 'Data'
			WHEN MF.type = 1 THEN 'Log'
			END AS 'File Type',
	   UPPER(LEFT(physical_name, 1)) AS 'Drive Letter',
	   LEFT(MF.physical_name, LEN(MF.physical_name) - CHARINDEX('\', REVERSE(MF.physical_name)) ),
	   MF.is_percent_growth AS 'Is % Growth Enabled?'


FROM sys.master_files AS MF

	INNER JOIN sys.databases AS D
		ON MF.database_id = D.database_id

WHERE  DB_NAME(MF.database_id) IN ( 'master', 'model', 'msdb', 'tempdb' )