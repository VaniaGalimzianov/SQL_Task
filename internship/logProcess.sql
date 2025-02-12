ALTER PROCEDURE dbo.LogProcess
    @ProcessName NVARCHAR(255),
    @Message NVARCHAR(MAX),
	@StartTime DATETIME2,
	@EndTime DATETIME2
AS
BEGIN
    INSERT INTO dbo.Logs (process_name, start_time, end_time, message)
    VALUES (@ProcessName, @StartTime, @EndTime, @Message);
END;
