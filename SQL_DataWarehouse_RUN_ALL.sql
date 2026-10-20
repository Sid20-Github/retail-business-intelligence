@echo off
REM ============================================================================
REM RUN_ALL.sql - Execute all warehouse scripts in order
REM Prerequisites: SQL Server 2022 with AdventureWorks2022 restored
REM Usage: sqlcmd -S YOUR_SERVER -E -i RUN_ALL.sql
REM ============================================================================

:r sql\01_CREATE_DATABASE.sql
:r sql\02_CREATE_TABLES.sql
:r sql\03_CREATE_INDEXES.sql
:r sql\04_POPULATE_DIM_DATE.sql
:r sql\05_ETL_LOAD_FROM_ADVENTUREWORKS.sql
:r sql\06_CREATE_VIEWS.sql
:r sql\07_CREATE_PROCEDURES_AND_FUNCTIONS.sql
:r sql\08_TEST_QUERIES.sql

PRINT 'All warehouse scripts executed.';
GO
