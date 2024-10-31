/* Code for Part 3 Question 20 of the database assigment divided into functions that all together give the desired results. 
Author: Oskar Weber

Note: all functions have _1 at the end, because functions with similar names already existed in the database.
First function is used for preparing the data from Patstat table. It does things that were mentioned in the hints for the excercise, with additional changes. 
*/
create function dbo.data_pre_processing (@inputstring nvarchar(1024))
returns nvarchar(1024)
as
begin
    -- leading and trailing spaces removal
    set @inputstring = ltrim(rtrim(@inputstring))
    -- multiple spaces removal
    while charindex('  ', @inputstring) > 0
    begin
        set @inputstring = replace(@inputstring,'  ',' ')
    end
    -- removing diacritics and interpunction. 
    -- latin1_general_bin removes diacritics by treating characters as binary.
    set @inputstring = convert(nvarchar(1024), @inputstring collate latin1_general_bin);
    set @inputstring = replace(@inputstring, ',', '');
    set @inputstring = replace(@inputstring, '.', '');
    set @inputstring = replace(@inputstring, '!', '');
    set @inputstring = replace(@inputstring, '?', '');
    set @inputstring = replace(@inputstring, ';', '');
    set @inputstring = replace(@inputstring, ':', '');

    -- remove subscript tags and symbols
    set @inputstring = replace(@inputstring, '<sub>', '');
    set @inputstring = replace(@inputstring, '</sub>', '');

    -- standardize spaces around punctuation
    set @inputstring = replace(replace(@inputstring, ' ,', ','), ', ', ', ');
    set @inputstring = replace(replace(@inputstring, ' .', '.'), '. ', '. ');

    -- convert text to lowercase for consistency
    set @inputstring = lower(@inputstring);

    return @inputstring
end
go

-- Start of all functions used for gathering the meta data
-- Function to extract xp number from a given text
create function dbo.extractxpnumber_1 (@text nvarchar(max))
returns nvarchar(50)
as
begin
    declare @xp_index int;
    declare @xp_number nvarchar(50);

	-- We try to find the index of the first occurrence of the pattern 'xp' followed by a digit in the input text
    set @xp_index = patindex('%xp[0-9]%', @text);
    if @xp_index > 0
    begin
		-- We extract the substring starting from the 'xp' pattern till the end of the text
        declare @rest nvarchar(max) = substring(@text, @xp_index, len(@text));
		-- We find the index of the first space after the 'xp' pattern in the extracted substring
        declare @space_index int = charindex(' ', @rest);
		-- If there is a space index we extract 'xp'number up to that space, if not we extract it till the end of the substring
        if @space_index > 0
            set @xp_number = substring(@rest, 1, @space_index - 1);
        else
            set @xp_number = @rest;

        return @xp_number;
    end
    return null;
end;
go

-- Function to extract issn based on the 8-digit pattern that is based on this website information: https://www.issn.org/understanding-the-issn/what-is-an-issn/#:~:text=The%20eighth%20digit%20is%20a,ISSN%200317%2D8471
create function dbo.extractissn_1 (@text nvarchar(max))
returns nvarchar(9)
as
begin
	-- We create a issn pattern that consists of 4 digits a hyphen and four digits that is standard format
    declare @issn_pattern nvarchar(50) = '%[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]%';
	-- Looking at the data we find that there is a possibility of an x in the last position so we have second pattern to account for it
    declare @issn_pattern_with_x nvarchar(50) = '%[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9x]%';
    declare @start_pos int;
    declare @issn nvarchar(9);

    -- First, we look for standard issn format with digits only
    set @start_pos = patindex(@issn_pattern, @text);
    
    -- Then if not found, we look for issn with x in the last position
    if @start_pos = 0
        set @start_pos = patindex(@issn_pattern_with_x, @text);

    if @start_pos > 0
    begin
		-- If we find the issn number we substruct it, since its always 9 characters (with hyphen)
        set @issn = substring(@text, @start_pos, 9);
        return @issn;
    end
    else
    begin
        return null;
    end
    return null
end;
go

