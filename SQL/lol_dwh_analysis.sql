-- Анализ игровой статистики League of Legends (DWH-слой)

-- 1. Топ‑15 чемпионов по винрейту (мин. 5 матчей)
SELECT 
    dc.champion_name,
    COUNT(*) AS matches,
    ROUND(100.0 * SUM(f.win) / COUNT(*), 2) AS winrate_percent
FROM fact_match_participant AS f
JOIN dim_champion AS dc ON f.champion_id = dc.champion_id
GROUP BY dc.champion_name
HAVING COUNT(*) >= 5
ORDER BY winrate_percent DESC
LIMIT 15;

-- 2. Среднее количество побед у топ-15 игроков по количеству матчей
-- есть ошибка в виде NULL
WITH top_players AS (
    SELECT 
        puuid,
        COUNT(*) AS total_matches,
        ROUND(100.0 * SUM(win) / COUNT(*), 2) AS winrate_percent
    FROM fact_match_participant
    GROUP BY puuid
    ORDER BY total_matches DESC
    LIMIT 15
)
SELECT 
    tp.puuid,
    tp.total_matches,
    tp.winrate_percent
FROM top_players tp;


-- 3. Топ-15 чемпионов с наибольшим количеством поражений (минимум 5 матчей)
SELECT 
    dc.champion_name,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN f.win = 0 THEN 1 ELSE 0 END) AS losses,
    ROUND(100.0 * SUM(CASE WHEN f.win = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS loss_percent,
    ROUND(100.0 * SUM(CASE WHEN f.win = 0 THEN 1 ELSE 0 END) / (SELECT COUNT(*) FROM fact_match_participant WHERE win = 0), 2) AS share_of_total_losses
FROM fact_match_participant AS f
JOIN dim_champion AS dc ON f.champion_id = dc.champion_id
GROUP BY dc.champion_name
HAVING COUNT(*) >= 5
ORDER BY losses DESC
LIMIT 15;

-- 4. Среднее количество побед/поражений по всем игрокам и их соотношение
SELECT 
    ROUND(AVG(wins), 2) AS avg_wins,
    ROUND(AVG(losses), 2) AS avg_losses,
    ROUND(AVG(wins) * 1.0 / NULLIF(AVG(losses), 0), 2) AS win_loss_ratio
FROM dim_player;


-- 5. Распределения игроков по очкам лиги (LP) (в интервале по 200 очков)
SELECT 
    dc.champion_name,
    COUNT(*) AS matches,
    (dp.leaguePoints - dp.leaguePoints % 200) AS lp_spread
FROM dim_player AS dp
INNER JOIN fact_match_participant AS f ON dp.puuid = f.puuid
INNER JOIN dim_champion AS dc ON f.champion_id = dc.champion_id
WHERE dp.leaguePoints IS NOT NULL
GROUP BY lp_spread, dc.champion_name
ORDER BY lp_spread DESC, matches DESC;

-- 6. Рспределение длительности матчей
-- Делим длительность матчей на 4 части
WITH quartiles AS (
    SELECT 
        game_duration_min,
        NTILE(4) OVER (ORDER BY game_duration_min) AS q
    FROM fact_match_participant
)
-- Считаем распределение показателей в зависимости от длительности матча
SELECT 
    MIN(game_duration_min) AS min,
    ROUND(AVG(game_duration_min), 2) AS mean,
    ROUND(MAX(CASE WHEN q = 1 THEN game_duration_min END), 2) AS q1,
    ROUND(AVG(CASE WHEN q IN (2,3) THEN game_duration_min END), 2) AS median,
    ROUND(MIN(CASE WHEN q = 3 THEN game_duration_min END), 2) AS q3,
    MAX(game_duration_min) AS max
FROM quartiles;


-- 7. Среднее количество убийств vs смертей по чемпионам (мин. 5 матчей)
SELECT 
    dc.champion_name,
    ROUND(AVG(f.kills), 2) AS avg_kills,
    ROUND(AVG(f.deaths), 2) AS avg_deaths,
    COUNT(*) AS matches
FROM fact_match_participant AS f
JOIN dim_champion AS dc ON f.champion_id = dc.champion_id
GROUP BY dc.champion_name
HAVING COUNT(*) >= 5
ORDER BY avg_kills DESC;