UPDATE AdventureWorksDW2022.dbo.stg_dimemp 
SET FirstName = 'Ryszard'  --typ 0 (zachowanie oryginalnych danych)
WHERE EmployeeKey = 275;

--w przypadku tej kwerendy próbowano zmieniæ atrybut ustawiony jako fixed-attribute, którego jest "niezmienny".
-- Z powodu zaznaczenia opcji Fail the transformation if changes are detected in a fixed attribute, wykonanie
-- pakietu SSIS nie zakoñczy³o siê sukcesem







