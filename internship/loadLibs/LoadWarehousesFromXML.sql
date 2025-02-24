CREATE OR ALTER PROCEDURE LoadWarehousesFromXML
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
        MERGE INTO dbo.Warehouses AS target
        USING (
            SELECT 
                Item.value('(id)[1]', 'INT') AS id,
                Item.value('(name)[1]', 'NVARCHAR(255)') AS name,
                Item.value('(address)[1]', 'NVARCHAR(255)') AS address,
                Item.value('(phone)[1]', 'NVARCHAR(50)') AS phone,
                Item.value('(created_date)[1]', 'DATETIME') AS created_date,
                Item.value('(last_update_date)[1]', 'DATETIME') AS last_update_date,
                Item.value('(lat)[1]', 'DECIMAL(15,10)') AS lat,
                Item.value('(lon)[1]', 'DECIMAL(15,10)') AS lon,
                Item.value('(open_time)[1]', 'TIME') AS open_time,
                Item.value('(close_time)[1]', 'TIME') AS close_time
            FROM @XmlData.nodes('/root/warehouses/warehouse') AS ItemData(Item)
        ) AS source
        ON target.id = source.id
        WHEN MATCHED THEN 
            UPDATE SET 
                target.name = source.name,
                target.address = source.address,
                target.phone = source.phone,
                target.last_update_date = source.last_update_date
        WHEN NOT MATCHED THEN
            INSERT (id, name, address, phone, created_date, last_update_date, lat, lon, open_time, close_time)
            VALUES (source.id, source.name, source.address, source.phone, source.created_date, source.last_update_date, source.lat, source.lon, source.open_time, source.close_time);

        -- Логирование успешной загрузки
        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadWarehousesFromXML', 'Successful data load into table Warehouses', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage;
        EXEC LogProcess 'LoadWarehousesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