-- Function to extract authors from a given text
create function dbo.extractauthors_1 (@text nvarchar(max))
returns nvarchar(255)
as
begin
	-- We look for a position of et al in the text that indicates that authors are mentioned there
    declare @etal_index int = charindex(' et al', @text);
    if @etal_index > 0
    begin
		-- If we find et al we extract the string from the begining to the end of et al
        return substring(@text, 1, @etal_index + 5);
    end
    else
    begin
		-- If we don't find any et al in the text we assume that generally name is at first position so we extract from begening to the first space in the text
        declare @first_space int = charindex(' ', @text);
        if @first_space > 0
            return substring(@text, 1, @first_space - 1);
        else
		-- If space not found (rather impossible) we just return null 
            return null;
    end
    return null
end;
go

-- Function to extract a publication date from a given text
create function dbo.extractpublicationdate_1 (@text nvarchar(max))
returns date
as
begin
    declare @date_str nvarchar(50);
	-- Date is often in paranthesis so we try to find it in the text
    declare @open_paren int = charindex('(', @text);
    declare @close_paren int = charindex(')', @text);

	-- If we find it then we try to create a numerical representation of a date from the text between parenthesis
    if @open_paren > 0 and @close_paren > @open_paren
    begin
        set @date_str = substring(@text, @open_paren + 1, @close_paren - @open_paren - 1);
        set @date_str = ltrim(rtrim(@date_str));

        -- replace month names with numbers to handle different languages
        set @date_str = lower(@date_str);

		-- Since sometimes the names where in different language we find 5 most common scientific languages (excluding chinese) and in case they are used we change them accordingly to numerical values

        -- replace month names with numbers (english)
        set @date_str = replace(@date_str, 'january', '01');
        set @date_str = replace(@date_str, 'february', '02');
        set @date_str = replace(@date_str, 'march', '03');
        set @date_str = replace(@date_str, 'april', '04');
        set @date_str = replace(@date_str, 'may', '05');
        set @date_str = replace(@date_str, 'june', '06');
        set @date_str = replace(@date_str, 'july', '07');
        set @date_str = replace(@date_str, 'august', '08');
        set @date_str = replace(@date_str, 'september', '09');
        set @date_str = replace(@date_str, 'october', '10');
        set @date_str = replace(@date_str, 'november', '11');
        set @date_str = replace(@date_str, 'december', '12');
        -- replace month names with numbers (french)
        set @date_str = replace(@date_str, 'janvier', '01');
        set @date_str = replace(@date_str, 'février', '02');
        set @date_str = replace(@date_str, 'fevrier', '02');
        set @date_str = replace(@date_str, 'mars', '03');
        set @date_str = replace(@date_str, 'avril', '04');
        set @date_str = replace(@date_str, 'mai', '05');
        set @date_str = replace(@date_str, 'juin', '06');
        set @date_str = replace(@date_str, 'juillet', '07');
        set @date_str = replace(@date_str, 'août', '08');
        set @date_str = replace(@date_str, 'aout', '08');
        set @date_str = replace(@date_str, 'septembre', '09');
        set @date_str = replace(@date_str, 'octobre', '10');
        set @date_str = replace(@date_str, 'novembre', '11');
        set @date_str = replace(@date_str, 'décembre', '12');
        set @date_str = replace(@date_str, 'decembre', '12');
        -- replace month names with numbers (spanish)
        set @date_str = replace(@date_str, 'enero', '01');
        set @date_str = replace(@date_str, 'febrero', '02');
        set @date_str = replace(@date_str, 'marzo', '03');
        set @date_str = replace(@date_str, 'abril', '04');
        set @date_str = replace(@date_str, 'mayo', '05');
        set @date_str = replace(@date_str, 'junio', '06');
        set @date_str = replace(@date_str, 'julio', '07');
        set @date_str = replace(@date_str, 'agosto', '08');
        set @date_str = replace(@date_str, 'septiembre', '09');
        set @date_str = replace(@date_str, 'setiembre', '09');
        set @date_str = replace(@date_str, 'octubre', '10');
        set @date_str = replace(@date_str, 'noviembre', '11');
        set @date_str = replace(@date_str, 'diciembre', '12');
        -- replace month names with numbers (german)
        set @date_str = replace(@date_str, 'januar', '01');
        set @date_str = replace(@date_str, 'februar', '02');
        set @date_str = replace(@date_str, 'märz', '03');
        set @date_str = replace(@date_str, 'maerz', '03');
        set @date_str = replace(@date_str, 'april', '04');
        set @date_str = replace(@date_str, 'mai', '05');
        set @date_str = replace(@date_str, 'juni', '06');
        set @date_str = replace(@date_str, 'juli', '07');
        set @date_str = replace(@date_str, 'august', '08');
        set @date_str = replace(@date_str, 'september', '09');
        set @date_str = replace(@date_str, 'oktober', '10');
        set @date_str = replace(@date_str, 'november', '11');
        set @date_str = replace(@date_str, 'dezember', '12');
        -- replace month names with numbers (italian)
        set @date_str = replace(@date_str, 'gennaio', '01');
        set @date_str = replace(@date_str, 'febbraio', '02');
        set @date_str = replace(@date_str, 'marzo', '03');
        set @date_str = replace(@date_str, 'aprile', '04');
        set @date_str = replace(@date_str, 'maggio', '05');
        set @date_str = replace(@date_str, 'giugno', '06');
        set @date_str = replace(@date_str, 'luglio', '07');
        set @date_str = replace(@date_str, 'agosto', '08');
        set @date_str = replace(@date_str, 'settembre', '09');
        set @date_str = replace(@date_str, 'ottobre', '10');
        set @date_str = replace(@date_str, 'novembre', '11');
        set @date_str = replace(@date_str, 'dicembre', '12');

        -- replace various separators with '-'
        set @date_str = replace(@date_str, '.', '-');
        set @date_str = replace(@date_str, '/', '-');
        set @date_str = replace(@date_str, ' - ', '-');
        set @date_str = replace(@date_str, ' ', '-');
        set @date_str = replace(@date_str, '--', '-');

        -- We try to convert the date string to date format
        declare @parsed_date date = try_convert(date, @date_str, 111); -- using format yyyy-mm-dd

        if @parsed_date is not null
            return @parsed_date;
        else
        begin
            -- In case of an error we try different date formats as well
            set @parsed_date = try_convert(date, @date_str, 103); -- dd/mm/yyyy
            if @parsed_date is not null
                return @parsed_date;

            set @parsed_date = try_convert(date, @date_str, 101); -- mm/dd/yyyy
            if @parsed_date is not null
                return @parsed_date;

        end
    end

    -- If date is not found in parentheses we search for a four-digit year, assuming papers are from 2000s or 1900s
    declare @year_pattern nvarchar(10) = '%[1-2][089][0-9][0-9]%';
    declare @year_pos int = patindex(@year_pattern, @text);

    if @year_pos > 0
    begin
		-- If we find a year we return a first day of that year
        declare @year_str nvarchar(4) = substring(@text, @year_pos, 4);
        if isnumeric(@year_str) = 1
            return try_convert(date, @year_str + '-01-01'); -- Convert to a date (yyyy-01-01)
    end

    return null;
