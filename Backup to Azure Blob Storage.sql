USE [master]
GO
/****** Object:  StoredProcedure [dbo].[BackupToAzure]    Script Date: 01/12/2020 12:32:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[BackupToAzure_2] (@Database AS NVARCHAR(128), @Execute AS BIT = 1, @BackupType AS VARCHAR(4) = 'Full')
AS


DECLARE @URL AS VARCHAR(150)
DECLARE @DayOfWeek AS VARCHAR(50)
DECLARE @FullURL AS VARCHAR(150)
DECLARE @SQL AS NVARCHAR(MAX)
DECLARE @ServerName AS VARCHAR(50)
DECLARE @DB_RecoveryModel AS TINYINT

/**-------------------**/
/** Check is database **/
/**-------------------**/

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = @Database AND source_database_id IS NULL) BEGIN  
	PRINT CONCAT('Requested database, ', @Database, ', cannot be backed up because it doesn''t meet the requirements. See SP for more details')
	RETURN
END

SET @DB_RecoveryModel = ( SELECT D.recovery_model FROM sys.databases AS D WHERE D.name = @Database )
SET @URL = 'https://ENTER_BLOB_STORAGE_URL.blob.core.windows.net/sqlbackups/'
SET @DayOfWeek = CASE DATEPART(WEEKDAY, GETDATE()) 
						WHEN 2 THEN 'Monday'
						WHEN 3 THEN 'Tuesday'
						WHEN 4 THEN 'Wednesday'
						WHEN 5 THEN 'Thursday'
						WHEN 6 THEN 'Friday'
						WHEN 7 THEN 'Saturday'
						WHEN 1 THEN 'Sunday'
						END
SET @ServerName = CASE WHEN CHARINDEX('\', @@servername) > 0
						THEN REPLACE( @@servername, '\', '/')
						ELSE CONCAT( @@servername, '/Root' )
						END

IF @BackupType = 'Full'
	BEGIN  

		/**----------------**/
		/** Set Parameters **/
		/**----------------**/

		SET @FullURL = (SELECT CONCAT(@URL, @ServerName, '/', @Database, '/', @DayOfWeek, '.bak'))
		SET @DB_RecoveryModel = ( SELECT D.recovery_model FROM sys.databases AS D WHERE D.name = @Database )

		/**-----------**/
		/** Build SQL **/
		/**-----------**/

		SET @SQL = CONCAT('BACKUP DATABASE [', @Database, ']', CHAR(13), 
						  'TO URL = ''', @FullURL, '''', CHAR(13), 
						  'WITH COMPRESSION, FORMAT, STATS = 5')

		IF @DB_RecoveryModel = 1
			BEGIN

				SET @SQL = CONCAT(@SQL, ', INIT')

			END

	END


IF @BackupType = 'Log'
	BEGIN  

		DECLARE @Time AS TIME = GETDATE()
		DECLARE @TimeVar AS VARCHAR(4) = REPLACE( @Time, ':', '')

		SET @URL = ( SELECT CONCAT(@URL, @ServerName, '/', @Database, '/', @TimeVar, '.trn') )

		SET @SQL = CONCAT( 'BACKUP LOG [', @Database, '] TO URL = ''', @URL, ''' WITH COMPRESSION, INIT, STATS = 5, FORMAT' )

	END
/**--------------------------------**/
/** Check if execution is required **/
/**--------------------------------**/

IF @Execute IS NULL OR @Execute = 1
	BEGIN

		/**-------------**/
		/** Execute SQL **/
		/**-------------**/

		PRINT CONCAT('Deploying backup to ', @FullURL, CHAR(13))

		EXECUTE sys.sp_executesql @Command = @SQL

		PRINT CONCAT(CHAR(13), 'Backup has been taken successfully. Now starting validation...', CHAR(13))

		/**-----------------**/
		/** Validate Backup **/
		/**-----------------**/

		IF @BackupType = 'Full' BEGIN  
			RESTORE VERIFYONLY FROM URL = @FullURL WITH STATS = 5	
        END    

	END


/**------------------------------**/
/** If execution is not required **/
/**------------------------------**/	

IF @Execute = 0
	BEGIN
		
		PRINT @SQL

	END