-- ============================================================
-- Load script: raw CSVs -> staging tables -> clean schema
-- Run each section in order in the Supabase SQL Editor,
-- importing CSVs via Table Editor between steps 1 and 2/3.
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1: Create staging tables (mirror the raw CSV headers
-- exactly, everything as TEXT) and the final clean tables.
-- Run this whole block first.
-- ------------------------------------------------------------

CREATE TABLE staging_hb (
    "HB"             TEXT,
    "HBName"         TEXT,
    "HBDateEnacted"  TEXT,
    "HBDateArchived" TEXT,
    "Country"        TEXT
);

CREATE TABLE staging_ae (
    "Month"                           TEXT,
    "Country"                         TEXT,
    "HBT"                             TEXT,
    "TreatmentLocation"               TEXT,
    "DepartmentType"                  TEXT,
    "AttendanceCategory"              TEXT,
    "NumberOfAttendancesAll"          TEXT,
    "NumberWithin4HoursAll"           TEXT,
    "NumberOver4HoursAll"             TEXT,
    "PercentageWithin4HoursAll"       TEXT,
    "NumberOfAttendancesEpisode"      TEXT,
    "NumberOfAttendancesEpisodeQF"    TEXT,
    "NumberWithin4HoursEpisode"       TEXT,
    "NumberWithin4HoursEpisodeQF"     TEXT,
    "NumberOver4HoursEpisode"         TEXT,
    "NumberOver4HoursEpisodeQF"       TEXT,
    "PercentageWithin4HoursEpisode"   TEXT,
    "PercentageWithin4HoursEpisodeQF" TEXT,
    "NumberOver8HoursEpisode"         TEXT,
    "NumberOver8HoursEpisodeQF"       TEXT,
    "PercentageOver8HoursEpisode"     TEXT,
    "PercentageOver8HoursEpisodeQF"   TEXT,
    "NumberOver12HoursEpisode"        TEXT,
    "NumberOver12HoursEpisodeQF"      TEXT,
    "PercentageOver12HoursEpisode"    TEXT,
    "PercentageOver12HoursEpisodeQF"  TEXT
);
-- Note: staging_ae mirrors ALL raw CSV columns, even ones the final
-- schema doesn't use (the "All" totals, and the *QF quality-flag
-- columns) — Supabase's importer rejects a CSV if any header is
-- missing from the target table, even columns you don't plan to keep.

CREATE TABLE dim_health_board (
    hbt_code    VARCHAR(9) PRIMARY KEY,
    hb_name     VARCHAR(100) NOT NULL
);

CREATE TABLE fact_ae_activity (
    id                          SERIAL PRIMARY KEY,
    month                       DATE NOT NULL,
    country                     VARCHAR(20),
    hbt_code                    VARCHAR(9) REFERENCES dim_health_board(hbt_code),
    treatment_location          VARCHAR(20),
    department_type             VARCHAR(50),
    attendance_category         VARCHAR(20),
    attendances_episode         INT,
    within_4hrs_episode         INT,
    over_4hrs_episode           INT,
    pct_within_4hrs_episode     NUMERIC(5,2),
    over_8hrs_episode           INT,
    pct_over_8hrs_episode       NUMERIC(5,2),
    over_12hrs_episode          INT,
    pct_over_12hrs_episode      NUMERIC(5,2)
);


-- ------------------------------------------------------------
-- STEP 2: In Table Editor, import each CSV into its staging
-- table (Insert -> Import data from CSV). Headers will match
-- automatically since the staging tables mirror the raw files.
--   hb14_hb19.csv              -> staging_hb
--   monthly_ae_activity_*.csv  -> staging_ae
-- Then come back here and run steps 3 and 4.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- STEP 3: Populate dim_health_board from staging_hb.
-- Must run BEFORE step 4 (fact table has a foreign key to this).
-- ------------------------------------------------------------

INSERT INTO dim_health_board (hbt_code, hb_name)
SELECT DISTINCT "HB", "HBName"
FROM staging_hb
WHERE "HB" IS NOT NULL;


-- ------------------------------------------------------------
-- STEP 4: Populate fact_ae_activity from staging_ae, casting
-- text columns to proper types.
--
-- NOTE: if this fails with a foreign key violation, it means
-- some HBT values in the activity data (e.g. a Scotland-wide
-- code like S92000003) aren't in the health board lookup file.
-- Add WHERE "HBT" IN (SELECT hbt_code FROM dim_health_board)
-- below to skip those rows, or add the missing code(s) to
-- dim_health_board manually first.
-- ------------------------------------------------------------

INSERT INTO fact_ae_activity (
    month, country, hbt_code, treatment_location, department_type,
    attendance_category, attendances_episode, within_4hrs_episode,
    over_4hrs_episode, pct_within_4hrs_episode, over_8hrs_episode,
    pct_over_8hrs_episode, over_12hrs_episode, pct_over_12hrs_episode
)
SELECT
    to_date("Month", 'YYYYMM'),
    "Country",
    "HBT",
    "TreatmentLocation",
    "DepartmentType",
    "AttendanceCategory",
    NULLIF("NumberOfAttendancesEpisode", '')::INT,
    NULLIF("NumberWithin4HoursEpisode", '')::INT,
    NULLIF("NumberOver4HoursEpisode", '')::INT,
    NULLIF("PercentageWithin4HoursEpisode", '')::NUMERIC,
    NULLIF("NumberOver8HoursEpisode", '')::INT,
    NULLIF("PercentageOver8HoursEpisode", '')::NUMERIC,
    NULLIF("NumberOver12HoursEpisode", '')::INT,
    NULLIF("PercentageOver12HoursEpisode", '')::NUMERIC
FROM staging_ae
WHERE "HBT" IN (SELECT hbt_code FROM dim_health_board);


-- ------------------------------------------------------------
-- STEP 5 (optional cleanup): drop staging tables once you've
-- confirmed fact_ae_activity and dim_health_board look right.
-- ------------------------------------------------------------

-- DROP TABLE staging_hb;
-- DROP TABLE staging_ae;
