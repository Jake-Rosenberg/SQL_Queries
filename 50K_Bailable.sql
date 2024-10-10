WITH ONCAMPUS
AS
(
	SELECT 
		OFFENDER,
		PPN,
		LNAME [Last Name],
		RNAME [First Name]
	FROM [LAT_Pull].[dbo].[pps_jailhouseview]
	WHERE OFFENDER IS NOT NULL AND FACILITY NOT IN ('OC', 'OJ')
),
MaxSeqNo
AS
(
	SELECT C.Offender, MAX( C.SeqNo ) [MaxSeqNo]
	FROM [LAT_Pull].[dbo].[pps_offenders] O, [LAT_Pull].[dbo].[pps_classification] C
	WHERE O.Intake <= C.Evaluated
      AND O.Offender = C.Offender
	GROUP BY C.Offender
),
BAILSUM
AS
(
	SELECT 
		d.OFFENDER,
		SUM(BAIL) [Total Bail]
	FROM [LAT_Pull].[dbo].[pps_dockets] d
	JOIN 
	(
		SELECT OFFENDER
		FROM [LAT_Pull].[dbo].[pps_dockets]
		GROUP BY OFFENDER
		HAVING COUNT(*) = COUNT(BAIL)
	) dd ON d.OFFENDER = dd.OFFENDER
	GROUP BY d.OFFENDER
),
DETAINER
AS
(
	SELECT OFFENDER
	FROM [LAT_Pull].[dbo].[pps_detainers]
	WHERE RELEASED IS NULL
)
SELECT DISTINCT
	o.PPN,
	o.[Last Name],
	o.[First Name],
	CASE
		WHEN [OVERRIDE] IS NULL THEN [CLASSIFICATION]
		ELSE [OVERRIDE]
	END AS [Custody Level],
	b.[Total Bail]
FROM [LAT_Pull].[dbo].[pps_openclocksview] ocv
INNER JOIN ONCAMPUS o ON o.OFFENDER = ocv.OFFENDER
INNER JOIN BAILSUM b ON b.OFFENDER = ocv.OFFENDER
INNER JOIN DETAINER d ON d.OFFENDER = o.OFFENDER 
INNER JOIN MaxSeqNo m ON ocv.OFFENDER = m.OFFENDER
INNER JOIN [LAT_Pull].[dbo].[pps_classification] c ON ocv.OFFENDER = c.OFFENDER AND m.MaxSeqNo = c.SEQNO
WHERE b.[Total Bail] > 0 AND b.[Total Bail] <= 50000
ORDER BY [Custody Level], [Total Bail]