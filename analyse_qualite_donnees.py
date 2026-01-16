#!/usr/bin/env python3
"""
Script d'analyse de qualité des données pour les fichiers CSV des Jeux Olympiques
Analyse: valeurs manquantes, doublons, types de données, cohérence, etc.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import json
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')


class AnalyseurQualiteDonnees:
    """Analyseur de qualité des données pour fichiers CSV"""

    def __init__(self, chemin_dossier='.'):
        self.chemin_dossier = Path(chemin_dossier)
        self.fichiers_csv = list(self.chemin_dossier.glob('*.csv'))
        self.resultats = {}

    def analyser_fichier(self, fichier_path):
        """Analyse approfondie d'un fichier CSV"""
        print(f"\n{'='*80}")
        print(f"Analyse de: {fichier_path.name}")
        print(f"{'='*80}")

        try:
            # Lecture du fichier
            df = pd.read_csv(fichier_path, low_memory=False)

            analyse = {
                'nom_fichier': fichier_path.name,
                'timestamp': datetime.now().isoformat(),
                'structure': self._analyser_structure(df),
                'completude': self._analyser_completude(df),
                'doublons': self._analyser_doublons(df),
                'types_donnees': self._analyser_types(df),
                'valeurs_uniques': self._analyser_unicite(df),
                'statistiques': self._statistiques_numeriques(df),
                'anomalies': self._detecter_anomalies(df),
                'dates': self._analyser_dates(df)
            }

            # Affichage du rapport
            self._afficher_rapport(analyse)

            return analyse

        except Exception as e:
            print(f"❌ Erreur lors de l'analyse de {fichier_path.name}: {e}")
            return None

    def _analyser_structure(self, df):
        """Analyse la structure du DataFrame"""
        return {
            'nombre_lignes': len(df),
            'nombre_colonnes': len(df.columns),
            'colonnes': list(df.columns),
            'taille_memoire_mb': df.memory_usage(deep=True).sum() / 1024**2
        }

    def _analyser_completude(self, df):
        """Analyse les valeurs manquantes"""
        valeurs_manquantes = df.isnull().sum()
        pourcentages = (valeurs_manquantes / len(df) * 100).round(2)

        colonnes_avec_manquantes = []
        for col in df.columns:
            nb_manquant = valeurs_manquantes[col]
            if nb_manquant > 0:
                colonnes_avec_manquantes.append({
                    'colonne': col,
                    'nb_manquant': int(nb_manquant),
                    'pourcentage': float(pourcentages[col])
                })

        # Vérifier aussi les chaînes vides
        vides_str = {}
        for col in df.select_dtypes(include=['object']).columns:
            nb_vides = (df[col] == '').sum()
            if nb_vides > 0:
                vides_str[col] = {
                    'nb_vides': int(nb_vides),
                    'pourcentage': float((nb_vides / len(df) * 100))
                }

        return {
            'total_valeurs': int(df.size),
            'total_manquantes': int(valeurs_manquantes.sum()),
            'pourcentage_manquant_global': float((valeurs_manquantes.sum() / df.size * 100)),
            'colonnes_avec_manquantes': sorted(colonnes_avec_manquantes,
                                              key=lambda x: x['pourcentage'],
                                              reverse=True),
            'chaines_vides': vides_str
        }

    def _analyser_doublons(self, df):
        """Détecte les doublons"""
        nb_doublons = df.duplicated().sum()
        nb_doublons_totaux = df.duplicated(keep=False).sum()

        # Identifier les colonnes potentielles d'identifiant
        cols_id = [col for col in df.columns if any(
            keyword in col.lower()
            for keyword in ['code', 'id', '_code', 'tag']
        )]

        doublons_par_id = {}
        for col in cols_id:
            if col in df.columns:
                nb_dup = df[col].duplicated().sum()
                if nb_dup > 0:
                    doublons_par_id[col] = int(nb_dup)

        return {
            'nb_lignes_dupliquees': int(nb_doublons),
            'nb_total_avec_duplicats': int(nb_doublons_totaux),
            'pourcentage': float((nb_doublons / len(df) * 100)) if len(df) > 0 else 0,
            'doublons_sur_colonnes_id': doublons_par_id
        }

    def _analyser_types(self, df):
        """Analyse les types de données"""
        types_info = {}
        for col in df.columns:
            dtype = str(df[col].dtype)
            types_info[col] = {
                'type': dtype,
                'type_infer': self._inferer_type_semantique(df[col])
            }

        return types_info

    def _inferer_type_semantique(self, series):
        """Infère le type sémantique d'une colonne"""
        # Vérifier si c'est une date
        if series.dtype == 'object':
            sample = series.dropna().head(100)
            if len(sample) > 0:
                # Test de date
                try:
                    pd.to_datetime(sample, errors='raise')
                    return 'date'
                except:
                    pass

                # Test de numérique
                try:
                    pd.to_numeric(sample, errors='raise')
                    return 'numeric_as_string'
                except:
                    pass

                # Vérifier si c'est une liste/JSON
                if any(str(val).startswith('[') or str(val).startswith('{')
                       for val in sample if pd.notna(val)):
                    return 'json/list'

        if series.dtype in ['int64', 'float64']:
            return 'numeric'

        return 'categorical/text'

    def _analyser_unicite(self, df):
        """Analyse la cardinalité des colonnes"""
        unicite = {}
        for col in df.columns:
            nb_unique = df[col].nunique()
            unicite[col] = {
                'nb_valeurs_uniques': int(nb_unique),
                'pourcentage_unique': float((nb_unique / len(df) * 100)) if len(df) > 0 else 0,
                'est_potentiellement_cle': nb_unique == len(df) and df[col].notna().all()
            }

        return unicite

    def _statistiques_numeriques(self, df):
        """Statistiques pour les colonnes numériques"""
        stats = {}
        cols_numeriques = df.select_dtypes(include=[np.number]).columns

        for col in cols_numeriques:
            if df[col].notna().sum() > 0:
                stats[col] = {
                    'min': float(df[col].min()) if pd.notna(df[col].min()) else None,
                    'max': float(df[col].max()) if pd.notna(df[col].max()) else None,
                    'moyenne': float(df[col].mean()) if pd.notna(df[col].mean()) else None,
                    'mediane': float(df[col].median()) if pd.notna(df[col].median()) else None,
                    'ecart_type': float(df[col].std()) if pd.notna(df[col].std()) else None,
                    'nb_zeros': int((df[col] == 0).sum())
                }

        return stats

    def _detecter_anomalies(self, df):
        """Détecte des anomalies potentielles"""
        anomalies = []

        # Colonnes entièrement vides
        for col in df.columns:
            if df[col].isna().all():
                anomalies.append(f"⚠️  Colonne '{col}' entièrement vide")

        # Colonnes avec une seule valeur
        for col in df.columns:
            if df[col].nunique() == 1 and df[col].notna().any():
                anomalies.append(f"⚠️  Colonne '{col}' contient une seule valeur unique")

        # Valeurs numériques suspectes (ex: 0.0 en masse)
        for col in df.select_dtypes(include=[np.number]).columns:
            if col.lower() in ['height', 'weight', 'hauteur', 'poids']:
                nb_zeros = (df[col] == 0).sum()
                if nb_zeros > len(df) * 0.5:
                    anomalies.append(f"⚠️  Colonne '{col}': {nb_zeros} valeurs à 0 ({(nb_zeros/len(df)*100):.1f}%)")

        # Incohérences dans les codes pays
        if 'country_code' in df.columns and 'country' in df.columns:
            # Vérifier la cohérence
            groupes = df.groupby('country_code')['country'].nunique()
            incoherent = groupes[groupes > 1]
            if len(incoherent) > 0:
                anomalies.append(f"⚠️  Incohérence: {len(incoherent)} codes pays avec plusieurs noms de pays")

        return anomalies

    def _analyser_dates(self, df):
        """Analyse les colonnes de dates"""
        colonnes_dates = []

        for col in df.columns:
            if 'date' in col.lower() or 'time' in col.lower():
                try:
                    dates = pd.to_datetime(df[col], errors='coerce')
                    nb_valides = dates.notna().sum()

                    if nb_valides > 0:
                        colonnes_dates.append({
                            'colonne': col,
                            'nb_dates_valides': int(nb_valides),
                            'date_min': str(dates.min()) if pd.notna(dates.min()) else None,
                            'date_max': str(dates.max()) if pd.notna(dates.max()) else None,
                            'nb_invalides': int(len(df) - nb_valides)
                        })
                except:
                    pass

        return colonnes_dates

    def _afficher_rapport(self, analyse):
        """Affiche un rapport formaté de l'analyse"""

        print(f"\n📊 STRUCTURE")
        print(f"   • Lignes: {analyse['structure']['nombre_lignes']:,}")
        print(f"   • Colonnes: {analyse['structure']['nombre_colonnes']}")
        print(f"   • Taille en mémoire: {analyse['structure']['taille_memoire_mb']:.2f} MB")

        print(f"\n📉 COMPLÉTUDE DES DONNÉES")
        print(f"   • Valeurs manquantes: {analyse['completude']['total_manquantes']:,} " +
              f"({analyse['completude']['pourcentage_manquant_global']:.2f}%)")

        if analyse['completude']['colonnes_avec_manquantes']:
            print(f"   • Top colonnes avec valeurs manquantes:")
            for item in analyse['completude']['colonnes_avec_manquantes'][:5]:
                print(f"     - {item['colonne']}: {item['nb_manquant']:,} ({item['pourcentage']:.1f}%)")

        if analyse['completude']['chaines_vides']:
            print(f"   • Chaînes vides détectées dans:")
            for col, info in list(analyse['completude']['chaines_vides'].items())[:3]:
                print(f"     - {col}: {info['nb_vides']:,} ({info['pourcentage']:.1f}%)")

        print(f"\n🔄 DOUBLONS")
        print(f"   • Lignes dupliquées: {analyse['doublons']['nb_lignes_dupliquees']:,} " +
              f"({analyse['doublons']['pourcentage']:.2f}%)")

        if analyse['doublons']['doublons_sur_colonnes_id']:
            print(f"   • Doublons sur colonnes d'identifiant:")
            for col, nb in analyse['doublons']['doublons_sur_colonnes_id'].items():
                print(f"     - {col}: {nb:,} doublons")

        print(f"\n🔑 UNICITÉ")
        cles_potentielles = [col for col, info in analyse['valeurs_uniques'].items()
                            if info['est_potentiellement_cle']]
        if cles_potentielles:
            print(f"   • Clés primaires potentielles: {', '.join(cles_potentielles)}")

        # Colonnes avec faible cardinalité
        faible_card = [(col, info['nb_valeurs_uniques'])
                      for col, info in analyse['valeurs_uniques'].items()
                      if info['nb_valeurs_uniques'] < 20 and info['nb_valeurs_uniques'] > 1]
        if faible_card:
            print(f"   • Colonnes catégorielles (< 20 valeurs):")
            for col, nb in sorted(faible_card, key=lambda x: x[1])[:5]:
                print(f"     - {col}: {nb} valeurs uniques")

        if analyse['statistiques']:
            print(f"\n📈 STATISTIQUES NUMÉRIQUES")
            for col, stats in list(analyse['statistiques'].items())[:3]:
                print(f"   • {col}:")
                if stats['min'] is not None:
                    print(f"     - Min: {stats['min']}, Max: {stats['max']}, Moyenne: {stats['moyenne']:.2f}")
                if stats['nb_zeros'] > 0:
                    print(f"     - Zéros: {stats['nb_zeros']:,}")

        if analyse['dates']:
            print(f"\n📅 DATES")
            for date_info in analyse['dates']:
                print(f"   • {date_info['colonne']}:")
                print(f"     - Dates valides: {date_info['nb_dates_valides']:,}")
                if date_info['date_min']:
                    print(f"     - Plage: {date_info['date_min']} → {date_info['date_max']}")

        if analyse['anomalies']:
            print(f"\n⚠️  ANOMALIES DÉTECTÉES")
            for anomalie in analyse['anomalies']:
                print(f"   {anomalie}")

    def analyser_tous(self):
        """Analyse tous les fichiers CSV du dossier"""
        print(f"\n{'='*80}")
        print(f"ANALYSE DE QUALITÉ DES DONNÉES - JEUX OLYMPIQUES")
        print(f"{'='*80}")
        print(f"Nombre de fichiers CSV trouvés: {len(self.fichiers_csv)}")

        for fichier in sorted(self.fichiers_csv):
            analyse = self.analyser_fichier(fichier)
            if analyse:
                self.resultats[fichier.name] = analyse

        # Résumé global
        self._generer_resume_global()

        # Sauvegarder les résultats
        self._sauvegarder_resultats()

    def _generer_resume_global(self):
        """Génère un résumé global de tous les fichiers"""
        print(f"\n\n{'='*80}")
        print(f"RÉSUMÉ GLOBAL DE LA QUALITÉ DES DONNÉES")
        print(f"{'='*80}")

        total_lignes = sum(r['structure']['nombre_lignes'] for r in self.resultats.values())
        total_colonnes = sum(r['structure']['nombre_colonnes'] for r in self.resultats.values())
        total_valeurs = sum(r['completude']['total_valeurs'] for r in self.resultats.values())
        total_manquantes = sum(r['completude']['total_manquantes'] for r in self.resultats.values())

        print(f"\n📊 Vue d'ensemble")
        print(f"   • Fichiers analysés: {len(self.resultats)}")
        print(f"   • Total lignes: {total_lignes:,}")
        print(f"   • Total colonnes: {total_colonnes}")
        print(f"   • Total valeurs: {total_valeurs:,}")
        print(f"   • Total valeurs manquantes: {total_manquantes:,} ({(total_manquantes/total_valeurs*100):.2f}%)")

        # Fichiers avec le plus de problèmes
        print(f"\n⚠️  Fichiers nécessitant le plus d'attention:")
        fichiers_scores = []
        for nom, res in self.resultats.items():
            score = (
                res['completude']['pourcentage_manquant_global'] +
                res['doublons']['pourcentage'] * 2 +
                len(res['anomalies']) * 5
            )
            fichiers_scores.append((nom, score, res))

        for nom, score, res in sorted(fichiers_scores, key=lambda x: x[1], reverse=True)[:5]:
            print(f"   • {nom} (score: {score:.1f})")
            print(f"     - {res['completude']['pourcentage_manquant_global']:.1f}% données manquantes")
            print(f"     - {res['doublons']['nb_lignes_dupliquees']:,} doublons")
            print(f"     - {len(res['anomalies'])} anomalies détectées")

        print(f"\n✅ Fichiers de bonne qualité:")
        for nom, score, res in sorted(fichiers_scores, key=lambda x: x[1])[:5]:
            if score < 10:
                print(f"   • {nom}")
                print(f"     - {res['completude']['pourcentage_manquant_global']:.1f}% données manquantes")
                print(f"     - {res['structure']['nombre_lignes']:,} lignes")

    def _sauvegarder_resultats(self):
        """Sauvegarde les résultats dans un fichier JSON"""
        output_file = self.chemin_dossier / 'rapport_qualite_donnees.json'

        # Convertir les types numpy en types Python natifs
        def convert_types(obj):
            if isinstance(obj, dict):
                return {k: convert_types(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_types(item) for item in obj]
            elif isinstance(obj, (np.integer, np.floating)):
                return float(obj)
            elif isinstance(obj, np.bool_):
                return bool(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            return obj

        resultats_convertis = convert_types(self.resultats)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(resultats_convertis, f, ensure_ascii=False, indent=2)

        print(f"\n💾 Rapport détaillé sauvegardé: {output_file}")


if __name__ == '__main__':
    analyseur = AnalyseurQualiteDonnees('.')
    analyseur.analyser_tous()
