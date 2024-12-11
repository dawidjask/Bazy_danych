IF OBJECT_ID('AdventureWorksDW2022.dbo.CSV_Customers', 'U') IS NOT NULL
DROP TABLE AdventureWorksDW2022.dbo.CSV_Customers;

CREATE TABLE AdventureWorksDW2022.dbo.CSV_Customers(
	FirstName varchar(255),
	LastName varchar(255),
	EmailAddress varchar(255),
	Address varchar(255),
	City varchar(255),
	Region varchar(255),
	PhoneNumber varchar(50),
	CREATE_TIMESTAMP datetime,
	UPDATE_TIMESTAMP datetime
);