end;
go

-- Function to extract volume from a given text
create function dbo.extractvolume_1 (@text nvarchar(max))
returns nvarchar(20)
as
begin
	-- We look for a vol in the text that would indicate volume
    declare @vol_index int = patindex('%vol %', @text);
	-- If not found we can try the german version of volume which is bd, as a some of papers from Patstat are in german
    if @vol_index = 0
        set @vol_index = patindex('%bd %', @text);

    if @vol_index > 0
    begin
		-- We extract the remaining part of the text starting after vol or bd
        declare @rest nvarchar(max) = substring(@text, @vol_index + 4, len(@text));
        set @rest = ltrim(@rest);
        declare @space_index int = charindex(' ', @rest);
		-- We substruct everything from vol/bd to the first space or if no space then from vol/bd to the end
        if @space_index > 0
            return substring(@rest, 1, @space_index - 1);
        else
            return @rest;
    end
    return null;
end;
go

-- Function to extract issue from a given text
create function dbo.extractissue_1 (@text nvarchar(max))
returns nvarchar(20)
as
begin
	-- We look for no in text that indicates issue number in English
    declare @issue_index int = patindex('%no %', @text);
    if @issue_index = 0
		-- If no no is found then we look for nr that indicates issue number in German
        set @issue_index = patindex('%nr %', @text);

	-- Then we just extract any number between no/nr and the first space or if no space then to the end of the text
    if @issue_index > 0
    begin
        declare @rest nvarchar(max) = substring(@text, @issue_index + 3, len(@text));
        set @rest = ltrim(@rest);
        declare @space_index int = charindex(' ', @rest);

        if @space_index > 0
            return substring(@rest, 1, @space_index - 1);
        else
            return @rest;
    end
    return null;
