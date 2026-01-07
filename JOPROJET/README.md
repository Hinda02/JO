# 🏅 Projet Entrepôt de Données - Jeux Olympiques Paris 2024

## 📋 Description

Projet d'entrepôt de données (Data Warehouse) pour analyser les statistiques des Jeux Olympiques de Paris 2024. Ce projet utilise un **schéma en étoile** et intègre la **hiérarchie des sports** demandée dans le sujet.

**Technologies utilisées :**
- ETL : Talend Open Studio / Python
- Base de données : PostgreSQL (ou MySQL)
- Visualisation : Power BI / Tableau / Qlik

---

## 📁 Structure du Projet

```
JOPROJET/
├── sql/
│   └── db_jo_dwh.sql           # Script de création de la base de données
├── etl/
│   ├── config.py               # Configuration et mapping des sports
│   ├── etl_main.py             # Script ETL principal (Python)
│   └── etl.log                 # Logs d'exécution
├── queries/
│   └── visualisations_requetes.sql  # Requêtes pour les analyses
├── docs/
│   ├── REPONSES_QUESTIONS.md   # Réponses aux questions du sujet
│   ├── GUIDE_TALEND.md         # Guide d'implémentation Talend
│   └── DIAGRAMME_ETL.png       # Schéma de la chaîne de chargement
└── README.md                   # Ce fichier
```

---

## 🎯 Objectifs du Projet

### Réalisations Demandées

✅ **Modèle de données** : Schéma en étoile avec hiérarchie des sports
✅ **Hiérarchie des sports** : 8 catégories intégrées
✅ **4 Visualisations principales** :
   1. Pyramide des âges par sexe (tous / médaillés)
   2. Rapport médaillés/participants par pays
   3. Tableau des médailles (multiples axes)
   4. Évolution chronologique des médailles

✅ **Réponses aux questions** :
   - Qualité des données
   - Problèmes rencontrés
   - Modèle de base de données
   - Corrélation politique/sports

---

## 🚀 Installation et Configuration

### Prérequis

- **Base de données** : PostgreSQL 12+ ou MySQL 8+
- **Python** : 3.8+ (pour les scripts ETL)
- **Talend Open Studio** : pour Data Integration
- **Power BI Desktop** : pour les visualisations (ou alternative)

### Étape 1 : Créer la Base de Données

```bash
# PostgreSQL
createdb jo_paris_2024_dwh
psql -d jo_paris_2024_dwh -f JOPROJET/sql/db_jo_dwh.sql

# MySQL
mysql -u root -p -e "CREATE DATABASE jo_paris_2024_dwh;"
mysql -u root -p jo_paris_2024_dwh < JOPROJET/sql/db_jo_dwh.sql
```

### Étape 2 : Configuration de l'ETL

**Avec Python :**
```bash
cd JOPROJET/etl
pip install pandas psycopg2-binary

# Éditer config.py avec vos paramètres de connexion
nano config.py

# Exécuter l'ETL
python etl_main.py
```

**Avec Talend :**
Voir le guide détaillé dans `docs/GUIDE_TALEND.md`

### Étape 3 : Connexion à Power BI

1. Ouvrir Power BI Desktop
2. **Obtenir les données** → **PostgreSQL / MySQL**
3. Saisir les informations de connexion
4. Importer les tables et vues
5. Utiliser les requêtes dans `queries/visualisations_requetes.sql`

---

## 📊 Modèle de Données

### Type : Schéma en Étoile (Star Schema)

**8 Dimensions :**
- `dim_country` : Pays (225 pays)
- `dim_athlete` : Athlètes (11 000+)
- `dim_sport` : Sports olympiques (~50)
- `dim_sport_hierarchy` : Catégories de sports (8)
- `dim_event` : Épreuves (~330)
- `dim_date` : Dimension temporelle (juillet-août 2024)
- `dim_venue` : Lieux de compétition (36)
- `dim_medal_type` : Types de médailles (3)

**2 Tables de Faits :**
- `fact_medals` : Médailles remportées (~2300 lignes)
- `fact_participation` : Participations (~11 000 lignes)

### Hiérarchie des Sports (8 Catégories)

| Catégorie | Sports Inclus |
|-----------|---------------|
| **Power Sports** | Weightlifting, Boxing, Judo, Karate, Taekwondo, Wrestling |
| **Endurance Sports** | Cycling, Rowing, Triathlon |
| **Speed Sports** | Athletics, Swimming, Basketball, Handball, Hockey, Football, Rugby |
| **Skill Sports** | Gymnastics, Fencing, Golf, Shooting, Archery, Table Tennis, Badminton, Tennis, Baseball/Softball |
| **Water Sports** | Aquatics, Canoeing, Sailing, Surfing |
| **Board Sports** | Skateboarding, Surfing |
| **Combination Sports** | Modern Pentathlon |
| **Team Sports** | Basketball, Volleyball, Handball, Hockey, Football, Rugby, Baseball/Softball |

---

## 🔍 Visualisations et Analyses

### 1. Pyramide des Âges

**Fichier SQL** : `queries/visualisations_requetes.sql` (requêtes 1.1 et 1.2)

**Power BI** :
- Type : Graphique en barres horizontales
- Axe X : Nombre d'athlètes
- Axe Y : Tranches d'âge
- Légende : Sexe
- Filtre : Tous / Médaillés uniquement

### 2. Rapport Médaillés/Participants

**Fichier SQL** : Section 2

