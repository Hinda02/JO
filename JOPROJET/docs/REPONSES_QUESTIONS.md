# Réponses aux Questions du Sujet
## Projet Entrepôt de Données - JO Paris 2024

---

## 1. Que pensez-vous de la qualité des données ?

### Points Positifs ✓

**Structure et Format**
- Fichiers CSV bien structurés et cohérents
- Encodage correct (UTF-8)
- Format de dates standardisé (ISO 8601)
- Identifiants uniques présents (codes athletes, pays, événements)
- Relations entre fichiers bien définies via les codes

**Complétude**
- Couverture complète des athlètes participants
- Données détaillées sur les médailles et médaillés
- Informations riches sur les événements et les horaires
- Données géographiques (pays, lieux de compétition)

### Points Problématiques ✗

**Valeurs Manquantes**
```
- height = 0.0 : ~60% des athlètes
- weight = 0.0 : ~55% des athlètes
- Colonnes biographiques peu renseignées :
  * hobbies : ~85% vides
  * education : ~75% vides
  * philosophy : ~90% vides
  * sporting_relatives : ~95% vides
```

**Incohérences**
- Certains sports apparaissent sous plusieurs noms (ex: Artistic Swimming vs Aquatics)
- Disciplines multiples stockées en format texte liste Python : `['Wrestling']`
- Données redondantes entre `medals.csv` et `medallists.csv`
- Format JSON/liste dans certaines colonnes texte

**Problèmes de Qualité**
- Doublons potentiels dans les médailles d'équipe
- Absence de clé primaire explicite dans certains fichiers
- Certains athlètes sans date de naissance
- Codes pays non uniformes (NOC vs ISO)

### Évaluation Globale

**Note de qualité : 7/10**

Les données sont **exploitables** pour l'analyse mais nécessitent un **nettoyage approfondi** lors de l'ETL.

---

## 2. Quels problèmes avez-vous rencontrés ?

### Problèmes Techniques

#### A. Mapping de la Hiérarchie des Sports
**Défi** : Associer chaque sport/discipline à sa catégorie hiérarchique
- Sports avec plusieurs noms (Cycling Road, Track Cycling → Cycling)
- Sports appartenant à plusieurs catégories (Surfing : Water Sports ET Board Sports)
- Disciplines détaillées vs sports génériques

**Solution Adoptée** :
```python
SPORT_NAME_MAPPING = {
    'Artistic Swimming': 'Aquatics',
    'Diving': 'Aquatics',
    'BMX Freestyle': 'Cycling',
    'Track Cycling': 'Cycling',
    ...
}
```

#### B. Gestion des Valeurs Nulles
**Problème** : height=0.0, weight=0.0 ne sont pas des NULL SQL
**Solution** : Conversion explicite dans l'ETL
```python
df['height'] = df['height'].replace(0.0, None)
df['weight'] = df['weight'].replace(0.0, None)
```

#### C. Format des Listes dans les CSV
**Problème** : Colonnes contenant `['Wrestling']` ou `['Sport1', 'Sport2']`
**Solution** : Utilisation de `ast.literal_eval()` pour parser
```python
import ast
disciplines_list = ast.literal_eval(row['disciplines'])
```

#### D. Médailles d'Équipe vs Individuelles
**Problème** : Risque de compter plusieurs fois la même médaille
**Solution** : Ajout d'un flag `is_team_medal` et `team_code` dans fact_medals

