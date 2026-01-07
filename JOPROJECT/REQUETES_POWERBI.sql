/* =========================================================
   REQUÊTES SQL POUR POWER BI - JO PARIS 2024
   4 Visualisations obligatoires + analyses bonus
   ========================================================= */

-- =====================================================
-- 1. PYRAMIDE DES ÂGES DES ATHLÈTES PAR SEXE
-- =====================================================

-- 1.1 Tous les participants
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
    -- Valeur négative pour les femmes (pour pyramide)
    CASE WHEN a.gender = 'Female' THEN -COUNT(*) ELSE COUNT(*) END AS Nombre_Pour_Pyramide
FROM dim_athlete a
WHERE a.birth_date IS NOT NULL
GROUP BY a.gender, Tranche_Age
ORDER BY a.gender, Tranche_Age;

-- 1.2 Uniquement les médaillés
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
    COUNT(DISTINCT a.athlete_sk) AS Nombre_Medallistes,
    -- Valeur négative pour les femmes
    CASE WHEN a.gender = 'Female' THEN -COUNT(DISTINCT a.athlete_sk) ELSE COUNT(DISTINCT a.athlete_sk) END AS Nombre_Pour_Pyramide
FROM dim_athlete a
INNER JOIN fact_medal fm ON a.athlete_sk = fm.athlete_sk
WHERE a.birth_date IS NOT NULL
GROUP BY a.gender, Tranche_Age
ORDER BY a.gender, Tranche_Age;


-- =====================================================
-- 2. RAPPORT MÉDAILLÉS / PARTICIPANTS PAR PAYS
-- =====================================================

SELECT
    c.country AS Pays,
    c.noc_code AS Code_Pays,
    COUNT(DISTINCT a.athlete_sk) AS Nombre_Athletes,
    COUNT(DISTINCT fm.athlete_sk) AS Nombre_Medallistes,
    CASE
        WHEN COUNT(DISTINCT a.athlete_sk) > 0
        THEN ROUND(COUNT(DISTINCT fm.athlete_sk) * 100.0 / COUNT(DISTINCT a.athlete_sk), 2)
        ELSE 0
    END AS Pourcentage_Efficacite,
    -- Ratio pour le graphique
    CASE
        WHEN COUNT(DISTINCT a.athlete_sk) > 0
        THEN COUNT(DISTINCT fm.athlete_sk) / COUNT(DISTINCT a.athlete_sk)
        ELSE 0
    END AS Ratio_Medailles
FROM dim_country c
LEFT JOIN dim_athlete a ON c.noc_code = a.noc_code
LEFT JOIN fact_medal fm ON a.athlete_sk = fm.athlete_sk
GROUP BY c.country, c.noc_code
HAVING Nombre_Athletes > 0
ORDER BY Nombre_Medallistes DESC, Nombre_Athletes DESC;


-- =====================================================
-- 3. TABLEAU DES MÉDAILLES
-- =====================================================

-- 3.1 Tableau classique par pays
SELECT
    c.country AS Pays,
    c.noc_code AS Code,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Medailles_Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Medailles_Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Medailles_Bronze,
    COUNT(*) AS Total_Medailles
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY c.country, c.noc_code
ORDER BY Medailles_Or DESC, Medailles_Argent DESC, Medailles_Bronze DESC;

-- 3.2 Médailles par pays et hiérarchie de sports
SELECT
    c.country AS Pays,
    sc.sport_category AS Categorie_Sport,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze,
    COUNT(*) AS Total
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY c.country, sc.sport_category
ORDER BY c.country, Total DESC;

-- 3.3 Médailles par pays, sport et sexe
SELECT
    c.country AS Pays,
    s.sport AS Sport,
    a.gender AS Sexe,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze,
    COUNT(*) AS Total
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
GROUP BY c.country, s.sport, a.gender
ORDER BY c.country, Total DESC;

-- 3.4 Médailles par type et sexe (global)
SELECT
    fm.medal_type AS Type_Medaille,
    a.gender AS Sexe,
    COUNT(*) AS Nombre
FROM fact_medal fm
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
GROUP BY fm.medal_type, a.gender
ORDER BY
    CASE fm.medal_type
        WHEN 'Gold' THEN 1
        WHEN 'Silver' THEN 2
        WHEN 'Bronze' THEN 3
    END,
    a.gender;


-- =====================================================
-- 4. ÉVOLUTION CHRONOLOGIQUE DES MÉDAILLES
-- =====================================================

-- 4.1 Évolution quotidienne globale
SELECT
    d.full_date AS Date,
    d.day_name AS Jour,
    COUNT(*) AS Nombre_Medailles,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Medailles_Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Medailles_Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Medailles_Bronze
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
GROUP BY d.full_date, d.day_name
ORDER BY d.full_date;

