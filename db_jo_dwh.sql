/* =========================================================
   JO PARIS 2024 - DATA WAREHOUSE (STAR SCHEMA) - MYSQL 8
   Charset: utf8mb4
   ========================================================= */

CREATE DATABASE IF NOT EXISTS jo_dwh
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE jo_dwh;

/* -----------------------------
   DIMENSIONS
------------------------------*/

DROP TABLE IF EXISTS fact_torch_route;
DROP TABLE IF EXISTS fact_participation;
DROP TABLE IF EXISTS fact_schedule;
DROP TABLE IF EXISTS fact_medal;

DROP TABLE IF EXISTS dim_technical_official;
DROP TABLE IF EXISTS dim_coach;
DROP TABLE IF EXISTS dim_team;
DROP TABLE IF EXISTS dim_athlete;
DROP TABLE IF EXISTS dim_venue;
DROP TABLE IF EXISTS dim_event;
DROP TABLE IF EXISTS dim_sport_category;
DROP TABLE IF EXISTS dim_sport;
DROP TABLE IF EXISTS dim_country;
DROP TABLE IF EXISTS dim_date;

/* DIM DATE */
CREATE TABLE dim_date (
  date_sk      INT AUTO_INCREMENT PRIMARY KEY,
  date_key     INT NOT NULL,              -- ex: 20240726
  full_date    DATE NOT NULL,
  year         SMALLINT NOT NULL,
  month        TINYINT  NOT NULL,
  day          TINYINT  NOT NULL,
  week_iso     TINYINT  NULL,
  day_name     VARCHAR(15) NULL,
  month_name   VARCHAR(15) NULL,
  UNIQUE KEY uk_dim_date_key (date_key),
  UNIQUE KEY uk_dim_date_full (full_date)
) ENGINE=InnoDB;

/* DIM COUNTRY / NOC */
CREATE TABLE dim_country (
  country_sk    INT AUTO_INCREMENT PRIMARY KEY,
  noc_code      VARCHAR(3)  NOT NULL,     -- NOC (ex: FRA)
  country       VARCHAR(100) NULL,
  country_long  VARCHAR(150) NULL,
  country_tag   VARCHAR(50) NULL,
  note          VARCHAR(1000) NULL,
  UNIQUE KEY uk_country_noc (noc_code)
) ENGINE=InnoDB;

/* DIM SPORT */
CREATE TABLE dim_sport (
  sport_sk     INT AUTO_INCREMENT PRIMARY KEY,
  sport_code   VARCHAR(50) NOT NULL,
  sport        VARCHAR(255) NULL,
  sport_url    VARCHAR(500) NULL,
  UNIQUE KEY uk_sport_code (sport_code)
) ENGINE=InnoDB;

