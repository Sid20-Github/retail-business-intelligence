-- ============================================================================
-- 04_POPULATE_DIM_DATE.sql
-- Populate DimDate from 2011-01-01 through 2025-12-31
-- Adventure Works fiscal year starts 1 July
-- ============================================================================

USE AW_Retail_DW;
GO

DELETE FROM dbo.DimDate;
GO

;WITH DateSequence AS
(
    SELECT CAST('2011-01-01' AS DATE) AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSequence
    WHERE FullDate < '2025-12-31'
)
INSERT INTO dbo.DimDate
(
    DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear,
    WeekOfYear, MonthNumber, MonthName, Quarter, QuarterName,
    [Year], IsWeekend, FiscalYear, FiscalQuarter
)
SELECT
    CONVERT(INT, FORMAT(ds.FullDate, 'yyyyMMdd'))           AS DateKey,
    ds.FullDate,
    DATEPART(WEEKDAY, ds.FullDate)                          AS DayOfWeek,
    DATENAME(WEEKDAY, ds.FullDate)                         AS DayName,
    DAY(ds.FullDate)                                        AS DayOfMonth,
    DATEPART(DAYOFYEAR, ds.FullDate)                        AS DayOfYear,
    DATEPART(ISO_WEEK, ds.FullDate)                         AS WeekOfYear,
    MONTH(ds.FullDate)                                      AS MonthNumber,
    DATENAME(MONTH, ds.FullDate)                            AS MonthName,
    DATEPART(QUARTER, ds.FullDate)                          AS Quarter,
    CONCAT('Q', DATEPART(QUARTER, ds.FullDate))             AS QuarterName,
    YEAR(ds.FullDate)                                       AS [Year],
    CASE WHEN DATEPART(WEEKDAY, ds.FullDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    CASE WHEN MONTH(ds.FullDate) >= 7 THEN YEAR(ds.FullDate) + 1 ELSE YEAR(ds.FullDate) END AS FiscalYear,
    CASE
        WHEN MONTH(ds.FullDate) IN (7, 8, 9)   THEN 1
        WHEN MONTH(ds.FullDate) IN (10, 11, 12) THEN 2
        WHEN MONTH(ds.FullDate) IN (1, 2, 3)    THEN 3
        ELSE 4
    END AS FiscalQuarter
FROM DateSequence ds
OPTION (MAXRECURSION 0);
GO

PRINT CONCAT('DimDate populated with ', @@ROWCOUNT, ' rows.');
GO
