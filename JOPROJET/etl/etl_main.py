"""
Script ETL Principal pour charger les données JO Paris 2024
Ce script peut être exécuté avec Python ou servir de référence pour Talend
"""

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime
import logging
from config import DB_CONFIG, CSV_FILES, get_sport_category
import sys
import ast

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('etl.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class JO_ETL:
    """Classe principale pour gérer l'ETL des données JO"""

    def __init__(self):
        self.conn = None
        self.cursor = None

    def connect_db(self):
        """Connexion à la base de données"""
        try:
            self.conn = psycopg2.connect(**DB_CONFIG)
            self.cursor = self.conn.cursor()
            logger.info("✓ Connexion à la base de données réussie")
        except Exception as e:
            logger.error(f"✗ Erreur de connexion à la base de données: {e}")
            raise

    def close_db(self):
        """Fermeture de la connexion"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("✓ Connexion fermée")

    def load_dim_country(self):
        """Chargement de la dimension Pays"""
        logger.info("Chargement de dim_country...")
        try:
            df = pd.read_csv(CSV_FILES['nocs'])

            # Nettoyage
            df = df.dropna(subset=['code'])

            # Insertion
            for _, row in df.iterrows():
                self.cursor.execute("""
                    INSERT INTO dim_country (country_code, country_name, country_long, country_tag, notes)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (country_code) DO NOTHING
                """, (row['code'], row['country'], row['country_long'], row['tag'], row.get('note', '')))

            self.conn.commit()
            logger.info(f"✓ {len(df)} pays chargés")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de dim_country: {e}")
            raise

    def load_dim_sport_and_events(self):
        """Chargement des dimensions Sport et Événements avec hiérarchie"""
        logger.info("Chargement de dim_sport et dim_event...")
        try:
            df = pd.read_csv(CSV_FILES['events'])

            # Obtenir les hierarchy_id
            self.cursor.execute("SELECT hierarchy_id, category_name FROM dim_sport_hierarchy")
            hierarchy_map = {row[1]: row[0] for row in self.cursor.fetchall()}

            sports_loaded = set()

            for _, row in df.iterrows():
                sport_name = row['sport']
                sport_code = row['sport_code']
                event_name = row['event']

                # Déterminer la catégorie hiérarchique
                category = get_sport_category(sport_name)
                hierarchy_id = hierarchy_map.get(category, hierarchy_map.get('Other Sports'))

                # Insérer le sport s'il n'existe pas déjà
                if sport_name not in sports_loaded:
                    self.cursor.execute("""
                        INSERT INTO dim_sport (sport_name, sport_code, hierarchy_id, sport_url)
                        VALUES (%s, %s, %s, %s)
                        ON CONFLICT DO NOTHING
                        RETURNING sport_id
                    """, (sport_name, sport_code, hierarchy_id, row.get('sport_url', '')))

                    result = self.cursor.fetchone()
                    if result:
                        sport_id = result[0]
                    else:
                        # Le sport existe déjà, récupérer son ID
                        self.cursor.execute("SELECT sport_id FROM dim_sport WHERE sport_name = %s", (sport_name,))
                        sport_id = self.cursor.fetchone()[0]

                    sports_loaded.add(sport_name)
                else:
                    # Récupérer l'ID du sport
                    self.cursor.execute("SELECT sport_id FROM dim_sport WHERE sport_name = %s", (sport_name,))
                    sport_id = self.cursor.fetchone()[0]

                # Déterminer le genre et le type d'événement
                gender = 'Mixed'
                if "Men's" in event_name or "Men" in event_name:
                    gender = 'Male'
                elif "Women's" in event_name or "Women" in event_name:
                    gender = 'Female'

                event_type = 'Team' if 'Team' in event_name else 'Individual'

                # Insérer l'événement
                self.cursor.execute("""
                    INSERT INTO dim_event (event_name, event_tag, sport_id, gender, event_type)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (event_name, row['tag'], sport_id, gender, event_type))

            self.conn.commit()
            logger.info(f"✓ {len(sports_loaded)} sports et {len(df)} événements chargés")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement des sports/événements: {e}")
            raise

    def load_dim_athlete(self):
        """Chargement de la dimension Athlète"""
        logger.info("Chargement de dim_athlete...")
        try:
            df = pd.read_csv(CSV_FILES['athletes'])

            # Nettoyage
            df = df.dropna(subset=['code', 'name'])

            # Calculer l'âge
            def calculate_age(birth_date):
                if pd.isna(birth_date):
                    return None
                try:
                    birth = pd.to_datetime(birth_date)
                    age = 2024 - birth.year
                    return age
                except:
                    return None

            df['age'] = df['birth_date'].apply(calculate_age)

            # Remplacer 0.0 par NULL pour height et weight
            df['height'] = df['height'].replace(0.0, None)
            df['weight'] = df['weight'].replace(0.0, None)

            # Obtenir les country_id
            self.cursor.execute("SELECT country_code, country_id FROM dim_country")
            country_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            # Insertion
            count = 0
            for _, row in df.iterrows():
                country_id = country_map.get(row.get('country_code'))

                self.cursor.execute("""
                    INSERT INTO dim_athlete (
                        code, name, name_short, name_tv, gender, birth_date, age,
                        height, weight, country_id, country_code, nationality,
                        nationality_code, birth_place, birth_country,
                        residence_place, residence_country, nickname, occupation, education
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (code) DO NOTHING
                """, (
                    row['code'], row['name'], row.get('name_short'), row.get('name_tv'),
                    row.get('gender'), row.get('birth_date'), row.get('age'),
                    row.get('height'), row.get('weight'), country_id,
                    row.get('country_code'), row.get('nationality'), row.get('nationality_code'),
                    row.get('birth_place'), row.get('birth_country'),
                    row.get('residence_place'), row.get('residence_country'),
                    row.get('nickname'), row.get('occupation'), row.get('education')
                ))
                count += 1

                if count % 1000 == 0:
                    self.conn.commit()
                    logger.info(f"  {count} athlètes chargés...")

            self.conn.commit()
            logger.info(f"✓ {count} athlètes chargés")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de dim_athlete: {e}")
            raise

    def load_dim_date(self):
        """Chargement de la dimension Date"""
        logger.info("Chargement de dim_date...")
        try:
            # Générer les dates de juillet à août 2024
            dates = pd.date_range(start='2024-07-01', end='2024-08-31', freq='D')

            for date in dates:
                self.cursor.execute("""
                    INSERT INTO dim_date (
                        full_date, day, month, year, day_of_week, day_name,
                        week_number, quarter, is_weekend
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (full_date) DO NOTHING
                """, (
                    date.date(),
                    date.day,
                    date.month,
                    date.year,
                    date.dayofweek,
                    date.day_name(),
                    date.isocalendar()[1],
                    (date.month - 1) // 3 + 1,
                    date.dayofweek >= 5
                ))

            self.conn.commit()
            logger.info(f"✓ {len(dates)} dates chargées")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de dim_date: {e}")
            raise

    def load_dim_venue(self):
        """Chargement de la dimension Venues"""
        logger.info("Chargement de dim_venue...")
        try:
            df = pd.read_csv(CSV_FILES['venues'])

            for _, row in df.iterrows():
                # Extraire le code du venue depuis le tag
                venue_code = row.get('tag', '')[:10]

                self.cursor.execute("""
                    INSERT INTO dim_venue (
                        venue_name, venue_code, sports, date_start, date_end,
                        venue_tag, venue_url
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (
                    row['venue'], venue_code, str(row.get('sports', '')),
                    row.get('date_start'), row.get('date_end'),
                    row.get('tag'), row.get('url')
                ))

            self.conn.commit()
            logger.info(f"✓ {len(df)} venues chargés")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de dim_venue: {e}")
            raise

    def load_fact_medals(self):
        """Chargement de la table de faits Médailles"""
        logger.info("Chargement de fact_medals...")
        try:
            df = pd.read_csv(CSV_FILES['medallists'])

            # Obtenir les mappings
            self.cursor.execute("SELECT code, athlete_id FROM dim_athlete")
            athlete_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT country_code, country_id FROM dim_country")
            country_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT event_name, event_id, sport_id FROM dim_event")
            event_map = {row[0]: (row[1], row[2]) for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT full_date, date_id FROM dim_date")
            date_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT medal_type, medal_type_id FROM dim_medal_type")
            medal_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            count = 0
            for _, row in df.iterrows():
                athlete_id = athlete_map.get(row.get('code_athlete'))
                country_id = country_map.get(row.get('country_code'))

                event_name = row.get('event')
                event_data = event_map.get(event_name)
                event_id = event_data[0] if event_data else None
                sport_id = event_data[1] if event_data else None

                medal_date = pd.to_datetime(row.get('medal_date')).date()
                date_id = date_map.get(medal_date)

                medal_type_id = medal_map.get(row.get('medal_type'))

                is_team = row.get('team_gender') is not None and pd.notna(row.get('team_gender'))

                if athlete_id and country_id and medal_type_id:
                    self.cursor.execute("""
                        INSERT INTO fact_medals (
                            athlete_id, country_id, sport_id, event_id, date_id,
                            medal_type_id, medal_date, is_team_medal, team_code
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        athlete_id, country_id, sport_id, event_id, date_id,
                        medal_type_id, medal_date, is_team, row.get('code_team')
                    ))
                    count += 1

                if count % 500 == 0:
                    self.conn.commit()
                    logger.info(f"  {count} médailles chargées...")

            self.conn.commit()
            logger.info(f"✓ {count} médailles chargées")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de fact_medals: {e}")
            raise

    def load_fact_participation(self):
        """Chargement de la table de faits Participation"""
        logger.info("Chargement de fact_participation...")
        try:
            df_athletes = pd.read_csv(CSV_FILES['athletes'])
            df_medallists = pd.read_csv(CSV_FILES['medallists'])

            # Créer un set des codes d'athlètes médaillés
            medallists_codes = set(df_medallists['code_athlete'].dropna().unique())

            # Obtenir les mappings
            self.cursor.execute("SELECT code, athlete_id FROM dim_athlete")
            athlete_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT country_code, country_id FROM dim_country")
            country_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            self.cursor.execute("SELECT sport_name, sport_id FROM dim_sport")
            sport_map = {row[0]: row[1] for row in self.cursor.fetchall()}

            count = 0
            for _, row in df_athletes.iterrows():
                athlete_code = row.get('code')
                athlete_id = athlete_map.get(athlete_code)
                country_id = country_map.get(row.get('country_code'))

                is_medallist = athlete_code in medallists_codes

                # Compter les médailles
                medal_count = len(df_medallists[df_medallists['code_athlete'] == athlete_code])

                # Extraire les disciplines
                disciplines = row.get('disciplines', '[]')
                try:
                    disciplines_list = ast.literal_eval(disciplines) if isinstance(disciplines, str) else []
                except:
                    disciplines_list = []

                # Insérer une ligne par discipline
                for discipline in disciplines_list:
                    sport_id = sport_map.get(discipline)

                    if athlete_id and country_id:
                        self.cursor.execute("""
                            INSERT INTO fact_participation (
                                athlete_id, country_id, sport_id, is_medallist, medal_count
                            )
                            VALUES (%s, %s, %s, %s, %s)
                        """, (athlete_id, country_id, sport_id, is_medallist, medal_count))
                        count += 1

                if count % 1000 == 0:
                    self.conn.commit()
                    logger.info(f"  {count} participations chargées...")

            self.conn.commit()
            logger.info(f"✓ {count} participations chargées")
        except Exception as e:
            self.conn.rollback()
            logger.error(f"✗ Erreur lors du chargement de fact_participation: {e}")
            raise

    def run_full_etl(self):
        """Exécution complète de l'ETL"""
        logger.info("=" * 70)
        logger.info("DÉMARRAGE DE L'ETL - JEUX OLYMPIQUES PARIS 2024")
        logger.info("=" * 70)

        try:
            self.connect_db()

            # Chargement des dimensions
            self.load_dim_country()
            self.load_dim_sport_and_events()
            self.load_dim_athlete()
            self.load_dim_date()
            self.load_dim_venue()

            # Chargement des faits
            self.load_fact_medals()
            self.load_fact_participation()

            logger.info("=" * 70)
            logger.info("✓✓✓ ETL TERMINÉ AVEC SUCCÈS ✓✓✓")
            logger.info("=" * 70)

        except Exception as e:
            logger.error(f"✗✗✗ ERREUR FATALE: {e}")
            raise
        finally:
            self.close_db()


if __name__ == "__main__":
    etl = JO_ETL()
    etl.run_full_etl()
