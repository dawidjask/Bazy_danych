DROP TABLE IF EXISTS AdventureWorksDW2022.dbo.CUSTOMERS_403167;
CREATE TABLE AdventureWorksDW2022.dbo.CUSTOMERS_403167 (
    ProductKey INT,
    CurrencyAlternateKey VARCHAR(3),
    LAST_NAME VARCHAR(255) NOT NULL,
    FIRST_NAME VARCHAR(255) NOT NULL,
    OrderDateKey INT,
    OrderQuantity INT,
    UnitPrice DECIMAL(10, 2),
    SecretCode VARCHAR(10)
);