**Power BI** :
- Type : Nuage de points (Scatter plot)
- Axe X : Nombre d'athlètes
- Axe Y : Nombre de médaillés
- Étiquettes : Pays
- Ligne de tendance : Activée

### 3. Tableau des Médailles

**Fichier SQL** : Section 3 (4 variantes)

**Power BI** :
- Type : Tableau / Matrice
- Lignes : Pays
- Colonnes : Or, Argent, Bronze, Total
- Filtres (Slicers) :
  - Hiérarchie des sports
  - Sport
  - Sexe
  - Type de médaille

### 4. Évolution Chronologique

**Fichier SQL** : Section 4 (5 variantes)

**Power BI** :
- Type : Graphique en aires / Ligne
- Axe X : Date
- Axe Y : Nombre de médailles
- Légende : Pays / Catégorie sport / Type médaille
- Filtres : Tous les axes disponibles

---

## 📈 Analyses Supplémentaires (Bonus)

Le fichier `queries/visualisations_requetes.sql` contient également :

- Top 10 athlètes les plus médaillés
- Sports les plus médaillés
- Distribution par hiérarchie de sports
- Âge moyen des médaillés par sport
- Parité homme/femme dans les médailles
- Corrélation politique/sports

---

## 🧪 Qualité des Données

### Points Positifs
✓ Structure cohérente
✓ Format standardisé (ISO 8601)
✓ Relations bien définies
✓ Couverture complète

### Points à Améliorer
⚠️ Valeurs manquantes (height, weight ~60%)
⚠️ Colonnes biographiques peu renseignées
⚠️ Noms de sports multiples
⚠️ Format liste Python dans CSV

**Note globale : 7/10**

Voir détails dans `docs/REPONSES_QUESTIONS.md`

---

## 🔧 Problèmes Résolus

1. **Mapping hiérarchie des sports** → Table de correspondance
2. **Valeurs 0.0 vs NULL** → Conversion explicite
3. **Format listes Python** → ast.literal_eval()
4. **Médailles d'équipe** → Flag is_team_medal
5. **Performance** → Commits par batch, index, vues

---

## 📝 Rapport et Soutenance

### Contenu du Rapport

1. **Introduction** : Contexte et objectifs
2. **Modèle de données** : Schéma en étoile avec diagramme
3. **Chaîne de chargement** : Diagramme ETL
4. **Réponses aux questions** : (voir `docs/REPONSES_QUESTIONS.md`)
5. **Visualisations** : Screenshots Power BI
6. **Analyses supplémentaires** : Bonus
7. **Conclusion** : Axes d'amélioration

### Présentation (10 min)

1. **Contexte** (1 min) : JO Paris 2024, objectifs
2. **Architecture** (2 min) : Schéma en étoile, technologies
3. **Hiérarchie des sports** (2 min) : 8 catégories, mapping
4. **Résultats** (3 min) : Statistiques clés, insights
5. **Difficultés** (2 min) : Problèmes et solutions

### Démonstration (10 min)

1. **Base de données** : Tables, relations
2. **Power BI** : Les 4 visualisations
3. **Interactivité** : Filtres, drill-down
4. **Analyses bonus** : Corrélation politique/sports

---

## 🎓 Corrélation Politique/Sports

**Observation principale** :
Les pays développés diversifient leurs médailles sur toutes les catégories de sports, tandis que les pays émergents se spécialisent sur les sports à faible coût (Power/Endurance Sports).

**Facteurs identifiés** :
- PIB/capita → Diversification ✓✓✓
- Géographie → Water/Board Sports ✓✓✓
- Tradition → Power Sports (ex-URSS) ✓✓✓
- Budget sportif → Skill Sports ✓✓✓✓

Voir analyse complète dans `docs/REPONSES_QUESTIONS.md`

---

## 🛠️ Technologies et Outils

| Composant | Technologie | Alternative |
|-----------|-------------|-------------|
| **ETL** | Talend Open Studio | Python + pandas |
| **Base de données** | PostgreSQL 14 | MySQL 8, SQL Server |
| **Visualisation** | Power BI Desktop | Tableau, Qlik Sense |
| **Versionnement** | Git | - |

---

## 📚 Documentation

- `docs/REPONSES_QUESTIONS.md` : Réponses détaillées aux questions
- `docs/GUIDE_TALEND.md` : Guide d'implémentation Talend
- `sql/db_jo_dwh.sql` : Script SQL commenté
- `queries/visualisations_requetes.sql` : Requêtes SQL annotées

---

## 👥 Équipe et Contacts

**Projet** : Entrepôt de données - JO Paris 2024
**Formation** : A5IMIG-150_25/26
**Module** : Entrepôt de données
**Enseignants** : ELSA NEGRE, CHRISTOPHE MAILLARD

**Date de remise** : 07/01/2026, 14h00
**Soutenance** : 16/01/2026, 13h45, Salle D305

---

## 📄 Licence

Projet académique - Tous droits réservés

---

## 🚀 Quick Start

```bash
# 1. Créer la base
createdb jo_paris_2024_dwh
psql -d jo_paris_2024_dwh -f JOPROJET/sql/db_jo_dwh.sql

# 2. Charger les données
cd JOPROJET/etl
python etl_main.py

# 3. Vérifier
psql -d jo_paris_2024_dwh -c "SELECT * FROM view_medal_table LIMIT 10;"

# 4. Ouvrir Power BI et connecter à la base
```

---

**Bon courage pour la soutenance ! 🎉**