end;
go

-- Function to extract pages from a given text
create function dbo.extractpages_1 (@text nvarchar(max))
returns nvarchar(50)
as
begin
	-- We look if there is pages (English) or seiten (German) in the text that would indicate that page range is after this
    declare @pages_index int = patindex('%pages %', @text);
    if @pages_index = 0
        set @pages_index = patindex('%seiten %', @text);

    if @pages_index > 0
    begin
		-- We extract everything from pages/seiten till the end
        declare @rest nvarchar(max) = substring(@text, @pages_index + 6, len(@text));
        set @rest = ltrim(@rest);

		-- Then we look if there is any information about xp number, issn or isbn to stop extraction so we don't mix the numbers, if none of them are present then we extract everything till the first space
        declare @stop_index int = patindex('%xp%', @rest);

        if @stop_index = 0
            set @stop_index = patindex('%issn%', @rest);
        if @stop_index = 0
            set @stop_index = patindex('%isbn%', @rest);

        if @stop_index > 0
            return substring(@rest, 1, @stop_index - 1);
        else
			declare @space_index int = charindex(' ', @rest);
			if @space_index > 0
				return substring(@rest, 1, @space_index - 1);
			else
				return @rest;
    end
    return null;
end;
go

-- Function to extract DOI from a given text
create function dbo.extractdoi_1 (@text nvarchar(max))
returns nvarchar(100)
as
begin
	-- We look if there is doi in the text that would indicate that DOI is there
    declare @doi_index int = patindex('%doi%', @text);
    if @doi_index > 0
    begin
		-- If doi is found we extract everything between doi and the first space after
        declare @rest nvarchar(max) = substring(@text, @doi_index + 3, len(@text));
        set @rest = ltrim(@rest);
        declare @space_index int = charindex(' ', @rest);

        if @space_index > 0
            return substring(@rest, 1, @space_index - 1);
        else
            return @rest;
    end
    return null;
end;
go

