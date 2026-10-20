-- ============================================================================
-- 09_COMPARISON_QUERIES.sql
-- Seven SQL queries matching neo4j/05_business_queries.cypher
-- Used for relational vs graph database comparison (Task 5)
-- ============================================================================

USE AdventureWorks2022;
GO

-- Q1: Total revenue and order count
SELECT
    COUNT(DISTINCT h.SalesOrderID)     AS totalOrders,
    ROUND(SUM(h.TotalDue), 2)          AS totalRevenue
FROM Sales.SalesOrderHeader AS h
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6);
GO

-- Q2: Top 10 products by revenue
SELECT TOP 10
    p.Name                             AS productName,
    pc.Name                            AS category,
    SUM(d.OrderQty)                    AS unitsSold,
    ROUND(SUM(d.LineTotal), 2)         AS totalRevenue
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d ON h.SalesOrderID = d.SalesOrderID
INNER JOIN Production.Product AS p ON d.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
GROUP BY p.Name, pc.Name
ORDER BY totalRevenue DESC;
GO

-- Q3: Top 10 customers by revenue
SELECT TOP 10
    COALESCE(CONCAT(pp.FirstName, ' ', pp.LastName), s.Name) AS customerName,
    CASE WHEN c.PersonID IS NOT NULL THEN 'Individual' ELSE 'Store' END AS customerType,
    COUNT(DISTINCT h.SalesOrderID)     AS orderCount,
    ROUND(SUM(h.TotalDue), 2)          AS totalRevenue
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.Customer AS c ON h.CustomerID = c.CustomerID
LEFT JOIN Person.Person AS pp ON c.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store AS s ON c.StoreID = s.BusinessEntityID
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
GROUP BY COALESCE(CONCAT(pp.FirstName, ' ', pp.LastName), s.Name),
         CASE WHEN c.PersonID IS NOT NULL THEN 'Individual' ELSE 'Store' END
ORDER BY totalRevenue DESC;
GO

-- Q4: Territory revenue ranking
SELECT
    t.Name                             AS territoryName,
    t.[Group]                          AS regionGroup,
    COUNT(DISTINCT h.SalesOrderID)     AS orderCount,
    ROUND(SUM(h.TotalDue), 2)          AS totalRevenue
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesTerritory AS t ON h.TerritoryID = t.TerritoryID
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
GROUP BY t.Name, t.[Group]
ORDER BY totalRevenue DESC;
GO

-- Q5: Products frequently bought together (relational — self-join)
SELECT TOP 10
    p1.Name                            AS product1,
    p2.Name                            AS product2,
    COUNT(DISTINCT h.SalesOrderID)     AS coPurchaseCount,
    ROUND(SUM(d1.LineTotal + d2.LineTotal), 2) AS combinedRevenue
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d1 ON h.SalesOrderID = d1.SalesOrderID
INNER JOIN Sales.SalesOrderDetail AS d2 ON h.SalesOrderID = d2.SalesOrderID
    AND d1.ProductID < d2.ProductID
INNER JOIN Production.Product AS p1 ON d1.ProductID = p1.ProductID
INNER JOIN Production.Product AS p2 ON d2.ProductID = p2.ProductID
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
GROUP BY p1.Name, p2.Name
HAVING COUNT(DISTINCT h.SalesOrderID) >= 5
ORDER BY coPurchaseCount DESC;
GO

-- Q6: Path between categories via co-purchased products (relational — recursive CTE)
WITH CoPurchase AS
(
    SELECT
        p1.ProductID AS product1Id, pc1.Name AS cat1,
        p2.ProductID AS product2Id, pc2.Name AS cat2
    FROM Sales.SalesOrderHeader AS h
    INNER JOIN Sales.SalesOrderDetail AS d1 ON h.SalesOrderID = d1.SalesOrderID
    INNER JOIN Sales.SalesOrderDetail AS d2 ON h.SalesOrderID = d2.SalesOrderID AND d1.ProductID < d2.ProductID
    INNER JOIN Production.Product AS p1 ON d1.ProductID = p1.ProductID
    INNER JOIN Production.Product AS p2 ON d2.ProductID = p2.ProductID
    INNER JOIN Production.ProductSubcategory AS psc1 ON p1.ProductSubcategoryID = psc1.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc1 ON psc1.ProductCategoryID = pc1.ProductCategoryID
    INNER JOIN Production.ProductSubcategory AS psc2 ON p2.ProductSubcategoryID = psc2.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS pc2 ON psc2.ProductCategoryID = pc2.ProductCategoryID
    WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
    GROUP BY p1.ProductID, pc1.Name, p2.ProductID, pc2.Name
    HAVING COUNT(DISTINCT h.SalesOrderID) >= 3
),
Paths AS
(
    SELECT cat1, cat2, product1Id, product2Id, 1 AS depth,
           CAST(pc1.cat1 + ' -> ' + p1.Name AS NVARCHAR(MAX)) AS pathTrace
    FROM CoPurchase cp
    INNER JOIN Production.Product p1 ON cp.product1Id = p1.ProductID
    INNER JOIN Production.ProductCategory pc1 ON cp.cat1 = pc1.Name
    WHERE cp.cat1 = 'Bikes' AND cp.cat2 <> 'Bikes'

    UNION ALL

    SELECT p.cat1, cp.cat2, cp.product1Id, cp.product2Id, p.depth + 1,
           p.pathTrace + ' -> ' + p2.Name
    FROM Paths p
    INNER JOIN CoPurchase cp ON cp.product1Id = p.product2Id
    INNER JOIN Production.Product p2 ON cp.product2Id = p2.ProductID
    WHERE p.depth < 4 AND cp.cat2 = 'Accessories'
)
SELECT TOP 5 pathTrace, depth AS pathLength
FROM Paths
WHERE cat2 = 'Accessories'
ORDER BY pathLength;
GO

-- Q7: Customer → Order → Product → Category (multi-table join)
SELECT TOP 15
    COALESCE(CONCAT(pp.FirstName, ' ', pp.LastName), 'Unknown') AS customer,
    pc.Name                            AS category,
    COUNT(DISTINCT h.SalesOrderID)     AS orders,
    SUM(p.ListPrice)                   AS approxSpend
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.Customer AS c ON h.CustomerID = c.CustomerID
INNER JOIN Person.Person AS pp ON c.PersonID = pp.BusinessEntityID
INNER JOIN Sales.SalesOrderDetail AS d ON h.SalesOrderID = d.SalesOrderID
INNER JOIN Production.Product AS p ON d.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory AS psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory AS pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE h.OnlineOrderFlag = 1 AND h.Status NOT IN (4, 6)
  AND h.OrderDate >= '2013-01-01'
  AND c.PersonID IS NOT NULL
GROUP BY COALESCE(CONCAT(pp.FirstName, ' ', pp.LastName), 'Unknown'), pc.Name
ORDER BY orders DESC;
GO
