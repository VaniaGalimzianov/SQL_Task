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

        -- Информация о начале загрузки
        SET @LogInfo = 'Started loading XML from ' + @XmlFilePath;

        -- Динамическая загрузка XML файла в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';

        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставка данных в таблицу return_lines
        INSERT INTO return_lines (line_id, return_id, item_id, quantity, price, amount, expir_date)
        SELECT 
            ReceiptLine.value('(line_id)[1]', 'INT'),
            ReceiptLine.value('(return_id)[1]', 'INT'),
            ReceiptLine.value('(item_id)[1]', 'INT'),
            ReceiptLine.value('(quantity)[1]', 'INT'),
            ReceiptLine.value('(price)[1]', 'DECIMAL(10, 2)'),
            ReceiptLine.value('(amount)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(expir_date)[1]', 'DATE')
        FROM @XmlData.nodes('/root/returns/return') AS ReceiptLine(ReceiptLine);

        SET @EndTime = SYSDATETIME();

        -- Логирование успешной загрузки
        EXEC LogProcess 'LoadReturnLinesFromXML', 'Successful data load into table return_lines', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логирование ошибки загрузки
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReturnLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
