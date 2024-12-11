IF OBJECT_ID('AdventureWorksDW2022.dbo.AUDIT_TABLE', 'U') IS NOT NULL
DROP TABLE AdventureWorksDW2022.dbo.AUDIT_TABLE;

CREATE TABLE AdventureWorksDW2022.dbo.AUDIT_TABLE(
	JobID integer,
	StartDT datetime,
	EndDT datetime,
	Rowcnt integer
);

