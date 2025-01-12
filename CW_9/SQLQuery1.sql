SELECT in_file, SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_email
FROM AdventureWorksDW2022.dbo.STG_CUSTOMERS
GROUP BY in_file
ORDER BY CAST(in_file AS INT);