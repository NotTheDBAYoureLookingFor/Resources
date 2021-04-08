CREATE TABLE #CheckDates
(

	[Database Name] Nvarchar(150),
	[Last Good CheckDB Date] sql_variant

)
INSERT INTO #CheckDates
EXECUTE sys.sp_MSforeachdb @command1 = N'SELECT ''?'' AS [Database Name],
										        DATABASEPROPERTYEX (''?'' , ''LastGoodCheckDbTime'' ) AS [Last Good CheckDB Date]'


SELECT CD.[Database Name],
	   CD.[Last Good CheckDB Date],
	   DATEDIFF(DAY,  CAST( CD.[Last Good CheckDB Date] AS DATETIME ), GETDATE()) AS 'Days Since Last Check'
FROM #CheckDates AS CD
WHERE CD.[Database Name]NOT IN ('tempdb')

DROP TABLE #CheckDates