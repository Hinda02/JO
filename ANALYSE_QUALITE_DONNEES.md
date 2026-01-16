# Analyse de Qualité des Données - Jeux Olympiques Paris 2024

## 📊 Vue d'ensemble

Cette analyse évalue la qualité des données de 12 fichiers CSV contenant des informations sur les Jeux Olympiques de Paris 2024.

### Statistiques globales

- **Fichiers analysés**: 12
- **Total lignes**: 25,019
- **Total colonnes**: 166
- **Total valeurs**: 619,512
- **Valeurs manquantes**: 127,216 (20.53%)

## 📁 Fichiers analysés

1. `athletes.csv` - 11,113 athlètes
2. `coaches.csv` - 974 entraîneurs
3. `events.csv` - 329 épreuves
4. `medallists.csv` - 2,315 médaillés
5. `medals.csv` - 1,044 médailles
6. `nocs.csv` - 224 comités nationaux olympiques
7. `schedules.csv` - 3,895 événements programmés
8. `schedules_preliminary.csv` - 2,907 événements préliminaires
9. `teams.csv` - 1,698 équipes
10. `technical_officials.csv` - 1,021 officiels techniques
11. `torch_route.csv` - 73 étapes de la flamme olympique
12. `venues.csv` - 35 sites de compétition

## 🔴 Fichiers nécessitant le plus d'attention

### 1. schedules_preliminary.csv (Score: 71.4)
**Problèmes identifiés:**
- ⚠️ **41.0%** de données manquantes
- 🔄 **292 doublons** détectés
- ⚠️ 1 anomalie: colonne `venue_url` entièrement vide

**Recommandations:**
- Nettoyer ou supprimer la colonne `venue_url` si non utilisée
- Investiguer et résoudre les doublons
- Compléter les données manquantes pour `event_name`, `status`, et `result_winnerLoserTie`

### 2. athletes.csv (Score: 35.4)
**Problèmes identifiés:**
- ⚠️ **25.4%** de données manquantes
- ⚠️ Anomalies critiques:
  - **54.3%** des valeurs de `height` sont à 0
  - **97.1%** des valeurs de `weight` sont à 0

**Top colonnes avec données manquantes:**
- `ritual`: 92.3% manquant
- `other_sports`: 90.5% manquant
- `influence`: 80.6% manquant
- `sporting_relatives`: 77.3% manquant
- `philosophy`: 75.0% manquant

**Recommandations:**
- Remplacer les valeurs 0 dans `height` et `weight` par NULL/NA
- Considérer la suppression des colonnes avec >90% de données manquantes si non critiques
- Collecter les données manquantes pour les colonnes importantes

### 3. technical_officials.csv (Score: 18.9)
**Problèmes identifiés:**
- 📅 **98.1%** des dates de naissance manquantes
- ⚠️ Colonnes `current` et `category` avec une seule valeur unique

**Recommandations:**
- Collecter les dates de naissance ou accepter cette limitation
- Supprimer les colonnes constantes (`current`, `category`)

### 4. teams.csv (Score: 17.2)
**Problèmes identifiés:**
- ⚠️ **17.2%** de données manquantes
- Principalement dans les colonnes `coaches` (85.5%)

**Recommandations:**
- Compléter les informations sur les entraîneurs si disponibles

### 5. coaches.csv (Score: 15.1)
**Problèmes identifiés:**
- ⚠️ **5.1%** de données manquantes
- Colonne `events`: 57.1% manquant
- ⚠️ Colonnes `current` et `category` avec une seule valeur unique

## ✅ Fichiers de bonne qualité

### 1. events.csv ⭐
- **0.0%** de données manquantes
- 329 lignes, 5 colonnes
- Aucun doublon
- Structure propre et cohérente

### 2. nocs.csv ⭐
- **0.0%** de données manquantes
- 224 lignes, 4 colonnes
- Données complètes sur les comités olympiques

### 3. medals.csv ⭐
- **0.1%** de données manquantes (seulement 1 valeur)
- 1,044 médailles enregistrées
- Données très fiables

### 4. schedules.csv ⭐
- **0.2%** de données manquantes
- 3,895 événements programmés
- Bonne qualité générale

### 5. venues.csv ⭐
- **1.0%** de données manquantes
- 35 sites de compétition
- Données quasi-complètes

## 🔍 Anomalies détectées par fichier

### athletes.csv
- ✗ Colonne `height`: 6,032 valeurs à 0 (54.3%)
- ✗ Colonne `weight`: 10,792 valeurs à 0 (97.1%)

### coaches.csv, technical_officials.csv
- ✗ Colonnes `current` et `category` contiennent une seule valeur unique (peuvent être supprimées)

