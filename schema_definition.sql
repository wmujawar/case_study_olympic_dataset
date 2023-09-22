CREATE DATABASE olympic_history;

DROP TABLE IF EXISTS athlete_events;
CREATE TABLE athlete_events
(
    id		INT,
    name	VARCHAR,
    sex		CHAR(1),
    age		VARCHAR,
    height	VARCHAR,
    weight	VARCHAR,
    team	VARCHAR,
    noc		VARCHAR,
    games	VARCHAR,
    year	INT,
    season	VARCHAR,
    city	VARCHAR,
    sport	VARCHAR,
    event	VARCHAR,
    medal	VARCHAR
);

DROP TABLE IF EXISTS noc_region;

CREATE TABLE noc_region
(
	noc		VARCHAR,
    region	VARCHAR,
    notes	TEXT
);

SELECT * FROM athlete_events;

CREATE EXTENSION tablefunc;
