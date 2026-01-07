# 🔧 Guide d'Implémentation Talend Open Studio
## Projet JO Paris 2024

---

## 📥 Installation de Talend Open Studio

### Téléchargement

1. Aller sur : https://www.talend.com/products/talend-open-studio/
2. Télécharger **Talend Open Studio for Data Integration**
3. Version recommandée : 8.0 ou supérieure
4. Installer et lancer l'application

### Création du Projet

1. Lancer Talend Open Studio
2. **Create a new project** → `JO_Paris_2024`
3. **Description** : Entrepôt de données JO Paris 2024

---

## 🔌 Configuration de la Connexion Base de Données

### Étape 1 : Créer une connexion DB

1. Dans **Repository** → **Metadata** → **Db Connections**
2. Clic droit → **Create connection**
3. **Name** : `JO_DWH_PostgreSQL`
4. **Purpose** : Data Warehouse JO Paris 2024
5. **DB Type** : PostgreSQL (ou MySQL selon votre choix)
6. **Login** : postgres
7. **Password** : votre_mot_de_passe
8. **Server** : localhost
9. **Port** : 5432
10. **Database** : jo_paris_2024_dwh
11. **Test connection** → Should be OK
12. **Finish**

### Étape 2 : Créer un contexte

1. **Repository** → **Contexts** → Clic droit → **Create context**
2. **Name** : `JO_Context`
3. Ajouter les variables :
   - `db_host` = localhost
   - `db_port` = 5432
   - `db_name` = jo_paris_2024_dwh
   - `db_user` = postgres
   - `db_password` = votre_mdp
   - `csv_path` = /home/user/JO

---

## 📦 Jobs Talend à Créer

### Architecture des Jobs

```
Master Job (orchestration)
├── Job_01_Load_Dim_Country
├── Job_02_Load_Dim_Sport_Hierarchy
├── Job_03_Load_Dim_Sport_And_Events
├── Job_04_Load_Dim_Athlete
├── Job_05_Load_Dim_Date
├── Job_06_Load_Dim_Venue
├── Job_07_Load_Fact_Medals
└── Job_08_Load_Fact_Participation
```

---

## 🛠️ Job 1 : Load_Dim_Country

### Objectif
Charger la dimension des pays depuis `nocs.csv`

### Composants Talend

```
tFileInputDelimited_1 (nocs.csv)
    ↓
tMap_1 (nettoyage, mapping)
    ↓
tDBOutput_1 (dim_country)
    ↓
tLogRow_1 (affichage logs)
```

### Configuration Détaillée

#### tFileInputDelimited_1
- **File name/Stream** : `context.csv_path + "/nocs.csv"`
- **Field separator** : `","`
- **Header** : 1
- **Schema** :
  ```
  code : String (3)
  country : String (100)
  country_long : String (150)
  tag : String (100)
  note : String (1000)
  ```

#### tMap_1
- **Input** : row1 (from tFileInputDelimited_1)
- **Output** : out_country
- **Mapping** :
  ```
  country_code = row1.code
  country_name = row1.country
  country_long = row1.country_long
  country_tag = row1.tag
  notes = row1.note
  ```
- **Filter** : `!Relational.ISNULL(row1.code)`

#### tDBOutput_1
- **Use existing connection** : JO_DWH_PostgreSQL
- **Table** : `dim_country`
- **Action on table** : None
- **Action on data** : Insert or update
- **Schema** :
  ```
  country_code : String (3)
  country_name : String (100)
  country_long : String (150)
  country_tag : String (100)
  notes : String
  ```
- **Update Key** : country_code

---

## 🛠️ Job 2 : Load_Dim_Sport_Hierarchy

### Objectif
Charger la hiérarchie des sports (données en dur)

### Composants Talend

```
tFixedFlowInput_1 (données hiérarchie)
    ↓
tDBOutput_1 (dim_sport_hierarchy)
```

### Configuration

#### tFixedFlowInput_1
- **Mode** : Use Inline Content (delimited)
- **Number of rows** : 8
- **Schema** :
  ```
  category_name : String
  category_code : String
  description : String
  ```