-- Function to extract an ISBN from a given text based on information about ISBN from: https://en.wikipedia.org/wiki/ISBN
create function dbo.extractisbn_1 (@text nvarchar(max))
returns nvarchar(20)
as
begin
    declare @isbn nvarchar(20) = null;
    declare @text_lower nvarchar(max) = lower(@text);
	-- We look for isbn in the text
    declare @isbn_pos int = patindex('%isbn%', @text_lower);
    declare @isbn_match nvarchar(50);
    declare @isbn_cleaned nvarchar(20);

    if @isbn_pos > 0
    begin
        -- We extract the text starting from isbn to the end
        declare @isbn_text nvarchar(100) = substring(@text_lower, @isbn_pos + 4, len(@text_lower));
        set @isbn_text = ltrim(@isbn_text);

        -- We extract up to the next space or non-digit/hyphen/space character
        declare @isbn_end_pos int = patindex('%[^0-9xx- ]%', @isbn_text);
        if @isbn_end_pos > 0
            set @isbn_match = substring(@isbn_text, 1, @isbn_end_pos - 1);
        else
			-- Or we extract until the end of the text
            set @isbn_match = @isbn_text;

        -- We clean the isbn
        set @isbn_cleaned = replace(replace(@isbn_match, ' ', ''), '-', '');

        -- We convert any lowercase 'x' to uppercase 'X'
        if right(@isbn_cleaned, 1) = 'x'
            set @isbn_cleaned = left(@isbn_cleaned, len(@isbn_cleaned) - 1) + 'X';

        -- We check length and numeric content for ISBN-13 and ISBN-10 cases
        if len(@isbn_cleaned) = 13 and isnumeric(@isbn_cleaned) = 1
            set @isbn = @isbn_cleaned;
        else if len(@isbn_cleaned) = 10 and isnumeric(left(@isbn_cleaned, 9)) = 1 and upper(right(@isbn_cleaned, 1)) in ('0','1','2','3','4','5','6','7','8','9','X')
            set @isbn = @isbn_cleaned;
    end
    else
    begin
        -- If isbn is not found, we proceed with pattern matching
        declare @isbn_pattern13 nvarchar(100);
        declare @isbn_pattern10 nvarchar(100);
        declare @isbn_start_pos int;

        -- Patterns for isbn-13 and isbn-10 with optional separators (hyphen, space)
        set @isbn_pattern13 = '%[0-9][- 0-9xx]{12,16}%';
        set @isbn_pattern10 = '%[0-9][- 0-9xx]{9,13}%';

        -- We search for isbn-13 first
        set @isbn_start_pos = patindex(@isbn_pattern13, @text_lower);

        if @isbn_start_pos > 0
        begin
            set @isbn_match = substring(@text_lower, @isbn_start_pos, 17); -- We extract up to 17 characters
            set @isbn_cleaned = replace(replace(@isbn_match, ' ', ''), '-', ''); -- We remove spaces and hyphens

            -- We verify that after cleaning, we have 13 digits in ISBN-13 we don't have X at the end
            if len(@isbn_cleaned) = 13 and isnumeric(@isbn_cleaned) = 1
                set @isbn = @isbn_cleaned;
        end
        else
        begin
            -- We search for isbn-10
            set @isbn_start_pos = patindex(@isbn_pattern10, @text_lower);

            if @isbn_start_pos > 0
            begin
                set @isbn_match = substring(@text_lower, @isbn_start_pos, 13); -- We extract up to 13 characters
                set @isbn_cleaned = replace(replace(@isbn_match, ' ', ''), '-', ''); -- We remove spaces and hyphens

                -- We convert any lowercase 'x' to uppercase 'X'
                if right(@isbn_cleaned, 1) = 'x'
                    set @isbn_cleaned = left(@isbn_cleaned, len(@isbn_cleaned) - 1) + 'X';

                -- We verify that after cleaning, we have 10 characters, including case where last digit is X
                if len(@isbn_cleaned) = 10 and isnumeric(left(@isbn_cleaned, 9)) = 1 and upper(right(@isbn_cleaned, 1)) in ('0','1','2','3','4','5','6','7','8','9','X')
                    set @isbn = @isbn_cleaned;
            end
        end
    end

    return @isbn;
end
go

-- Function to extract all remaining text after extracting the meta data
create function dbo.extractremainingtext_1 (
	-- As input we consider the given text and all meta data about it
    @inputtext nvarchar(max),
    @authors nvarchar(255),
    @publicationdate date,
    @volume nvarchar(20),
    @issue nvarchar(20),
    @pages nvarchar(50),
    @xpnumber nvarchar(50),
    @issn nvarchar(9),
    @doi nvarchar(100),
    @isbn nvarchar(20)
)
returns nvarchar(max)
as
begin
    declare @remainingtext nvarchar(max) = @inputtext;

    -- We remove each extracted piece of meta data from the input text
    if @authors is not null
        set @remainingtext = replace(@remainingtext, @authors, '');

    if @publicationdate is not null
        set @remainingtext = replace(@remainingtext, convert(nvarchar, @publicationdate, 111), '');

    if @volume is not null
        set @remainingtext = replace(@remainingtext, 'vol ' + @volume, '');

    if @issue is not null
        set @remainingtext = replace(@remainingtext, 'no ' + @issue, '');

    if @pages is not null
        set @remainingtext = replace(@remainingtext, 'pages ' + @pages, '');

    if @xpnumber is not null
        set @remainingtext = replace(@remainingtext, @xpnumber, '');

    if @issn is not null
        set @remainingtext = replace(@remainingtext, @issn, '');

    if @doi is not null
        set @remainingtext = replace(@remainingtext, 'doi' + @doi, '');

    if @isbn is not null
        set @remainingtext = replace(@remainingtext, 'isbn' + @isbn, '');

    -- We remove extra spaces
    set @remainingtext = ltrim(rtrim(@remainingtext));
    set @remainingtext = replace(@remainingtext, '  ', ' ');

    return @remainingtext;
