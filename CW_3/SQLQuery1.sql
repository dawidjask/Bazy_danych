-- 1. Tworzymy procedurê
CREATE PROCEDURE GetCurrencyRatesByYearsAgo
    @YearsAgo INT
AS
BEGIN
    -- Obliczanie daty sprzed @YearsAgo lat
    DECLARE @CutOffDate DATE;
    SET @CutOffDate = DATEADD(YEAR, -@YearsAgo, GETDATE());

    -- Wybieramy kursy wymiany dla GBP i EUR
    SELECT
        fcr.CurrencyKey,
        dc.CurrencyAlternateKey,
        fcr.DateKey,
        fcr.Date,
        fcr.AverageRate,
        fcr.EndOfDayRate
    FROM
        FactCurrencyRate fcr
    INNER JOIN
        DimCurrency dc
    ON
        fcr.CurrencyKey = dc.CurrencyKey
    WHERE
        fcr.Date <= @CutOffDate
        AND (dc.CurrencyAlternateKey = 'GBP' OR dc.CurrencyAlternateKey = 'EUR');
END;

-- 2. Wywo³anie procedury, by natychmiast zobaczyæ wyniki
EXEC GetCurrencyRatesByYearsAgo @YearsAgo = 5;
