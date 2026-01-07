"""
Configuration pour l'ETL des données JO Paris 2024
Ce fichier contient les paramètres de connexion et les chemins des fichiers
"""

import os
from pathlib import Path

# Configuration de la base de données
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'jo_paris_2024_dwh',
    'user': 'postgres',
    'password': 'postgres'
}

# Chemins des fichiers CSV source
BASE_DIR = Path(__file__).parent.parent.parent
DATA_DIR = BASE_DIR

CSV_FILES = {
    'athletes': DATA_DIR / 'athletes.csv',
    'coaches': DATA_DIR / 'coaches.csv',
    'events': DATA_DIR / 'events.csv',
    'medallists': DATA_DIR / 'medallists.csv',
    'medals': DATA_DIR / 'medals.csv',
    'nocs': DATA_DIR / 'nocs.csv',
    'schedules': DATA_DIR / 'schedules.csv',
    'schedules_preliminary': DATA_DIR / 'schedules_preliminary.csv',
    'teams': DATA_DIR / 'teams.csv',
    'technical_officials': DATA_DIR / 'technical_officials.csv',
    'torch_route': DATA_DIR / 'torch_route.csv',
    'venues': DATA_DIR / 'venues.csv'
}

# Hiérarchie des sports selon le sujet
SPORT_HIERARCHY = {
    'Power Sports': ['Weightlifting', 'Boxing', 'Judo', 'Karate', 'Taekwondo', 'Wrestling'],
    'Endurance Sports': ['Cycling', 'Rowing', 'Triathlon'],
    'Speed Sports': ['Athletics', 'Swimming', 'Basketball', 'Handball', 'Hockey', 'Football', 'Rugby'],
    'Skill Sports': ['Gymnastics', 'Fencing', 'Golf', 'Shooting', 'Archery', 'Table Tennis',
                     'Badminton', 'Tennis', 'Baseball/Softball'],
    'Water Sports': ['Aquatics', 'Canoeing', 'Sailing', 'Surfing'],
    'Board Sports': ['Skateboarding', 'Surfing'],
    'Combination Sports': ['Modern Pentathlon'],
    'Team Sports': ['Basketball', 'Volleyball', 'Handball', 'Hockey', 'Football', 'Rugby', 'Baseball/Softball']
}

# Mapping des noms de sports alternatifs
SPORT_NAME_MAPPING = {
    'Artistic Swimming': 'Aquatics',
    'Diving': 'Aquatics',
    'Marathon Swimming': 'Aquatics',
    'Water Polo': 'Aquatics',
    'BMX Freestyle': 'Cycling',
    'BMX Racing': 'Cycling',
    'Mountain Bike': 'Cycling',
    'Cycling Road': 'Cycling',
    'Track Cycling': 'Cycling',
    'Sprint': 'Athletics',
    'Marathon': 'Athletics',
    'Race Walk': 'Athletics',
    'Artistic Gymnastics': 'Gymnastics',
    'Rhythmic Gymnastics': 'Gymnastics',
    'Trampoline': 'Gymnastics',
    'Canoe Slalom': 'Canoeing',
    'Canoe Sprint': 'Canoeing',
    'Beach Volleyball': 'Volleyball',
    '3x3 Basketball': 'Basketball',
    'Breaking': 'Skill Sports',
    'Taekwondo': 'Taekwondo',
    'Greco-Roman': 'Wrestling',
    'Freestyle': 'Wrestling'
}

def get_sport_category(sport_name):
    """
    Retourne la catégorie hiérarchique d'un sport
    """
    # Normaliser le nom du sport
    normalized_name = SPORT_NAME_MAPPING.get(sport_name, sport_name)

    for category, sports in SPORT_HIERARCHY.items():
        if normalized_name in sports or sport_name in sports:
            return category

    # Catégorie par défaut si non trouvée
    return 'Other Sports'

# Configuration du logging
LOG_FILE = BASE_DIR / 'JOPROJET' / 'etl' / 'etl.log'
LOG_LEVEL = 'INFO'