-- 4.2 Évolution par pays (avec cumul)
SELECT
    d.full_date AS Date,
    c.country AS Pays,
    COUNT(*) AS Nombre_Medailles,
    SUM(COUNT(*)) OVER (PARTITION BY c.country ORDER BY d.full_date) AS Medailles_Cumulees
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY d.full_date, c.country
ORDER BY d.full_date, Nombre_Medailles DESC;

-- 4.3 Évolution par hiérarchie de sports
SELECT
    d.full_date AS Date,
    sc.sport_category AS Categorie_Sport,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY d.full_date, sc.sport_category
ORDER BY d.full_date, Nombre_Medailles DESC;

-- 4.4 Évolution par sexe
SELECT
    d.full_date AS Date,
    a.gender AS Sexe,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
GROUP BY d.full_date, a.gender
ORDER BY d.full_date, a.gender;

-- 4.5 Évolution complète (tous les axes)
SELECT
    d.full_date AS Date,
    d.day_name AS Jour,
    c.country AS Pays,
    sc.sport_category AS Categorie_Sport,
    s.sport AS Sport,
    a.gender AS Sexe,
    fm.medal_type AS Type_Medaille,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_date d ON fm.date_sk = d.date_sk
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
GROUP BY d.full_date, d.day_name, c.country, sc.sport_category, s.sport, a.gender, fm.medal_type
ORDER BY d.full_date, Nombre_Medailles DESC;


-- =====================================================
-- 5. ANALYSES SUPPLÉMENTAIRES (BONUS)
-- =====================================================

-- 5.1 Top 10 athlètes les plus médaillés
SELECT
    a.name AS Athlete,
    a.gender AS Sexe,
    c.country AS Pays,
    COUNT(*) AS Nombre_Medailles,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze
FROM fact_medal fm
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
JOIN dim_country c ON fm.country_sk = c.country_sk
GROUP BY a.name, a.gender, c.country
ORDER BY Nombre_Medailles DESC, Or DESC
LIMIT 10;

-- 5.2 Sports les plus médaillés
SELECT
    s.sport AS Sport,
    sc.sport_category AS Categorie,
    COUNT(*) AS Nombre_Medailles
FROM fact_medal fm
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY s.sport, sc.sport_category
ORDER BY Nombre_Medailles DESC;

-- 5.3 Distribution des médailles par hiérarchie de sports
SELECT
    sc.sport_category AS Categorie_Sport,
    COUNT(*) AS Total_Medailles,
    COUNT(CASE WHEN fm.medal_type = 'Gold' THEN 1 END) AS Or,
    COUNT(CASE WHEN fm.medal_type = 'Silver' THEN 1 END) AS Argent,
    COUNT(CASE WHEN fm.medal_type = 'Bronze' THEN 1 END) AS Bronze,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_medal), 2) AS Pourcentage_Total
FROM fact_medal fm
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY sc.sport_category
ORDER BY Total_Medailles DESC;

-- 5.4 Parité homme/femme dans les médailles
SELECT
    c.country AS Pays,
    COUNT(CASE WHEN a.gender = 'Male' THEN 1 END) AS Medailles_Hommes,
    COUNT(CASE WHEN a.gender = 'Female' THEN 1 END) AS Medailles_Femmes,
    COUNT(*) AS Total_Medailles,
    ROUND(COUNT(CASE WHEN a.gender = 'Female' THEN 1 END) * 100.0 / COUNT(*), 2) AS Pourcentage_Femmes
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_athlete a ON fm.athlete_sk = a.athlete_sk
GROUP BY c.country
HAVING Total_Medailles >= 10
ORDER BY Total_Medailles DESC;


-- =====================================================
-- 6. CORRÉLATION POLITIQUE NATIONALE / HIÉRARCHIE SPORTS
-- =====================================================

-- 6.1 Distribution des médailles par pays et catégorie
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

-- 6.2 Pays dominants par catégorie de sport
SELECT
    sc.sport_category AS Categorie_Sport,
    c.country AS Pays_Dominant,
    COUNT(*) AS Nombre_Medailles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sc.sport_category), 2) AS Part_De_Marche
FROM fact_medal fm
JOIN dim_country c ON fm.country_sk = c.country_sk
JOIN dim_sport s ON fm.sport_sk = s.sport_sk
JOIN dim_sport_category sc ON s.sport_code = sc.sport_code
GROUP BY sc.sport_category, c.country
ORDER BY sc.sport_category, Nombre_Medailles DESC;


-- =====================================================
-- FIN DES REQUÊTES
-- =====================================================

-- NOTES D'UTILISATION POWER BI :
-- 1. Importer ces requêtes via "Obtenir les données" → MySQL
-- 2. Pour la pyramide des âges : Utiliser un graphique en barres horizontales
-- 3. Pour le rapport médaillés/participants : Utiliser un nuage de points (scatter)
-- 4. Pour le tableau des médailles : Utiliser une matrice avec slicers
-- 5. Pour l'évolution chronologique : Utiliser un graphique en aires ou lignes
