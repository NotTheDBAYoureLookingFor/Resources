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

	[Database Name] NVARCHAR(128), 
	[Table Name] NVARCHAR(261),
	[Trigger Name] NVARCHAR(128),
	[Created Date] DATETIME

)
GO

/******************************/
/**  Populate Results table  **/
/******************************/
EXECUTE sys.sp_MSforeachdb @command1 = N'USE [?]
				
										 INSERT INTO #Results ([Database Name], [Table Name], [Trigger Name], [Created Date])
										 SELECT DB_NAME() AS ''Database Name'',
												CONCAT( ''['', s.name, ''].['', o.name, '']'' ),
												t.name AS ''Trigger Name'',
												t.create_date AS ''Created Date''

										FROM sys.triggers AS t 

											INNER JOIN sys.objects AS o 
												ON t.parent_id = o.object_id
	
											INNER JOIN sys.schemas AS s 
												ON o.schema_id = s.schema_id 
		
										WHERE t.is_ms_shipped = 0	
											AND DB_NAME() != ''ReportServer'''

/***********************/
/**  Display results  **/
/***********************/
SELECT R.[Database Name],
	   R.[Table Name],
	   R.[Trigger Name],
	   R.[Created Date]

FROM #Results AS R

ORDER BY R.[Database Name],
		 R.[Table Name], 
		 R.[Trigger Name]

/***************/
/**  Cleanup  **/
/***************/
DROP TABLE #Results