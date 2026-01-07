-- ============================================================================
-- Script de création de l'entrepôt de données - Jeux Olympiques Paris 2024
-- Modèle : Schéma en Étoile (Star Schema)
-- Base de données : PostgreSQL / MySQL compatible
-- ============================================================================

-- ============================================================================
-- SUPPRESSION DES TABLES EXISTANTES (pour réinitialisation)
-- ============================================================================

DROP TABLE IF EXISTS fact_participation CASCADE;
DROP TABLE IF EXISTS fact_medals CASCADE;
DROP TABLE IF EXISTS dim_medal_type CASCADE;
DROP TABLE IF EXISTS dim_venue CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_event CASCADE;
DROP TABLE IF EXISTS dim_sport CASCADE;
DROP TABLE IF EXISTS dim_sport_hierarchy CASCADE;
DROP TABLE IF EXISTS dim_athlete CASCADE;
DROP TABLE IF EXISTS dim_country CASCADE;

-- ============================================================================
-- TABLES DE DIMENSIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- Dimension : Pays (NOC - National Olympic Committee)
-- --------------------------------------------------------------------------
CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    country_code VARCHAR(3) UNIQUE NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    country_long VARCHAR(150),
    country_tag VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_country_code ON dim_country(country_code);
CREATE INDEX idx_country_name ON dim_country(country_name);

