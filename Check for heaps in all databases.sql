/***************************************/
/**  Drop Results table if it exists  **/
/***************************************/
IF OBJECT_ID('tempdb.dbo.#Results') IS NOT NULL
	DROP TABLE #Results
GO

/****************************/
/**  Create Results table  **/
/****************************/
CREATE TABLE #Results
(

	[Database Name] nvarchar(128),
	[Table Name] nvarchar(261),
	[Rows in Table] INT,
	[Times Accessed By Users] INT,
	[Times Accessed By System] INT

)
GO

/******************************/
/**  Populate Results table  **/
/******************************/
EXECUTE sys.sp_MSforeachdb @command1 = N'
										USE [?]

										INSERT INTO #Results ([Database Name], [Table Name], [Rows in Table], [Times Accessed By Users], [Times Accessed By System])

										SELECT DB_NAME() AS ''Database Name'',
											   CONCAT( ''['', S.name, ''].['', o.name, '']'' ) AS ''Table Name'',
											   --FORMAT( p.rows, ''#,###'') AS ''Rows in Table'',
											   p.rows AS ''Rows in Table'',
											   ius.user_seeks + ius.user_scans + ius.user_lookups + ius.user_updates AS ''Times Accessed By Users'',
											   ius.system_seeks + ius.system_scans + ius.system_lookups + ius.system_updates AS ''Times Accessed By System''

										FROM [?].sys.indexes AS i 
	
											INNER JOIN .sys.objects AS o 
												ON i.object_id = o.object_id

											INNER JOIN [?].sys.partitions AS p 
												ON i.object_id = p.object_id AND i.index_id = p.index_id

											INNER JOIN [?].sys.databases AS sd 
												ON sd.name = N''?''

											INNER JOIN [?].sys.schemas AS S 
												ON o.schema_id = S.schema_id

											LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats AS ius 
												ON i.object_id = ius.object_id 
												AND i.index_id = ius.index_id 
												AND ius.database_id = sd.database_id

										WHERE i.type_desc = ''HEAP'' 
											AND COALESCE(NULLIF(ius.user_seeks,0), NULLIF(ius.user_scans,0), NULLIF(ius.user_lookups,0), NULLIF(ius.user_updates,0)) IS NOT NULL
											AND sd.name <> ''tempdb'' 
											AND sd.name <> ''DWDiagnostics'' 
											AND o.is_ms_shipped = 0 
											AND o.type <> ''S'''


/***********************/
/**  Display results  **/
/***********************/
SELECT R.[Database Name],
	   R.[Table Name],
	   FORMAT( R.[Rows in Table], '#,###') AS [Rows in Table],
	   FORMAT( R.[Times Accessed By Users], '#,###') AS [Times Accessed By Users],
	   FORMAT( R.[Times Accessed By System], '#,###') AS [Times Accessed By System]

FROM #Results AS R

ORDER BY 1, R.[Rows in Table] DESC