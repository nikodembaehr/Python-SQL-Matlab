--q20
SELECT TOP 500 *
 into #sampleboi
 FROM Patstat

--removing leading and trailing white spaces
UPDATE #sampleboi
SET npl_biblio = LTRIM(RTRIM(npl_biblio));
--removing double spaces
UPDATE #sampleboi
SET npl_biblio = REPLACE(npl_biblio, '  ', ' ');
--removing diacritics
-- Create a function to remove diacritics
CREATE FUNCTION dbo.RemoveDiacritics (@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @output NVARCHAR(MAX);
    SET @output = @input;

    -- Replace accented characters with their non-accented counterparts
    SET @output = REPLACE(@output, N'À', 'A');
    SET @output = REPLACE(@output, N'Á', 'A');
    SET @output = REPLACE(@output, N'Â', 'A');
    SET @output = REPLACE(@output, N'Ã', 'A');
    SET @output = REPLACE(@output, N'Ä', 'A');
    SET @output = REPLACE(@output, N'Å', 'A');
    SET @output = REPLACE(@output, N'à', 'a');
    SET @output = REPLACE(@output, N'á', 'a');
    SET @output = REPLACE(@output, N'â', 'a');
    SET @output = REPLACE(@output, N'ã', 'a');
    SET @output = REPLACE(@output, N'ä', 'a');
    SET @output = REPLACE(@output, N'å', 'a');
    SET @output = REPLACE(@output, N'È', 'E');
    SET @output = REPLACE(@output, N'É', 'E');
    SET @output = REPLACE(@output, N'Ê', 'E');
    SET @output = REPLACE(@output, N'Ë', 'E');
    SET @output = REPLACE(@output, N'è', 'e');
    SET @output = REPLACE(@output, N'é', 'e');
    SET @output = REPLACE(@output, N'ê', 'e');
    SET @output = REPLACE(@output, N'ë', 'e');
    SET @output = REPLACE(@output, N'Ì', 'I');
    SET @output = REPLACE(@output, N'Í', 'I');
    SET @output = REPLACE(@output, N'Î', 'I');
    SET @output = REPLACE(@output, N'Ï', 'I');
    SET @output = REPLACE(@output, N'ì', 'i');
    SET @output = REPLACE(@output, N'í', 'i');
    SET @output = REPLACE(@output, N'î', 'i');
    SET @output = REPLACE(@output, N'ï', 'i');
    SET @output = REPLACE(@output, N'Ò', 'O');
    SET @output = REPLACE(@output, N'Ó', 'O');
    SET @output = REPLACE(@output, N'Ô', 'O');
    SET @output = REPLACE(@output, N'Õ', 'O');
    SET @output = REPLACE(@output, N'Ö', 'O');
    SET @output = REPLACE(@output, N'Ø', 'O');
    SET @output = REPLACE(@output, N'ò', 'o');
    SET @output = REPLACE(@output, N'ó', 'o');
    SET @output = REPLACE(@output, N'ô', 'o');
    SET @output = REPLACE(@output, N'õ', 'o');
    SET @output = REPLACE(@output, N'ö', 'o');
    SET @output = REPLACE(@output, N'ø', 'o');
    SET @output = REPLACE(@output, N'Ù', 'U');
    SET @output = REPLACE(@output, N'Ú', 'U');
    SET @output = REPLACE(@output, N'Û', 'U');
    SET @output = REPLACE(@output, N'Ü', 'U');
    SET @output = REPLACE(@output, N'ù', 'u');
    SET @output = REPLACE(@output, N'ú', 'u');
    SET @output = REPLACE(@output, N'û', 'u');
    SET @output = REPLACE(@output, N'ü', 'u');
    SET @output = REPLACE(@output, N'Ý', 'Y');
    SET @output = REPLACE(@output, N'ý', 'y');
    SET @output = REPLACE(@output, N'ÿ', 'y');
    SET @output = REPLACE(@output, N'Ç', 'C');
    SET @output = REPLACE(@output, N'ç', 'c');
    SET @output = REPLACE(@output, N'Ñ', 'N');
    SET @output = REPLACE(@output, N'ñ', 'n');

    RETURN @output;
END;
UPDATE #sampleboi
SET npl_biblio = dbo.RemoveDiacritics(npl_biblio);

select *
from #sampleboi


--Creating a table called PublicationInfo, with columns for the title, author and remainder of information, on the basis of which clustering can commence
CREATE TABLE #PublicationInfo (
    npl_publn_id INT,
    Author NVARCHAR(MAX),
    Title NVARCHAR(MAX),
    Remainder NVARCHAR(MAX)
);

