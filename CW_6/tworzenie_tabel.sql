IF OBJECT_ID('AdventureWorksDW2022.dbo.stg_dimemp', 'U') IS NOT NULL
DROP TABLE AdventureWorksDW2022.dbo.stg_dimemp;

SELECT 
    EmployeeKey,
    FirstName,
    LastName,
    Title
INTO AdventureWorksDW2022.dbo.stg_dimemp
FROM AdventureWorksDW2022.dbo.DimEmployee
WHERE EmployeeKey >= 270 AND EmployeeKey <= 275;

IF OBJECT_ID('AdventureWorksDW2022.dbo.scd_dimemp', 'U') IS NOT NULL
DROP TABLE AdventureWorksDW2022.dbo.scd_dimemp;

CREATE TABLE AdventureWorksDW2022.dbo.scd_dimemp (
    EmployeeKey int,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Title nvarchar(50),
    StartDate datetime,
    EndDate datetime
);


INSERT INTO AdventureWorksDW2022.dbo.scd_dimemp (EmployeeKey, FirstName, LastName, Title, StartDate, EndDate)
SELECT 
    EmployeeKey, 
    FirstName, 
    LastName, 
    Title, 
    NULL AS StartDate, 
    NULL AS EndDate
FROM AdventureWorksDW2022.dbo.DimEmployee
WHERE EmployeeKey >= 270 AND EmployeeKey <= 275;


SELECT * FROM AdventureWorksDW2022.dbo.stg_dimemp;
SELECT * FROM AdventureWorksDW2022.dbo.scd_dimemp;