#### E. Clés Étrangères et Intégrité Référentielle
**Problème** : Certains codes athlètes/pays introuvables
**Solution** :
- Chargement des dimensions AVANT les faits
- Gestion des codes manquants (logs d'erreur)
- ON CONFLICT DO NOTHING pour éviter les duplicatas

### Problèmes Conceptuels

#### F. Choix du Modèle de Données
**Dilemme** : Modèle en étoile vs flocon
**Décision** : Schéma en étoile (Star Schema)
- Plus simple pour les analyses
- Meilleures performances pour les requêtes BI
- Dénormalisation acceptable pour un datamart

#### G. Granularité des Faits
**Question** : Une médaille d'équipe = 1 ligne ou N lignes (1 par athlète) ?
**Choix** : 1 ligne par athlète médaillé
- Permet les analyses individuelles
- Facilite le calcul du nombre de médaillés
- Flag `is_team_medal` pour distinguer

### Problèmes de Performance

#### H. Volume de Données
- 11 000+ athlètes → insertion lente
- **Solution** : Commits par batch (1000 lignes)

#### I. Requêtes Complexes
- Jointures multiples pour les analyses
- **Solution** : Création de vues matérialisées et index

---

## 3. Fournissez le modèle de votre base de données

### Type de Modèle : **Schéma en Étoile (Star Schema)**

### Justification du Choix

**Pourquoi pas Merise ?**
- Merise est orienté OLTP (transactions)
- Notre projet est OLAP (analyse)
- Besoin d'optimisation pour les requêtes BI

**Pourquoi pas Flocon (Snowflake) ?**
- Trop de jointures → performances dégradées
- Complexité inutile pour notre cas
- Schéma en étoile suffit

**Avantages du Schéma en Étoile**
- ✓ Requêtes rapides (moins de jointures)
- ✓ Facile à comprendre
- ✓ Optimal pour Power BI / Tableau
- ✓ Dimensions dénormalisées
- ✓ Tables de faits centrales

### Architecture du Modèle

```
                    ┌──────────────────┐
                    │  dim_date        │
                    │  ───────────     │
                    │  date_id (PK)    │
                    │  full_date       │
                    │  day, month, year│
                    └──────────────────┘
                             │
                             │
    ┌──────────────┐         │         ┌──────────────┐
    │ dim_country  │         │         │  dim_athlete │
    │ ──────────── │         │         │  ──────────  │
    │ country_id   │         │         │  athlete_id  │
    │ country_code │         │         │  name, gender│
    │ country_name │         │         │  birth_date  │
    └──────────────┘         │         │  country_id  │
           │                 │         └──────────────┘
           │                 │                │
           │                 │                │
           └─────────┐       │       ┌────────┘
                     │       │       │
                ┌────▼───────▼───────▼────┐
                │    FACT_MEDALS          │
                │    ──────────────        │
                │    medal_fact_id (PK)   │
                │    athlete_id (FK)      │
                │    country_id (FK)      │
                │    sport_id (FK)        │
                │    event_id (FK)        │
                │    date_id (FK)         │
                │    medal_type_id (FK)   │
                │    medal_date           │
                └─────────────────────────┘
                     │       │       │
           ┌─────────┘       │       └────────┐
           │                 │                │
           │                 │                │
    ┌──────▼──────┐   ┌──────▼──────┐  ┌─────▼──────────┐
    │  dim_sport  │   │  dim_event  │  │ dim_medal_type │
    │  ────────── │   │  ──────────  │  │  ────────────  │
    │  sport_id   │   │  event_id   │  │  medal_type_id │
    │  sport_name │   │  event_name │  │  medal_type    │
    │ hierarchy_id│   │  sport_id   │  │  medal_code    │
    └─────────────┘   │  gender     │  └────────────────┘
           │          └─────────────┘
           │
    ┌──────▼────────────┐
    │ dim_sport_        │
    │ hierarchy         │
    │ ──────────────    │
    │ hierarchy_id (PK) │
    │ category_name     │
    └───────────────────┘
```

### Tables Principales

#### DIMENSIONS (8 tables)
1. **dim_country** : Pays participants
2. **dim_athlete** : Athlètes
3. **dim_sport** : Sports olympiques
4. **dim_sport_hierarchy** : Catégories de sports (Power, Endurance, etc.)
5. **dim_event** : Épreuves sportives
6. **dim_date** : Dimension temporelle
7. **dim_venue** : Lieux de compétition
8. **dim_medal_type** : Types de médailles (Or, Argent, Bronze)

#### FAITS (2 tables)
1. **fact_medals** : Médailles remportées
2. **fact_participation** : Participations des athlètes

### Cardinalités

```
dim_country (1) ──→ (N) dim_athlete
dim_country (1) ──→ (N) fact_medals
dim_athlete (1) ──→ (N) fact_medals
dim_sport (1) ──→ (N) fact_medals
dim_sport (1) ──→ (N) dim_event
dim_sport_hierarchy (1) ──→ (N) dim_sport
dim_date (1) ──→ (N) fact_medals
dim_medal_type (1) ──→ (N) fact_medals
```

### Optimisations Implémentées

**Index Créés**
- Index sur toutes les clés étrangères
- Index sur les colonnes de filtrage fréquent (country_code, sport_name, medal_date)
- Index composites pour les requêtes complexes

**Vues Analytiques**
- `view_medal_table` : Tableau des médailles
- `view_medals_by_sport_hierarchy` : Médailles par catégorie
- `view_country_efficiency` : Ratio médaillés/participants
- `view_age_distribution` : Distribution des âges
- `view_medals_timeline` : Évolution chronologique

---

## 4. Trouvez-vous une corrélation entre une politique nationale et la hiérarchie des sports ?

### Méthodologie d'Analyse

Pour répondre à cette question, nous avons analysé :
1. La distribution des médailles par pays et catégorie de sports
2. La spécialisation des pays dans certaines catégories
3. Les facteurs géographiques, économiques et culturels

### Observations Principales

#### A. Pays Développés : Diversification

**Caractéristiques** : USA, France, Allemagne, Royaume-Uni, Japon
- ✓ Médailles réparties sur TOUTES les catégories
- ✓ Forte présence dans Skill Sports (infrastructures coûteuses)
- ✓ Investissement important dans la formation
- ✓ Centres d'excellence multi-sports

**Politique Sportive** :
- Budget élevé
- Programmes de détection des talents
- Installations de classe mondiale

#### B. Pays Émergents : Spécialisation Power/Endurance

**Caractéristiques** : Kenya, Éthiopie, Jamaïque, Cuba
- ✓ Concentration sur 1-2 catégories (Power ou Endurance)
- ✓ Peu de médailles en Skill Sports
- ✓ Sports à faible coût d'infrastructure

**Exemples** :
- **Kenya/Éthiopie** → Endurance Sports (course à pied)
- **Cuba** → Power Sports (boxe, lutte)
- **Jamaïque** → Speed Sports (sprint)

**Politique Sportive** :
- Spécialisation par tradition culturelle
- Optimisation des ressources limitées
- Focus sur les sports "accessibles"

#### C. Influence Géographique

**Pays Côtiers → Water Sports**
- Australie, Nouvelle-Zélande : voile, surf, natation
- Scandinavie : canoë, voile

**Pays Montagneux → Sports spécifiques**
- Suisse, Autriche : (sports d'hiver hors JO été)
- Népal : endurance (altitude)

**Climat et Culture**
- Pays chauds → Endurance difficile
- Pays tropicaux → Sports indoor climatisés

#### D. Héritage Historique et Politique

**Ex-URSS et Bloc de l'Est**
- Forte tradition en Power Sports (lutte, haltérophilie)
- Système de formation étatique hérité
- Russie, Ukraine, Kazakhstan

**Pays Asiatiques**
- Forte présence en Skill Sports (précision)
- Japon : judo, karaté (sports nationaux)
- Chine : diversification récente (investissements massifs)

### Corrélations Identifiées

| Facteur | Corrélation avec Hiérarchie Sports | Force |
|---------|-----------------------------------|--------|
| **PIB/capita** | Diversification (toutes catégories) | Forte ✓✓✓ |
| **Population** | Volume de médailles | Moyenne ✓✓ |
| **Géographie** | Water Sports / Board Sports | Forte ✓✓✓ |
| **Tradition** | Power Sports (ex-URSS) | Forte ✓✓✓ |
| **Climat** | Endurance Sports | Moyenne ✓✓ |
| **Budget sportif** | Skill Sports (coût élevé) | Très forte ✓✓✓✓ |

### Conclusion

**OUI, il existe une corrélation claire entre politique nationale et hiérarchie des sports**

**Pays riches** : Investissement tous azimuts → toutes catégories
**Pays pauvres** : Spécialisation stratégique → Power/Endurance (faible coût)
**Géographie** : Influence naturelle → Water/Board Sports
**Culture/Histoire** : Traditions nationales → certains sports

**Recommandation pour l'analyse BI** :
Créer un segment de pays par niveau de développement et analyser la répartition des médailles par catégorie de sports pour visualiser ces corrélations.

---

## Résumé des Réponses

| Question | Réponse Synthétique |
|----------|---------------------|
| **Qualité données** | 7/10 - Exploitables mais nécessitent nettoyage |
| **Problèmes** | Valeurs nulles, mapping sports, format listes, performances |
| **Modèle BDD** | Schéma en Étoile (Star Schema) - 8 dimensions + 2 faits |
| **Corrélation politique/sports** | OUI - Forte corrélation PIB/diversification, géographie/spécialisation |

---

**Date de création** : 2026-01-07
**Projet** : Entrepôt de Données - JO Paris 2024
**Auteur** : Équipe Projet
