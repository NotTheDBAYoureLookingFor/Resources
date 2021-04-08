SELECT d.name AS 'Database Name',
	   MAX(b.backup_finish_date) AS 'Backup Completed @',
	   DATEDIFF(DAY, MAX(b.backup_finish_date), GETDATE()) AS 'Days Since Backup'

FROM master.sys.databases d
	
	LEFT OUTER JOIN msdb.dbo.backupset AS b 
		ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
		AND b.type = 'D'
		AND b.server_name = SERVERPROPERTY('ServerName')

WHERE d.database_id <> 2  
	AND d.state NOT IN(1, 6, 10) 
	AND d.is_in_standby = 0 
	AND d.source_database_id IS NULL 

GROUP BY d.name