end;
go

-- This is the end of all meta data functions that are based on hint for the excercise 20
-- I divided the creation of scoring system and clustering the articles into 5 steps:

-- Step 1: We create a temporary table with meta data for each record in Patstat table
select
    npl_publn_id,
    dbo.extractauthors_1(npl_biblio_cleared) as authors,
    dbo.extractpublicationdate_1(npl_biblio_cleared) as publicationdate,
    dbo.extractvolume_1(npl_biblio_cleared) as volume,
    dbo.extractissue_1(npl_biblio_cleared) as issue,
    dbo.extractpages_1(npl_biblio_cleared) as pages,
    dbo.extractxpnumber_1(npl_biblio_cleared) as xpnumber,
    dbo.extractissn_1(npl_biblio_cleared) as issn,
    dbo.extractdoi_1(npl_biblio_cleared) as doi,
    dbo.extractisbn_1(npl_biblio_cleared) as isbn,
    dbo.extractremainingtext_1(
        npl_biblio_cleared,
        dbo.extractauthors_1(npl_biblio_cleared),
        dbo.extractpublicationdate_1(npl_biblio_cleared),
        dbo.extractvolume_1(npl_biblio_cleared),
        dbo.extractissue_1(npl_biblio_cleared),
        dbo.extractpages_1(npl_biblio_cleared),
        dbo.extractxpnumber_1(npl_biblio_cleared),
        dbo.extractissn_1(npl_biblio_cleared),
        dbo.extractdoi_1(npl_biblio_cleared),
        dbo.extractisbn_1(npl_biblio_cleared)
    ) as remainingtext
into #temp_meta_data
from (
    select 
        npl_publn_id, 
        dbo.data_pre_processing(npl_biblio) as npl_biblio_cleared
    from (select * from Patstat) as pt
) as t;

-- Step 2: We compare pairwise the records to calculate similarity scores and insert it into temporary table. The scores were assigned using trial and error method after checking similarity scores for top 100 records of Patstat
create index idx_npl_publn_id ON #temp_meta_data(npl_publn_id);
create index idx_authors ON #temp_meta_data(authors);
create index idx_publicationdate ON #temp_meta_data(publicationdate);
create index idx_volume ON #temp_meta_data(volume);
create index idx_issue ON #temp_meta_data(issue);
create index idx_pages ON #temp_meta_data(pages);
create index idx_xpnumber ON #temp_meta_data(xpnumber);
create index idx_issn ON #temp_meta_data(issn);
create index idx_doi ON #temp_meta_data(doi);
create index idx_isbn ON #temp_meta_data(isbn);
select
    ta1.npl_publn_id as id1,
    ta2.npl_publn_id as id2,
        
    --  Author similarity score
    case
        when ta1.authors is not null and ta2.authors is not null and ta1.authors = ta2.authors then 4 -- Exact match (4 points)
        when ta1.authors is not null and ta2.authors is not null and dbo.levenshtein(ta1.authors, ta2.authors, 20) < 5 then 3 -- We allow slight variations (3 points)
        else 0
    end as author_similarity,

    -- Publication date similarity score
    case
		when ta1.publicationdate is not null and ta2.publicationdate is not null and ta1.publicationdate = ta2.publicationdate then 3  -- Exact match (3 points)
		when ta1.publicationdate is not null and ta2.publicationdate is not null and year(ta1.publicationdate) = year(ta2.publicationdate) then 2  -- Same year but different dates (2 points)
		when ta1.publicationdate is not null and ta2.publicationdate is not null and abs(datediff(year, ta1.publicationdate, ta2.publicationdate)) = 1 then 1  -- Difference of 1 year (1 point)
		else 0
	end as date_similarity,

    -- Volume similarity score
    case
		when ta1.volume is not null and ta2.volume is not null and ta1.volume = ta2.volume then 2 -- Exact match (2 points)
		else 0
	end as volume_similarity,

    -- Issue similarity score
    case
		when ta1.issue is not null and ta2.issue is not null and ta1.issue = ta2.issue then 2 -- Exact match (2 points)
		else 0
	end as issue_similarity,

    -- Pages similarity score
	case
		when ta1.pages is not null and ta2.pages is not null and ta1.pages = ta2.pages then 2 -- Exact match (2 points)
		else 0
	end as pages_similarity,

    -- XP number similarity score (important)
    case
        when ta1.xpnumber is not null and ta2.xpnumber is not null and ta1.xpnumber = ta2.xpnumber then 5 -- Exact match (5 points)
        else 0
    end as xpnumber_similarity,

    -- ISSN similarity score (important)
    case
        when ta1.issn is not null and ta2.issn is not null and ta1.issn = ta2.issn then 5 -- Exact match (5 points)
        else 0
    end as issn_similarity,

    -- DOI similarity score (very important)
    case
        when ta1.doi is not null and ta2.doi is not null and ta1.doi = ta2.doi then 15 -- Exact match (15 points)
        else 0
    end as doi_similarity,

    -- ISBN similarity score (very important)
    case
        when ta1.isbn is not null and ta2.isbn is not null and ta1.isbn = ta2.isbn then 15 -- Exact match (15 points)
        else 0
    end as isbn_similarity,

    -- Remaining text (title) similarity score using levenshtein distance
    case
    when len(ta1.remainingtext) between len(ta2.remainingtext) - 10 and len(ta2.remainingtext) + 10
        and dbo.levenshtein(ta1.remainingtext, ta2.remainingtext, 20) < 15 then 5
    else 0
    end as title_similarity
