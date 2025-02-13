CREATE OR ALTER PROCEDURE LoadReceiptsFromXML
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

        -- Динамическая загрузка XML файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';

        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставка данных в таблицу receipts
        INSERT INTO receipts (receipt_id, terminal_id, warehouse_id, doc_type, date, items_count)
        SELECT 
            NEWID() AS receipt_id,  -- Генерируем GUID, если его нет в XML
            Receipt.value('(terminalid)[1]', 'NVARCHAR(255)'),
            Receipt.value('(warehouseid)[1]', 'INT'),
            Receipt.value('(doc_type)[1]', 'NVARCHAR(10)'),
            TRY_CAST(Receipt.value('(date)[1]', 'NVARCHAR(19)') AS DATETIME2),
            Receipt.value('(items_count)[1]', 'INT')
        FROM @XmlData.nodes('/root/receipts/receipt') AS Receipt(Receipt);

		SET @EndTime = SYSDATETIME();

        -- Логирование успешной загрузки
        EXEC LogProcess 'LoadReceiptsFromXML', 'Successful data load into table receipts', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логировние ошибки загрузки
        SET @ErrorMessage = ERROR_MESSAGE();
		    SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReceiptsFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
