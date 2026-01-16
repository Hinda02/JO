#!/usr/bin/env python3
"""
Script d'analyse des formats de données pour les fichiers CSV des Jeux Olympiques
Analyse: cohérence des formats, validation URLs/emails, codes ISO, formats de dates, etc.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import json
import re
from datetime import datetime
from urllib.parse import urlparse
import warnings
warnings.filterwarnings('ignore')


class AnalyseurFormatsDonnees:
    """Analyseur des formats de données pour fichiers CSV"""

    def __init__(self, chemin_dossier='.'):
        self.chemin_dossier = Path(chemin_dossier)
        self.fichiers_csv = list(self.chemin_dossier.glob('*.csv'))
        self.resultats = {}

        # Expressions régulières pour la validation
        self.patterns = {
            'email': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            'url': r'^https?://[^\s]+$',
            'iso_date': r'^\d{4}-\d{2}-\d{2}',
            'code_pays_2': r'^[A-Z]{2}$',
            'code_pays_3': r'^[A-Z]{3}$',
            'phone': r'^\+?[\d\s\-\(\)]+$',
            'time': r'^\d{2}:\d{2}(:\d{2})?',
            'code_numerique': r'^\d+$',
            'tag_slug': r'^[a-z0-9\-]+$'
        }

    def analyser_fichier(self, fichier_path):
        """Analyse approfondie des formats d'un fichier CSV"""
        print(f"\n{'='*80}")
        print(f"Analyse des formats: {fichier_path.name}")
        print(f"{'='*80}")

        try:
            df = pd.read_csv(fichier_path, low_memory=False)

            analyse = {
                'nom_fichier': fichier_path.name,
                'timestamp': datetime.now().isoformat(),
                'formats_colonnes': self._analyser_formats_colonnes(df),
                'validation_urls': self._valider_urls(df),
                'validation_emails': self._valider_emails(df),
                'formats_dates': self._analyser_formats_dates(df),
                'codes_iso': self._valider_codes_iso(df),
                'coherence_casse': self._analyser_casse(df),
                'caracteres_speciaux': self._analyser_caracteres_speciaux(df),
                'formats_numeriques': self._analyser_formats_numeriques(df),
                'structures_json': self._analyser_json_lists(df),
                'espacements': self._analyser_espacements(df),
                'longueurs': self._analyser_longueurs(df),
                'patterns_specifiques': self._detecter_patterns_specifiques(df)
            }

            self._afficher_rapport(analyse)
            return analyse

        except Exception as e:
            print(f"❌ Erreur lors de l'analyse de {fichier_path.name}: {e}")
            return None

    def _analyser_formats_colonnes(self, df):
        """Détecte et analyse les formats de chaque colonne"""
        formats = {}

        for col in df.columns:
            sample = df[col].dropna().astype(str).head(100)
            if len(sample) == 0:
                formats[col] = {'type_detecte': 'vide', 'exemples': []}
                continue

            # Détection du type de format
            type_detecte = 'texte'
            pattern_match = None

            if col.lower() in ['email', 'e_mail', 'mail']:
                type_detecte = 'email'
                pattern_match = self.patterns['email']
            elif col.lower() in ['url', 'link', 'website', 'site']:
                type_detecte = 'url'
                pattern_match = self.patterns['url']
            elif 'url' in col.lower():
                type_detecte = 'url'
                pattern_match = self.patterns['url']
            elif 'date' in col.lower():
                type_detecte = 'date'
                pattern_match = self.patterns['iso_date']
            elif 'time' in col.lower():
                type_detecte = 'time'
                pattern_match = self.patterns['time']
            elif col.lower() in ['country_code', 'noc', 'nationality_code']:
                type_detecte = 'code_pays'
                pattern_match = self.patterns['code_pays_3']
            elif 'code' in col.lower() and df[col].dtype in ['int64', 'float64']:
                type_detecte = 'code_numerique'
            elif col.lower() == 'tag' or col.lower().endswith('_tag'):
                type_detecte = 'tag_slug'
                pattern_match = self.patterns['tag_slug']
            elif df[col].dtype in ['int64', 'float64']:
                type_detecte = 'numerique'

            # Validation du pattern si applicable
            conformite = None
            nb_valides = 0
            nb_invalides = 0
            exemples_invalides = []

            if pattern_match:
                for val in sample:
                    if re.match(pattern_match, str(val)):
                        nb_valides += 1
                    else:
                        nb_invalides += 1
                        if len(exemples_invalides) < 5:
                            exemples_invalides.append(str(val)[:100])

                conformite = {
                    'nb_valides': nb_valides,
                    'nb_invalides': nb_invalides,
                    'taux_conformite': (nb_valides / len(sample) * 100) if len(sample) > 0 else 0,
                    'exemples_invalides': exemples_invalides
                }

            formats[col] = {
                'type_detecte': type_detecte,
                'exemples': sample.head(3).tolist(),
                'conformite': conformite
            }

        return formats

    def _valider_urls(self, df):
        """Valide toutes les colonnes d'URLs"""
        colonnes_url = [col for col in df.columns if 'url' in col.lower()]
        resultats = {}

        for col in colonnes_url:
            urls = df[col].dropna()
            if len(urls) == 0:
                resultats[col] = {'total': 0, 'valides': 0, 'invalides': 0, 'problemes': ['Colonne vide']}
                continue

            valides = 0
            invalides = 0
            problemes = []
            schemas = {}
            domaines = {}

            for url in urls:
                url_str = str(url).strip()
                try:
                    parsed = urlparse(url_str)
                    if parsed.scheme and parsed.netloc:
                        valides += 1
                        # Statistiques sur les schémas
                        schemas[parsed.scheme] = schemas.get(parsed.scheme, 0) + 1
                        # Statistiques sur les domaines
                        domaines[parsed.netloc] = domaines.get(parsed.netloc, 0) + 1
                    else:
                        invalides += 1
                        if len(problemes) < 5:
                            problemes.append(f"Format invalide: {url_str[:50]}")
                except:
                    invalides += 1
                    if len(problemes) < 5:
                        problemes.append(f"Erreur parsing: {url_str[:50]}")

            resultats[col] = {
                'total': len(urls),
                'valides': valides,
                'invalides': invalides,
                'taux_validite': (valides / len(urls) * 100) if len(urls) > 0 else 0,
                'schemas': dict(sorted(schemas.items(), key=lambda x: x[1], reverse=True)[:5]),
                'top_domaines': dict(sorted(domaines.items(), key=lambda x: x[1], reverse=True)[:5]),
                'problemes': problemes
            }

        return resultats

    def _valider_emails(self, df):
        """Valide les colonnes d'emails"""
        colonnes_email = [col for col in df.columns if any(
            keyword in col.lower() for keyword in ['email', 'mail', 'e_mail']
        )]
        resultats = {}

        for col in colonnes_email:
            emails = df[col].dropna()
            if len(emails) == 0:
                continue

            valides = 0
            invalides = 0
            domaines = {}

            for email in emails:
                email_str = str(email).strip()
                if re.match(self.patterns['email'], email_str):
                    valides += 1
                    domaine = email_str.split('@')[1] if '@' in email_str else 'inconnu'
                    domaines[domaine] = domaines.get(domaine, 0) + 1
                else:
                    invalides += 1

            resultats[col] = {
                'total': len(emails),
                'valides': valides,
                'invalides': invalides,
                'taux_validite': (valides / len(emails) * 100) if len(emails) > 0 else 0,
                'top_domaines': dict(sorted(domaines.items(), key=lambda x: x[1], reverse=True)[:10])
            }

        return resultats

    def _analyser_formats_dates(self, df):
        """Analyse les formats de dates"""
        colonnes_dates = [col for col in df.columns if 'date' in col.lower() or 'time' in col.lower()]
        resultats = {}

        for col in colonnes_dates:
            dates_str = df[col].dropna().astype(str)
            if len(dates_str) == 0:
                continue

            formats_detectes = {
                'ISO 8601': 0,
                'ISO avec timezone': 0,
                'Date seule': 0,
                'Datetime': 0,
                'Autre': 0,
                'Invalide': 0
            }

            exemples_formats = {}

            for date_str in dates_str.head(100):
                # ISO 8601 complet avec timezone
                if re.match(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-Z]', date_str):
                    formats_detectes['ISO avec timezone'] += 1
                    if 'ISO avec timezone' not in exemples_formats:
                        exemples_formats['ISO avec timezone'] = date_str
                # ISO 8601 datetime
                elif re.match(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', date_str):
                    formats_detectes['Datetime'] += 1
                    if 'Datetime' not in exemples_formats:
                        exemples_formats['Datetime'] = date_str
                # Date seule
                elif re.match(r'^\d{4}-\d{2}-\d{2}$', date_str):
                    formats_detectes['Date seule'] += 1
                    if 'Date seule' not in exemples_formats:
                        exemples_formats['Date seule'] = date_str
                # ISO 8601
                elif re.match(r'^\d{4}-\d{2}-\d{2}', date_str):
                    formats_detectes['ISO 8601'] += 1
                    if 'ISO 8601' not in exemples_formats:
                        exemples_formats['ISO 8601'] = date_str
                else:
                    formats_detectes['Autre'] += 1
                    if 'Autre' not in exemples_formats:
                        exemples_formats['Autre'] = date_str

            # Essayer de parser les dates
            try:
                dates_parsed = pd.to_datetime(df[col], errors='coerce')
                nb_valides = dates_parsed.notna().sum()
                nb_invalides = len(df[col]) - df[col].isna().sum() - nb_valides

                resultats[col] = {
                    'formats_detectes': formats_detectes,
                    'exemples': exemples_formats,
                    'nb_parsable': int(nb_valides),
                    'nb_non_parsable': int(nb_invalides),
                    'taux_validite': float((nb_valides / len(df[col].dropna()) * 100)) if len(df[col].dropna()) > 0 else 0
                }
            except:
                resultats[col] = {
                    'formats_detectes': formats_detectes,
                    'exemples': exemples_formats,
                    'erreur': 'Impossible de parser les dates'
                }

        return resultats

    def _valider_codes_iso(self, df):
        """Valide les codes ISO (pays, etc.)"""
        colonnes_codes = [col for col in df.columns if any(
            keyword in col.lower() for keyword in ['country_code', 'noc', 'nationality', 'code_2', 'code_3']
        )]
        resultats = {}

        for col in colonnes_codes:
            codes = df[col].dropna().astype(str)
            if len(codes) == 0:
                continue

            longueurs = codes.str.len().value_counts().to_dict()
            casse_upper = (codes.str.isupper()).sum()
            casse_lower = (codes.str.islower()).sum()
            casse_mixed = len(codes) - casse_upper - casse_lower

            # Vérifier le format
            pattern_2 = self.patterns['code_pays_2']
            pattern_3 = self.patterns['code_pays_3']

            conformes_2 = codes.apply(lambda x: bool(re.match(pattern_2, str(x)))).sum()
            conformes_3 = codes.apply(lambda x: bool(re.match(pattern_3, str(x)))).sum()

            resultats[col] = {
                'total': len(codes),
                'valeurs_uniques': codes.nunique(),
                'longueurs': {k: int(v) for k, v in longueurs.items()},
                'casse': {
                    'majuscules': int(casse_upper),
                    'minuscules': int(casse_lower),
                    'mixte': int(casse_mixed)
                },
                'conformite_ISO_2': int(conformes_2),
                'conformite_ISO_3': int(conformes_3),
                'top_valeurs': codes.value_counts().head(10).to_dict()
            }

        return resultats

    def _analyser_casse(self, df):
        """Analyse la cohérence de la casse (majuscules/minuscules)"""
        resultats = {}

        colonnes_texte = df.select_dtypes(include=['object']).columns

        for col in colonnes_texte:
            valeurs = df[col].dropna().astype(str)
            if len(valeurs) == 0 or col.lower().endswith('url'):
                continue

            total = len(valeurs)
            upper = valeurs.str.isupper().sum()
            lower = valeurs.str.islower().sum()
            title = valeurs.str.istitle().sum()
            mixed = total - upper - lower - title

            # Détecter les incohérences
            incoherences = []
            if upper > 0 and lower > 0:
                incoherences.append(f"Mélange majuscules/minuscules")
            if title > 0 and (upper > total * 0.1 or lower > total * 0.1):
                incoherences.append(f"Mélange Title Case avec autres formats")

            resultats[col] = {
                'total': int(total),
                'majuscules': int(upper),
                'minuscules': int(lower),
                'title_case': int(title),
                'mixte': int(mixed),
                'taux_coherence': float((max(upper, lower, title) / total * 100)) if total > 0 else 0,
                'incoherences': incoherences
            }

        # Ne garder que les colonnes avec des incohérences potentielles
        return {k: v for k, v in resultats.items() if v['taux_coherence'] < 95 and v['total'] > 10}

    def _analyser_caracteres_speciaux(self, df):
        """Détecte les caractères spéciaux et problématiques"""
        resultats = {}

        colonnes_texte = df.select_dtypes(include=['object']).columns

        for col in colonnes_texte:
            valeurs = df[col].dropna().astype(str)
            if len(valeurs) == 0:
                continue

            # Détecter différents types de caractères
            avec_accents = valeurs.str.contains(r'[àâäéèêëïîôùûüÿæœç]', case=False, regex=True).sum()
            avec_apostrophes = valeurs.str.contains(r"['']", regex=True).sum()
            avec_guillemets = valeurs.str.contains(r'["«»""]', regex=True).sum()
            avec_tirets = valeurs.str.contains(r'[–—−]', regex=True).sum()
            avec_symboles = valeurs.str.contains(r'[®™©]', regex=True).sum()
            avec_emoji = valeurs.str.contains(r'[\U0001F600-\U0001F64F]', regex=True).sum()

            stats = {
                'accents': int(avec_accents),
                'apostrophes': int(avec_apostrophes),
                'guillemets': int(avec_guillemets),
                'tirets_speciaux': int(avec_tirets),
                'symboles': int(avec_symboles),
                'emoji': int(avec_emoji)
            }

            # Ne garder que si des caractères spéciaux sont détectés
            if sum(stats.values()) > 0:
                resultats[col] = stats

        return resultats

    def _analyser_formats_numeriques(self, df):
        """Analyse les formats des colonnes numériques"""
        resultats = {}

        colonnes_num = df.select_dtypes(include=[np.number]).columns

        for col in colonnes_num:
            valeurs = df[col].dropna()
            if len(valeurs) == 0:
                continue

            # Détecter si ce sont des entiers ou des décimaux
            est_entier = (valeurs % 1 == 0).all()
            nb_decimales = 0

            if not est_entier:
                # Compter le nombre de décimales
                valeurs_str = valeurs.astype(str)
                decimales = valeurs_str.str.split('.').str[1].str.len()
                nb_decimales = int(decimales.max()) if decimales.notna().any() else 0

            # Détection de plages
            min_val = float(valeurs.min())
            max_val = float(valeurs.max())

            # Détection de patterns spécifiques
            patterns = []
            if col.lower() in ['height', 'weight', 'age']:
                if min_val == 0 or max_val == 0:
                    patterns.append("Contient des zéros suspects")

            if col.lower().endswith('_code') or 'code' in col.lower():
                patterns.append("Code numérique")

            resultats[col] = {
                'est_entier': bool(est_entier),
                'nb_decimales': nb_decimales,
                'min': min_val,
                'max': max_val,
                'amplitude': float(max_val - min_val),
                'nb_zeros': int((valeurs == 0).sum()),
                'nb_negatifs': int((valeurs < 0).sum()),
                'patterns': patterns
            }

        return resultats

    def _analyser_json_lists(self, df):
        """Analyse les colonnes contenant des structures JSON ou listes"""
        resultats = {}

        colonnes_obj = df.select_dtypes(include=['object']).columns

        for col in colonnes_obj:
            sample = df[col].dropna().astype(str).head(100)
            if len(sample) == 0:
                continue

            # Détecter si c'est du JSON/liste
            nb_listes = sample.str.startswith('[').sum()
            nb_dicts = sample.str.startswith('{').sum()

            if nb_listes > 0 or nb_dicts > 0:
                type_structure = 'liste' if nb_listes > nb_dicts else 'dict'

                # Essayer de parser
                nb_valides = 0
                nb_invalides = 0
                exemples = []

                for val in sample.head(10):
                    try:
                        parsed = json.loads(val.replace("'", '"'))
                        nb_valides += 1
                        if len(exemples) < 3:
                            exemples.append(str(parsed)[:100])
                    except:
                        nb_invalides += 1

                resultats[col] = {
                    'type_structure': type_structure,
                    'nb_structures_detectees': int(nb_listes + nb_dicts),
                    'nb_parsable': nb_valides,
                    'nb_non_parsable': nb_invalides,
                    'exemples': exemples
                }

        return resultats

    def _analyser_espacements(self, df):
        """Détecte les problèmes d'espacement"""
        resultats = {}

        colonnes_texte = df.select_dtypes(include=['object']).columns

        for col in colonnes_texte:
            valeurs = df[col].dropna().astype(str)
            if len(valeurs) == 0:
                continue

            # Détecter les espaces en début/fin
            espaces_debut = valeurs.str.match(r'^\s').sum()
            espaces_fin = valeurs.str.match(r'\s$').sum()
            espaces_multiples = valeurs.str.contains(r'\s{2,}', regex=True).sum()
            tabulations = valeurs.str.contains(r'\t', regex=True).sum()

            problemes = {
                'espaces_debut': int(espaces_debut),
                'espaces_fin': int(espaces_fin),
                'espaces_multiples': int(espaces_multiples),
                'tabulations': int(tabulations)
            }

            # Ne garder que si des problèmes sont détectés
            if sum(problemes.values()) > 0:
                resultats[col] = problemes

        return resultats

    def _analyser_longueurs(self, df):
        """Analyse les longueurs des chaînes de caractères"""
        resultats = {}

        colonnes_texte = df.select_dtypes(include=['object']).columns

        for col in colonnes_texte:
            valeurs = df[col].dropna().astype(str)
            if len(valeurs) == 0:
                continue

            longueurs = valeurs.str.len()

            resultats[col] = {
                'min': int(longueurs.min()),
                'max': int(longueurs.max()),
                'moyenne': float(longueurs.mean()),
                'mediane': float(longueurs.median()),
                'nb_vides': int((longueurs == 0).sum())
            }

        return resultats

    def _detecter_patterns_specifiques(self, df):
        """Détecte des patterns spécifiques aux données olympiques"""
        patterns = {}

        # Détecter les colonnes de genre
        if 'gender' in df.columns:
            valeurs = df['gender'].value_counts().to_dict()
            patterns['gender'] = {
                'valeurs': valeurs,
                'normalise': all(v in ['M', 'F', 'Male', 'Female', 'W', 'X'] for v in valeurs.keys())
            }

        # Détecter les formats de noms
        if 'name' in df.columns:
            noms = df['name'].dropna().astype(str)
            avec_virgule = noms.str.contains(',').sum()
            patterns['name'] = {
                'format_nom_prenom': int(avec_virgule),
                'format_standard': len(noms) - int(avec_virgule),
                'suggestion': 'Format "NOM, Prénom"' if avec_virgule > len(noms) / 2 else 'Format standard'
            }

        # Détecter les colonnes de médailles
        cols_medailles = [col for col in df.columns if 'medal' in col.lower()]
        for col in cols_medailles:
            valeurs = df[col].value_counts().to_dict()
            patterns[col] = {
                'valeurs': valeurs,
                'normalise': all(v in ['Gold', 'Silver', 'Bronze', 'GOLD', 'SILVER', 'BRONZE'] for v in valeurs.keys())
            }

        return patterns

    def _afficher_rapport(self, analyse):
        """Affiche un rapport formaté de l'analyse des formats"""
        print(f"\n📝 FORMATS DES COLONNES")
        formats_interessants = {k: v for k, v in analyse['formats_colonnes'].items()
                               if v.get('conformite') and v['conformite']['nb_invalides'] > 0}

        if formats_interessants:
            for col, info in list(formats_interessants.items())[:5]:
                conf = info['conformite']
                print(f"   • {col} ({info['type_detecte']}):")
                print(f"     - Taux de conformité: {conf['taux_conformite']:.1f}%")
                if conf['exemples_invalides']:
                    print(f"     - Exemples invalides: {conf['exemples_invalides'][0]}")
        else:
            print(f"   ✓ Tous les formats détectés sont conformes")

        if analyse['validation_urls']:
            print(f"\n🔗 VALIDATION DES URLs")
            for col, info in analyse['validation_urls'].items():
                print(f"   • {col}:")
                print(f"     - Valides: {info['valides']}/{info['total']} ({info['taux_validite']:.1f}%)")
                if info['invalides'] > 0:
                    print(f"     - Invalides: {info['invalides']}")
                    if info['problemes']:
                        print(f"     - Problèmes: {info['problemes'][0]}")
                if info.get('schemas'):
                    print(f"     - Schémas: {', '.join(f'{k}({v})' for k, v in info['schemas'].items())}")

        if analyse['validation_emails']:
            print(f"\n📧 VALIDATION DES EMAILS")
            for col, info in analyse['validation_emails'].items():
                print(f"   • {col}: {info['valides']}/{info['total']} valides ({info['taux_validite']:.1f}%)")

        if analyse['formats_dates']:
            print(f"\n📅 FORMATS DES DATES")
            for col, info in analyse['formats_dates'].items():
                print(f"   • {col}:")
                formats = {k: v for k, v in info['formats_detectes'].items() if v > 0}
                print(f"     - Formats: {', '.join(f'{k}({v})' for k, v in formats.items())}")
                if 'taux_validite' in info:
                    print(f"     - Taux de validité: {info['taux_validite']:.1f}%")

        if analyse['codes_iso']:
            print(f"\n🌍 CODES ISO (PAYS)")
            for col, info in analyse['codes_iso'].items():
                print(f"   • {col}:")
                print(f"     - {info['valeurs_uniques']} valeurs uniques")
                if info.get('longueurs'):
                    print(f"     - Longueurs: {info['longueurs']}")
                casse = info['casse']
                if casse['majuscules'] > 0:
                    print(f"     - Casse: {casse['majuscules']} majuscules, {casse['minuscules']} minuscules")

        if analyse['coherence_casse']:
            print(f"\n🔤 COHÉRENCE DE LA CASSE")
            for col, info in analyse['coherence_casse'].items():
                print(f"   • {col}:")
                print(f"     - Cohérence: {info['taux_coherence']:.1f}%")
                if info['incoherences']:
                    for inc in info['incoherences']:
                        print(f"     ⚠️  {inc}")

        if analyse['caracteres_speciaux']:
            print(f"\n✨ CARACTÈRES SPÉCIAUX")
            for col, stats in list(analyse['caracteres_speciaux'].items())[:5]:
                chars = [f"{k}({v})" for k, v in stats.items() if v > 0]
                print(f"   • {col}: {', '.join(chars)}")

        if analyse['structures_json']:
            print(f"\n📦 STRUCTURES JSON/LISTES")
            for col, info in analyse['structures_json'].items():
                print(f"   • {col} ({info['type_structure']}):")
                print(f"     - Structures détectées: {info['nb_structures_detectees']}")
                print(f"     - Parsable: {info['nb_parsable']}, Non-parsable: {info['nb_non_parsable']}")

        if analyse['espacements']:
            print(f"\n␣ PROBLÈMES D'ESPACEMENT")
            for col, probs in list(analyse['espacements'].items())[:5]:
                issues = [f"{k}({v})" for k, v in probs.items() if v > 0]
                print(f"   • {col}: {', '.join(issues)}")

        if analyse['patterns_specifiques']:
            print(f"\n🎯 PATTERNS SPÉCIFIQUES DÉTECTÉS")
            for col, info in analyse['patterns_specifiques'].items():
                print(f"   • {col}:")
                if 'valeurs' in info:
                    print(f"     - Valeurs: {info['valeurs']}")
                if 'suggestion' in info:
                    print(f"     - {info['suggestion']}")

    def analyser_tous(self):
        """Analyse tous les fichiers CSV du dossier"""
        print(f"\n{'='*80}")
        print(f"ANALYSE DES FORMATS DE DONNÉES - JEUX OLYMPIQUES")
        print(f"{'='*80}")
        print(f"Nombre de fichiers CSV trouvés: {len(self.fichiers_csv)}")

        for fichier in sorted(self.fichiers_csv):
            analyse = self.analyser_fichier(fichier)
            if analyse:
                self.resultats[fichier.name] = analyse

        self._generer_resume_global()
        self._sauvegarder_resultats()

    def _generer_resume_global(self):
        """Génère un résumé global des formats"""
        print(f"\n\n{'='*80}")
        print(f"RÉSUMÉ GLOBAL DES FORMATS")
        print(f"{'='*80}")

        # Compter les problèmes de formats
        total_urls_invalides = sum(
            sum(info.get('validation_urls', {}).get(col, {}).get('invalides', 0)
                for col in info.get('validation_urls', {}))
            for info in self.resultats.values()
        )

        total_problemes_espacements = sum(
            len(info.get('espacements', {}))
            for info in self.resultats.values()
        )

        total_incoherences_casse = sum(
            len(info.get('coherence_casse', {}))
            for info in self.resultats.values()
        )

        print(f"\n⚠️  Problèmes détectés:")
        print(f"   • URLs invalides: {total_urls_invalides}")
        print(f"   • Colonnes avec problèmes d'espacement: {total_problemes_espacements}")
        print(f"   • Colonnes avec incohérences de casse: {total_incoherences_casse}")

        # Formats de dates
        formats_dates_utilises = set()
        for res in self.resultats.values():
            for col, info in res.get('formats_dates', {}).items():
                if 'exemples' in info:
                    formats_dates_utilises.update(info['exemples'].keys())

        if formats_dates_utilises:
            print(f"\n📅 Formats de dates utilisés:")
            for fmt in sorted(formats_dates_utilises):
                print(f"   • {fmt}")

    def _sauvegarder_resultats(self):
        """Sauvegarde les résultats dans un fichier JSON"""
        output_file = self.chemin_dossier / 'rapport_formats_donnees.json'

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

        print(f"\n💾 Rapport des formats sauvegardé: {output_file}")


if __name__ == '__main__':
    analyseur = AnalyseurFormatsDonnees('.')
    analyseur.analyser_tous()
