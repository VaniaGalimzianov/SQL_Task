CREATE OR ALTER PROCEDURE LoadIncomeLinesFromXML
    @XmlFilePath NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @XmlData XML;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @LogInfo NVARCHAR(4000);
    DECLARE @LogError NVARCHAR(4000);
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @StartTime DATETIME2;
    DECLARE @EndTime DATETIME2;

    BEGIN TRY
        SET DATEFORMAT dmy;
        SET @StartTime = SYSDATETIME();

        -- Логируем начало загрузки
        SET @LogInfo = 'Started loading XML from ' + @XmlFilePath;

        -- Очищаем таблицу перед загрузкой
        TRUNCATE TABLE income;

        -- Загружаем XML файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу income_lines, связывая income_id с товарами
        INSERT INTO income_lines (item_id, quantity, price, amount, income_id)
        SELECT 
            ISNULL(Item.value('(item_id)[1]', 'INT'), 0),
            ISNULL(Item.value('(quantity)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Item.value('(price)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Item.value('(amount)[1]', 'DECIMAL(10,2)'), 0.00),
            Inflow.value('(id)[1]', 'INT')  -- Берем income_id из inflow
        FROM @XmlData.nodes('/root/inflows/inflow') AS Inflow(Inflow)
        CROSS APPLY Inflow.nodes('items/item') AS Item(Item)  -- Соединяем товары с приходами
        WHERE Inflow.value('(id)[1]', 'INT') IN (SELECT id FROM income);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadIncomeLinesFromXML', 'Successful data load into table income_lines', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadIncomeLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
