SELECT S.name AS 'Job Name',
	   S.description AS 'Job Description',
	   CASE WHEN LastOutcome.run_status = 1
			THEN 'Success'
			ELSE 'Failure'
			END AS 'Last Run Outcome',
	   STUFF( STUFF( LastOutcome.run_date, 5, 0, '-' ), 8, 0, '-' ) AS 'Last Run Date'

FROM msdb..sysjobs AS S

	CROSS APPLY ( SELECT TOP 1 S1.run_status,
							   S1.run_date
				  FROM msdb..sysjobhistory AS S1
				  WHERE S.job_id = S1.job_id
					AND S1.step_id = 0
				  ORDER BY S1.instance_id DESC) AS LastOutcome

WHERE S.enabled = 1

ORDER BY 1