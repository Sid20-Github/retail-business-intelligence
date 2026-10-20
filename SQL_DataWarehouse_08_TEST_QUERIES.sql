-- ============================================================================
-- 08_TEST_QUERIES.sql
-- Validation queries — run after full ETL load
-- ============================================================================

USE AW_Retail_DW;
GO

PRINT '=== TEST 1: Row counts ===';
SELECT 'DimDate' AS TableName, COUNT(*) AS RowCount FROM dbo.DimDate
UNION ALL SELECT 'DimProduct', COUNT(*) FROM dbo.DimProduct
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM dbo.DimCustomer
UNION ALL SELECT 'DimTerritory', COUNT(*) FROM dbo.DimTerritory
UNION ALL SELECT 'DimEmployee', COUNT(*) FROM dbo.DimEmployee
UNION ALL SELECT 'DimPromotion', COUNT(*) FROM dbo.DimPromotion
UNION ALL SELECT 'FactInternetSales', COUNT(*) FROM dbo.FactInternetSales;
GO

PRINT '=== TEST 2: Referential integrity — orphan fact rows ===';
SELECT COUNT(*) AS OrphanFactRows
FROM dbo.FactInternetSales AS f
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimDate d WHERE d.DateKey = f.OrderDateKey)
   OR NOT EXISTS (SELECT 1 FROM dbo.DimProduct p WHERE p.ProductKey = f.ProductKey)
   OR NOT EXISTS (SELECT 1 FROM dbo.DimCustomer c WHERE c.CustomerKey = f.CustomerKey)
   OR NOT EXISTS (SELECT 1 FROM dbo.DimTerritory t WHERE t.TerritoryKey = f.TerritoryKey);
GO

PRINT '=== TEST 3: Revenue reconciliation vs AdventureWorks2022 ===';
SELECT
    dw.TotalRevenue AS DW_Revenue,
    src.SourceRevenue,
    dw.TotalRevenue - src.SourceRevenue AS Variance
FROM
(
    SELECT SUM(LineTotal) AS TotalRevenue FROM dbo.FactInternetSales
) AS dw
CROSS JOIN
(
    SELECT SUM(d.LineTotal) AS SourceRevenue
    FROM AdventureWorks2022.Sales.SalesOrderHeader AS h
    INNER JOIN AdventureWorks2022.Sales.SalesOrderDetail AS d ON h.SalesOrderID = d.SalesOrderID
    WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
) AS src;
GO

PRINT '=== TEST 4: Monthly sales via stored procedure ===';
EXEC dbo.usp_Report_MonthlySales @Year = 2022;
GO

PRINT '=== TEST 5: Top 10 products ===';
EXEC dbo.usp_Report_ProductPerformance @TopN = 10;
GO

PRINT '=== TEST 6: Top 10 customers ===';
EXEC dbo.usp_Report_CustomerAnalysis @TopN = 10;
GO

PRINT '=== TEST 7: Territory performance ===';
EXEC dbo.usp_Report_TerritoryPerformance;
GO

PRINT '=== TEST 8: Gross margin function ===';
SELECT dbo.fn_GrossMarginPct(SUM(LineTotal), SUM(GrossProfit)) AS OverallMarginPct
FROM dbo.FactInternetSales;
GO

PRINT '=== TEST 9: Date range table-valued function ===';
SELECT * FROM dbo.fn_SalesByDateRange('2022-01-01', '2022-03-31')
ORDER BY FullDate;
GO

PRINT '=== TEST 10: ETL control and error log ===';
SELECT TOP 5 * FROM dbo.ETL_Control ORDER BY ControlID DESC;
SELECT TOP 5 * FROM dbo.ETL_ErrorLog ORDER BY ErrorLogID DESC;
GO

PRINT 'All test queries completed.';
GO
