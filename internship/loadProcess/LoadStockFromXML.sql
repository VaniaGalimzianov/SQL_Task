
CREATE OR ALTER PROCEDURE LoadStockFromXML
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
        TRUNCATE TABLE stock;

        -- Загружаем XML в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу stock
        INSERT INTO stock (warehouse_id, item_id, quantity, cogs)
        SELECT 
            WarehouseData.value('(id)[1]', 'INT') AS warehouse_id,
            ItemData.value('(id)[1]', 'INT') AS item_id,
            ItemData.value('(quantity)[1]', 'DECIMAL(18,3)') AS quantity,
            ItemData.value('(cogs)[1]', 'DECIMAL(18,2)') AS cogs
        FROM @XmlData.nodes('/root/warehouses/warehouse') AS Warehouse(WarehouseData)
        CROSS APPLY WarehouseData.nodes('items/item') AS Items(ItemData);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadStockFromXML', 'Successful data load into table stock', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadStockFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
