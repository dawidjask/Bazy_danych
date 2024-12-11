UPDATE AdventureWorksDW2022.dbo.stg_dimemp 
SET LastName = 'Nowak' --typ 1 (nadpisywanie)
WHERE EmployeeKey = 270;


UPDATE AdventureWorksDW2022.dbo.stg_dimemp 
SET Title = 'Senior Design Engineer' --typ 2 (dodanie nowego rekordu)
WHERE EmployeeKey = 274;