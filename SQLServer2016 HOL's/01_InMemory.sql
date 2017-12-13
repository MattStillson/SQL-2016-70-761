-- Memory Optimized Data create folder c:\data
ALTER DATABASE TicketReservations ADD FILEGROUP TicketReservations_mod CONTAINS
MEMORY_OPTIMIZED_DATA;
GO

ALTER DATABASE TicketReservations ADD FILE (name='TicketReservations_mod1', filename='c:\data\TicketReservations_mod1') TO FILEGROUP TicketReservations;
GO

ALTER DATABASE TicketReservations SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON
GO

CREATE SEQUENCE [dbo].[TicketReservationSequence]
    AS INT
    START WITH 1
    INCREMENT BY 1
    CACHE 50000;
GO

CREATE TABLE [dbo].[TicketReservationDetail] (
    TicketReservationID BIGINT	NOT NULL,
    TicketReservationDetailID BIGINT IDENTITY	NOT NULL,
    Quantity    INT             NOT NULL,
    FlightID	INT             NOT NULL,
    Comment      NVARCHAR (1000),
 CONSTRAINT [PK_TicketReservationDetail] PRIMARY KEY CLUSTERED (TicketReservationDetailID)
);
GO

CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
AS
BEGIN
	DECLARE @loop int = 0;
	WHILE (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment)
			VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END;
GO

CREATE PROCEDURE ReadMultipleReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @CurrentSeq int = 0;
	DECLARE @Sum int = 0;
	DECLARE @loop int = 0;
	WHILE (@tranCount < @ServerTransactions)
	BEGIN
		BEGIN TRY
			SELECT @CurrentSeq = RAND() * IDENT_CURRENT(N'dbo.TicketReservationDetail')
			SET @loop = 0
			BEGIN TRAN
			WHILE (@loop < @RowsPerTransaction)
			BEGIN
				SELECT @Sum += FlightID from dbo.TicketReservationDetail where TicketReservationDetailID = @CurrentSeq - @loop;
				SET @loop += 1;
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO

CREATE PROCEDURE BatchInsertReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @TS Datetime2;
	DECLARE @Char_TS NVARCHAR(23);
	DECLARE @CurrentSeq int = 0;

	SET @TS = SYSDATETIME();
	SET @Char_TS = CAST(@TS AS NVARCHAR(23));
	WHILE (@tranCount < @ServerTransactions)
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			SET @CurrentSeq = NEXT VALUE FOR TicketReservationSequence ;
			EXEC InsertReservationDetails  @CurrentSeq, @RowsPerTransaction, @Char_TS, @ThreadID;
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO

DROP PROCEDURE InsertReservationDetails;
DROP TABLE TicketReservationDetail;
CREATE TABLE [dbo].[TicketReservationDetail] (
    TicketReservationID BIGINT	NOT NULL,
    TicketReservationDetailID BIGINT IDENTITY	NOT NULL,
    Quantity    INT             NOT NULL,
    FlightID	INT             NOT NULL,
    Comment      NVARCHAR (1000),
    CONSTRAINT [PK_TicketReservationDetail] PRIMARY KEY NONCLUSTERED (TicketReservationDetailID)
) WITH (MEMORY_OPTIMIZED=ON);
GO

CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
WITH NATIVE_COMPILATION, SCHEMABINDING
as
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')
	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment)
		    VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
GO

SET NOCOUNT ON;
GO
CREATE PROCEDURE sp_temp
AS
    BEGIN
        DROP TABLE IF EXISTS #temp1
        CREATE TABLE #temp1
            (
              c1 INT NOT NULL ,
              c2 NVARCHAR(4000)
            );
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  #temp1
                VALUES  ( @i, N'abc' );
                SET @i += 1
            END;
        COMMIT
    END;
GO

-- a single filter function can be used for all session-level temp tables
CREATE FUNCTION dbo.fn_SessionFilter(@session_id smallint)
    RETURNS TABLE
WITH SCHEMABINDING, NATIVE_COMPILATION
AS
    RETURN SELECT 1 as fn_SessionFilter WHERE @session_id=@@spid;
GO


DROP TABLE IF EXISTS dbo.temp1
GO

CREATE TABLE dbo.temp1
    (
      c1 INT NOT NULL ,
      c2 NVARCHAR(4000) ,
      session_id SMALLINT NOT NULL DEFAULT ( @@spid ) ,
      INDEX IX_session_id ( session_id ) ,
      CONSTRAINT CHK_temp1_session_id CHECK ( session_id = @@spid ),
    )
    WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY);
GO

-- add security policy to enable filtering on session_id, for each temp table

CREATE SECURITY POLICY dbo.temp1Filter
ADD FILTER PREDICATE dbo.fn_SessionFilter(session_id)
ON dbo.temp1
WITH (STATE = ON);
GO
DROP PROCEDURE IF EXISTS sp_temp
GO
CREATE PROCEDURE sp_temp
AS
    BEGIN
        DELETE FROM dbo.temp1;
        BEGIN TRAN
        DECLARE @i INT = 0;
        WHILE @i < 100
            BEGIN
                INSERT  dbo.temp1 (c1, c2)
                VALUES  ( @i, N'abc' );
                SET @i += 1;
            END;
        COMMIT
    END;
GO
