SELECT 
    OrderDate,
    COUNT(*) AS OrdersCount
FROM 
    AdventureWorksDW2022.dbo.FactInternetSales
GROUP BY 
    OrderDate
HAVING 
    COUNT(*) < 100
ORDER BY 
    OrdersCount DESC;

WITH RankedProducts AS (
    SELECT 
        OrderDate,
        ProductKey,
        UnitPrice,
        ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC) AS Rank
    FROM 
        AdventureWorksDW2022.dbo.FactInternetSales
)
SELECT 
    OrderDate,
    ProductKey,
    UnitPrice
FROM 
    RankedProducts
WHERE 
    Rank <= 3
ORDER BY 
    OrderDate, Rank;
