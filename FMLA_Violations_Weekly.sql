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
		DATEPART(WEEK, ApplyDate) AS WeekNumber,
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
	u.WeekNumber,
	COUNT(u.ApplyDate) AS [Times Used],
	SUM(u.DurationInHours) AS [Hours Used Total],
	(l.FrequencyEpisodesPerInterval * l.DurationSeconds) / 3600 AS [Total Hours Allowed Per Episode],
	DATEADD(DAY, (1 - DATEPART(WEEKDAY, DATEFROMPARTS(u.[Year], 1, 1))) + ((u.WeekNumber - 1) * 7), DATEFROMPARTS(u.[Year], 1, 1)) AS WeekStartDate,
	DATEADD(DAY, (7 - DATEPART(WEEKDAY, DATEFROMPARTS(u.[Year], 1, 1))) + ((u.WeekNumber - 1) * 7), DATEFROMPARTS(u.[Year], 1, 1)) AS WeekEndDate
FROM LeaveCases l
INNER JOIN PayrollCount p ON p.PersonId = l.PersonId
INNER JOIN Usage u ON u.PersonId = l.PersonId
WHERE FrequencyInterval = 'Week' 
  AND FrequencyIntervalCount = 1
  AND DurationSeconds > 0
  AND (l.FrequencyEpisodesPerInterval * l.DurationSeconds) < 604800
  AND DATEADD(DAY, (1 - DATEPART(WEEKDAY, DATEFROMPARTS(u.[Year], 1, 1))) + ((u.WeekNumber - 1) * 7), DATEFROMPARTS(u.[Year], 1, 1)) > l.StartDate
  AND DATEADD(DAY, (7 - DATEPART(WEEKDAY, DATEFROMPARTS(u.[Year], 1, 1))) + ((u.WeekNumber - 1) * 7), DATEFROMPARTS(u.[Year], 1, 1)) < l.EndDate
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
	u.WeekNumber
HAVING 
	(COUNT(u.ApplyDate) > FrequencyEpisodesPerInterval) 
	OR (SUM(u.DurationInHours) > ((l.FrequencyEpisodesPerInterval * l.DurationSeconds) / 3600));