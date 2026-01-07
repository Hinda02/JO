# 🏅 JOPROJECT - Entrepôt de Données JO Paris 2024
## Projet Talend Open Studio

---

## 📋 DESCRIPTION

Projet d'entrepôt de données (Data Warehouse) pour analyser les Jeux Olympiques de Paris 2024 avec **Talend Open Studio**.

**Technologie** : Talend Open Studio for Data Integration
**Base de données** : MySQL 8
**Modèle** : Schéma en Étoile (Star Schema)

---

## 📂 STRUCTURE DU PROJET

```
JOPROJECT/
├── process/                         # Jobs Talend
│   ├── JOB_Build_DIM_0.1.item      # Chargement des 9 dimensions
│   ├── JOB_Load_FACT_MEDAL_0.1.item        # Chargement médailles
│   ├── JOB_Load_FACT_PARTICIPATION_0.1.item  # Chargement participations
│   └── JOB_Load_FACT_SCHDULE_0.1.item      # Chargement calendriers
├── metadata/                        # Métadonnées Talend
│   └── fileDelimited/               # Définitions CSV
├── talend.project                   # Fichier projet Talend
├── ANALYSE_ET_CORRECTIONS.md        # Rapport d'analyse complet
├── GUIDE_CORRECTIONS_RAPIDES.md     # Guide de corrections (25 min)
├── REQUETES_POWERBI.sql             # 19 requêtes pour Power BI
└── README.md                        # Ce fichier
```

---

## 🎯 JOBS TALEND

### 1. JOB_Build_DIM

**Fonction** : Charger les 9 tables de dimensions

**Sources CSV** :
- athletes.csv → dim_athlete
- coaches.csv → dim_coach
- teams.csv → dim_team
- technical_officials.csv → dim_technical_official
- nocs.csv → dim_country
- events.csv → dim_event
- venues.csv → dim_venue
- sports (depuis events.csv) → dim_sport
- Générées → dim_date

**Temps d'exécution** : ~30-45 secondes

### 2. JOB_Load_FACT_MEDAL

**Fonction** : Charger la table fact_medal

**Source CSV** : medallists.csv

**Lookups** :
- dim_date (medal_date)
- dim_country (noc_code)
- dim_sport (sport_code)
- dim_event (event_tag)
- dim_athlete (athlete_code)

**Temps d'exécution** : ~15-20 secondes

### 3. JOB_Load_FACT_PARTICIPATION

**Fonction** : Agréger les participations par pays/sport

**Source** : Agrégation depuis dim_team

**Transformations** :
- GROUP BY noc_code, discipline_code
- SUM(athletes_count)
- COUNT(*) AS teams_count

**Temps d'exécution** : ~5-10 secondes

### 4. JOB_Load_FACT_SCHDULE

**Fonction** : Charger les horaires des épreuves

**Source CSV** : schedules.csv

**Transformations** :
- Parsing dates ISO8601
- Extraction de date_key
- Lookups multiples

**Temps d'exécution** : ~10-15 secondes

---

## 🚀 INSTALLATION ET UTILISATION

### Prérequis

- Talend Open Studio for Data Integration 8.0+
- MySQL 8.0+
- Fichiers CSV des JO Paris 2024

### Étape 1 : Créer la base de données

```bash
mysql -u root -p -e "CREATE DATABASE jo_dwh;"
mysql -u root -p jo_dwh < /home/user/JO/db_jo_dwh.sql
mysql -u root -p jo_dwh < /home/user/JO/db_jo_dwh_complement.sql
```

### Étape 2 : Ouvrir le projet dans Talend

1. Lancer Talend Open Studio
2. **Import** → **Import items**
3. Sélectionner le dossier `JOPROJECT`

### Étape 3 : Configurer la connexion MySQL

1. Repository → Metadata → Db Connections
2. Modifier la connexion existante :
   - Host : localhost
   - Port : 3306
   - Database : jo_dwh
   - User : root
   - Password : votre_mot_de_passe

### Étape 4 : Exécuter les jobs

