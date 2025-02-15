CREATE OR ALTER PROCEDURE LoadIncomeFromXML
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

        -- Загружаем XML файл в переменную
        SET @SQL = 'SELECT @XmlData = CAST(BulkColumn AS XML)
                    FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x;';
        EXEC sp_executesql @SQL, N'@XmlData XML OUTPUT', @XmlData OUTPUT;

        -- Вставляем данные в таблицу income
        INSERT INTO income (id, warehouse_id, docdate, supplier_id, amount, status)
        SELECT 
            IncomeData.value('(id)[1]', 'INT'),
            IncomeData.value('(warehouse_id)[1]', 'INT'),
            TRY_CAST(IncomeData.value('(docdate)[1]', 'NVARCHAR(19)') AS DATETIME2),
            IncomeData.value('(supplier_id)[1]', 'INT'),
            IncomeData.value('(amount)[1]', 'DECIMAL(10,2)'),
            IncomeData.value('(status)[1]', 'NVARCHAR(50)')
        FROM @XmlData.nodes('/root/inflows/inflow') AS IncomeData(IncomeData);

        SET @EndTime = SYSDATETIME();

        -- Логируем успешную загрузку
        EXEC LogProcess 'LoadIncomeFromXML', 'Successful data load into table income', @StartTime, @EndTime;

    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @LogError = 'Error: ' + @ErrorMessage; 
        EXEC LogProcess 'LoadIncomeFromXML', @LogError, @StartTime, @EndTime;
    END CATCH;
END;
