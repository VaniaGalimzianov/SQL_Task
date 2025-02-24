CREATE OR ALTER PROCEDURE LoadMoveGoodsFromXML
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
        TRUNCATE TABLE movegoods;

        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу movegoods
        INSERT INTO movegoods (id, src_warehouse_id, dst_warehouse_id, amount, status, status_name, created_date)
        SELECT 
            Move.value('(id)[1]', 'INT'),
            Move.value('(src_warehouse_id)[1]', 'INT'),
            Move.value('(dst_warehouse_id)[1]', 'INT'),
            Move.value('(amount)[1]', 'DECIMAL(10,2)'),
            Move.value('(status)[1]', 'VARCHAR(255)'),
            Move.value('(status_name)[1]', 'VARCHAR(255)'),
            TRY_CAST(Move.value('(created_date)[1]', 'NVARCHAR(19)') AS DATETIME2)
        FROM @XmlData.nodes('/root/movegoods/movegood') AS MoveData(Move);

        SET @EndTime = SYSDATETIME();
        EXEC LogProcess 'LoadMoveGoodsFromXML', 'Successful data load into table movegoods', @StartTime, @EndTime;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadReturnLinesFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