- **Values** :
  ```
  "Power Sports","POWER","Sports de force et combat"
  "Endurance Sports","ENDURANCE","Sports d'endurance"
  "Speed Sports","SPEED","Sports de vitesse"
  "Skill Sports","SKILL","Sports de précision"
  "Water Sports","WATER","Sports aquatiques"
  "Board Sports","BOARD","Sports de glisse"
  "Combination Sports","COMBO","Sports combinés"
  "Team Sports","TEAM","Sports collectifs"
  ```

#### tDBOutput_1
- **Table** : `dim_sport_hierarchy`
- **Action** : Insert

---

## 🛠️ Job 3 : Load_Dim_Sport_And_Events

### Objectif
Charger sports et événements avec mapping de la hiérarchie

### Composants Talend

```
tFileInputDelimited_1 (events.csv)
    ↓
tMap_1 (mapping hiérarchie + nettoyage)
    ↓ ← tDBInput_1 (lookup hierarchy)
tDBOutput_1 (dim_sport) ─┐
    ↓                      │
tMap_2 (événements)       │
    ↓ ← tDBInput_2 (lookup sports)
tDBOutput_2 (dim_event)
```

### Configuration

#### tMap_1 : Mapping de la Hiérarchie

**Lookup** : hierarchy (from tDBInput_1)
```sql
SELECT hierarchy_id, category_name FROM dim_sport_hierarchy
```

**Expression Routines** :
Créer une routine Java `SportHierarchyMapper` :

```java
public static String getSportCategory(String sportName) {
    // Power Sports
    if (sportName.contains("Weight") || sportName.equals("Boxing") ||
        sportName.equals("Judo") || sportName.equals("Wrestling") ||
        sportName.equals("Taekwondo")) {
        return "Power Sports";
    }
    // Endurance Sports
    if (sportName.contains("Cycling") || sportName.equals("Rowing") ||
        sportName.equals("Triathlon")) {
        return "Endurance Sports";
    }
    // Speed Sports
    if (sportName.equals("Athletics") || sportName.equals("Swimming") ||
        sportName.equals("Basketball") || sportName.equals("Handball") ||
        sportName.equals("Hockey") || sportName.equals("Football") ||
        sportName.equals("Rugby")) {
        return "Speed Sports";
    }
    // Skill Sports
    if (sportName.contains("Gymnastics") || sportName.equals("Fencing") ||
        sportName.equals("Golf") || sportName.equals("Shooting") ||
        sportName.equals("Archery") || sportName.contains("Tennis") ||
        sportName.equals("Badminton") || sportName.contains("Baseball")) {
        return "Skill Sports";
    }
    // Water Sports
    if (sportName.contains("Aquatics") || sportName.equals("Canoeing") ||
        sportName.equals("Sailing") || sportName.equals("Surfing")) {
        return "Water Sports";
    }
    // Board Sports
    if (sportName.equals("Skateboarding") || sportName.equals("Surfing")) {
        return "Board Sports";
    }
    // Combination Sports
    if (sportName.contains("Pentathlon")) {
        return "Combination Sports";
    }
    // Team Sports
    if (sportName.equals("Basketball") || sportName.equals("Volleyball") ||
        sportName.equals("Handball") || sportName.equals("Hockey") ||
        sportName.equals("Football") || sportName.equals("Rugby") ||
        sportName.contains("Baseball")) {
        return "Team Sports";
    }
    return "Other Sports";
}
```

**tMap Expression** :
```
category = SportHierarchyMapper.getSportCategory(row1.sport)
hierarchy_id = lookup(category).hierarchy_id
```

---

## 🛠️ Job 4 : Load_Dim_Athlete

### Objectif
Charger les athlètes avec calcul de l'âge

### Composants Talend

```
tFileInputDelimited_1 (athletes.csv)
    ↓
tMap_1 (calcul âge, nettoyage)
    ↓ ← tDBInput_1 (lookup countries)
tDBOutput_1 (dim_athlete)
    ↓
tLogRow_1
```

