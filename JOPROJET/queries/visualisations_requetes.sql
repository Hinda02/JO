-- ============================================================================
-- Requêtes SQL pour les Visualisations - Projet JO Paris 2024
-- Ces requêtes répondent aux exigences du sujet de soutenance
-- ============================================================================

-- ============================================================================
-- 1. PYRAMIDE DES ÂGES DES ATHLÈTES PAR SEXE
-- ============================================================================

-- 1.1 Tous les participants
SELECT
    a.gender AS Sexe,
    CASE
        WHEN a.age < 18 THEN '< 18'
        WHEN a.age BETWEEN 18 AND 22 THEN '18-22'
        WHEN a.age BETWEEN 23 AND 27 THEN '23-27'
        WHEN a.age BETWEEN 28 AND 32 THEN '28-32'
        WHEN a.age BETWEEN 33 AND 37 THEN '33-37'
        WHEN a.age >= 38 THEN '38+'
        ELSE 'Inconnu'
    END AS Tranche_Age,
    COUNT(*) AS Nombre_Athletes,
    CASE WHEN a.gender = 'Male' THEN COUNT(*) ELSE -COUNT(*) END AS Nombre_Pour_Pyramide
FROM dim_athlete a
WHERE a.age IS NOT NULL
GROUP BY a.gender, Tranche_Age
ORDER BY a.gender, Tranche_Age;

-- 1.2 Uniquement les médaillés
SELECT
    a.gender AS Sexe,
    CASE
        WHEN a.age < 18 THEN '< 18'
        WHEN a.age BETWEEN 18 AND 22 THEN '18-22'
        WHEN a.age BETWEEN 23 AND 27 THEN '23-27'
        WHEN a.age BETWEEN 28 AND 32 THEN '28-32'
        WHEN a.age BETWEEN 33 AND 37 THEN '33-37'
        WHEN a.age >= 38 THEN '38+'
        ELSE 'Inconnu'
    END AS Tranche_Age,
    COUNT(DISTINCT a.athlete_id) AS Nombre_Medallistes,
    CASE WHEN a.gender = 'Male' THEN COUNT(DISTINCT a.athlete_id) ELSE -COUNT(DISTINCT a.athlete_id) END AS Nombre_Pour_Pyramide
FROM dim_athlete a
INNER JOIN fact_medals fm ON a.athlete_id = fm.athlete_id
WHERE a.age IS NOT NULL
GROUP BY a.gender, Tranche_Age
ORDER BY a.gender, Tranche_Age;

-- ============================================================================
-- 2. RAPPORT ENTRE NOMBRE DE MÉDAILLÉS ET NOMBRE DE PARTICIPANTS PAR PAYS
-- ============================================================================

SELECT
    c.country_name AS Pays,
    c.country_code AS Code_Pays,
    COUNT(DISTINCT fp.athlete_id) AS Nombre_Athletes,
    COUNT(DISTINCT CASE WHEN fp.is_medallist THEN fp.athlete_id END) AS Nombre_Medallistes,
    CASE
        WHEN COUNT(DISTINCT fp.athlete_id) > 0
        THEN ROUND(
            CAST(COUNT(DISTINCT CASE WHEN fp.is_medallist THEN fp.athlete_id END) AS NUMERIC) * 100.0 /
            COUNT(DISTINCT fp.athlete_id), 2
        )
        ELSE 0
    END AS Pourcentage_Efficacite,
    CAST(COUNT(DISTINCT CASE WHEN fp.is_medallist THEN fp.athlete_id END) AS NUMERIC) /
    NULLIF(COUNT(DISTINCT fp.athlete_id), 0) AS Ratio_Medailles
FROM fact_participation fp
JOIN dim_country c ON fp.country_id = c.country_id
GROUP BY c.country_name, c.country_code
HAVING COUNT(DISTINCT fp.athlete_id) > 0
ORDER BY Nombre_Medallistes DESC, Nombre_Athletes DESC;

