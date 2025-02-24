CREATE OR ALTER PROCEDURE LoadStoresFromXML
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
        TRUNCATE TABLE stores;

        -- Загружаем XML файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу stores
        INSERT INTO stores (id, name, address, phone, open_time, close_time, created_date, last_update_date, lat, lon, location_name, organisation_id, manager_user_id)
        SELECT 
            StoreData.value('(id)[1]', 'INT'),
            StoreData.value('(name)[1]', 'NVARCHAR(255)'),
            StoreData.value('(address)[1]', 'NVARCHAR(255)'),
            StoreData.value('(phone)[1]', 'NVARCHAR(50)'),
            StoreData.value('(open_time)[1]', 'TIME'),
            StoreData.value('(close_time)[1]', 'TIME'),
            TRY_CAST(StoreData.value('(created_date)[1]', 'NVARCHAR(19)') AS DATETIME2),
            TRY_CAST(StoreData.value('(last_update_date)[1]', 'NVARCHAR(19)') AS DATETIME2),
            StoreData.value('(lat)[1]', 'DECIMAL(15,8)'),
            StoreData.value('(lon)[1]', 'DECIMAL(15,8)'),
            StoreData.value('(location_name)[1]', 'NVARCHAR(100)'),
            StoreData.value('(organisation_id)[1]', 'INT'),
            StoreData.value('(manager_user_id)[1]', 'INT')
        FROM @XmlData.nodes('/root/warehouses/warehouse') AS StoreData(StoreData);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadStoresFromXML', 'Successful data load into table stores', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadStoresFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
