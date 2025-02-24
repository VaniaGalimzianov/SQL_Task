CREATE OR ALTER PROCEDURE LoadSuppliersFromXML
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
        MERGE INTO dbo.Suppliers AS target
        USING (
            SELECT 
                Item.value('(id)[1]', 'INT') AS id,
                Item.value('(name)[1]', 'NVARCHAR(255)') AS name,
                Item.value('(created_date)[1]', 'DATETIME') AS created_date,
                Item.value('(last_update_date)[1]', 'DATETIME') AS last_update_date,
                Item.value('(external_id)[1]', 'INT') AS external_id,
                Item.value('(type_name)[1]', 'NVARCHAR(255)') AS type_name
            FROM @XmlData.nodes('/root/suppliers/supplier') AS ItemData(Item)
        ) AS source
        ON target.id = source.id
        WHEN MATCHED THEN 
            UPDATE SET 
                target.name = source.name,
                target.last_update_date = source.last_update_date,
                target.external_id = source.external_id,
                target.type_name = source.type_name
        WHEN NOT MATCHED THEN
            INSERT (id, name, created_date, last_update_date, external_id, type_name)
            VALUES (source.id, source.name, source.created_date, source.last_update_date, source.external_id, source.type_name);

        -- Логирование успешной загрузки
        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadSuppliersFromXML', 'Successful data load into table Suppliers', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage;
        EXEC LogProcess 'LoadSuppliersFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
