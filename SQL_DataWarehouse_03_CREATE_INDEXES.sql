-- ============================================================================
-- 03_CREATE_INDEXES.sql
-- Non-clustered indexes for query performance
-- ============================================================================

USE AW_Retail_DW;
GO

-- DimProduct: lookup by business key and current row
CREATE NONCLUSTERED INDEX IX_DimProduct_ProductID_IsCurrent
    ON dbo.DimProduct (ProductID, IsCurrent)
    INCLUDE (ProductKey, ProductName, CategoryName, SubcategoryName, StandardCost);
GO

CREATE NONCLUSTERED INDEX IX_DimProduct_Category
    ON dbo.DimProduct (CategoryName, SubcategoryName)
    INCLUDE (ProductKey, ProductName, ListPrice);
GO

-- DimCustomer: lookup by business key
CREATE NONCLUSTERED INDEX IX_DimCustomer_CustomerID_IsCurrent
    ON dbo.DimCustomer (CustomerID, IsCurrent)
    INCLUDE (CustomerKey, CustomerName, CustomerType);
GO

-- DimDate: year/month for aggregations
CREATE NONCLUSTERED INDEX IX_DimDate_Year_Month
    ON dbo.DimDate ([Year], MonthNumber)
    INCLUDE (DateKey, FullDate, MonthName, Quarter);
GO

-- FactInternetSales: common filter and join columns
CREATE NONCLUSTERED INDEX IX_FactInternetSales_OrderDateKey
    ON dbo.FactInternetSales (OrderDateKey)
    INCLUDE (LineTotal, OrderQty, GrossProfit, ProductKey, CustomerKey, TerritoryKey);
GO

CREATE NONCLUSTERED INDEX IX_FactInternetSales_ProductKey
    ON dbo.FactInternetSales (ProductKey)
    INCLUDE (LineTotal, OrderQty, GrossProfit, OrderDateKey);
GO

CREATE NONCLUSTERED INDEX IX_FactInternetSales_CustomerKey
    ON dbo.FactInternetSales (CustomerKey)
    INCLUDE (LineTotal, OrderQty, OrderDateKey);
GO

CREATE NONCLUSTERED INDEX IX_FactInternetSales_TerritoryKey
    ON dbo.FactInternetSales (TerritoryKey)
    INCLUDE (LineTotal, OrderQty, OrderDateKey);
GO

CREATE NONCLUSTERED INDEX IX_FactInternetSales_EmployeeKey
    ON dbo.FactInternetSales (EmployeeKey)
    INCLUDE (LineTotal, OrderDateKey);
GO

PRINT 'Indexes created successfully.';
GO
