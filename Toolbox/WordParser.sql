/**
   TITLE: Master Table DDL

   DESCRIPTION:
   This is to be used in order to eliminate ,_ in a string.

   REVISION HISTORY:

     DATE       AUTHOR          CHANGE DESCRIPTION                                             
     
     2017,12,13 Matt Stillson   Inital Commit
*/
USE Master;
GO

IF EXISTS (SELECT * FROM sys.objects
           WHERE OBJECT_ID = OBJECT_ID(N'dbo.fn_Word_Parsing')
                 AND type IN (N'U'))
    DROP FUNCTION dbo.fn_Word_Parsing;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

CREATE FUNCTION dbo.fn_Word_Parsing(
    @multiwordstring VARCHAR(254)
    , @wordnumber NUMERIC
)
    RETURNS VARCHAR(254)
    AS
    BEGIN
        DECLARE @remainingstring VARCHAR(254)
        SET @remainingstring = @multiwordstring

        DECLARE @numberofwords NUMERIC
        SET @numberofwords = (LEN(@remainingstring)-LEN(REPLACE(@remainingstring, ',', ''))+1)

        DECLARE @word VARCHAR(45)
        DECLARE @parsingwords TABLE(
             Lines NUMERIC IDENTITY(1,1)
            ,Word VARCHAR(254)
        )

        WHILE @numberofwords > 1
        BEGIN
            SET @word = LEFT(@remainingstring, CHARINDEX(',', @remainingstring)-1)
            INSERT INTO @parsingwords(word)
            SELECT @Word

            SET @remainingstring = REPLACE(@remainingstring, CONCAT(@Word, ','), '')
            SET @numberofwords=(LEN(@remainingstring) - LEN(REPLACE(@remainingstring, ',', '')) + 1)

            IF @numberofwords = 1
              BREAK

            ELSE
              CONTINUE
        END

      IF @numberofwords = 1
        SELECT @word = @remainingstring
      INSERT INTO @parsedwords(word)
      SELECT @word

      RETURN
        (SELECT word
         FROM   @parsedwords
         WHERE  line = @wordnumber)
  END
GO