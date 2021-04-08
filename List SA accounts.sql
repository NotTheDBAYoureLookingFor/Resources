SELECT l.name AS 'Login Name',
	   l.createdate AS 'Login Created',
	   l.hasaccess AS 'Has Access',
	   CASE WHEN l.isntname = 1 THEN 'Windows Login'
			WHEN l.isntname = 0 THEN 'SQL Login'
			END AS 'Account Type',
	   CASE WHEN LastLogin.login_name IS NOT NULL
			THEN 1
			ELSE 0
			END AS 'Has Active Session'

FROM master.sys.syslogins AS l

	LEFT JOIN (SELECT DISTINCT login_name
			   FROM master.sys.dm_exec_sessions
			   ) AS LastLogin
		ON l.name = LastLogin.login_name

WHERE l.sysadmin = 1
	AND l.name <> SUSER_SNAME(0x01)
	AND l.denylogin = 0
	AND l.name NOT LIKE 'NT SERVICE\%'
	AND l.name NOT IN ('l_certSignSmDetach')