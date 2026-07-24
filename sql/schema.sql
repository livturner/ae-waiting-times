-- ============================================================
-- Final schema: NHS Scotland A&E Waiting Times project
-- These are the two tables your analysis queries run against.
-- (Staging tables and the load process live in load_data.sql)
-- ============================================================

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