-- ============================================================================
-- 3. TABLEAU DES MÉDAILLES
-- ============================================================================

-- 3.1 Tableau classique par pays
SELECT
    c.country_name AS Pays,
    c.country_code AS Code,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Medailles_Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Medailles_Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Medailles_Bronze,
    COUNT(*) AS Total_Medailles
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY c.country_name, c.country_code
ORDER BY Medailles_Or DESC, Medailles_Argent DESC, Medailles_Bronze DESC;

-- 3.2 Médailles par pays et hiérarchie de sports
SELECT
    c.country_name AS Pays,
    sh.category_name AS Categorie_Sport,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Bronze,
    COUNT(*) AS Total
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY c.country_name, sh.category_name
ORDER BY c.country_name, Total DESC;

-- 3.3 Médailles par pays, sport et sexe
SELECT
    c.country_name AS Pays,
    s.sport_name AS Sport,
    a.gender AS Sexe,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Bronze,
    COUNT(*) AS Total
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY c.country_name, s.sport_name, a.gender
ORDER BY c.country_name, Total DESC;

-- 3.4 Médailles par type et sexe
SELECT
    mt.medal_type AS Type_Medaille,
    a.gender AS Sexe,
    COUNT(*) AS Nombre
FROM fact_medals fm
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
GROUP BY mt.medal_type, a.gender
ORDER BY mt.medal_code, a.gender;

-- ============================================================================
-- 4. REPRÉSENTATION CHRONOLOGIQUE DU NOMBRE DE MÉDAILLES
-- ============================================================================

-- 4.1 Évolution quotidienne globale
SELECT
    d.full_date AS Date,
    d.day_name AS Jour,
    COUNT(*) AS Nombre_Medailles,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Medailles_Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Medailles_Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Medailles_Bronze
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY d.full_date, d.day_name
ORDER BY d.full_date;

-- 4.2 Évolution par pays
SELECT
    d.full_date AS Date,
    c.country_name AS Pays,
    COUNT(*) AS Nombre_Medailles,
    SUM(COUNT(*)) OVER (PARTITION BY c.country_name ORDER BY d.full_date) AS Medailles_Cumulees
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_country c ON fm.country_id = c.country_id
GROUP BY d.full_date, c.country_name
ORDER BY d.full_date, Nombre_Medailles DESC;

-- 4.3 Évolution par hiérarchie de sports
SELECT
    d.full_date AS Date,
    sh.category_name AS Categorie_Sport,
    COUNT(*) AS Nombre_Medailles
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
GROUP BY d.full_date, sh.category_name
ORDER BY d.full_date, Nombre_Medailles DESC;

-- 4.4 Évolution par sexe
SELECT
    d.full_date AS Date,
    a.gender AS Sexe,
    COUNT(*) AS Nombre_Medailles
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
GROUP BY d.full_date, a.gender
ORDER BY d.full_date, a.gender;

-- 4.5 Évolution complète avec tous les axes
SELECT
    d.full_date AS Date,
    d.day_name AS Jour,
    c.country_name AS Pays,
    sh.category_name AS Categorie_Sport,
    s.sport_name AS Sport,
    a.gender AS Sexe,
    mt.medal_type AS Type_Medaille,
    COUNT(*) AS Nombre_Medailles
FROM fact_medals fm
JOIN dim_date d ON fm.date_id = d.date_id
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY d.full_date, d.day_name, c.country_name, sh.category_name, s.sport_name, a.gender, mt.medal_type
ORDER BY d.full_date, Nombre_Medailles DESC;

-- ============================================================================
-- 5. ANALYSES SUPPLÉMENTAIRES (BONUS)
-- ============================================================================

-- 5.1 Top 10 athlètes les plus médaillés
SELECT
    a.name AS Athlete,
    a.gender AS Sexe,
    c.country_name AS Pays,
    COUNT(*) AS Nombre_Medailles,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Bronze
