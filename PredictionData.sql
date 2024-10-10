WITH Calendar AS (
    SELECT 
        Dates.EventDate, 
        DATENAME(WEEKDAY, Dates.EventDate) AS DayOfWeek, 
        CASE 
            WHEN DATEPART(WEEKDAY, EventDate) IN (1, 7) THEN 1 
            ELSE 0 
        END AS IsWeekend, 
        dbo.IsPayday(Dates.EventDate) AS IsPayday
    FROM (
        SELECT DISTINCT EventDate
        FROM dbo.v_Combined_ShiftAndCalloutData
    ) AS Dates
    LEFT OUTER JOIN PDP_Apps.dbo.Paydays AS p 
        ON Dates.EventDate = p.PaydayDate
), 
PayWeekend AS (
    SELECT DATEADD(DAY, 1, PaydayDate) AS EventDate
    FROM PDP_Apps.dbo.Paydays AS p
    UNION ALL
    SELECT DATEADD(DAY, 2, PaydayDate) AS EventDate
    FROM PDP_Apps.dbo.Paydays AS p
    UNION ALL
    SELECT DATEADD(DAY, 3, PaydayDate) AS EventDate
    FROM PDP_Apps.dbo.Paydays AS p
), 
Weather AS (
    SELECT 
        ObservationDate, 
        Fastest2MinWindSpeed, 
        Fastest5SecWindSpeed, 
        Snowfall, 
        MaxRelativeHumidity, 
        SeaLevelPressure, 
        Precipitation, 
        AvgRelativeHumidity, 
        SnowDepth, 
        StationPressure, 
        MinRelativeHumidity, 
        DirectionFastest2MinWind, 
        AvgWindSpeed, 
        DirectionFastest5SecWind, 
        AvgWetBulbTemp, 
        MaxTemperature, 
        AvgDewPointTemp, 
        MinTemperature, 
        SmokeOrHazeFlag, 
        FogIcefogFreezingfogFlag, 
        HeavyFogFreezingFogFlag
    FROM dbo.Weather_History_KPHL
), 
Holidays AS (
    SELECT DISTINCT Date AS HolidayDate
    FROM PDP_Apps.dbo.Holidays
), 
DayBeforeHolidays AS (
    SELECT DISTINCT DATEADD(DAY, -1, Date) AS DayBeforeHolidayDate
    FROM PDP_Apps.dbo.Holidays
), 
DayAfterHolidays AS (
    SELECT DISTINCT DATEADD(DAY, 1, Date) AS DayAfterHolidayDate
    FROM PDP_Apps.dbo.Holidays
)
SELECT 
    C.EventDate, 
    C.DayOfWeek, 
    DATENAME(DAYOFYEAR, C.EventDate) AS [Day of Year], 
    C.IsWeekend, 
    C.IsPayday, 
    CASE 
        WHEN pw.EventDate IS NOT NULL THEN 1 
        ELSE 0 
    END AS IsPayWeekend, 
    CASE 
        WHEN H.HolidayDate IS NULL THEN 0 
        ELSE 1 
    END AS IsHoliday, 
    CASE 
        WHEN H.HolidayDate IS NOT NULL THEN 0 
        WHEN DBH.DayBeforeHolidayDate IS NULL THEN 0 
        ELSE 1 
    END AS IsDayBeforeHoliday, 
    CASE 
        WHEN H.HolidayDate IS NOT NULL THEN 0 
        WHEN DAH.DayAfterHolidayDate IS NULL THEN 0 
        ELSE 1 
    END AS IsDayAfterHoliday, 
    CASE 
        WHEN S.Callout IS NULL THEN 'Worked' 
        ELSE S.Callout 
    END AS Paycode, 
    S.Payroll, 
    AE.Department, 
    AE.Title, 
    AE.YearsOfService, 
    w.Fastest2MinWindSpeed, 
    w.Fastest5SecWindSpeed, 
    w.Snowfall, 
    w.MaxRelativeHumidity, 
    w.SeaLevelPressure, 
    w.Precipitation, 
    w.AvgRelativeHumidity, 
    w.SnowDepth, 
    w.StationPressure, 
    w.MinRelativeHumidity, 
    w.DirectionFastest2MinWind, 
    w.AvgWindSpeed, 
    w.DirectionFastest5SecWind, 
    w.AvgWetBulbTemp, 
    w.MaxTemperature, 
    w.AvgDewPointTemp, 
    w.MinTemperature, 
    w.SmokeOrHazeFlag, 
    w.FogIcefogFreezingfogFlag, 
    w.HeavyFogFreezingFogFlag
FROM 
    dbo.v_Combined_ShiftAndCalloutData AS S
    INNER JOIN Calendar AS C ON S.EventDate = C.EventDate
    LEFT OUTER JOIN PayWeekend AS pw ON C.EventDate = pw.EventDate
    LEFT OUTER JOIN Holidays AS H ON C.EventDate = H.HolidayDate
    LEFT OUTER JOIN DayBeforeHolidays AS DBH ON C.EventDate = DBH.DayBeforeHolidayDate
    LEFT OUTER JOIN DayAfterHolidays AS DAH ON C.EventDate = DAH.DayAfterHolidayDate
    INNER JOIN Weather AS w ON w.ObservationDate = C.EventDate
    INNER JOIN dbo.v_AllEmployees AS AE ON AE.Payroll = S.Payroll
WHERE 
    (S.Callout IS NULL) 
    OR (S.Callout <> 'OT')
