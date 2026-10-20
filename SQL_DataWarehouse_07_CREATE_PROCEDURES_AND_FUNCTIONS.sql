-- ============================================================================
-- 07_CREATE_PROCEDURES_AND_FUNCTIONS.sql
-- Stored procedures and scalar functions for ETL and reporting
-- ============================================================================

USE AW_Retail_DW;
GO

-- Scalar function: convert date to DateKey
CREATE OR ALTER FUNCTION dbo.fn_DateToKey (@InputDate DATE)
RETURNS INT
AS
BEGIN
    RETURN CONVERT(INT, FORMAT(@InputDate, 'yyyyMMdd'));
END;
GO

-- Scalar function: gross margin percentage
CREATE OR ALTER FUNCTION dbo.fn_GrossMarginPct
(
    @Revenue     DECIMAL(19,4),
    @GrossProfit DECIMAL(19,4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    IF @Revenue = 0 RETURN 0;
    RETURN ROUND(@GrossProfit / @Revenue * 100, 2);
END;
GO

-- Table-valued function: sales for a date range
CREATE OR ALTER FUNCTION dbo.fn_SalesByDateRange
(
    @StartDate DATE,
    @EndDate   DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        d.FullDate,
        d.[Year],
        d.MonthName,
        SUM(f.LineTotal)   AS Revenue,
        SUM(f.OrderQty)    AS Units,
        SUM(f.GrossProfit) AS GrossProfit
    FROM dbo.FactInternetSales AS f
    INNER JOIN dbo.DimDate AS d ON f.OrderDateKey = d.DateKey
    WHERE d.FullDate BETWEEN @StartDate AND @EndDate
    GROUP BY d.FullDate, d.[Year], d.MonthName
);
GO

-- Stored procedure: monthly sales report dataset
CREATE OR ALTER PROCEDURE dbo.usp_Report_MonthlySales
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [Year],
        MonthNumber,
        MonthName,
        OrderCount,
        UnitsSold,
        TotalRevenue,
        TotalGrossProfit,
        GrossMarginPct
    FROM dbo.vw_SalesSummary
    WHERE @Year IS NULL OR [Year] = @Year
    ORDER BY [Year], MonthNumber;
END;
GO

-- Stored procedure: product performance report
CREATE OR ALTER PROCEDURE dbo.usp_Report_ProductPerformance
    @CategoryName NVARCHAR(50) = NULL,
    @TopN         INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        ProductName,
        CategoryName,
        SubcategoryName,
        UnitsSold,
        TotalRevenue,
        TotalGrossProfit,
        GrossMarginPct
    FROM dbo.vw_ProductPerformance
    WHERE @CategoryName IS NULL OR CategoryName = @CategoryName
    ORDER BY TotalRevenue DESC;
END;
GO

-- Stored procedure: customer analysis report
CREATE OR ALTER PROCEDURE dbo.usp_Report_CustomerAnalysis
    @CustomerType NVARCHAR(10) = NULL,
    @TopN         INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        CustomerName,
        CustomerType,
        TerritoryName,
        CountryRegion,
        OrderCount,
        TotalRevenue,
        AvgOrderValue
    FROM dbo.vw_CustomerAnalysis
    WHERE @CustomerType IS NULL OR CustomerType = @CustomerType
    ORDER BY TotalRevenue DESC;
END;
GO

-- Stored procedure: territory performance report
CREATE OR ALTER PROCEDURE dbo.usp_Report_TerritoryPerformance
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TerritoryName,
        CountryRegionCode,
        RegionGroup,
        OrderCount,
        UnitsSold,
        TotalRevenue,
        TotalGrossProfit,
        AvgOrderValue,
        SalesYTD,
        SalesLastYear
    FROM dbo.vw_TerritoryPerformance
    ORDER BY TotalRevenue DESC;
END;
GO

-- Stored procedure: incremental ETL watermark
CREATE OR ALTER PROCEDURE dbo.usp_GetLastLoadDate
    @PackageName NVARCHAR(100),
    @LastLoadDate DATETIME2(0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @LastLoadDate = ISNULL(MAX(LastLoadDate), '1900-01-01')
    FROM dbo.ETL_Control
    WHERE PackageName = @PackageName;
END;
GO

PRINT 'Procedures and functions created successfully.';
GO
