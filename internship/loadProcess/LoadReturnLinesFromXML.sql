CREATE OR ALTER PROCEDURE LoadReturnLinesFromXML
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

        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу return_lines, связывая return_id с товарами
        INSERT INTO return_lines (line_id, return_id, item_id, quantity, price, amount, expir_date)
        SELECT 
            Item.value('(line_id)[1]', 'INT'),
            ReturnData.value('(id)[1]', 'INT'),
            ISNULL(Item.value('(item_id)[1]', 'INT'), 0),
            ISNULL(Item.value('(quantity)[1]', 'DECIMAL(10,3)'), 0.000),
            ISNULL(Item.value('(price)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Item.value('(amount)[1]', 'DECIMAL(10,2)'), 0.00),
            TRY_CAST(Item.value('(expir_date)[1]', 'NVARCHAR(10)') AS DATE)
        FROM @XmlData.nodes('/root/returns/return') AS ReturnData(ReturnData)
        CROSS APPLY ReturnData.nodes('items/item') AS Item(Item)
        WHERE ReturnData.value('(id)[1]', 'INT') IN (SELECT id FROM returns);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadReturnLinesFromXML', 'Successful data load into table return_lines', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReturnLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
