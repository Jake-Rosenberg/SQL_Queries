WITH LeaveCases AS
(
	SELECT *
	FROM [PDP_UKG].[dbo].[v_FMLA_Tracking]
	WHERE Frequency = 'Intermittent' AND Title = 'Correctional Officer'
),
PayrollCount AS
(
	SELECT PersonId
	FROM [PDP_UKG].[dbo].[v_FMLA_Tracking]
	GROUP BY PersonId
	HAVING COUNT(*) = 1
),
Usage AS
(
	SELECT 
		PersonId,
		ApplyDate,
		YEAR(ApplyDate) AS [Year],
		DATEPART(MONTH, ApplyDate) AS [Month],
		DurationInHours
	FROM [PDP_UKG].[dbo].[UKG_PaycodeEdits]
	WHERE Paycode LIKE 'Leave Case%' AND ApplyDate >= DATEADD(YEAR, -1, GETDATE())
)
SELECT 
	l.Payroll,
	l.StartDate,
	l.EndDate,
	l.Summary,
	u.[Year],
	u.[Month],
	COUNT(u.ApplyDate) AS [Times Used],
	SUM(u.DurationInHours) AS [Hours Used Total],
	(l.FrequencyEpisodesPerInterval * l.DurationSeconds) / 3600 AS [Total Hours Allowed Per Month],
	SUM(u.DurationInHours) - ((l.FrequencyEpisodesPerInterval * l.DurationSeconds) / 3600) [Hours Violated]
FROM LeaveCases l
INNER JOIN PayrollCount p ON p.PersonId = l.PersonId
INNER JOIN Usage u ON u.PersonId = l.PersonId
WHERE FrequencyInterval = 'Month'
	AND FrequencyIntervalCount = 1
	AND DurationSeconds > 0
	AND (l.FrequencyEpisodesPerInterval * l.DurationSeconds) < 2678400
	AND DATEFROMPARTS(u.[Year], u.[Month], DAY(u.ApplyDate)) >= StartDate
	AND DATEFROMPARTS(u.[Year], u.[Month], DAY(u.ApplyDate)) <= EndDate
GROUP BY
	l.Payroll,
	l.StartDate,
	l.EndDate,
	l.FrequencyEpisodesPerInterval,
	l.FrequencyIntervalCount,
	l.FrequencyInterval,
	l.DurationSeconds,
	l.Summary,
	u.[Year],
	u.[Month]
HAVING (SUM(u.DurationInHours) > ((l.FrequencyEpisodesPerInterval * l.DurationSeconds) / 3600));