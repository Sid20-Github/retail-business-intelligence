-- ============================================================================
-- 01_CREATE_DATABASE.sql
-- B9DA111 Retail BI — Create AW_Retail_DW database
-- Prerequisites: SQL Server 2022, AdventureWorks2022 restored
-- ============================================================================

USE master;
GO

IF DB_ID(N'AW_Retail_DW') IS NOT NULL
BEGIN
    ALTER DATABASE AW_Retail_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AW_Retail_DW;
END
GO

CREATE DATABASE AW_Retail_DW;
GO

ALTER DATABASE AW_Retail_DW SET RECOVERY SIMPLE;
GO

USE AW_Retail_DW;
GO

PRINT 'Database AW_Retail_DW created successfully.';
GO
