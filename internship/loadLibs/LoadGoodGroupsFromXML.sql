CREATE OR ALTER PROCEDURE LoadGoodGroupsFromXML
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
        SET @LogInfo = 'Started loading XML from ' + @XmlFilePath;

        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Используем MERGE для вставки или обновления данных
        MERGE INTO pharmacy.dbo.GoodGroups AS target
        USING (
            SELECT 
                Item.value('(id)[1]', 'INT') AS id,
                Item.value('(name)[1]', 'NVARCHAR(255)') AS name,
                Item.value('(parent_id)[1]', 'INT') AS parent_id,
                Item.value('(created_date)[1]', 'DATETIME') AS created_date,
                Item.value('(last_update_date)[1]', 'DATETIME') AS last_update_date
            FROM @XmlData.nodes('/root/item_groups/item_group') AS ItemData(Item)
        ) AS source
        ON target.id = source.id
        WHEN MATCHED THEN 
            UPDATE SET 
                target.name = source.name,
                target.parent_id = source.parent_id,
                target.last_update_date = source.last_update_date
        WHEN NOT MATCHED THEN
            INSERT (id, name, parent_id, created_date, last_update_date)
            VALUES (source.id, source.name, source.parent_id, source.created_date, source.last_update_date);

        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadGoodGroupsFromXML', 'Successful data load into table GoodGroups', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage;
        EXEC LogProcess 'LoadGoodGroupsFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
