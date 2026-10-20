-- ============================================================================
-- 06_CREATE_VIEWS.sql
-- Analytical views for SSRS, Tableau, and ad-hoc queries
-- ============================================================================

USE AW_Retail_DW;
GO

CREATE OR ALTER VIEW dbo.vw_SalesSummary
AS
SELECT
    d.[Year],
    d.MonthNumber,
    d.MonthName,
    d.Quarter,
    d.QuarterName,
    COUNT(DISTINCT f.SalesOrderNumber)     AS OrderCount,
    SUM(f.OrderQty)                        AS UnitsSold,
    SUM(f.LineTotal)                       AS TotalRevenue,
    SUM(f.StandardCost)                    AS TotalCost,
    SUM(f.GrossProfit)                     AS TotalGrossProfit,
    CASE WHEN SUM(f.LineTotal) = 0 THEN 0
         ELSE SUM(f.GrossProfit) / SUM(f.LineTotal) * 100 END AS GrossMarginPct
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimDate AS d ON f.OrderDateKey = d.DateKey
GROUP BY d.[Year], d.MonthNumber, d.MonthName, d.Quarter, d.QuarterName;
GO

CREATE OR ALTER VIEW dbo.vw_ProductPerformance
AS
SELECT
    p.ProductKey,
    p.ProductID,
    p.ProductName,
    p.CategoryName,
    p.SubcategoryName,
    p.Color,
    SUM(f.OrderQty)                        AS UnitsSold,
    SUM(f.LineTotal)                       AS TotalRevenue,
    SUM(f.GrossProfit)                     AS TotalGrossProfit,
    CASE WHEN SUM(f.LineTotal) = 0 THEN 0
         ELSE SUM(f.GrossProfit) / SUM(f.LineTotal) * 100 END AS GrossMarginPct,
    AVG(f.UnitPrice)                       AS AvgUnitPrice
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimProduct AS p ON f.ProductKey = p.ProductKey AND p.IsCurrent = 1
GROUP BY p.ProductKey, p.ProductID, p.ProductName, p.CategoryName, p.SubcategoryName, p.Color;
GO

CREATE OR ALTER VIEW dbo.vw_CustomerAnalysis
AS
SELECT
    c.CustomerKey,
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.TerritoryName,
    c.CountryRegion,
    COUNT(DISTINCT f.SalesOrderNumber)     AS OrderCount,
    SUM(f.OrderQty)                        AS UnitsPurchased,
    SUM(f.LineTotal)                       AS TotalRevenue,
    SUM(f.GrossProfit)                     AS TotalGrossProfit,
    CASE WHEN COUNT(DISTINCT f.SalesOrderNumber) = 0 THEN 0
         ELSE SUM(f.LineTotal) / COUNT(DISTINCT f.SalesOrderNumber) END AS AvgOrderValue
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimCustomer AS c ON f.CustomerKey = c.CustomerKey AND c.IsCurrent = 1
GROUP BY c.CustomerKey, c.CustomerID, c.CustomerName, c.CustomerType, c.TerritoryName, c.CountryRegion;
GO

CREATE OR ALTER VIEW dbo.vw_TerritoryPerformance
AS
SELECT
    t.TerritoryKey,
    t.TerritoryID,
    t.TerritoryName,
    t.CountryRegionCode,
    t.RegionGroup,
    t.SalesYTD,
    t.SalesLastYear,
    COUNT(DISTINCT f.SalesOrderNumber)     AS OrderCount,
    SUM(f.OrderQty)                        AS UnitsSold,
    SUM(f.LineTotal)                       AS TotalRevenue,
    SUM(f.GrossProfit)                     AS TotalGrossProfit,
    CASE WHEN COUNT(DISTINCT f.SalesOrderNumber) = 0 THEN 0
         ELSE SUM(f.LineTotal) / COUNT(DISTINCT f.SalesOrderNumber) END AS AvgOrderValue
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimTerritory AS t ON f.TerritoryKey = t.TerritoryKey
GROUP BY t.TerritoryKey, t.TerritoryID, t.TerritoryName, t.CountryRegionCode,
         t.RegionGroup, t.SalesYTD, t.SalesLastYear;
GO

CREATE OR ALTER VIEW dbo.vw_SalesDetail
AS
SELECT
    f.SalesOrderNumber,
    f.SalesOrderLineNumber,
    od.FullDate                            AS OrderDate,
    sd.FullDate                            AS ShipDate,
    p.ProductName,
    p.CategoryName,
    p.SubcategoryName,
    c.CustomerName,
    c.CustomerType,
    t.TerritoryName,
    t.RegionGroup,
    e.EmployeeName,
    f.OrderQty,
    f.UnitPrice,
    f.DiscountAmount,
    f.LineTotal,
    f.GrossProfit
FROM dbo.FactInternetSales AS f
INNER JOIN dbo.DimDate AS od ON f.OrderDateKey = od.DateKey
LEFT JOIN dbo.DimDate AS sd ON f.ShipDateKey = sd.DateKey
INNER JOIN dbo.DimProduct AS p ON f.ProductKey = p.ProductKey AND p.IsCurrent = 1
INNER JOIN dbo.DimCustomer AS c ON f.CustomerKey = c.CustomerKey AND c.IsCurrent = 1
INNER JOIN dbo.DimTerritory AS t ON f.TerritoryKey = t.TerritoryKey
INNER JOIN dbo.DimEmployee AS e ON f.EmployeeKey = e.EmployeeKey;
GO

PRINT 'Views created successfully.';
GO
