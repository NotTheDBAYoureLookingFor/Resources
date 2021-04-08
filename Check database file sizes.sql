SELECT D.name AS 'Database Name',
	   CAST( D.create_date AS DATE ) AS 'Created Date',
	   CAST( (SUM( CASE WHEN MF.Type = 0 THEN MF.size ELSE 0 END) * 8) / 1024.0 / 1024.0 AS DECIMAL(10, 2) ) AS 'Database Data Size (GB)',
	   CAST( (SUM( CASE WHEN MF.Type = 1 THEN MF.size ELSE 0 END) * 8) / 1024.0 / 1024.0 AS DECIMAL(10, 2) ) AS 'Database Log Size (GB)',
	   CONCAT( CAST( CAST( (SUM( CASE WHEN MF.Type = 1 THEN MF.size ELSE 0 END) * 8) / 1024.0 / 1024.0 AS DECIMAL(10, 2) ) 
		/ CAST( (SUM( CASE WHEN MF.Type = 0 THEN MF.size ELSE 0 END) * 8) / 1024.0 / 1024.0 AS DECIMAL(10, 2) ) 
		* 100 AS DECIMAL(10, 2) ), '%' )  AS 'Log size in relation to data'



FROM sys.databases AS D
	
	INNER JOIN sys.master_files AS MF
		ON D.database_id = MF.database_id

WHERE is_auto_update_stats_async_on = 1

	--AND MF.type = 0

GROUP BY D.name,
		 CAST( D.create_date AS DATE )