### Configuration tMap_1

**Expression pour calculer l'âge** :
```java
// Si birth_date non null
TalendDate.getYear(TalendDate.getCurrentDate()) -
TalendDate.getYear(TalendDate.parseDate("yyyy-MM-dd", row1.birth_date))
```

**Transformation height/weight** :
```java
// Remplacer 0.0 par null
row1.height == 0.0 ? null : row1.height
row1.weight == 0.0 ? null : row1.weight
```

**Action sur données** : Insert or Update on duplicate

---

## 🛠️ Job 5 : Load_Dim_Date

### Objectif
Générer la dimension temporelle

### Composants Talend

```
tRowGenerator_1 (générer dates)
    ↓
tMap_1 (calcul attributs date)
    ↓
tDBOutput_1 (dim_date)
```

### Configuration tRowGenerator_1

- **Number of rows** : 62 (1er juillet au 31 août 2024)
- **Schema** :
  ```
  date_seq : Integer
  ```

### Configuration tMap_1

**Expressions** :
```java
// Date de base : 2024-07-01
Date baseDate = TalendDate.parseDate("yyyy-MM-dd", "2024-07-01");

// Ajouter les jours
full_date = TalendDate.addDate(baseDate, row1.date_seq, "dd")

// Attributs
day = TalendDate.getDay(full_date)
month = TalendDate.getMonth(full_date)
year = TalendDate.getYear(full_date)
day_of_week = TalendDate.getDayOfWeek(full_date)
day_name = new java.text.SimpleDateFormat("EEEE").format(full_date)
week_number = TalendDate.getWeekOfYear(full_date)
quarter = (month - 1) / 3 + 1
is_weekend = (day_of_week == 1 || day_of_week == 7)
```

---

## 🛠️ Job 7 : Load_Fact_Medals

### Objectif
Charger les médailles avec toutes les FK

### Composants Talend

```
tFileInputDelimited_1 (medallists.csv)
    ↓
tMap_1 (lookups multiples)
    ↓ ← tDBInput_1 (athletes)
    ↓ ← tDBInput_2 (countries)
    ↓ ← tDBInput_3 (events)
    ↓ ← tDBInput_4 (dates)
    ↓ ← tDBInput_5 (medal_types)
tDBOutput_1 (fact_medals)
    ↓
tLogRow_1
```

### Configuration tMap_1

**Lookups à configurer** :
```
athlete : code_athlete → athlete_id
country : country_code → country_id
event : event_name → event_id, sport_id
date : medal_date → date_id
medal_type : medal_type → medal_type_id
```

**Expressions** :
```java
athlete_id = athlete.athlete_id
country_id = country.country_id
sport_id = event.sport_id
event_id = event.event_id
date_id = date.date_id
medal_type_id = medal_type.medal_type_id
medal_date = row1.medal_date
is_team_medal = !Relational.ISNULL(row1.team_gender)
team_code = row1.code_team
```

**Gestion des erreurs** :
- **Reject** : Lorsqu'un lookup échoue
- Connecter à un tLogRow pour voir les erreurs

---

## 🛠️ Master Job : Orchestration Complète

### Objectif
Exécuter tous les jobs dans le bon ordre

### Composants

```
tPrejob ──> tDBConnection_1 (connexion DB)
   ↓
tRunJob_1 (Job_01_Load_Dim_Country)
   ↓ OnComponentOk
tRunJob_2 (Job_02_Load_Dim_Sport_Hierarchy)
   ↓ OnComponentOk
tRunJob_3 (Job_03_Load_Dim_Sport_And_Events)
   ↓ OnComponentOk
tRunJob_4 (Job_04_Load_Dim_Athlete)
   ↓ OnComponentOk
tRunJob_5 (Job_05_Load_Dim_Date)
   ↓ OnComponentOk
tRunJob_6 (Job_06_Load_Dim_Venue)
   ↓ OnComponentOk
tRunJob_7 (Job_07_Load_Fact_Medals)
   ↓ OnComponentOk
tRunJob_8 (Job_08_Load_Fact_Participation)
   ↓ OnComponentOk
tPostjob ──> tDBClose_1 (fermeture connexion)
```