**Ordre obligatoire** :
1. `JOB_Build_DIM` (dimensions d'abord)
2. `JOB_Load_FACT_MEDAL`
3. `JOB_Load_FACT_PARTICIPATION`
4. `JOB_Load_FACT_SCHDULE`

---

## ⚠️ PROBLÈMES CONNUS ET CORRECTIONS

### 🔴 CRITIQUE : Hiérarchie des sports non chargée

**Problème** : Table dim_sport_category vide
**Solution** : Exécuter `db_jo_dwh_complement.sql` OU charger `sport_category.csv`

**Voir** : `GUIDE_CORRECTIONS_RAPIDES.md`

### 🔴 CRITIQUE : Chemins codés en dur (Windows)

**Problème** : Chemins `C:/Users/Bonjour/...` non portables
**Solution** : Créer un contexte `JO_Context` et modifier les jobs

**Voir** : `GUIDE_CORRECTIONS_RAPIDES.md` (Section "Correction 3")

### 🟠 IMPORTANT : Pas de master job

**Problème** : Les 4 jobs doivent être lancés manuellement
**Solution** : Créer un Master Job avec tRunJob

---

## 📊 MODÈLE DE DONNÉES

### Schéma en Étoile

**9 Dimensions** :
- dim_date : Dimension temporelle
- dim_country : Pays (NOC)
- dim_sport : Sports olympiques
- dim_sport_category : **Hiérarchie des 8 catégories**
- dim_event : Épreuves sportives
- dim_venue : Lieux de compétition
- dim_athlete : Athlètes
- dim_team : Équipes
- dim_coach : Entraîneurs
- dim_technical_official : Officiels techniques

**4 Tables de Faits** :
- fact_medal : Médailles remportées
- fact_participation : Participations agrégées
- fact_schedule : Calendrier des épreuves
- fact_torch_route : Parcours de la flamme

### Hiérarchie des Sports (8 catégories)

| Catégorie | Description |
|-----------|-------------|
| **Power Sports** | Sports de force (6 sports) |
| **Endurance Sports** | Sports d'endurance (3 sports) |
| **Speed Sports** | Sports de vitesse (7 sports) |
| **Skill Sports** | Sports de précision (9 sports) |
| **Water Sports** | Sports aquatiques (4 sports) |
| **Board Sports** | Sports de glisse (1 sport) |
| **Combination Sports** | Sports combinés (1 sport) |
| **Team Sports** | Sports collectifs (1 sport) |

**Fichier** : `sport_category.csv` (32 lignes)

---

## 📈 VISUALISATIONS POWER BI

### Fichier de requêtes

**Emplacement** : `REQUETES_POWERBI.sql`
**Contenu** : 19 requêtes SQL prêtes à l'emploi

### 4 Visualisations Obligatoires

1. **Pyramide des âges** (Requêtes 1.1 et 1.2)
2. **Rapport médaillés/participants** (Requête 2)
3. **Tableau des médailles** (Requêtes 3.1 à 3.4)
4. **Évolution chronologique** (Requêtes 4.1 à 4.5)

### Analyses Supplémentaires (Bonus)

- Top 10 athlètes
- Sports les plus médaillés
- Distribution par catégorie
- Parité homme/femme
- Corrélation politique/sports

---

## 📚 DOCUMENTATION

### Fichiers de Documentation

| Document | Description |
|----------|-------------|
| `ANALYSE_ET_CORRECTIONS.md` | Analyse complète du projet, problèmes, solutions |
| `GUIDE_CORRECTIONS_RAPIDES.md` | Guide de corrections en 25 minutes |
| `REQUETES_POWERBI.sql` | Requêtes SQL pour les visualisations |

### Documentation Complémentaire (JOPROJET)

Sur la branche `claude/analyze-thesis-project-uPmWU` :
- `JOPROJET/docs/REPONSES_QUESTIONS.md` : Réponses aux 4 questions du sujet
- `JOPROJET/docs/GUIDE_TALEND.md` : Guide détaillé Talend
- `JOPROJET/docs/DIAGRAMME_CHAINE_CHARGEMENT.md` : Architecture ETL

---

## 🎯 CONFORMITÉ AU SUJET

### Exigences Respectées

| Exigence | État | Commentaire |
|----------|------|-------------|
| Modèle en étoile | ✅ OK | Schéma correct |
| Hiérarchie 8 sports | ⚠️ À COMPLÉTER | Table vide, script fourni |
| ETL Talend | ✅ OK | 4 jobs fonctionnels |
| 4 Visualisations | ✅ OK | Requêtes SQL fournies |
| Réponses questions | ✅ OK | Documents fournis (JOPROJET) |
| Diagramme ETL | ✅ OK | Screenshots + documentation |

### Actions Nécessaires (25 min)

1. ✅ Exécuter `db_jo_dwh_complement.sql`
2. ✅ Charger `sport_category.csv` dans dim_sport_category
3. ✅ Créer les 4 visualisations Power BI

**Voir** : `GUIDE_CORRECTIONS_RAPIDES.md`

---

## 🔧 MAINTENANCE

### Rejeu des Jobs

**ATTENTION** : Les jobs font des INSERT uniquement

Pour rejeu complet :
```sql
-- Purger les tables de faits
TRUNCATE TABLE fact_torch_route;
TRUNCATE TABLE fact_participation;
TRUNCATE TABLE fact_schedule;
TRUNCATE TABLE fact_medal;

-- Puis relancer les jobs
```

### Vérifications

```sql
-- Vérifier le nombre de lignes
SELECT 'dim_country', COUNT(*) FROM dim_country
UNION ALL SELECT 'dim_sport', COUNT(*) FROM dim_sport
UNION ALL SELECT 'dim_sport_category', COUNT(*) FROM dim_sport_category
UNION ALL SELECT 'dim_athlete', COUNT(*) FROM dim_athlete
UNION ALL SELECT 'fact_medal', COUNT(*) FROM fact_medal;

-- Vérifier la hiérarchie des sports
SELECT sport_category, COUNT(*)
FROM dim_sport_category
GROUP BY sport_category;
```

---

## 📞 SUPPORT

### En cas de problème

1. Consulter `ANALYSE_ET_CORRECTIONS.md`
2. Consulter `GUIDE_CORRECTIONS_RAPIDES.md`
3. Vérifier les logs Talend

### Ressources

- Talend Community : https://community.talend.com/
- Documentation MySQL : https://dev.mysql.com/doc/
- Power BI : https://docs.microsoft.com/power-bi/

---

## 👥 INFORMATIONS PROJET

**Projet** : Entrepôt de Données - JO Paris 2024
**Formation** : A5IMIG-150_25/26
**Module** : Entrepôt de données
**Enseignants** : ELSA NEGRE, CHRISTOPHE MAILLARD

**Date de remise** : 07/01/2026, 14h00
**Soutenance** : 16/01/2026, 13h45, Salle D305

---

## 📄 LICENCE

Projet académique - Tous droits réservés

---

**Dernière mise à jour** : 2026-01-07
**Version** : 1.0 - Corrigée et documentée