-- Populate #PublicationInfo with data from #sampleboi
INSERT INTO #PublicationInfo (npl_publn_id, Author, Title, Remainder)
SELECT
    npl_publn_id,
    CASE
        WHEN CHARINDEX(':', npl_biblio) > 0 THEN SUBSTRING(npl_biblio, 1, CHARINDEX(':', npl_biblio) - 1)
        ELSE '' -- Handle the case where ':' is not found
    END AS Author,
    CASE
        WHEN CHARINDEX(':', npl_biblio) > 0 THEN
            CASE
                WHEN CHARINDEX('.', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX(':', npl_biblio) + 1, CHARINDEX('.', npl_biblio, CHARINDEX(':', npl_biblio) + 1) - CHARINDEX(':', npl_biblio) - 1)
                WHEN CHARINDEX(',', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX(':', npl_biblio) + 1, CHARINDEX(',', npl_biblio, CHARINDEX(':', npl_biblio) + 1) - CHARINDEX(':', npl_biblio) - 1)
                WHEN CHARINDEX(';', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX(':', npl_biblio) + 1, CHARINDEX(';', npl_biblio, CHARINDEX(':', npl_biblio) + 1) - CHARINDEX(':', npl_biblio) - 1)
                ELSE '' -- Handle the case where the ending delimiter is not found
            END
        ELSE '' -- Handle the case where ':' is not found
    END AS Title,
    CASE
        WHEN CHARINDEX(':', npl_biblio) > 0 THEN
            CASE
                WHEN CHARINDEX('.', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX('.', npl_biblio, CHARINDEX(':', npl_biblio) + 1), LEN(npl_biblio))
                WHEN CHARINDEX(',', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX(',', npl_biblio, CHARINDEX(':', npl_biblio) + 1), LEN(npl_biblio))
                WHEN CHARINDEX(';', npl_biblio, CHARINDEX(':', npl_biblio) + 1) > 0 THEN SUBSTRING(npl_biblio, CHARINDEX(';', npl_biblio, CHARINDEX(':', npl_biblio) + 1), LEN(npl_biblio))
                ELSE '' -- Handle the case where the ending delimiter is not found
            END
        ELSE '' -- Handle the case where ':' is not found
    END AS Remainder
FROM #sampleboi; -- Using #sampleboi as the source table

-- Show the first few rows of #PublicationInfo
SELECT  * FROM #PublicationInfo;

-- Drop the temporary table if you no longer need it
-- DROP TABLE #PublicationInfo;


--- Create a new temporary table #AuthorGroups
CREATE TABLE #AuthorGroups (
    Author NVARCHAR(MAX),
    npl_publn_id INT
);

-- Create a temporary table to store the authors and their publications
CREATE TABLE #AuthorsAndPublications (
    Author NVARCHAR(MAX),
    npl_publn_id INT
);

-- Populate the #AuthorsAndPublications table
INSERT INTO #AuthorsAndPublications (Author, npl_publn_id)
SELECT DISTINCT
    Author,
    npl_publn_id
FROM #PublicationInfo
WHERE Author IS NOT NULL;

-- Initialize variables
DECLARE @ProcessedAuthors TABLE (
    Author NVARCHAR(MAX)
);

