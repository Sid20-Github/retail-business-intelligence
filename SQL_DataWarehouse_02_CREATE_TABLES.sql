-- ============================================================================
-- 02_CREATE_TABLES.sql
-- Star schema tables for AW_Retail_DW
-- ============================================================================

USE AW_Retail_DW;
GO

-- ---------------------------------------------------------------------------
-- DimDate
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimDate
(
    DateKey         INT           NOT NULL,
    FullDate        DATE          NOT NULL,
    DayOfWeek       TINYINT       NOT NULL,
    DayName         NVARCHAR(10)  NOT NULL,
    DayOfMonth      TINYINT       NOT NULL,
    DayOfYear       SMALLINT      NOT NULL,
    WeekOfYear      TINYINT       NOT NULL,
    MonthNumber     TINYINT       NOT NULL,
    MonthName       NVARCHAR(10)  NOT NULL,
    Quarter         TINYINT       NOT NULL,
    QuarterName     NVARCHAR(2)   NOT NULL,
    [Year]          SMALLINT      NOT NULL,
    IsWeekend       BIT           NOT NULL,
    FiscalYear      SMALLINT      NOT NULL,
    FiscalQuarter   TINYINT       NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey),
    CONSTRAINT UQ_DimDate_FullDate UNIQUE (FullDate)
);
GO

-- ---------------------------------------------------------------------------
-- DimProduct (SCD Type 2)
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimProduct
(
    ProductKey       INT            NOT NULL IDENTITY(1,1),
    ProductID        INT            NOT NULL,
    ProductNumber    NVARCHAR(25)   NOT NULL,
    ProductName      NVARCHAR(50)   NOT NULL,
    Color            NVARCHAR(15)   NULL,
    Size             NVARCHAR(5)    NULL,
    SubcategoryName  NVARCHAR(50)   NULL,
    CategoryName     NVARCHAR(50)   NULL,
    StandardCost     DECIMAL(19,4)  NOT NULL,
    ListPrice        DECIMAL(19,4)  NOT NULL,
    StartDate        DATETIME2(0)   NOT NULL,
    EndDate          DATETIME2(0)   NOT NULL,
    IsCurrent        BIT            NOT NULL,
    CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ProductKey)
);
GO

-- ---------------------------------------------------------------------------
-- DimCustomer (SCD Type 2)
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimCustomer
(
    CustomerKey      INT            NOT NULL IDENTITY(1,1),
    CustomerID       INT            NOT NULL,
    CustomerType     NVARCHAR(10)   NOT NULL,
    CustomerName     NVARCHAR(100)  NOT NULL,
    EmailPromotion   INT            NOT NULL,
    TerritoryName    NVARCHAR(50)   NULL,
    CountryRegion    NVARCHAR(3)    NULL,
    StartDate        DATETIME2(0)   NOT NULL,
    EndDate          DATETIME2(0)   NOT NULL,
    IsCurrent        BIT            NOT NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerKey)
);
GO

-- ---------------------------------------------------------------------------
-- DimTerritory (SCD Type 1)
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimTerritory
(
    TerritoryKey         INT            NOT NULL IDENTITY(1,1),
    TerritoryID          INT            NOT NULL,
    TerritoryName        NVARCHAR(50)   NOT NULL,
    CountryRegionCode    NVARCHAR(3)    NOT NULL,
    RegionGroup          NVARCHAR(50)   NOT NULL,
    SalesYTD             DECIMAL(19,4)  NOT NULL,
    SalesLastYear        DECIMAL(19,4)  NOT NULL,
    CONSTRAINT PK_DimTerritory PRIMARY KEY CLUSTERED (TerritoryKey),
    CONSTRAINT UQ_DimTerritory_TerritoryID UNIQUE (TerritoryID)
);
GO

-- ---------------------------------------------------------------------------
-- DimEmployee (includes Unknown member at key 0)
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimEmployee
(
    EmployeeKey      INT            NOT NULL,
    EmployeeID       INT            NOT NULL,
    EmployeeName     NVARCHAR(100)  NOT NULL,
    Title            NVARCHAR(50)   NULL,
    TerritoryName    NVARCHAR(50)   NULL,
    SalesQuota       DECIMAL(19,4)  NULL,
    CommissionPct    DECIMAL(5,4)   NULL,
    CONSTRAINT PK_DimEmployee PRIMARY KEY CLUSTERED (EmployeeKey)
);
GO