-- --------------------------------------------------------------------------
-- Dimension : Hiérarchie des Sports
-- --------------------------------------------------------------------------
CREATE TABLE dim_sport_hierarchy (
    hierarchy_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    category_code VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hierarchy_category ON dim_sport_hierarchy(category_name);

-- Insertion des catégories de sports selon le sujet
INSERT INTO dim_sport_hierarchy (category_name, category_code, description) VALUES
('Power Sports', 'POWER', 'Sports de force et combat'),
('Endurance Sports', 'ENDURANCE', 'Sports d''endurance'),
('Speed Sports', 'SPEED', 'Sports de vitesse'),
('Skill Sports', 'SKILL', 'Sports de précision et technique'),
('Water Sports', 'WATER', 'Sports aquatiques'),
('Board Sports', 'BOARD', 'Sports de glisse'),
('Combination Sports', 'COMBO', 'Sports combinés'),
('Team Sports', 'TEAM', 'Sports collectifs');

-- --------------------------------------------------------------------------
-- Dimension : Sports
-- --------------------------------------------------------------------------
CREATE TABLE dim_sport (
    sport_id SERIAL PRIMARY KEY,
    sport_name VARCHAR(100) NOT NULL,
    sport_code VARCHAR(10),
    hierarchy_id INTEGER REFERENCES dim_sport_hierarchy(hierarchy_id),
    sport_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sport_name ON dim_sport(sport_name);
CREATE INDEX idx_sport_code ON dim_sport(sport_code);
CREATE INDEX idx_sport_hierarchy ON dim_sport(hierarchy_id);

-- --------------------------------------------------------------------------
-- Dimension : Événements (Épreuves)
-- --------------------------------------------------------------------------
CREATE TABLE dim_event (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(200) NOT NULL,
    event_tag VARCHAR(100),
    sport_id INTEGER REFERENCES dim_sport(sport_id),
    gender VARCHAR(10), -- Male, Female, Mixed
    event_type VARCHAR(50), -- Individual, Team
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_event_name ON dim_event(event_name);
CREATE INDEX idx_event_sport ON dim_event(sport_id);
CREATE INDEX idx_event_gender ON dim_event(gender);

-- --------------------------------------------------------------------------
-- Dimension : Athlètes
-- --------------------------------------------------------------------------
CREATE TABLE dim_athlete (
    athlete_id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE,
    name VARCHAR(200) NOT NULL,
    name_short VARCHAR(100),
    name_tv VARCHAR(100),
    gender VARCHAR(10),
    birth_date DATE,
    age INTEGER,
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    country_id INTEGER REFERENCES dim_country(country_id),
    country_code VARCHAR(3),
    nationality VARCHAR(100),
    nationality_code VARCHAR(3),
    birth_place VARCHAR(200),
    birth_country VARCHAR(100),
    residence_place VARCHAR(200),
    residence_country VARCHAR(100),
    nickname VARCHAR(100),
    occupation VARCHAR(200),
    education TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_athlete_code ON dim_athlete(code);
CREATE INDEX idx_athlete_name ON dim_athlete(name);
CREATE INDEX idx_athlete_country ON dim_athlete(country_id);
CREATE INDEX idx_athlete_gender ON dim_athlete(gender);
CREATE INDEX idx_athlete_birth_date ON dim_athlete(birth_date);

-- --------------------------------------------------------------------------
-- Dimension : Dates
-- --------------------------------------------------------------------------
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    day INTEGER,
    month INTEGER,
    year INTEGER,
    day_of_week VARCHAR(10),
    day_name VARCHAR(20),
    week_number INTEGER,
    quarter INTEGER,
    is_weekend BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_date_full ON dim_date(full_date);
CREATE INDEX idx_date_year_month ON dim_date(year, month);

-- --------------------------------------------------------------------------
-- Dimension : Lieux de compétition (Venues)
-- --------------------------------------------------------------------------
CREATE TABLE dim_venue (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(200) NOT NULL,
    venue_code VARCHAR(10),
    location VARCHAR(200),
    sports TEXT, -- JSON ou liste de sports
    date_start DATE,
    date_end DATE,
    venue_tag VARCHAR(100),
    venue_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_venue_name ON dim_venue(venue_name);
CREATE INDEX idx_venue_code ON dim_venue(venue_code);

-- --------------------------------------------------------------------------
-- Dimension : Type de Médaille
-- --------------------------------------------------------------------------
CREATE TABLE dim_medal_type (
    medal_type_id SERIAL PRIMARY KEY,
    medal_type VARCHAR(20) NOT NULL,
    medal_code INTEGER NOT NULL,
    medal_order INTEGER, -- Pour tri : Or=1, Argent=2, Bronze=3
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_medal_type ON dim_medal_type(medal_type);
CREATE INDEX idx_medal_code ON dim_medal_type(medal_code);

-- Insertion des types de médailles
INSERT INTO dim_medal_type (medal_type, medal_code, medal_order) VALUES
('Gold Medal', 1, 1),
('Silver Medal', 2, 2),
('Bronze Medal', 3, 3);

-- ============================================================================
-- TABLES DE FAITS
-- ============================================================================

-- --------------------------------------------------------------------------
-- Fait : Médailles
-- --------------------------------------------------------------------------
CREATE TABLE fact_medals (
    medal_fact_id SERIAL PRIMARY KEY,
    athlete_id INTEGER REFERENCES dim_athlete(athlete_id),
    country_id INTEGER REFERENCES dim_country(country_id),
    sport_id INTEGER REFERENCES dim_sport(sport_id),
    event_id INTEGER REFERENCES dim_event(event_id),
    date_id INTEGER REFERENCES dim_date(date_id),
    medal_type_id INTEGER REFERENCES dim_medal_type(medal_type_id),
    venue_id INTEGER,
    medal_date DATE NOT NULL,
    is_team_medal BOOLEAN DEFAULT FALSE,
    team_code VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fact_medals_athlete ON fact_medals(athlete_id);
CREATE INDEX idx_fact_medals_country ON fact_medals(country_id);
CREATE INDEX idx_fact_medals_sport ON fact_medals(sport_id);
CREATE INDEX idx_fact_medals_event ON fact_medals(event_id);
CREATE INDEX idx_fact_medals_date ON fact_medals(date_id);
CREATE INDEX idx_fact_medals_medal_type ON fact_medals(medal_type_id);
CREATE INDEX idx_fact_medals_medal_date ON fact_medals(medal_date);

-- --------------------------------------------------------------------------
-- Fait : Participation
-- --------------------------------------------------------------------------
CREATE TABLE fact_participation (
    participation_id SERIAL PRIMARY KEY,
    athlete_id INTEGER REFERENCES dim_athlete(athlete_id),
    country_id INTEGER REFERENCES dim_country(country_id),
    sport_id INTEGER REFERENCES dim_sport(sport_id),
    event_id INTEGER REFERENCES dim_event(event_id),
    is_medallist BOOLEAN DEFAULT FALSE,
    medal_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fact_participation_athlete ON fact_participation(athlete_id);
CREATE INDEX idx_fact_participation_country ON fact_participation(country_id);
CREATE INDEX idx_fact_participation_sport ON fact_participation(sport_id);
CREATE INDEX idx_fact_participation_medallist ON fact_participation(is_medallist);

-- ============================================================================
-- VUES ANALYTIQUES
-- ============================================================================

-- --------------------------------------------------------------------------
-- Vue : Tableau des médailles par pays
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_medal_table AS
SELECT
    c.country_name,
    c.country_code,
    COUNT(CASE WHEN mt.medal_order = 1 THEN 1 END) AS gold_medals,
    COUNT(CASE WHEN mt.medal_order = 2 THEN 1 END) AS silver_medals,
    COUNT(CASE WHEN mt.medal_order = 3 THEN 1 END) AS bronze_medals,
    COUNT(*) AS total_medals
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY c.country_name, c.country_code
ORDER BY gold_medals DESC, silver_medals DESC, bronze_medals DESC;

-- --------------------------------------------------------------------------
-- Vue : Médailles par hiérarchie de sports
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_medals_by_sport_hierarchy AS
SELECT
    sh.category_name,
    c.country_name,
    s.sport_name,
    mt.medal_type,
    COUNT(*) AS medal_count
FROM fact_medals fm
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY sh.category_name, c.country_name, s.sport_name, mt.medal_type
ORDER BY sh.category_name, medal_count DESC;

-- --------------------------------------------------------------------------
-- Vue : Ratio médaillés / participants par pays
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_country_efficiency AS
SELECT
    c.country_name,
    c.country_code,
    COUNT(DISTINCT fp.athlete_id) AS total_athletes,
    COUNT(DISTINCT CASE WHEN fp.is_medallist THEN fp.athlete_id END) AS total_medallists,
    CASE
        WHEN COUNT(DISTINCT fp.athlete_id) > 0
        THEN ROUND(CAST(COUNT(DISTINCT CASE WHEN fp.is_medallist THEN fp.athlete_id END) AS NUMERIC) * 100 / COUNT(DISTINCT fp.athlete_id), 2)
        ELSE 0
    END AS efficiency_percentage
FROM fact_participation fp
JOIN dim_country c ON fp.country_id = c.country_id
GROUP BY c.country_name, c.country_code
ORDER BY efficiency_percentage DESC;

-- --------------------------------------------------------------------------
-- Vue : Distribution des âges des athlètes
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_age_distribution AS
SELECT
    a.gender,
    CASE
        WHEN a.age < 18 THEN 'Under 18'
        WHEN a.age BETWEEN 18 AND 22 THEN '18-22'
        WHEN a.age BETWEEN 23 AND 27 THEN '23-27'
        WHEN a.age BETWEEN 28 AND 32 THEN '28-32'
        WHEN a.age BETWEEN 33 AND 37 THEN '33-37'
        ELSE '38+'
    END AS age_group,
    COUNT(*) AS total_athletes,
    COUNT(CASE WHEN fp.is_medallist THEN 1 END) AS medallists
FROM dim_athlete a
LEFT JOIN fact_participation fp ON a.athlete_id = fp.athlete_id
WHERE a.age IS NOT NULL
GROUP BY a.gender, age_group
ORDER BY a.gender, age_group;

-- --------------------------------------------------------------------------
-- Vue : Évolution chronologique des médailles
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW view_medals_timeline AS
SELECT
    d.full_date,
    d.day_name,
    c.country_name,
    sh.category_name AS sport_category,
    s.sport_name,
    mt.medal_type,
    COUNT(*) AS daily_medals
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY d.full_date, d.day_name, c.country_name, sh.category_name, s.sport_name, mt.medal_type
ORDER BY d.full_date, daily_medals DESC;

-- ============================================================================
-- COMMENTAIRES SUR LES TABLES
-- ============================================================================

COMMENT ON TABLE dim_country IS 'Dimension des pays participants aux JO';
COMMENT ON TABLE dim_sport_hierarchy IS 'Hiérarchie des catégories de sports selon le sujet';
COMMENT ON TABLE dim_sport IS 'Dimension des sports olympiques';
COMMENT ON TABLE dim_event IS 'Dimension des épreuves sportives';
COMMENT ON TABLE dim_athlete IS 'Dimension des athlètes participants';
COMMENT ON TABLE dim_date IS 'Dimension temporelle';
COMMENT ON TABLE dim_venue IS 'Dimension des lieux de compétition';
COMMENT ON TABLE dim_medal_type IS 'Dimension des types de médailles';
COMMENT ON TABLE fact_medals IS 'Table de faits des médailles remportées';
COMMENT ON TABLE fact_participation IS 'Table de faits des participations';

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================
--
-- NOTES D'UTILISATION :
-- 1. Ce schéma suit le modèle en étoile (Star Schema)
-- 2. Les dimensions sont normalisées
-- 3. Les tables de faits contiennent les mesures et clés étrangères
-- 4. Les vues facilitent les requêtes analytiques
-- 5. Les index optimisent les performances des requêtes
--
-- Pour charger les données, utiliser les scripts ETL dans le dossier /etl
-- ============================================================================