-- Start processing authors
WHILE EXISTS (SELECT 1 FROM #AuthorsAndPublications)
BEGIN
    DECLARE @Author NVARCHAR(MAX);

    -- Get the first author from the table
    SELECT TOP 1 @Author = Author
    FROM #AuthorsAndPublications;

    -- Create a table to store the current group of authors
    DECLARE @CurrentAuthorGroup TABLE (
        Author NVARCHAR(MAX),
        npl_publn_id INT
    );

    -- Insert the first author into the current group
    INSERT INTO @CurrentAuthorGroup (Author, npl_publn_id)
    SELECT Author, npl_publn_id
    FROM #AuthorsAndPublications
    WHERE Author = @Author;

    -- Mark the author as processed
    INSERT INTO @ProcessedAuthors (Author)
    VALUES (@Author);

    -- Remove the processed author from the #AuthorsAndPublications table
    DELETE FROM #AuthorsAndPublications
    WHERE Author = @Author;

    -- Find and add similar authors to the current group
    INSERT INTO @CurrentAuthorGroup (Author, npl_publn_id)
    SELECT A.Author, A.npl_publn_id
    FROM #AuthorsAndPublications A
    INNER JOIN @CurrentAuthorGroup C ON
        A.Author <> C.Author
        AND (
            CHARINDEX(C.Author, A.Author) > 0
            OR CHARINDEX(A.Author, C.Author) > 0
        );

    -- Mark processed authors as processed
    INSERT INTO @ProcessedAuthors (Author)
    SELECT DISTINCT Author
    FROM @CurrentAuthorGroup;

    -- Remove the processed authors from the #AuthorsAndPublications table
    DELETE A
    FROM #AuthorsAndPublications A
    INNER JOIN @ProcessedAuthors P ON A.Author = P.Author;
    
    -- Insert the current group into #AuthorGroups if it meets the criteria
    IF (SELECT COUNT(*) FROM @CurrentAuthorGroup) >= 3
    BEGIN
        INSERT INTO #AuthorGroups (Author, npl_publn_id)
        SELECT DISTINCT Author, npl_publn_id
        FROM @CurrentAuthorGroup;
    END;
END;
DELETE FROM #AuthorGroups
WHERE Author = '';
-- Show the #AuthorGroups table
SELECT * FROM #AuthorGroups;

-- Drop the temporary tables
DROP TABLE #AuthorsAndPublications;
-- DROP TABLE #AuthorGroups;


--cluster on author

-- Create a new temporary table to store the clustered author groups
CREATE TABLE #ClusteredAuthorGroups (
    ClusterID INT,
    Author NVARCHAR(MAX),
    npl_publn_id INT
);

-- Initialize the cluster ID
DECLARE @ClusterID INT = 1;

-- Loop through each distinct author
DECLARE @Author NVARCHAR(MAX);

DECLARE AuthorCursor CURSOR FOR
SELECT DISTINCT Author
FROM #AuthorGroups;

OPEN AuthorCursor;

FETCH NEXT FROM AuthorCursor INTO @Author;

-- Start assigning cluster IDs
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insert all publications of the current author with the same cluster ID
    INSERT INTO #ClusteredAuthorGroups (ClusterID, Author, npl_publn_id)
    SELECT @ClusterID, Author, npl_publn_id
    FROM #AuthorGroups
    WHERE Author = @Author;

    -- Increment the cluster ID for the next author
    SET @ClusterID = @ClusterID + 1;

    FETCH NEXT FROM AuthorCursor INTO @Author;
END

-- Close and deallocate the cursor
CLOSE AuthorCursor;
DEALLOCATE AuthorCursor;

-- Show the #ClusteredAuthorGroups table
SELECT * FROM #ClusteredAuthorGroups;

-- Drop the temporary tables
DROP TABLE #ClusteredAuthorGroups;
-- DROP TABLE #AuthorGroups;















