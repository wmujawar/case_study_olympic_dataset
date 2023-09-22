-- 1. How many olympics games have been held?
SELECT COUNT(DISTINCT games) AS total_olympic_games
FROM athlete_events;

-- 2. List down all Olympics games held so far.
SELECT DISTINCT year, season, city
FROM athlete_events
ORDER BY year;

-- 3. Mention the total no of nations who participated in each olympics game?
SELECT games, COUNT (DISTINCT region) AS total_region
FROM athlete_events a
INNER JOIN noc_region r
ON a.noc = r.noc
GROUP BY games;

-- 4. Which year saw the highest and lowest no of countries participating in olympics
WITH total_countries AS
(
    SELECT games, COUNT (DISTINCT region) AS total_region 
    FROM athlete_events a
    INNER JOIN noc_region r
    ON a.noc = r.noc
    GROUP BY games
)

SELECT DISTINCT CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_region), ' - ',
              FIRST_VALUE(total_region) OVER(ORDER BY total_region)) AS Lowest_Countries,
       CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_region DESC), ' - ',
              FIRST_VALUE(total_region) OVER(ORDER BY total_region DESC)) AS Highest_Countries
FROM total_countries;

-- 5. Which nation has participated in all of the olympic games
WITH total_games AS
(
	SELECT COUNT(DISTINCT games) AS total_olympic_games
	FROM athlete_events
)

SELECT region, COUNT(DISTINCT games) AS total_participation
FROM athlete_events e
INNER JOIN noc_region r
ON e.noc = r.noc
GROUP BY region
HAVING COUNT(DISTINCT games) = (
    SELECT total_olympic_games
    FROM total_games
);

-- 6. Identify the sport which was played in all summer olympics.
WITH total_summer_games AS
(
    SELECT COUNT(DISTINCT games) AS total_games
    FROM athlete_events
    WHERE season = 'Summer'
),

all_summer_sports AS
(
    SELECT DISTINCT games, sport
    FROM athlete_events
),

total_summer_sports AS
(
    SELECT sport, COUNT(1) AS total_sports
    FROM all_summer_sports
    GROUP BY sport
)

SELECT *
FROM total_summer_sports s
INNER JOIN total_summer_games g
ON s.total_sports = g.total_games;

-- 7. Which Sports were just played only once in the olympics.
SELECT sport, COUNT(DISTINCT games) AS games_count
FROM athlete_events
GROUP BY sport
HAVING COUNT(DISTINCT games) = 1;

-- 8. Fetch the total no of sports played in each olympic games.
SELECT games, COUNT(DISTINCT sport) as total_no_of_sports
FROM athlete_events
GROUP BY games;

-- 9. Fetch oldest athletes to win a gold medal
SELECT name, sex, age, team, games, city, sport, event, medal
FROM
(
    SELECT *, RANK() OVER(ORDER BY age DESC) as rnk
    FROM athlete_events
    WHERE medal = 'Gold'
    AND age != 'NA'
) event_with_rank
WHERE rnk = 1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
WITH male_participant_count AS
(
    SELECT COUNT(name) AS male_count
    FROM athlete_events
    WHERE sex = 'M'
),

female_participant_count AS
(
    SELECT COUNT(name) AS female_count
    FROM athlete_events
    WHERE sex = 'F'
)

SELECT CONCAT('1:', ROUND(male_count::decimal / female_count, 2)) AS ratio
FROM male_participant_count
CROSS JOIN female_participant_count


-- 11. Fetch the top 5 athletes who have won the most gold medals.
WITH athlete_with_gold_medals AS
(
    SELECT name, team, COUNT(medal) AS total_medals
    FROM athlete_events
    WHERE medal = 'Gold'
    GROUP BY name, team
),

athletes_with_rank AS
(
    SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk
    FROM athlete_with_gold_medals
)

SELECT *
FROM athletes_with_rank
WHERE rnk <= 5
ORDER BY total_medals DESC;

-- 12. Fetch the top 5 athletes who have won the most medals
WITH athlete_with_medals AS
(
    SELECT name, team, COUNT(medal) AS total_medals
    FROM athlete_events
    WHERE medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY name, team
),

athletes_with_rank AS
(
    SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk
    FROM athlete_with_medals
)

SELECT name, team, total_medals
FROM athletes_with_rank
WHERE rnk <= 5
ORDER BY total_medals DESC;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH team_with_medals AS
(
    SELECT region, COUNT(medal) AS total_medals
    FROM athlete_events e
    INNER JOIN noc_region r
    ON e.noc = r.noc
    WHERE medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY region
),

team_rank AS
(
    SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rnk
    FROM team_with_medals
)

SELECT region, total_medals, rnk
FROM team_rank
WHERE rnk <= 5
ORDER BY total_medals DESC;

-- 14. List down total gold, silver and bronze medals won by each country.
SELECT country, COALESCE(gold, 0) AS gold, COALESCE(silver, 0) AS silver, COALESCE(bronze, 0) AS bronze
FROM CROSSTAB(
  'SELECT region, medal, COUNT(1) AS medal_count
  FROM athlete_events e
  INNER JOIN noc_region r
  ON e.noc = r.noc
  WHERE medal IN (''Gold'', ''Silver'', ''Bronze'')
  GROUP BY region, medal
  ORDER BY region, medal',
  'VALUES(''Bronze''), (''Gold''), (''Silver'')'
) AS FINAL_RESULT(country VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)
ORDER BY gold DESC, silver DESC, bronze DESC;

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
SELECT SUBSTRING(game_region, 1, POSITION(' - ' IN game_region) - 1) AS games,
        SUBSTRING(game_region, POSITION(' - ' IN game_region) + 3) AS country,
        COALESCE(gold, 0) AS gold, COALESCE(silver, 0) AS silver, COALESCE(bronze, 0 ) AS bronze
