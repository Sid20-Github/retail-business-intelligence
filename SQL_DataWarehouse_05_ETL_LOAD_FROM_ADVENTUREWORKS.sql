-- ============================================================================
-- 05_ETL_LOAD_FROM_ADVENTUREWORKS.sql
-- Full initial load from AdventureWorks2022 into AW_Retail_DW
-- Run after 01-04 scripts. Mirrors SSIS package logic for standalone execution.
-- ============================================================================

USE AW_Retail_DW;
GO

SET NOCOUNT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    -- Clear fact first so dimension tables can be refreshed
    TRUNCATE TABLE dbo.FactInternetSales;

    -- -----------------------------------------------------------------------
    -- DimTerritory (Type 1 — full refresh)
    -- -----------------------------------------------------------------------
    DELETE FROM dbo.DimTerritory;

    INSERT INTO dbo.DimTerritory
        (TerritoryID, TerritoryName, CountryRegionCode, RegionGroup, SalesYTD, SalesLastYear)
    SELECT
        st.TerritoryID,
        st.Name,
        st.CountryRegionCode,
        st.[Group],
        CAST(st.SalesYTD AS DECIMAL(19,4)),
        CAST(st.SalesLastYear AS DECIMAL(19,4))
    FROM AdventureWorks2022.Sales.SalesTerritory AS st;

    -- -----------------------------------------------------------------------
    -- DimEmployee (Type 1 — full refresh, preserve Unknown row)
    -- -----------------------------------------------------------------------
    DELETE FROM dbo.DimEmployee WHERE EmployeeKey <> 0;

    INSERT INTO dbo.DimEmployee
        (EmployeeKey, EmployeeID, EmployeeName, Title, TerritoryName, SalesQuota, CommissionPct)
    SELECT
        sp.BusinessEntityID,
        sp.BusinessEntityID,
        CONCAT(p.FirstName, N' ', p.LastName),
        e.JobTitle,
        st.Name,
        CAST(sp.SalesQuota AS DECIMAL(19,4)),
        CAST(sp.CommissionPct AS DECIMAL(5,4))
    FROM AdventureWorks2022.Sales.SalesPerson AS sp
    INNER JOIN AdventureWorks2022.HumanResources.Employee AS e
        ON sp.BusinessEntityID = e.BusinessEntityID
    INNER JOIN AdventureWorks2022.Person.Person AS p
        ON e.BusinessEntityID = p.BusinessEntityID
    LEFT JOIN AdventureWorks2022.Sales.SalesTerritory AS st
        ON sp.TerritoryID = st.TerritoryID;

    -- -----------------------------------------------------------------------
    -- DimPromotion (Type 1 — full refresh, preserve None row)
    -- -----------------------------------------------------------------------
    DELETE FROM dbo.DimPromotion WHERE PromotionKey <> 0;

    INSERT INTO dbo.DimPromotion
        (PromotionKey, PromotionID, PromotionName, DiscountPct, [Type], Category)
    SELECT
        so.SpecialOfferID,
        so.SpecialOfferID,
        so.Description,
        CAST(so.DiscountPct AS DECIMAL(5,4)),
        so.[Type],
        so.Category
    FROM AdventureWorks2022.Sales.SpecialOffer AS so;

    -- -----------------------------------------------------------------------
    -- DimProduct (SCD Type 2 — initial load, all current)
    -- -----------------------------------------------------------------------
    DELETE FROM dbo.DimProduct;

    INSERT INTO dbo.DimProduct
    (
        ProductID, ProductNumber, ProductName, Color, Size,
        SubcategoryName, CategoryName, StandardCost, ListPrice,
        StartDate, EndDate, IsCurrent
    )
    SELECT
        p.ProductID,
        p.ProductNumber,
        p.Name,
        p.Color,
        p.Size,
        psc.Name,
        pc.Name,
        CAST(p.StandardCost AS DECIMAL(19,4)),
        CAST(p.ListPrice AS DECIMAL(19,4)),
        COALESCE(p.SellStartDate, '2011-01-01'),
        CAST('9999-12-31 23:59:59' AS DATETIME2(0)),
        1
    FROM AdventureWorks2022.Production.Product AS p
    LEFT JOIN AdventureWorks2022.Production.ProductSubcategory AS psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    LEFT JOIN AdventureWorks2022.Production.ProductCategory AS pc
        ON psc.ProductCategoryID = pc.ProductCategoryID;

    -- -----------------------------------------------------------------------
    -- DimCustomer (SCD Type 2 — initial load)
    -- -----------------------------------------------------------------------
    DELETE FROM dbo.DimCustomer;

    INSERT INTO dbo.DimCustomer
    (
        CustomerID, CustomerType, CustomerName, EmailPromotion,
        TerritoryName, CountryRegion, StartDate, EndDate, IsCurrent
    )
    SELECT
        c.CustomerID,
        CASE WHEN c.PersonID IS NOT NULL THEN N'Individual' ELSE N'Store' END,
        COALESCE(
            CONCAT(pp.FirstName, N' ', pp.LastName),
            s.Name,
            N'Unknown Customer'
        ),
        COALESCE(pp.EmailPromotion, 0),
        st.Name,
        st.CountryRegionCode,
        CAST('2011-01-01' AS DATETIME2(0)),
        CAST('9999-12-31 23:59:59' AS DATETIME2(0)),
        1
    FROM AdventureWorks2022.Sales.Customer AS c
    LEFT JOIN AdventureWorks2022.Person.Person AS pp
        ON c.PersonID = pp.BusinessEntityID
    LEFT JOIN AdventureWorks2022.Sales.Store AS s
        ON c.StoreID = s.BusinessEntityID
    LEFT JOIN AdventureWorks2022.Sales.SalesTerritory AS st
        ON c.TerritoryID = st.TerritoryID;

    -- -----------------------------------------------------------------------
    -- FactInternetSales
    -- -----------------------------------------------------------------------
    INSERT INTO dbo.FactInternetSales
    (
        SalesOrderNumber, SalesOrderLineNumber, OrderDateKey, ShipDateKey,
        ProductKey, CustomerKey, TerritoryKey, EmployeeKey, PromotionKey,
        OrderQty, UnitPrice, DiscountAmount, LineTotal, StandardCost, GrossProfit
    )
    SELECT
        h.SalesOrderNumber,
        d.SalesOrderDetailID,
        CONVERT(INT, FORMAT(CAST(h.OrderDate AS DATE), 'yyyyMMdd')),
        CASE WHEN h.ShipDate IS NULL THEN NULL
             ELSE CONVERT(INT, FORMAT(CAST(h.ShipDate AS DATE), 'yyyyMMdd')) END,
        dp.ProductKey,
        dc.CustomerKey,
        dt.TerritoryKey,
        COALESCE(de.EmployeeKey, 0),
        COALESCE(promo.PromotionKey, 0),
        d.OrderQty,
        CAST(d.UnitPrice AS DECIMAL(19,4)),
        CAST(d.OrderQty * d.UnitPriceDiscount AS DECIMAL(19,4)),
        CAST(d.LineTotal AS DECIMAL(19,4)),
        CAST(dp.StandardCost * d.OrderQty AS DECIMAL(19,4)),
        CAST(d.LineTotal - (dp.StandardCost * d.OrderQty) AS DECIMAL(19,4))
    FROM AdventureWorks2022.Sales.SalesOrderHeader AS h
    INNER JOIN AdventureWorks2022.Sales.SalesOrderDetail AS d
        ON h.SalesOrderID = d.SalesOrderID
    INNER JOIN dbo.DimProduct AS dp
        ON d.ProductID = dp.ProductID AND dp.IsCurrent = 1
    INNER JOIN dbo.DimCustomer AS dc
        ON h.CustomerID = dc.CustomerID AND dc.IsCurrent = 1
    INNER JOIN dbo.DimTerritory AS dt
        ON h.TerritoryID = dt.TerritoryID
    LEFT JOIN dbo.DimEmployee AS de
        ON h.SalesPersonID = de.EmployeeID
    OUTER APPLY
    (
        SELECT TOP (1) dp2.PromotionKey
        FROM AdventureWorks2022.Sales.SpecialOfferProduct AS sop
        INNER JOIN AdventureWorks2022.Sales.SpecialOffer AS so
            ON sop.SpecialOfferID = so.SpecialOfferID
        INNER JOIN dbo.DimPromotion AS dp2
            ON so.SpecialOfferID = dp2.PromotionID
        WHERE sop.ProductID = d.ProductID
          AND h.OrderDate BETWEEN so.StartDate AND so.EndDate
        ORDER BY so.DiscountPct DESC
    ) AS promo
    WHERE h.OnlineOrderFlag = 1
      AND h.Status NOT IN (4, 6);

    -- -----------------------------------------------------------------------
    -- ETL Control record
    -- -----------------------------------------------------------------------
    DECLARE @FactRows INT = (SELECT COUNT(*) FROM dbo.FactInternetSales);

    INSERT INTO dbo.ETL_Control (PackageName, LastLoadDate, RowsProcessed)
    VALUES (N'Initial_Full_Load', SYSDATETIME(), @FactRows);

    COMMIT TRANSACTION;

    PRINT 'ETL full load completed successfully.';
    PRINT CONCAT('FactInternetSales rows: ', @FactRows);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO dbo.ETL_ErrorLog (PackageName, TaskName, ErrorCode, ErrorDescription)
    VALUES (N'Initial_Full_Load', N'SQL_Script', ERROR_NUMBER(), ERROR_MESSAGE());
    THROW;
END CATCH;
GO
