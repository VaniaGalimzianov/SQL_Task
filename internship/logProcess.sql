CREATE PROCEDURE dbo.LogProcess
    @process_name NVARCHAR(255),
    @handler NVARCHAR(255),
    @error_message NVARCHAR(MAX) = NULL
AS
BEGIN
    IF @error_message IS NULL
        UPDATE dbo.Logs
        SET end_time = GETDATE()
        WHERE process_name = @process_name AND handler = @handler AND end_time IS NULL;
    ELSE
        INSERT INTO dbo.Logs (process_name, start_time, handler, error_message)
        VALUES (@process_name, GETDATE(), @handler, @error_message);
END;
