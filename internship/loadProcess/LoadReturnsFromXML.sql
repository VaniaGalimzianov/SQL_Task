CREATE OR ALTER PROCEDURE LoadReturnsFromXML
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

        -- Вставка данных в таблицу returns
        INSERT INTO returns (id, warehouse_id, docnum, docdate, supplier_id, amount, status, status_name)
        SELECT 
            ReceiptLine.value('(id)[1]', 'INT'),
            ReceiptLine.value('(warehouse_id)[1]', 'INT'),
            ReceiptLine.value('(docnum)[1]', 'VARCHAR(255)'),
            ReceiptLine.value('(docdate)[1]', 'DATETIME2'),
            ReceiptLine.value('(supplier_id)[1]', 'INT'),
            ReceiptLine.value('(amount)[1]', 'DECIMAL(10,2)'),
            ReceiptLine.value('(status)[1]', 'VARCHAR(255)'),
            ReceiptLine.value('(status_name)[1]', 'VARCHAR(255)')
        FROM @XmlData.nodes('/root/returns/return') AS ReceiptLine(ReceiptLine);

        SET @EndTime = SYSDATETIME();

        -- Логирование успешной загрузки
        EXEC LogProcess 'LoadReturnsFromXML', 'Successful data load into table returns', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логирование ошибки загрузки
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReturnsFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
