CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,       -- Уникальный ключ в формате ГГГГММДД
    DateValue DATE NOT NULL,        -- Дата
    Year INT NOT NULL,              -- Год
    Quarter INT NOT NULL,           -- Квартал
    Month INT NOT NULL,             -- Номер месяца
    MonthName NVARCHAR(20) NOT NULL,-- Название месяца
    Day INT NOT NULL,               -- День месяца
    DayOfWeek INT NOT NULL,         -- День недели (1 = Понедельник)
    DayOfWeekName NVARCHAR(20) NOT NULL, -- Название дня недели
    WeekOfYear INT NOT NULL,        -- Номер недели в году
    IsWeekend BIT NOT NULL,         -- Флаг выходного дня
    IsHoliday BIT DEFAULT 0         -- Флаг праздника (можно обновить отдельно)
);

DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate DATE = DATEADD(YEAR, 5, @StartDate);
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate < @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey, DateValue, Year, Quarter, Month, MonthName, Day, 
        DayOfWeek, DayOfWeekName, WeekOfYear, IsWeekend
    )
    VALUES (
        CONVERT(INT, FORMAT(@CurrentDate, 'yyyyMMdd')),
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DAY(@CurrentDate),
        DATEPART(WEEKDAY, @CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        DATEPART(WEEK, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (7, 1) THEN 1 ELSE 0 END
    );

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;