into #pairwise_similarity
from
    #temp_meta_data ta1
join
    #temp_meta_data ta2
on
    ta1.npl_publn_id < ta2.npl_publn_id

-- Step 3: We create a temporary table to store pairwise similarities with a score threshold
select id1, id2, 
		-- Weighted sum for the total similarity score is used
       (author_similarity * 1.2 + date_similarity * 2 + volume_similarity + issue_similarity + pages_similarity + xpnumber_similarity * 2 + issn_similarity + doi_similarity * 3 + isbn_similarity * 2 + title_similarity * 1.5) AS total_score
into #pairwise_similarity_filtered
from #pairwise_similarity
-- Threshold of 12 is used as minimal similarity score to say that two papers are the same
where (author_similarity * 2 + date_similarity * 2 + volume_similarity + issue_similarity + pages_similarity + xpnumber_similarity * 2 + issn_similarity + doi_similarity * 3 + isbn_similarity * 2 + title_similarity * 1.5) >= 12;

-- Step 4: We create the clustering algorithm using 6 substeps;
/*
The algorithm performs iterative clustering based on pairwise similarities between npl_publn_id. 
It starts with a single npl_publn_id that has not yet been clustered and finds all npl_publn_id that are directly similar to the initial id. 
Then it does the same for all npl_publn_id that it found to be similar in previous step. It does that until no new similar npl_publn_id are found. Then the cluster is formed.
Once a cluster is formed, all npl_publn_id in the cluster are assigned the same cluster ID, and they are marked as processed. 
Then in the next iteration it finds another unprocessed npl_publn_id and does the same as for the initial npl_publn_id, creating another cluster.
The process repeats for each unprocessed npl_publn_id until all npl_publn_id have been clustered, ensuring that no npl_publn_id is assigned to more than one cluster.
WARNING: This algorithm takes a very long time to execute!
An example to visualize the algorithm:
We have initial cluster with ID1. We check similarities of ID1 and see it is connected to ID2 and ID3. We add ID2 and ID3 to the intial cluster.
Then we check similarities of ID2 and see it is connected to ID4. We add ID4 to the cluster. 
Then we check similarities of ID3 and see it is not connected to anything.
We then check similarities of ID4 to see it is not connected to anything.
Hence no new connections so cluster is formed and has IDs: ID1, ID2, ID3, ID4
We do that for every ID in the list.

Notes: I am not sure if this algorithm wouldn't be faster in Python than in SQL as it might be that this language is not perfect for this type of operations.
However I think this algorithm is easy to implement and understand so I used it in this assigment.
*/
-- Substep 1: Create the temporary table to store unclustered IDs with a processed flag
create table #unclustered_ids (
    npl_publn_id int primary key,
    processed bit default 0
);

