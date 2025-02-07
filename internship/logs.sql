CREATE TABLE dbo.Logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    process_name NVARCHAR(255),
    start_time DATETIME,
    end_time DATETIME NULL,
    handler NVARCHAR(255),
    error_message NVARCHAR(MAX) NULL
);
