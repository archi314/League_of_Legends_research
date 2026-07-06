
DROP TABLE IF EXISTS fact_match_participant;
DROP TABLE IF EXISTS dim_player;
DROP TABLE IF EXISTS dim_champion;

-- Влючение возможности работать с внещним ключом
PRAGMA foreign_keys = ON;

-- Создание таблиц
CREATE TABLE IF NOT EXISTS dim_player (
    puuid TEXT PRIMARY KEY,
    leaguePoints INTEGER,
    rank TEXT,
    wins INTEGER,
    losses INTEGER,
    veteran INTEGER,
    inactive INTEGER,
    freshBlood INTEGER,
    hotStreak INTEGER
);

CREATE TABLE IF NOT EXISTS dim_champion (
    champion_id INTEGER PRIMARY KEY,
    champion_name TEXT,
    title TEXT,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS fact_match_participant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER,
    puuid TEXT,
    champion_id INTEGER,
    team TEXT,
    winning_team INTEGER,
    kills INTEGER,
    deaths INTEGER,
    assists INTEGER,
    gold_earned INTEGER,
    damage_to_champions INTEGER,
    minions_killed INTEGER,
    vision_score INTEGER,
    win INTEGER,
    role TEXT,
    team_position TEXT,
    game_duration_sec INTEGER,
    game_duration_min NUMERIC,
    kda NUMERIC,
    FOREIGN KEY (puuid) REFERENCES dim_player(puuid),
    FOREIGN KEY (champion_id) REFERENCES dim_champion(champion_id),
	UNIQUE(match_id, puuid)
 );

-- Перенесём значения таблиц
INSERT INTO dim_player (puuid, leaguePoints, rank, wins, losses, veteran, inactive, freshBlood, hotStreak)
SELECT
    p.puuid,
    p.leaguePoints,
    p.rank,
    p.wins,
    p.losses,
    p.veteran,
    p.inactive,
    p.freshBlood,
    p.hotStreak
FROM players AS p
LEFT JOIN dim_player AS dp ON p.puuid = dp.puuid
WHERE dp.puuid IS NULL;

INSERT INTO dim_champion (champion_id, champion_name, title, tags)
SELECT
    c.champion_id,
    c.champion_name,
    c.title,
    c.tags
FROM champions AS c
LEFT JOIN dim_champion AS dc ON c.champion_id = dc.champion_id
WHERE dc.champion_id IS NULL;

-- часть значений puuid теряется, не понимаю верно ли соединил по ключам таблицы 
-- и стоило ли иенно так делать
INSERT INTO fact_match_participant (
    match_id, puuid, champion_id, team, winning_team,
    kills, deaths, assists, gold_earned, damage_to_champions,
    minions_killed, vision_score, win, role, team_position,
    game_duration_sec, game_duration_min, kda
)
SELECT 
    m.match_id,
    dp.puuid,
    dc.champion_id,
    m.team,
    m.winning_team,
    m.kills,
    m.deaths,
    m.assists,
    m.gold_earned,
    m.damage_to_champions,
    m.minions_killed,
    m.vision_score,
    m.win,
    m.role,
    m.team_position,
    m.game_duration_sec,
    m.game_duration_min,
    (m.kills + m.assists) * 1.0 / NULLIF(m.deaths, 0) AS kda
FROM matches AS m
LEFT JOIN dim_player AS dp ON m.puuid = dp.puuid
LEFT JOIN dim_champion AS dc ON m.champion = dc.champion_name
LEFT JOIN fact_match_participant AS f
    ON m.match_id = f.match_id AND m.puuid = f.puuid
WHERE f.match_id IS NULL;