INSERT INTO dbo.DimEmployee (EmployeeKey, EmployeeID, EmployeeName, Title, TerritoryName, SalesQuota, CommissionPct)
VALUES (0, -1, N'Unknown Salesperson', NULL, NULL, NULL, NULL);
GO

-- ---------------------------------------------------------------------------
-- DimPromotion (includes None member at key 0)
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.DimPromotion
(
    PromotionKey     INT            NOT NULL,
    PromotionID      INT            NOT NULL,
    PromotionName    NVARCHAR(255)  NOT NULL,
    DiscountPct      DECIMAL(5,4)   NULL,
    [Type]           NVARCHAR(50)   NULL,
    Category         NVARCHAR(50)   NULL,
    CONSTRAINT PK_DimPromotion PRIMARY KEY CLUSTERED (PromotionKey)
);
GO

INSERT INTO dbo.DimPromotion (PromotionKey, PromotionID, PromotionName, DiscountPct, [Type], Category)
VALUES (0, -1, N'No Promotion', NULL, NULL, NULL);
GO

-- ---------------------------------------------------------------------------
-- FactInternetSales
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.FactInternetSales
(
    FactInternetSalesKey  BIGINT         NOT NULL IDENTITY(1,1),
    SalesOrderNumber      NVARCHAR(25)   NOT NULL,
    SalesOrderLineNumber  INT            NOT NULL,
    OrderDateKey          INT            NOT NULL,
    ShipDateKey           INT            NULL,
    ProductKey            INT            NOT NULL,
    CustomerKey           INT            NOT NULL,
    TerritoryKey          INT            NOT NULL,
    EmployeeKey           INT            NOT NULL,
    PromotionKey          INT            NOT NULL,
    OrderQty              INT            NOT NULL,
    UnitPrice             DECIMAL(19,4)  NOT NULL,
    DiscountAmount        DECIMAL(19,4)  NOT NULL,
    LineTotal             DECIMAL(19,4)  NOT NULL,
    StandardCost          DECIMAL(19,4)  NOT NULL,
    GrossProfit           DECIMAL(19,4)  NOT NULL,
    CONSTRAINT PK_FactInternetSales PRIMARY KEY CLUSTERED (FactInternetSalesKey),
    CONSTRAINT FK_FactInternetSales_DimDate_Order
        FOREIGN KEY (OrderDateKey) REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactInternetSales_DimDate_Ship
        FOREIGN KEY (ShipDateKey) REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactInternetSales_DimProduct
        FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct (ProductKey),
    CONSTRAINT FK_FactInternetSales_DimCustomer
        FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactInternetSales_DimTerritory
        FOREIGN KEY (TerritoryKey) REFERENCES dbo.DimTerritory (TerritoryKey),
    CONSTRAINT FK_FactInternetSales_DimEmployee
        FOREIGN KEY (EmployeeKey) REFERENCES dbo.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactInternetSales_DimPromotion
        FOREIGN KEY (PromotionKey) REFERENCES dbo.DimPromotion (PromotionKey),
    CONSTRAINT UQ_FactInternetSales_OrderLine
        UNIQUE (SalesOrderNumber, SalesOrderLineNumber)
);
GO

-- ---------------------------------------------------------------------------
-- ETL Control and Logging
-- ---------------------------------------------------------------------------
CREATE TABLE dbo.ETL_Control
(
    ControlID        INT            NOT NULL IDENTITY(1,1),
    PackageName      NVARCHAR(100)  NOT NULL,
    LastLoadDate     DATETIME2(0)   NOT NULL,
    RowsProcessed    INT            NOT NULL DEFAULT 0,
    CONSTRAINT PK_ETL_Control PRIMARY KEY CLUSTERED (ControlID)
);
GO

CREATE TABLE dbo.ETL_ErrorLog
(
    ErrorLogID       BIGINT         NOT NULL IDENTITY(1,1),
    PackageName      NVARCHAR(100)  NOT NULL,
    TaskName         NVARCHAR(100)  NOT NULL,
    ErrorCode        INT            NULL,
    ErrorDescription NVARCHAR(4000) NOT NULL,
    ErrorDateTime    DATETIME2(0)   NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_ETL_ErrorLog PRIMARY KEY CLUSTERED (ErrorLogID)
);
GO

PRINT 'All warehouse tables created successfully.';
GO
