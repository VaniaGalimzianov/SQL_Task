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

        -- Загружаем XML-файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        INSERT INTO stock (id)
        SELECT 
            ReturnData.value('(id)[1]', 'INT')
        FROM @XmlData.nodes('/root/warehouses/warehouse') AS ReturnData(ReturnData)
        

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
