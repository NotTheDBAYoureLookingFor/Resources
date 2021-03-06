USE [master]
GO

/**

	@SortOrder takes the following values (TableName, RowCount, IndexCount, ColumnCount)

**/

ALTER PROCEDURE [dbo].[DescribeObject] (@Database AS SYSNAME,
												  @SchemaName AS SYSNAME = NULL, 
												  @TableName AS SYSNAME = NULL,
												  @SortOrder AS VARCHAR(15) = 'TableName'
												  )
AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @SQL AS NVARCHAR(MAX)

IF @Database IS NULL OR NOT EXISTS (SELECT 1 FROM sys.databases AS D WHERE D.name = @Database) BEGIN 
	RAISERROR ('Variable @Database must contain a valid database name.', 10, 1)
	RETURN 
END

IF @SortOrder NOT IN ('TableName', 'RowCount', 'IndexCount', 'ColumnCount', '') BEGIN  
	RAISERROR ('Variable @SortOrder must contain a valid value from the following: TableName, RowCount, IndexCount, ColumnCount', 10, 1)
	RETURN 
END



/********************************/
/**  Column level description  **/
/********************************/
SET @SQL = CONCAT('USE [', @Database, ']

SELECT T.name AS ''Table Name'',  
	   C.name AS ''Column Name'', 
	   CASE WHEN T1.name IN (''VARCHAR'',''NVARCHAR'',''CHAR'',''NCHAR'',''DECIMAL'')
			THEN CASE WHEN C.max_length = -1 THEN CONCAT( UPPER(T1.name), ''(MAX)'' )
					  ELSE CONCAT( UPPER(T1.name), ''('', C.max_length, '')'' )
					  END
			ELSE UPPER(T1.name)
			END AS ''Data Type'',
	   S.name AS ''Schema Name'',
	   COALESCE( ForTbl.RefTable, ''N/A'' ) AS ''Links To'',
	   C.is_nullable AS ''Nullable'',
	   C.is_identity AS ''Identity Column'',
	   C.is_computed AS ''Computed Column''

FROM sys.tables AS T

	INNER JOIN sys.columns AS C
		ON T.object_id = C.object_id

	INNER JOIN sys.schemas AS S
		ON T.schema_id = S.schema_id

	INNER JOIN sys.types AS T1
		ON C.system_type_id = T1.user_type_id

	OUTER APPLY (
					SELECT TOP 1 CONCAT(SS1.name, ''.'', ST1.name) AS RefTable
					FROM sys.foreign_key_columns AS SFK
						INNER JOIN sys.tables AS ST ON SFK.parent_object_id = ST.object_id
						INNER JOIN sys.objects AS SO ON SO.object_id = SFK.referenced_object_id
						INNER JOIN sys.columns AS SC ON ST.object_id = SC.object_id AND SFK.parent_column_id = SC.column_id
						INNER JOIN sys.schemas AS SS ON ST.schema_id = SS.schema_id
						INNER JOIN sys.tables AS ST1 ON SFK.referenced_object_id = ST1.object_id
						INNER JOIN sys.schemas AS SS1 ON ST1.schema_id = SS1.schema_id
					WHERE T.name = ST.name
						AND S.name = SS.name
						AND C.name = SC.name ) AS ForTbl

WHERE S.name = ')

SET @SQL = CONCAT(@SQL, CASE WHEN @SchemaName IS NOT NULL THEN CONCAT('''', @SchemaName, ''' ') ELSE 'S.name' END )

SET @SQL = CONCAT(@SQL, ' AND T.name = ', CASE WHEN @TableName IS NOT NULL THEN CONCAT('''', @TableName, ''' ') ELSE 'T.name' END )
	
SET @SQL = CONCAT(@SQL, ' ORDER BY S.name, T.name, C.column_id ASC')

PRINT 'Script Starting:

/*********************************/
Executing Column Level Stats:
/*********************************/

'

PRINT @SQL

RAISERROR('', 0, 1) WITH NOWAIT


EXECUTE sys.sp_executesql @SQL


/*******************************/
/**  Table level description  **/
/*******************************/

SET @SQL = CONCAT('USE [', @Database, ']

SELECT CONCAT( S.name, ''.'', T.name) AS ''Table Name'',
	   T.create_date AS ''Created Date'',
	   T.modify_date AS ''Last Altered'',
	   T.max_column_id_used AS ''Column Count'',
	   T.temporal_type AS ''Is Temporal?'',
	   FORMAT( SUM( CASE WHEN P.index_id IN (1, 0) THEN P.rows ELSE 0 END ), ''#,##0'' ) AS ''Row Count'',
	   COUNT( DISTINCT CASE WHEN P.index_id > 0 THEN P.index_id ELSE NULL END ) AS ''Index Count''

FROM sys.tables AS T

	INNER JOIN sys.schemas AS S ON T.schema_id = S.schema_id

	LEFT JOIN sys.partitions AS P ON T.object_id = P.object_id

WHERE S.name = ')

SET @SQL = CONCAT(@SQL, CASE WHEN @SchemaName IS NOT NULL THEN CONCAT('''', @SchemaName, ''' ') ELSE 'S.name' END )

SET @SQL = CONCAT(@SQL, ' AND T.name = ', CASE WHEN @TableName IS NOT NULL THEN CONCAT('''', @TableName, ''' ') ELSE 'T.name' END )
	
SET @SQL = CONCAT(@SQL, ' 

GROUP BY CONCAT( S.name, ''.'', T.name),
	   T.create_date,
	   T.modify_date,
	   T.max_column_id_used,
	   T.temporal_type ')

IF @SortOrder IN ('TableName','') BEGIN  
	SET @SQL = CONCAT(@SQL, ' 
	
ORDER BY CONCAT( S.name, ''.'', T.name)')
END

IF @SortOrder = 'RowCount' BEGIN  
	SET @SQL = CONCAT(@SQL, ' 
	
ORDER BY SUM( CASE WHEN P.index_id IN (1, 0) THEN P.rows ELSE 0 END ) DESC')
END

IF @SortOrder = 'IndexCount' BEGIN  
	SET @SQL = CONCAT(@SQL, ' 
	
ORDER BY COUNT( DISTINCT CASE WHEN P.index_id > 0 THEN P.index_id ELSE NULL END ) DESC')
END

IF @SortOrder = 'ColumnCount' BEGIN  
	SET @SQL = CONCAT(@SQL, ' 
	
ORDER BY T.max_column_id_used DESC')
END

PRINT CONCAT('Sort order selected: ', @SortOrder)
PRINT CONCAT('
/*********************************/
Executing Table Level Stats:
/*********************************/

', @SQL)

RAISERROR('', 0, 1) WITH NOWAIT
EXECUTE sys.sp_executesql @SQL

/********************************/
/**  Schema level description  **/
/********************************/
IF @TableName IS NULL BEGIN  

	SET @SQL = CONCAT('USE [', @Database, ']

	SELECT S.name AS ''Schema Name'',
		   COUNT(*) AS ''Table Count''

	FROM sys.tables AS T

		INNER JOIN sys.schemas AS S ON T.schema_id = S.schema_id

	WHERE S.name = ')

	SET @SQL = CONCAT(@SQL, CASE WHEN @SchemaName IS NOT NULL THEN CONCAT('''', @SchemaName, ''' ') ELSE 'S.name' END, ' GROUP BY S.name' )

	PRINT CONCAT('
/*********************************/
Executing Schema Level Stats:
/*********************************/

', @SQL)
	
	RAISERROR('', 0, 1) WITH NOWAIT

	EXECUTE sys.sp_executesql @SQL

END


/**********************************/
/**  Database level description  **/
/**********************************/
IF @TableName IS NULL AND @SchemaName IS NULL BEGIN 

	SET @SQL = CONCAT( '
	SELECT D.name AS ''Database Name'',
		   D.create_date AS ''Created Date'',
		   D.compatibility_level AS ''Compat Level'',
		   D.collation_name AS ''Collation'',
		   D.state_desc AS ''State'',
		   D.recovery_model_desc AS ''Recovery Model''

	FROM sys.databases AS D

	WHERE D.name = ''', @Database,'''')

		PRINT CONCAT('
/*********************************/
Executing Database Level Stats:
/*********************************/
', @SQL)

	RAISERROR('', 0, 1) WITH NOWAIT

	EXECUTE sys.sp_executesql @SQL
	
END


/*********************************/
/**  Database file description  **/
/*********************************/
IF @TableName IS NULL AND @SchemaName IS NULL BEGIN 

	SET @SQL = CONCAT('USE [', @Database, ']

	SELECT DF.file_id AS ''File ID'',
		   DF.type_desc AS ''File Type'',
		   DF.name AS ''Logical Name'',
		   DF.physical_name AS ''Physical Location'',
		   DF.state_desc AS ''State'',
		   ((DF.size * 8) / 1024) AS ''Size in MBytes'',
		   DF.growth AS ''Growth Size''

	FROM sys.database_files AS DF')

		PRINT CONCAT('
/*********************************/
Executing File Level Stats:
/*********************************/

', @SQL)

	RAISERROR('', 0, 1) WITH NOWAIT

	EXECUTE sys.sp_executesql @SQL

END