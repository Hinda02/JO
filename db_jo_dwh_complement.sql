/* =========================================================
   COMPLÉMENT AU SCRIPT db_jo_dwh.sql
   Ajout des données hiérarchie des sports + vues analytiques
   ========================================================= */

USE jo_dwh;

/* -----------------------------
   INSERTION HIÉRARCHIE DES SPORTS
   Selon le sujet de soutenance
------------------------------*/

-- Insertion des 32 mappings sport → catégorie
INSERT INTO dim_sport_category (sport_code, sport_category) VALUES
('Weightlifting', 'Power Sports'),
('Boxing', 'Power Sports'),
('Judo', 'Power Sports'),
('Karate', 'Power Sports'),
('Taekwondo', 'Power Sports'),
('Wrestling', 'Power Sports'),
('Cycling', 'Endurance Sports'),
('Rowing', 'Endurance Sports'),
('Triathlon', 'Endurance Sports'),
('Athletics', 'Speed Sports'),
('Swimming', 'Speed Sports'),
('Basketball', 'Speed Sports'),
('Handball', 'Speed Sports'),
('Hockey', 'Speed Sports'),
('Football', 'Speed Sports'),
('Rugby', 'Speed Sports'),
('Gymnastics', 'Skill Sports'),
('Fencing', 'Skill Sports'),
('Golf', 'Skill Sports'),
('Shooting', 'Skill Sports'),
('Archery', 'Skill Sports'),
('Table Tennis', 'Skill Sports'),
('Badminton', 'Skill Sports'),
('Tennis', 'Skill Sports'),
('Baseball/Softball', 'Skill Sports'),
('Aquatics', 'Water Sports'),
('Canoeing', 'Water Sports'),
('Sailing', 'Water Sports'),
('Surfing', 'Water Sports'),
('Skateboarding', 'Board Sports'),
('Modern Pentathlon', 'Combination Sports'),
('Volleyball', 'Team Sports')
ON DUPLICATE KEY UPDATE sport_category = VALUES(sport_category);

/* -----------------------------
   VUES ANALYTIQUES POUR POWER BI
------------------------------*/

-- Vue 1 : Tableau des médailles par pays (classique)
CREATE OR REPLACE VIEW view_medal_table AS
SELECT
    c.country AS Pays,
    c.noc_code AS Code_Pays,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Medailles_Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Medailles_Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Medailles_Bronze,
    COUNT(*) AS Total_Medailles
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY c.country, c.noc_code
ORDER BY Medailles_Or DESC, Medailles_Argent DESC, Medailles_Bronze DESC;

-- Vue 2 : Médailles par catégorie de sport et pays
CREATE OR REPLACE VIEW view_medals_by_sport_category AS
SELECT
    sc.sport_category AS Categorie_Sport,
    c.country AS Pays,
    s.sport AS Sport,
    fm.medal_type AS Type_Medaille,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY sc.sport_category, c.country, s.sport, fm.medal_type
ORDER BY sc.sport_category, Nombre_Medailles DESC;

-- Vue 3 : Distribution des médailles par catégorie (agrégée)
CREATE OR REPLACE VIEW view_medals_distribution_by_category AS
SELECT
    sc.sport_category AS Categorie_Sport,
    COUNT(*) AS Total_Medailles,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_medal), 2) AS Pourcentage
FROM fact_medal fm
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY sc.sport_category
ORDER BY Total_Medailles DESC;

-- Vue 4 : Rapport médaillés/participants par pays
CREATE OR REPLACE VIEW view_country_efficiency AS
SELECT
    c.country AS Pays,
    c.noc_code AS Code,
    COUNT(DISTINCT a.athlete_sk) AS Total_Athletes,
    COUNT(DISTINCT fm.athlete_sk) AS Total_Medallistes,
    CASE
        WHEN COUNT(DISTINCT a.athlete_sk) > 0
        THEN ROUND(COUNT(DISTINCT fm.athlete_sk) * 100.0 / COUNT(DISTINCT a.athlete_sk), 2)
        ELSE 0
    END AS Pourcentage_Efficacite
FROM dim_country c
LEFT JOIN dim_athlete a ON c.noc_code = a.noc_code
LEFT JOIN fact_medal fm ON a.athlete_sk = fm.athlete_sk
GROUP BY c.country, c.noc_code
HAVING Total_Athletes > 0
ORDER BY Pourcentage_Efficacite DESC;

