SELECT db.name AS 'Database Name',
	   'Page Repairs' AS 'Count Source',
	   COUNT(*) AS Pages

FROM sys.dm_hadr_auto_page_repair AS rp
	
	INNER JOIN master.sys.databases AS db 
		ON rp.database_id = db.database_id

WHERE rp.modification_time >= DATEADD(dd, -30, GETDATE())

GROUP BY db.name


UNION ALL


SELECT db.name AS 'Database Name',
	   'Suspect Pages' AS 'Count Source',
	   COUNT(*) AS Pages

FROM msdb.dbo.suspect_pages As sp
	
	INNER JOIN master.sys.databases AS db ON sp.database_id = db.database_id
	
WHERE sp.last_update_date >= DATEADD(dd, -30, GETDATE())

GROUP BY db.name