FROM fact_medals fm
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY a.name, a.gender, c.country_name
ORDER BY Nombre_Medailles DESC, Or DESC
LIMIT 10;

-- 5.2 Sports les plus médaillés
SELECT
    s.sport_name AS Sport,
    sh.category_name AS Categorie,
    COUNT(*) AS Nombre_Medailles
FROM fact_medals fm
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
GROUP BY s.sport_name, sh.category_name
ORDER BY Nombre_Medailles DESC;

-- 5.3 Distribution des médailles par hiérarchie de sports
SELECT
    sh.category_name AS Categorie_Sport,
    COUNT(*) AS Total_Medailles,
    COUNT(CASE WHEN mt.medal_code = 1 THEN 1 END) AS Or,
    COUNT(CASE WHEN mt.medal_code = 2 THEN 1 END) AS Argent,
    COUNT(CASE WHEN mt.medal_code = 3 THEN 1 END) AS Bronze,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_medals), 2) AS Pourcentage_Total
FROM fact_medals fm
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_medal_type mt ON fm.medal_type_id = mt.medal_type_id
GROUP BY sh.category_name
ORDER BY Total_Medailles DESC;

-- 5.4 Analyse âge moyen des médaillés par sport
SELECT
    s.sport_name AS Sport,
    sh.category_name AS Categorie,
    ROUND(AVG(a.age), 1) AS Age_Moyen,
    MIN(a.age) AS Age_Min,
    MAX(a.age) AS Age_Max,
    COUNT(*) AS Nombre_Medailles
FROM fact_medals fm
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
WHERE a.age IS NOT NULL
GROUP BY s.sport_name, sh.category_name
HAVING COUNT(*) >= 5
ORDER BY Age_Moyen DESC;

-- 5.5 Parité homme/femme dans les médailles
SELECT
    c.country_name AS Pays,
    COUNT(CASE WHEN a.gender = 'Male' THEN 1 END) AS Medailles_Hommes,
    COUNT(CASE WHEN a.gender = 'Female' THEN 1 END) AS Medailles_Femmes,
    COUNT(*) AS Total_Medailles,
    ROUND(
        COUNT(CASE WHEN a.gender = 'Female' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS Pourcentage_Femmes
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_athlete a ON fm.athlete_id = a.athlete_id
GROUP BY c.country_name
HAVING COUNT(*) >= 10
ORDER BY Total_Medailles DESC;

-- ============================================================================
-- 6. CORRÉLATION POLITIQUE NATIONALE ET HIÉRARCHIE DES SPORTS
-- ============================================================================

-- 6.1 Distribution des médailles par pays et catégorie de sports
SELECT
    c.country_name AS Pays,
    sh.category_name AS Categorie_Sport,
    COUNT(*) AS Nombre_Medailles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.country_name), 2
    ) AS Pourcentage_Par_Pays
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
GROUP BY c.country_name, sh.category_name
HAVING COUNT(*) >= 3
ORDER BY c.country_name, Nombre_Medailles DESC;

-- 6.2 Spécialisation des pays par catégorie
SELECT
    sh.category_name AS Categorie_Sport,
    c.country_name AS Pays_Dominant,
    COUNT(*) AS Nombre_Medailles,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sh.category_name), 2
    ) AS Part_De_Marche
FROM fact_medals fm
JOIN dim_country c ON fm.country_id = c.country_id
JOIN dim_sport s ON fm.sport_id = s.sport_id
JOIN dim_sport_hierarchy sh ON s.hierarchy_id = sh.hierarchy_id
GROUP BY sh.category_name, c.country_name
QUALIFY ROW_NUMBER() OVER (PARTITION BY sh.category_name ORDER BY COUNT(*) DESC) <= 5
ORDER BY sh.category_name, Nombre_Medailles DESC;

-- ============================================================================
-- FIN DES REQUÊTES
-- ============================================================================
