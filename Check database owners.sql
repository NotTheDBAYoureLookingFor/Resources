SELECT D.name AS 'Database Name',
	   D.create_date AS 'Created Date',
	   D.state_desc AS 'Database State',
	   S.name AS 'Database Owner'

FROM sys.databases AS D

	INNER JOIN sys.syslogins AS S ON D.owner_sid = S.sid

WHERE (SUSER_SNAME(owner_sid) <> SUSER_SNAME(0x01))