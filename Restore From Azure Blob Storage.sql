USE [master]
GO

CREATE OR ALTER PROCEDURE [dbo].[RestoreFromAzure] (@Database VARCHAR(20), 
													@Execute BIT = 0,
													@OriginServer NVARCHAR(150) = '')
AS

/**********************************/
/**  Declare working parameters  **/
/**********************************/
DECLARE @DayOfWeek AS VARCHAR(10)
DECLARE @URL AS VARCHAR(150)
DECLARE @SQL AS VARCHAR(MAX)
DECLARE @ServerName AS VARCHAR(50)
DECLARE @DB_RecoveryModel AS TINYINT


/******************************/
/**  Set working parameters  **/
/******************************/
SET @DB_RecoveryModel = ( SELECT D.recovery_model FROM sys.databases AS D WHERE D.name = @Database )

IF @OriginServer = ''
	BEGIN
		SET @ServerName = CASE WHEN CHARINDEX('\', @@servername) > 0
							   THEN REPLACE( @@servername, '\', '/')
							   ELSE CONCAT( @@servername, '/Root' )
							   END    	
    END

IF @OriginServer <> '' 
	BEGIN  
		SET @ServerName = CASE WHEN CHARINDEX('\', @OriginServer) > 0
							   THEN REPLACE( @OriginServer, '\', '/')
							   ELSE CONCAT( @OriginServer, '/Root' )
							   END 
	END

/***********************************************/
/**  If DB to restore is Full Recovery Model  **/
/***********************************************/
IF @DB_RecoveryModel = 1
	BEGIN

		/**  Find the last time a full backup was taken  **/
		DECLARE @LastFullBackup AS DATETIME	

		SET @LastFullBackup = (SELECT MAX( B.backup_start_date ) 
							   FROM msdb..backupset AS B 
									INNER JOIN msdb..backupmediaset AS B1 ON B.media_set_id = B1.media_set_id
									INNER JOIN msdb..backupmediafamily AS B2 ON B1.media_set_id = B2.media_set_id
							   WHERE B.database_name = @Database
									AND B.type = 'D'
									AND B2.device_type = 9)


		/**  Get all backups, in order, since (and including) the last full backup  **/
		SELECT CONCAT( 'RESTORE ', 
						CASE WHEN B.type = 'D' THEN 'DATABASE ' WHEN B.type = 'L' THEN 'LOG ' END,
					    QUOTENAME(B.database_name),
						' FROM URL = ''',
						B2.physical_device_name,
						''' WITH STATS = 5, NORECOVERY, REPLACE  '	   
			   ) AS 'SQL Statement',
			   ROW_NUMBER() OVER(ORDER BY B.backup_start_date ASC) AS 'Run Order'

		FROM msdb..backupset AS B

			INNER JOIN msdb..backupmediaset AS B1 ON B.media_set_id = B1.media_set_id

			INNER JOIN msdb..backupmediafamily AS B2 ON B1.media_set_id = B2.media_set_id

		WHERE B.database_name = @Database
			AND B.backup_start_date >= @LastFullBackup
			AND B2.device_type = 9

		UNION 

		/**  Append the recovery command at the end  **/
		SELECT CONCAT('RESTORE DATABASE [', @Database, '] WITH RECOVERY'), 999

		ORDER BY 2

END


/*************************************************/
/**  If DB to restore is Simple Recovery Model  **/
/*************************************************/
IF @DB_RecoveryModel = 3
	BEGIN

		SET @DayOfWeek = DATENAME(WEEKDAY, GETDATE())
		SET @URL = CONCAT('https://ENTER_BLOB_STORAGE_URL.blob.core.windows.net/sqlbackups/', @ServerName, '/', @Database, '/', @DayOfWeek, '.bak')

		/** Set default RESTORE statement **/
		SET @SQL = (SELECT CONCAT('RESTORE DATABASE ', @Database, ' FROM URL = ''', @URL, '''', ' WITH STATS = 5 '))


		/**  If @Execute is true, execute the command  **/
		IF @Execute = 1 
		BEGIN 
			PRINT CONCAT('Restoring ', @Database, ' from ', @URL, CHAR(13))
			EXECUTE (@SQL)
		END


		/**  If @Execute is false, print the SQL command  **/
		IF @Execute = 0 
		BEGIN 
			PRINT @SQL
		END

END