-- Substep 2: Insert distinct npl_publn_id from the Patstat table into the unclustered list
insert into #unclustered_ids (npl_publn_id)
select distinct npl_publn_id
from (select top 100 * from Patstat) as pt;

-- Substep 3: Create a table to store clusters and initialize cluster counter, and create indices for speeding up the process
create table #clusters (
    npl_publn_id int,
    cluster_id int
);
-- Initialize a cluster counter
declare @cluster_id int = 1;
-- Create an index on the processed column to speed up lookups
create index idx_processed on #unclustered_ids (processed);
-- Create composite indexes on the pairwise similarity table to speed up the joins
create index idx_similarity on #pairwise_similarity_filtered (id1, id2);

-- Substep 4: Start the clustering process
while exists (select 1 from #unclustered_ids where processed = 0)
begin
    -- Create a temporary table to store the current cluster IDs (initially just the first unclustered ID)
    create table #current_cluster (
        npl_publn_id int primary key
    );

    -- Insert the first unprocessed ID into the temporary cluster table
    insert into #current_cluster (npl_publn_id)
    select top 1 npl_publn_id
    from #unclustered_ids
    where processed = 0
    order by npl_publn_id;

    -- Create a temporary table to store the next set of IDs connected to the current cluster
    create table #next_cluster (
        npl_publn_id int primary key
    );

    declare @added_ids int = 1;

    -- Iterate to find all connected IDs until no new IDs are added
    while @added_ids > 0
    begin
        -- Insert IDs connected to the current cluster into the next cluster table
        insert into #next_cluster (npl_publn_id)
        select distinct ps.id1
        from #pairwise_similarity_filtered ps
        join #current_cluster cc on ps.id2 = cc.npl_publn_id
        where ps.id1 not in (select npl_publn_id from #current_cluster)
        
        union
        
        select distinct ps.id2
        from #pairwise_similarity_filtered ps
        join #current_cluster cc on ps.id1 = cc.npl_publn_id
        where ps.id2 not in (select npl_publn_id from #current_cluster);

        -- Check how many new IDs were added
        set @added_ids = @@ROWCOUNT;

        -- Insert the new IDs from #next_cluster into #current_cluster
        insert into #current_cluster (npl_publn_id)
        select npl_publn_id from #next_cluster;

        -- Clear the next cluster table for the next iteration
        truncate table #next_cluster;
    end;

    -- Insert all the IDs from #current_cluster into the #clusters table with the same cluster ID
    insert into #clusters (npl_publn_id, cluster_id)
    select npl_publn_id, @cluster_id
    from #current_cluster;

    -- Mark all clustered records as processed
    update #unclustered_ids
    set processed = 1
    where npl_publn_id in (select npl_publn_id from #current_cluster);

    -- Increment the cluster counter
    set @cluster_id = @cluster_id + 1;

    -- Drop the temporary cluster tables after each iteration
    drop table #current_cluster;
    drop table #next_cluster;
end;


-- Substep 5: Cleanup - Delete processed rows in one go
delete from #unclustered_ids where processed = 1;

-- Substep 6: Select the results
select * into group7_patstat_clusters from #clusters

-- END of the excercise 20.

-- Cleanup temporary resources
drop index idx_processed on #unclustered_ids;
drop index idx_similarity on #pairwise_similarity_filtered;
drop table if exists #unclustered_ids;
drop table if exists #clusters;

-- Cleanup of all temporary tables and functions to keep database organized
drop table if exists #temp_meta_data, #pairwise_similarity, #pairwise_similarity_filtered, #unclustered_ids
drop function if exists dbo.data_pre_processing, dbo.extractxpnumber_1, dbo.extractissn_1, dbo.extractauthors_1, dbo.extractpublicationdate_1, dbo.extractvolume_1, dbo.extractissue_1, dbo.extractpages_1, dbo.extractdoi_1, dbo.extractisbn_1, dbo.extractremainingtext_1