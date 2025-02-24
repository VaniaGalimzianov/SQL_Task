CREATE OR ALTER PROCEDURE LoadMoveGoodLinesFromXML
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
        TRUNCATE TABLE movegood_lines;

        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        INSERT INTO movegood_lines (line_id, movegood_id, item_id, quantity, price, amount)
        SELECT 
            Item.value('(line_id)[1]', 'INT') AS line_id,
            Move.value('(id)[1]', 'INT') AS movegood_id,
            Item.value('(item_id)[1]', 'INT'),
            Item.value('(quantity)[1]', 'DECIMAL(10,3)'),
            Item.value('(price)[1]', 'DECIMAL(10,4)'),
            Item.value('(amount)[1]', 'DECIMAL(10,2)')
        FROM @XmlData.nodes('/root/movegoods/movegood') AS MoveData(Move)
        CROSS APPLY Move.nodes('items/item') AS ItemData(Item);

        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadMoveGoodLinesFromXML', 'Successful data load into table movegoods_lines', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadMoveGoodLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
