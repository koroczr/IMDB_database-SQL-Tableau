DROP DATABASE IF EXISTS imdb;
CREATE DATABASE imdb;

/*Create the tables !*/
#########################################################################################
USE imdb;
DROP TABLE IF EXISTS name_basics;
CREATE TABLE name_basics
	(
	nconst varchar(255) primary key not null,
	primaryName varchar(255),
	birthYear int,
	deathYear int,
	primaryProfession varchar(255),
	knownForTitles varchar(255)
	);
    
USE imdb;
DROP TABLE IF EXISTS title_akas;
CREATE TABLE title_akas
	(
    titleId varchar(255),
    ordering varchar(255),
    title varchar(1000), 
    region varchar(255),
    lang varchar(255),
    typ varchar(255),
    attributes varchar(255),
    isOriginalTitle int
	);
    
USE imdb;
DROP TABLE IF EXISTS title_basics;
CREATE TABLE title_basics
	(
    tconst varchar(255) primary key not null,
    titleType varchar(255),
    primaryTitle varchar(1000),
    originalTitle varchar(1000),
    isAdult	 int,
    startYear int,
    endYear	int,
    runtimeMinutes varchar(255),
    genres varchar(255)
	);
    
USE imdb;
DROP TABLE IF EXISTS title_crew;
CREATE TABLE title_crew
	(
    tconst varchar(255) primary key not null,
    directors varchar(7000),	
    writers varchar(8000)
	);
    
USE imdb;
DROP TABLE IF EXISTS title_episode;
CREATE TABLE title_episode
	(
    tconst varchar(255) primary key not null,
    parentTconst varchar(255),	
    seasonNumber int,
    episodeNumber int
	);
    
USE imdb;
DROP TABLE IF EXISTS title_principals;
CREATE TABLE title_principals
	(
    tconst varchar(255),
    ordering int,
    nconst varchar(255),
    category varchar(255),
    job varchar(2000),
    characters varchar(2000)
	);
    
USE imdb;
DROP TABLE IF EXISTS title_ratings;
CREATE TABLE title_ratings
	(
    tconst varchar(255) primary key not null,
    averageRating float,
    numVotes int
	);

#########################################################################################
/* Load the Data into tables */
#########################################################################################

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/name.basics.csv' INTO TABLE name_basics
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.akas.csv' INTO TABLE title_akas
CHARACTER SET utf8
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.basics.csv' INTO TABLE title_basics
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.crew.csv' INTO TABLE title_crew
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.episode.csv' INTO TABLE title_episode
CHARACTER SET utf8
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.principals.csv' INTO TABLE title_principals
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
    (tconst ,
    ordering ,
    nconst ,
    category,
    job ,
    characters,
    @dummy,
    @dummy,
    @dummy,
    @dummy,
    @dummy);

SET global local_infile = 'ON';
LOAD DATA INFILE 'C:/Projects/imdb_dataset/TSV_CSV/title.ratings.csv' INTO TABLE title_ratings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

#########################################################################################
SHOW VARIABLES LIKE "local_infile";
SHOW VARIABLES LIKE "secure_file_priv";



commit;



-- What was the top 10 movie based on the most votes and ratings ?

create index idx_titleid on title_akas(titleID);    
create index idx_tconst on title_ratings(tconst);    
create index idx_tisOriginalTitle on title_akas(isOriginalTitle);    

SELECT 
    ta.title, tr.numVotes, tr.averageRating
FROM
    title_akas AS ta
        JOIN
    title_ratings AS tr ON tr.tconst = ta.titleId
WHERE
    ta.isOriginalTitle = '1'
ORDER BY tr.numVotes DESC , tr.averageRating DESC
LIMIT 10;

/*
-- What was the top 10 longest series based on the season numbers ?

create index idx_tconst on title_basics(tconst);
create index idx_tconst on title_episode(tconst);

select
tb.originalTitle, tb.startYear, tb.endYear, tb.genres, te.seasonNumber, te.episodeNumber
from
title_basics as tb 
join
title_episode as te on te.tconst = tb.tconst
where te.seasonNumber <1000
order by te.seasonNumber desc
limit 10;
*/

-- Who directed "The Dark Knight" movie ?

use imdb;
drop procedure if exists director_searcher;
Delimiter $$
create procedure director_searcher(in movie_name varchar(255), out director varchar(255))
begin

SELECT 
    nb.primaryName
into director FROM
    name_basics AS nb
        JOIN
    title_crew AS tc ON tc.directors = nb.nconst
        JOIN
    title_basics AS tb ON tb.tconst = tc.tconst
WHERE
    tb.primaryTitle = movie_name and tb.titleType = 'movie';


end$$
Delimiter ;

set @director = '0';
call imdb.director_searcher('The Dark Knight', @director);
SELECT @director;


-- What was the ratio between the actor and actress, who were born between 1950 and 1999?

CREATE INDEX idx_primaryProfession on name_basics(primaryProfession);
CREATE INDEX idx_birthYear on name_basics(birthYear);

SELECT 
    primaryName,
    birthYear,
    CASE
        WHEN
            (primaryProfession LIKE '%actor%'
                AND birthYear BETWEEN '1950-01-01' AND '1999-12-31')
        THEN
            'actor'
        WHEN
            (primaryProfession LIKE '%actress%'
                AND birthYear BETWEEN '1950-01-01' AND '1999-12-31')
        THEN
            'actress'
        ELSE 'other'
    END AS Actoractress
FROM
    name_basics
WHERE
    birthYear BETWEEN '1950-01-01' AND '1999-12-31';


-- How many movies were appeared after 2000? Where the duritaion was longer than 30 mins. and it was not adult movie!

CREATE INDEX idx_isAdult on title_basics(isAdult);
CREATE INDEX idx_runtimeMinutes on title_basics(runtimeMinutes);
CREATE INDEX idx_startYear on title_basics(startYear);
CREATE INDEX idx_titleType on title_basics(titleType);


SELECT 
    primaryTitle, startyear
FROM
    title_basics
WHERE
    isAdult = '0' AND runtimeMinutes > '30' AND startYear > '2000-01-01' AND titleType = 'movie';



-- Who were the top 10 actor or actress, how acted the most in films?

create index idx_nnconst on name_basics(nconst);
create index idx_tnconst on title_principals(nconst);
create index idx_ttconst on title_principals(tconst);
create index idx_ptconst on title_basics(tconst);

SELECT 
    nb.primaryName, COUNT(nb.primaryName) AS number_of_movies
FROM
    name_basics AS nb
        JOIN
    title_principals AS tp ON tp.nconst = nb.nconst
        JOIN
    title_basics AS tb ON tb.tconst = tp.tconst
WHERE
    (tp.category = 'actor'
        OR tp.category = 'actress')
        AND tb.titleType = 'movie'
GROUP BY nb.primaryName
ORDER BY COUNT(nb.primaryName) DESC
limit 10;