/* DIM SPORT CATEGORY (mapping demandé) */
CREATE TABLE dim_sport_category (
  sport_cat_sk    INT AUTO_INCREMENT PRIMARY KEY,
  sport_code      VARCHAR(50) NOT NULL,
  sport_category  VARCHAR(30) NOT NULL,   -- Power/Endurance/Speed/Skill/Water/Board/Combination/Team
  UNIQUE KEY uk_sportcat (sport_code),
  CONSTRAINT fk_sportcat_sport
    FOREIGN KEY (sport_code) REFERENCES dim_sport(sport_code)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* DIM EVENT */
CREATE TABLE dim_event (
  event_sk     INT AUTO_INCREMENT PRIMARY KEY,
  event_tag    VARCHAR(120) NOT NULL,     -- events.tag
  event        VARCHAR(255) NULL,         -- events.event
  sport_code   VARCHAR(50) NULL,          -- lien métier vers dim_sport
  UNIQUE KEY uk_event_tag (event_tag),
  KEY idx_event_sport_code (sport_code),
  CONSTRAINT fk_event_sport
    FOREIGN KEY (sport_code) REFERENCES dim_sport(sport_code)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* DIM VENUE */
CREATE TABLE dim_venue (
  venue_sk     INT AUTO_INCREMENT PRIMARY KEY,
  venue_tag    VARCHAR(120) NULL,         -- si tu as un tag/code dans venues.csv
  venue        VARCHAR(255) NULL,
  city         VARCHAR(120) NULL,
  country      VARCHAR(120) NULL,
  date_start   DATE NULL,
  date_end     DATE NULL,
  url          VARCHAR(500) NULL,
  UNIQUE KEY uk_venue_tag (venue_tag),
  KEY idx_venue_name (venue)
) ENGINE=InnoDB;

/* DIM ATHLETE */
CREATE TABLE dim_athlete (
  athlete_sk        INT AUTO_INCREMENT PRIMARY KEY,
  athlete_code      VARCHAR(40) NOT NULL, -- athletes.code
  name              VARCHAR(255) NULL,
  name_short        VARCHAR(255) NULL,
  name_tv           VARCHAR(255) NULL,
  gender            VARCHAR(10)  NULL,
  function_role     VARCHAR(80)  NULL,
  birth_date        DATE NULL,
  height_cm         DECIMAL(6,2) NULL,
  weight_kg         DECIMAL(6,2) NULL,
  noc_code          VARCHAR(3)   NULL,    -- athletes.country_code (souvent NOC)
  nationality_code  VARCHAR(10)  NULL,
  UNIQUE KEY uk_athlete_code (athlete_code),
  KEY idx_athlete_noc (noc_code),
  CONSTRAINT fk_athlete_country
    FOREIGN KEY (noc_code) REFERENCES dim_country(noc_code)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* DIM TEAM */
CREATE TABLE dim_team (
  team_sk          INT AUTO_INCREMENT PRIMARY KEY,
  team_code        VARCHAR(40) NOT NULL, -- teams.code
  team             VARCHAR(255) NULL,
  team_gender      VARCHAR(10)  NULL,
  noc_code         VARCHAR(3)   NULL,
  discipline       VARCHAR(255) NULL,
  discipline_code  VARCHAR(80)  NULL,
  num_athletes     INT NULL,
  num_coaches      INT NULL,
  UNIQUE KEY uk_team_code (team_code),
  KEY idx_team_noc (noc_code),
  CONSTRAINT fk_team_country
    FOREIGN KEY (noc_code) REFERENCES dim_country(noc_code)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* (OPTIONNEL) DIM COACH */
CREATE TABLE dim_coach (
  coach_sk      INT AUTO_INCREMENT PRIMARY KEY,
  coach_code    VARCHAR(40) NOT NULL,
  name          VARCHAR(255) NULL,
  gender        VARCHAR(10)  NULL,
  function_role VARCHAR(80)  NULL,
  category      VARCHAR(80)  NULL,
  birth_date    DATE NULL,
  noc_code      VARCHAR(3)   NULL,
  UNIQUE KEY uk_coach_code (coach_code),
  KEY idx_coach_noc (noc_code),
  CONSTRAINT fk_coach_country
    FOREIGN KEY (noc_code) REFERENCES dim_country(noc_code)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* (OPTIONNEL) DIM TECHNICAL OFFICIAL */
CREATE TABLE dim_technical_official (
  official_sk INT AUTO_INCREMENT PRIMARY KEY,

  official_code VARCHAR(40) NOT NULL,
  name VARCHAR(255) NULL,
  gender VARCHAR(10) NULL,
  function_role VARCHAR(80) NULL,
  category VARCHAR(10) NULL,

  organisation_code VARCHAR(40) NULL,
  organisation VARCHAR(255) NULL,
  organisation_long VARCHAR(255) NULL,
  disciplines TEXT NULL,
  birth_date DATE NULL,

  UNIQUE KEY uk_official_code (official_code),
  KEY idx_org_code (organisation_code)
) ENGINE=InnoDB;

/* -----------------------------
   FACTS
------------------------------*/

/* FACT MEDAL (1 ligne = 1 médaille attribuée)
   Sources typiques: medallists.csv (+ medals.csv si tu veux comparer)
*/
CREATE TABLE fact_medal (
  medal_sk      BIGINT AUTO_INCREMENT PRIMARY KEY,

  date_sk       INT NULL,
  country_sk    INT NULL,
  sport_sk      INT NULL,
  event_sk      INT NULL,
  athlete_sk    INT NULL,
  team_sk       INT NULL,

  medal_type    VARCHAR(10) NOT NULL,     -- Gold/Silver/Bronze
  medal_count   TINYINT NOT NULL DEFAULT 1,

  -- dégénérés / trace
  source_event_tag  VARCHAR(120) NULL,
  source_sport_code VARCHAR(50)  NULL,
  source_noc_code   VARCHAR(3)   NULL,

  KEY idx_fm_date (date_sk),
  KEY idx_fm_country (country_sk),
  KEY idx_fm_sport (sport_sk),
  KEY idx_fm_event (event_sk),
  KEY idx_fm_athlete (athlete_sk),
  KEY idx_fm_team (team_sk),

  CONSTRAINT fk_fm_date    FOREIGN KEY (date_sk)    REFERENCES dim_date(date_sk)       ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fm_country FOREIGN KEY (country_sk) REFERENCES dim_country(country_sk) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fm_sport   FOREIGN KEY (sport_sk)   REFERENCES dim_sport(sport_sk)     ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fm_event   FOREIGN KEY (event_sk)   REFERENCES dim_event(event_sk)     ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fm_athlete FOREIGN KEY (athlete_sk) REFERENCES dim_athlete(athlete_sk) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fm_team    FOREIGN KEY (team_sk)    REFERENCES dim_team(team_sk)       ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* FACT SCHEDULE (1 ligne = 1 session/épreuve planifiée)
   Sources: schedules.csv (+ schedules_preliminary.csv)
*/
CREATE TABLE fact_schedule (
  schedule_sk    BIGINT AUTO_INCREMENT PRIMARY KEY,

  start_date_sk  INT NULL,
  end_date_sk    INT NULL,
  sport_sk       INT NULL,
  event_sk       INT NULL,
  venue_sk       INT NULL,

  start_ts       DATETIME NULL,
  end_ts         DATETIME NULL,
  status         VARCHAR(50) NULL,
  phase          VARCHAR(120) NULL,
  gender         VARCHAR(20) NULL,
  event_type     VARCHAR(80) NULL,
  is_medal_event TINYINT NULL,        -- 0/1 si info dispo

  sessions_count TINYINT NOT NULL DEFAULT 1,

  KEY idx_fs_start (start_date_sk),
  KEY idx_fs_event (event_sk),
  KEY idx_fs_venue (venue_sk),

  CONSTRAINT fk_fs_start_date FOREIGN KEY (start_date_sk) REFERENCES dim_date(date_sk)  ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fs_end_date   FOREIGN KEY (end_date_sk)   REFERENCES dim_date(date_sk)  ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fs_sport      FOREIGN KEY (sport_sk)      REFERENCES dim_sport(sport_sk) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fs_event      FOREIGN KEY (event_sk)      REFERENCES dim_event(event_sk) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fs_venue      FOREIGN KEY (venue_sk)      REFERENCES dim_venue(venue_sk) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* FACT PARTICIPATION (agrégée: pays/sport/date)
   Sources: athletes.csv + teams.csv (+ schedule pour date si tu veux)
*/
CREATE TABLE fact_participation (
  part_sk       BIGINT AUTO_INCREMENT PRIMARY KEY,
  date_sk       INT NULL,
  country_sk    INT NULL,
  sport_sk      INT NULL,

  athletes_count INT NOT NULL DEFAULT 0,
  teams_count    INT NOT NULL DEFAULT 0,

  UNIQUE KEY uk_part (date_sk, country_sk, sport_sk),

  CONSTRAINT fk_fp_date    FOREIGN KEY (date_sk)    REFERENCES dim_date(date_sk)       ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fp_country FOREIGN KEY (country_sk) REFERENCES dim_country(country_sk) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fp_sport   FOREIGN KEY (sport_sk)   REFERENCES dim_sport(sport_sk)     ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

/* FACT TORCH ROUTE (1 ligne = 1 étape)
   Source: torch_route.csv
*/
CREATE TABLE fact_torch_route (
  torch_sk     BIGINT AUTO_INCREMENT PRIMARY KEY,
  date_sk      INT NULL,
  country_sk   INT NULL,

  city         VARCHAR(120) NULL,
  location     VARCHAR(255) NULL,
  latitude     DECIMAL(9,6) NULL,
  longitude    DECIMAL(9,6) NULL,

  step_count   TINYINT NOT NULL DEFAULT 1,

  KEY idx_tr_date (date_sk),
  KEY idx_tr_country (country_sk),

  CONSTRAINT fk_tr_date    FOREIGN KEY (date_sk)    REFERENCES dim_date(date_sk)       ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_tr_country FOREIGN KEY (country_sk) REFERENCES dim_country(country_sk) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;