### Configuration

- **Propagate context** : Cocher pour tous les tRunJob
- **Use independent process** : Décocher
- **Die on error** : Cocher

---

## 📊 Composants Talend Utiles

### Composants Essentiels

| Composant | Usage |
|-----------|-------|
| **tFileInputDelimited** | Lecture CSV |
| **tDBInput** | Requêtes SELECT (lookups) |
| **tDBOutput** | Insertion/Update en base |
| **tMap** | Transformations et jointures |
| **tLogRow** | Debug et logs |
| **tRowGenerator** | Générer des données |
| **tFixedFlowInput** | Données en dur |
| **tRunJob** | Exécuter un autre job |
| **tDBConnection** | Connexion DB |
| **tDBClose** | Fermeture connexion |

### Composants pour Gestion Erreurs

| Composant | Usage |
|-----------|-------|
| **tDie** | Arrêter le job sur erreur |
| **tWarn** | Logger un warning |
| **tLogCatcher** | Capturer les logs |
| **Reject** | Gérer les rejets dans tMap |

---

## 🎨 Bonnes Pratiques Talend

### Design

✓ **Nommer clairement** les jobs et composants
✓ **Organiser** les jobs par catégorie (dimensions, faits)
✓ **Commenter** les tMap complexes
✓ **Utiliser des contexts** pour la configuration
✓ **Créer des routines** pour la logique métier

### Performance

✓ **Commits par batch** : tDBOutput → Advanced → Commit every X rows (1000)
✓ **Désactiver logs** en production : tStatCatcher OFF
✓ **Utiliser tMap** plutôt que tJoin quand possible
✓ **Index** : Créer des index sur les colonnes de lookup

### Qualité

✓ **Gestion des erreurs** : Toujours gérer les rejets
✓ **Logs** : tLogRow pour debug, tLogCatcher pour prod
✓ **Tests** : Tester chaque job individuellement avant le master
✓ **Documentation** : Ajouter des notes dans les jobs

---

## 🐛 Dépannage

### Problème : "Table or view does not exist"
**Solution** : Vérifier que le script SQL a été exécuté

### Problème : "Column not found"
**Solution** : Vérifier le schéma dans tDBOutput

### Problème : "Null pointer exception"
**Solution** : Gérer les nulls dans tMap avec `Relational.ISNULL()`

### Problème : Performances lentes
**Solution** :
- Augmenter la mémoire JVM (Run → Edit VM Arguments)
- Commits par batch
- Désactiver tStatCatcher

### Problème : Encodage caractères spéciaux
**Solution** : tFileInputDelimited → Encoding : UTF-8

---

## 📈 Statistiques de Chargement Attendues

| Table | Nombre de lignes approximatif |
|-------|-------------------------------|
| dim_country | 225 |
| dim_sport_hierarchy | 8 |
| dim_sport | ~50 |
| dim_event | ~330 |
| dim_athlete | ~11 000 |
| dim_date | 62 |
| dim_venue | 36 |
| dim_medal_type | 3 |
| fact_medals | ~2 300 |
| fact_participation | ~11 000 |

---

## 🎯 Checklist Validation Talend

- [ ] Tous les jobs s'exécutent sans erreur
- [ ] Les statistiques de lignes correspondent
- [ ] Les lookups fonctionnent (pas de null FK)
- [ ] La hiérarchie des sports est correctement mappée
- [ ] Les vues SQL retournent des résultats cohérents
- [ ] Les logs sont propres (pas d'erreur/warning)
- [ ] Le master job orchestre correctement
- [ ] Documentation et commentaires ajoutés

---

## 📚 Ressources

- **Documentation Talend** : https://help.talend.com/
- **Forums** : https://community.talend.com/
- **Tutoriels** : Talend Academy

---

**Bon développement ! 🚀**
