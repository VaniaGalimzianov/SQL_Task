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

        -- Информация о начале загрузки
        SET @LogInfo = 'Started loading XML from ' + @XmlFilePath;

        -- Динамическая загрузка XML файла в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';

        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставка данных в таблицу receipt_lines
        INSERT INTO receipt_lines (line_id, receipt_id, item_id, quantity, pricebase, pricesale, discount, amount, cogs)
        SELECT 
            NEWID() AS line_id,
            ReceiptLine.value('(receipt_id)[1]', 'UNIQUEIDENTIFIER'),
            ReceiptLine.value('(itemid)[1]', 'INT'),
            ReceiptLine.value('(quantity)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(pricebase)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(pricesale)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(discount)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(amount)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(cogs)[1]', 'DECIMAL(10,2)')
        FROM @XmlData.nodes('/root/receipts/receipt') AS ReceiptLine(ReceiptLine);

        SET @EndTime = SYSDATETIME();

        -- Логирование успешной загрузки
        EXEC LogProcess 'LoadReceiptLinesFromXML', 'Successful data load into table receipt_lines', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логирование ошибки загрузки
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReceiptLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