### schedules_preliminary.csv
- ✗ Colonne `venue_url` entièrement vide

## 📋 Types de données détectés

Le script a automatiquement inféré les types sémantiques des données:
- **Dates**: Formats ISO détectés et validés
- **Numériques**: Entiers et décimaux
- **Catégoriels**: Codes pays, genres, disciplines
- **JSON/Listes**: Colonnes contenant des structures JSON
- **Texte**: Descriptions, biographies

## 🔑 Clés primaires identifiées

Colonnes identifiées comme clés primaires potentielles (valeurs uniques sans NULL):

- `athletes.csv`: `code`
- `coaches.csv`: `code`, `name`
- `medallists.csv`: `code`
- `nocs.csv`: `code_3letters`, `code_2letters`
- `teams.csv`: `code`
- `technical_officials.csv`: `code`, `name`
- `torch_route.csv`: `title`, `tag`, `url`
- `venues.csv`: `venue`, `tag`, `url`

## 📊 Statistiques par catégorie

### Complétude
- 5 fichiers avec **< 2%** de données manquantes ✅
- 3 fichiers avec **5-20%** de données manquantes ⚠️
- 1 fichier avec **> 40%** de données manquantes 🔴

### Doublons
- 11 fichiers **sans doublons** ✅
- 1 fichier avec **292 doublons** 🔴

### Cohérence
- Tous les fichiers ont des formats de colonnes cohérents
- Les codes pays sont standardisés (ISO 3166)
- Les dates suivent le format ISO 8601

## 🛠️ Recommandations générales

### Priorité haute 🔴
1. **Nettoyer schedules_preliminary.csv**: Résoudre les 292 doublons
2. **Corriger athletes.csv**: Remplacer les 0 par NULL dans `height` et `weight`
3. **Valider les dates**: Compléter les dates de naissance manquantes où possible

### Priorité moyenne 🟡
1. **Optimiser le schéma**: Supprimer les colonnes constantes ou entièrement vides
2. **Enrichir les données**: Compléter les informations sur les entraîneurs
3. **Documenter**: Ajouter des métadonnées sur la signification des colonnes

### Priorité basse 🟢
1. **Standardiser les formats**: Uniformiser les listes JSON
2. **Ajouter des validations**: Contraintes d'intégrité référentielle entre fichiers
3. **Optimiser le stockage**: Normaliser les données redondantes

## 📖 Utilisation du script

### Installation des dépendances
```bash
pip install pandas numpy
```

### Exécution
```bash
python3 analyse_qualite_donnees.py
```

### Sortie
- **Affichage console**: Rapport détaillé pour chaque fichier
- **Fichier JSON**: `rapport_qualite_donnees.json` (67 KB)

## 📈 Métriques de qualité

### Score de qualité par fichier
Le score combine:
- % de données manquantes
- Nombre de doublons (pondéré x2)
- Nombre d'anomalies (pondéré x5)

**Plus le score est bas, meilleure est la qualité.**

| Fichier | Score | Qualité |
|---------|-------|---------|
| events.csv | 0.0 | ⭐⭐⭐⭐⭐ |
| nocs.csv | 0.0 | ⭐⭐⭐⭐⭐ |
| medals.csv | 0.1 | ⭐⭐⭐⭐⭐ |
| schedules.csv | 0.2 | ⭐⭐⭐⭐⭐ |
| venues.csv | 1.0 | ⭐⭐⭐⭐ |
| medallists.csv | 4.7 | ⭐⭐⭐⭐ |
| coaches.csv | 15.1 | ⭐⭐⭐ |
| teams.csv | 17.2 | ⭐⭐⭐ |
| technical_officials.csv | 18.9 | ⭐⭐⭐ |
| athletes.csv | 35.4 | ⭐⭐ |
| schedules_preliminary.csv | 71.4 | ⭐ |

## 🎯 Conclusion

Les données des Jeux Olympiques de Paris 2024 sont globalement de **bonne qualité**, avec:

✅ **Points forts:**
- 5 fichiers de qualité excellente (0-1% de données manquantes)
- Structure cohérente et standardisée
- Clés primaires bien définies
- Formats de dates standardisés

⚠️ **Points d'amélioration:**
- Nettoyer les fichiers `schedules_preliminary.csv` et `athletes.csv`
- Compléter les données biographiques des athlètes
- Supprimer les colonnes non utilisées ou constantes

📊 **Qualité globale: 79.47%** (basée sur la complétude des données)

---

*Analyse générée le: 2026-01-16*
*Script: `analyse_qualite_donnees.py`*
*Rapport détaillé: `rapport_qualite_donnees.json`*