FROM CROSSTAB(
  'SELECT CONCAT(games, '' - '', region) game_region, medal, COUNT(1) AS medal_count
  FROM athlete_events e
  INNER JOIN noc_region r
  ON e.noc = r.noc
  WHERE medal IN (''Gold'', ''Silver'', ''Bronze'')
  GROUP BY games, region, medal
  ORDER BY games, region, medal',
  'VALUES (''Bronze''), (''Gold''), (''Silver'')'
) AS FINAL_RESULT(game_region VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH pivot_record AS
(
  SELECT SUBSTRING(game_region, 1, POSITION(' - ' IN game_region) - 1) AS games,
        SUBSTRING(game_region, POSITION(' - ' IN game_region) + 3) AS country,
        COALESCE(gold, 0) AS gold, COALESCE(silver, 0) AS silver, COALESCE(bronze, 0 ) AS bronze
  FROM CROSSTAB(
    'SELECT CONCAT(games, '' - '', region) game_region, medal, COUNT(1) AS medal_count
    FROM athlete_events e
    INNER JOIN noc_region r
    ON e.noc = r.noc
    WHERE medal IN (''Gold'', ''Silver'', ''Bronze'')
    GROUP BY games, region, medal
    ORDER BY games, region',
    'VALUES (''Bronze''), (''Gold''), (''Silver'')'
  ) AS FINAL_RESULT(game_region VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)
)

SELECT DISTINCT games,
	CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY gold DESC), ' - ',
        FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
  CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY silver DESC), ' - ',
        FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
  CONCAT(FIRST_VALUE(country) OVER(PARTITION BY games ORDER BY bronze DESC), ' - ',
        FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze
FROM pivot_record
ORDER BY games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH pivot_record AS
(
  SELECT SUBSTRING(game_region, 1, POSITION(' - ' IN game_region) - 1) AS games,
        SUBSTRING(game_region, POSITION(' - ' IN game_region) + 3) AS country,
        COALESCE(gold, 0) AS gold, COALESCE(silver, 0) AS silver, COALESCE(bronze, 0 ) AS bronze
  FROM CROSSTAB(
    'SELECT CONCAT(games, '' - '', region) game_region, medal, COUNT(1) AS medal_count
    FROM athlete_events e
    INNER JOIN noc_region r
    ON e.noc = r.noc
    WHERE medal IN (''Gold'', ''Silver'', ''Bronze'')
    GROUP BY games, region, medal
    ORDER BY games, region',
    'VALUES (''Bronze''), (''Gold''), (''Silver'')'
  ) AS FINAL_RESULT(game_region VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)
),

country_wise_total_medals AS
(
	SELECT games, region AS country, COUNT(1) as total_medals
  FROM athlete_events e
  INNER JOIN noc_region r
  ON e.noc = r.noc
  WHERE medal <> 'NA'
  GROUP BY games, region
)

SELECT DISTINCT p.games,
	CONCAT(FIRST_VALUE(p.country) OVER(PARTITION BY p.games ORDER BY gold DESC), ' - ',
        FIRST_VALUE(gold) OVER(PARTITION BY p.games ORDER BY gold DESC)) AS max_gold,
  CONCAT(FIRST_VALUE(p.country) OVER(PARTITION BY p.games ORDER BY silver DESC), ' - ',
        FIRST_VALUE(silver) OVER(PARTITION BY p.games ORDER BY silver DESC)) AS max_silver,
  CONCAT(FIRST_VALUE(p.country) OVER(PARTITION BY p.games ORDER BY bronze DESC), ' - ',
        FIRST_VALUE(bronze) OVER(PARTITION BY p.games ORDER BY bronze DESC)) AS max_bronze,
        
  CONCAT(FIRST_VALUE(c.country) OVER(PARTITION BY c.games ORDER BY total_medals DESC), ' - ',
        FIRST_VALUE(total_medals) OVER(PARTITION BY c.games ORDER BY total_medals DESC)) AS max_medals
FROM pivot_record p
INNER JOIN country_wise_total_medals c
ON p.games = c.games AND p.country = c.country
ORDER BY games;

-- 18. Which countries have never won gold medal but have won silver/bronze medals?
WITH region_with_medals AS
(
  SELECT region AS country,
        COALESCE(gold, 0) AS gold,
        COALESCE(silver, 0) AS silver,
        COALESCE(bronze, 0) AS bronze
  FROM CROSSTAB(
    'SELECT region, medal, COUNT(1) AS medal_count
    FROM athlete_events e
    INNER JOIN noc_region r
    ON e.noc = r.noc
    WHERE medal IN (''Gold'', ''Silver'', ''Bronze'')
    GROUP BY region, medal
    ORDER BY region',
    'VALUES (''Bronze''), (''Gold''), (''Silver'')'
  ) AS FINAL_RESULT(region VARCHAR, bronze BIGINT, gold BIGINT, silver BIGINT)
)

SELECT *
FROM region_with_medals
WHERE gold = 0 AND (silver > 0 OR bronze > 0)
ORDER BY silver DESC, bronze DESC;

-- 19. In which Sport/event, India has won highest medals.
SELECT sport, COUNT(1) AS total_medals
FROM athlete_events e
INNER JOIN noc_region r
ON e.noc = r.noc
WHERE medal <> 'NA'
AND region = 'India'
GROUP BY region, sport
ORDER BY total_medals DESC
LIMIT 1;

-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
SELECT team, sport, games, COUNT(1) AS total_medals
FROM athlete_events
WHERE medal <> 'NA'
AND team = 'India'
AND sport = 'Hockey'
GROUP BY team, sport, games
ORDER BY total_medals DESC
