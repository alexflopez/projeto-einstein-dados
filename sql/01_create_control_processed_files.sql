USE opendatasus;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'control_processed_files')
BEGIN
    CREATE TABLE dbo.control_processed_files (
        fileName VARCHAR(255) NOT NULL PRIMARY KEY,
        processedAt DATETIME DEFAULT GETDATE()
    );
END;
GO