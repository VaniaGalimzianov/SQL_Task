CREATE OR ALTER PROCEDURE LoadGoodsFromXML
    @XmlFilePath NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @XmlData XML;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @LogError NVARCHAR(MAX);
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Выполняем MERGE
        MERGE INTO dbo.Goods AS target
        USING (
            SELECT 
                Item.value('(id)[1]', 'INT') AS id,
                Item.value('(name)[1]', 'NVARCHAR(255)') AS name,
                Item.value('(manufacturer_id)[1]', 'INT') AS manufacturer_id,
                Item.value('(barcodes)[1]', 'NVARCHAR(100)') AS barcodes,
                Item.value('(vat_percent)[1]', 'DECIMAL(5,2)') AS vat_percent,
                Item.value('(created_date)[1]', 'DATETIME') AS created_date,
                Item.value('(last_update_date)[1]', 'DATETIME') AS last_update_date
            FROM @XmlData.nodes('/root/items/item') AS ItemData(Item)
        ) AS source
        ON target.id = source.id
        WHEN MATCHED THEN 
            UPDATE SET 
                target.name = source.name,
                target.manufacturer_id = source.manufacturer_id,
                target.barcodes = source.barcodes,
                target.vat_percent = source.vat_percent,
                target.last_update_date = source.last_update_date
        WHEN NOT MATCHED THEN
            INSERT (id, name, manufacturer_id, barcodes, vat_percent, created_date, last_update_date)
            VALUES (source.id, source.name, source.manufacturer_id, source.barcodes, source.vat_percent, source.created_date, source.last_update_date);

        -- Логирование успешной загрузки
        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadGoodsFromXML', 'Successful data load into table Goods', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage;
        EXEC LogProcess 'LoadGoodGroupsFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
