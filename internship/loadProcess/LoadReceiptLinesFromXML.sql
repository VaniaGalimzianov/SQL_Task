CREATE OR ALTER PROCEDURE LoadReceiptLinesFromXML
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

        -- Вставляем данные в таблицу receipt_lines
        INSERT INTO receipt_lines (line_id, receipt_id, item_id, quantity, pricebase, pricesale, discount, amount, cogs)
        SELECT 
            ISNULL(Item.value('(line_id)[1]', 'UNIQUEIDENTIFIER'), NEWID()) AS line_id,
            Receipt.value('(receipt_id)[1]', 'UNIQUEIDENTIFIER'),
            Item.value('(itemid)[1]', 'INT'),
            ISNULL(Item.value('(quantity)[1]', 'DECIMAL(10,3)'), 0),
            ISNULL(Item.value('(pricebase)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Item.value('(pricesale)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Receipt.value('(discount)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Receipt.value('(amount)[1]', 'DECIMAL(10,2)'), 0.00),
            ISNULL(Item.value('(cogs)[1]', 'DECIMAL(10,2)'), 0.00)
        FROM @XmlData.nodes('/root/receipts/receipt') AS Receipt(Receipt)
        CROSS APPLY Receipt.nodes('items/item') AS Item(Item)
        WHERE Receipt.value('(receipt_id)[1]', 'UNIQUEIDENTIFIER') IN (SELECT receipt_id FROM receipts);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadReceiptLinesFromXML', 'Successful data load into table receipt_lines', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReceiptLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