-- Vue 5 : Pyramide des âges des athlètes
CREATE OR REPLACE VIEW view_age_distribution AS
SELECT
    a.gender AS Sexe,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') < 18 THEN '< 18'
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') BETWEEN 18 AND 22 THEN '18-22'
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') BETWEEN 23 AND 27 THEN '23-27'
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') BETWEEN 28 AND 32 THEN '28-32'
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') BETWEEN 33 AND 37 THEN '33-37'
        WHEN TIMESTAMPDIFF(YEAR, a.birth_date, '2024-07-26') >= 38 THEN '38+'
        ELSE 'Inconnu'
    END AS Tranche_Age,
    COUNT(*) AS Nombre_Athletes,
    COUNT(CASE WHEN fm.athlete_sk IS NOT NULL THEN 1 END) AS Nombre_Medallistes
FROM dim_athlete a
LEFT JOIN fact_medal fm ON a.athlete_sk = fm.athlete_sk
WHERE a.birth_date IS NOT NULL
GROUP BY a.gender, Tranche_Age
ORDER BY a.gender, Tranche_Age;

-- Vue 6 : Évolution chronologique des médailles
CREATE OR REPLACE VIEW view_medals_timeline AS
SELECT
    d.full_date AS Date,
    d.day_name AS Jour,
    c.country AS Pays,
    sc.sport_category AS Categorie_Sport,
    s.sport AS Sport,
    fm.medal_type AS Type_Medaille,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY d.full_date, d.day_name, c.country, sc.sport_category, s.sport, fm.medal_type
ORDER BY d.full_date, Nombre_Medailles DESC;

-- Vue 7 : Corrélation pays/catégorie de sports
CREATE OR REPLACE VIEW view_country_sport_specialization AS
SELECT
    c.country AS Pays,
    sc.sport_category AS Categorie_Sport,
    COUNT(*) AS Nombre_Medailles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.country), 2) AS Pourcentage_Pays
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY c.country, sc.sport_category
HAVING Nombre_Medailles >= 2
ORDER BY c.country, Nombre_Medailles DESC;

-- Vue 8 : Top 10 athlètes les plus médaillés
CREATE OR REPLACE VIEW view_top_athletes AS
SELECT
    a.name AS Athlete,
    a.gender AS Sexe,
    c.country AS Pays,
    COUNT(*) AS Total_Medailles,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze
FROM fact_medal fm
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY a.name, a.gender, c.country
ORDER BY Total_Medailles DESC, Or DESC
LIMIT 10;

/* -----------------------------
   STATISTIQUES ET CONTRÔLES
------------------------------*/

-- Statistiques sur le chargement
CREATE OR REPLACE VIEW view_data_quality_stats AS
SELECT
    'Countries' AS Table_Name,
    COUNT(*) AS Row_Count,
    COUNT(CASE WHEN noc_code IS NULL THEN 1 END) AS Null_Keys
FROM dim_country
UNION ALL
SELECT
    'Sports',
    COUNT(*),
    COUNT(CASE WHEN sport_code IS NULL THEN 1 END)
FROM dim_sport
UNION ALL
SELECT
    'Sport Categories',
    COUNT(*),
    COUNT(CASE WHEN sport_code IS NULL THEN 1 END)
FROM dim_sport_category
UNION ALL
SELECT
    'Events',
    COUNT(*),
    COUNT(CASE WHEN event_tag IS NULL THEN 1 END)
FROM dim_event
UNION ALL
SELECT
    'Athletes',
    COUNT(*),
    COUNT(CASE WHEN athlete_code IS NULL THEN 1 END)
FROM dim_athlete
UNION ALL
SELECT
    'Medals',
    COUNT(*),
    COUNT(CASE WHEN medal_sk IS NULL THEN 1 END)
FROM fact_medal
UNION ALL
SELECT
    'Participations',
    COUNT(*),
    COUNT(CASE WHEN part_sk IS NULL THEN 1 END)
FROM fact_participation;

/* -----------------------------
   FIN DU SCRIPT COMPLÉMENTAIRE
------------------------------*/

-- Afficher les statistiques après insertion
SELECT * FROM view_data_quality_stats;

-- Vérifier la hiérarchie des sports
SELECT sport_category, COUNT(*) AS nb_sports
FROM dim_sport_category
GROUP BY sport_category
ORDER BY sport_category;
