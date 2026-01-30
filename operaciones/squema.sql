-- Formula One Database Schema for PostgreSQL
-- Corrected and Optimized for ERD Visualization
-- Author: Antigravity AI

-- ============================================================================
-- REFERENCE TABLES
-- ============================================================================

CREATE TABLE circuits (
    circuit_id VARCHAR(50) PRIMARY KEY,
    circuit_name VARCHAR(255) NOT NULL,
    lat DECIMAL(10, 6),
    long DECIMAL(10, 6),
    locality VARCHAR(255),
    country VARCHAR(100),
    url VARCHAR(500)
);

CREATE TABLE constructors (
    constructor_id VARCHAR(50) PRIMARY KEY,
    constructor_name VARCHAR(255) NOT NULL,
    nationality VARCHAR(100),
    url VARCHAR(500)
);

CREATE TABLE drivers (
    driver_id VARCHAR(50) PRIMARY KEY,
    given_name VARCHAR(100) NOT NULL,
    family_name VARCHAR(100) NOT NULL,
    code VARCHAR(3),
    permanent_number INTEGER,
    date_of_birth DATE,
    nationality VARCHAR(100),
    url VARCHAR(500)
);

CREATE TABLE seasons (
    season INTEGER PRIMARY KEY,
    url VARCHAR(500)
);

CREATE TABLE status (
    status_id INTEGER PRIMARY KEY,
    status VARCHAR(255) NOT NULL UNIQUE,
    count INTEGER DEFAULT 0
);

-- ============================================================================
-- MAIN TABLES
-- ============================================================================

CREATE TABLE races (
    race_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL REFERENCES seasons(season),
    round INTEGER NOT NULL,
    race_name VARCHAR(255) NOT NULL,
    circuit_id VARCHAR(50) NOT NULL REFERENCES circuits(circuit_id),
    circuit_name VARCHAR(255),
    date DATE NOT NULL,
    time TIME,
    first_practice TIMESTAMP,
    second_practice TIMESTAMP,
    third_practice TIMESTAMP,
    qualifying TIMESTAMP,
    sprint TIMESTAMP,
    url VARCHAR(500),
    CONSTRAINT uk_races_season_round UNIQUE (season, round)
);

-- ============================================================================
-- EVENT TABLES (Connected to Races, Drivers, and Constructors)
-- ============================================================================

CREATE TABLE qualifying_results (
    qualify_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    driver_name VARCHAR(255),
    constructor_id VARCHAR(50) NOT NULL REFERENCES constructors(constructor_id),
    constructor_name VARCHAR(255),
    number INTEGER,
    position INTEGER,
    q1 VARCHAR(20),
    q2 VARCHAR(20),
    q3 VARCHAR(20),
    CONSTRAINT fk_qualifying_race FOREIGN KEY (season, round) REFERENCES races(season, round),
    CONSTRAINT uk_qualifying_season_round_driver UNIQUE (season, round, driver_id)
);

CREATE TABLE sprint_results (
    sprint_result_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    driver_name VARCHAR(255),
    constructor_id VARCHAR(50) NOT NULL REFERENCES constructors(constructor_id),
    constructor_name VARCHAR(255),
    number INTEGER,
    position INTEGER,
    position_text VARCHAR(10),
    points DECIMAL(5, 2) DEFAULT 0,
    grid INTEGER,
    laps INTEGER,
    status VARCHAR(255) REFERENCES status(status),
    time VARCHAR(50),
    fastest_lap_lap INTEGER,
    fastest_lap_time VARCHAR(20),
    CONSTRAINT fk_sprint_race FOREIGN KEY (season, round) REFERENCES races(season, round),
    CONSTRAINT uk_sprint_season_round_driver UNIQUE (season, round, driver_id)
);

CREATE TABLE race_results (
    result_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    driver_name VARCHAR(255),
    constructor_id VARCHAR(50) NOT NULL REFERENCES constructors(constructor_id),
    constructor_name VARCHAR(255),
    number INTEGER,
    position INTEGER,
    position_text VARCHAR(10),
    points DECIMAL(5, 2) DEFAULT 0,
    grid INTEGER,
    laps INTEGER,
    status VARCHAR(255) REFERENCES status(status),
    time VARCHAR(50),
    fastest_lap_rank INTEGER,
    fastest_lap_lap INTEGER,
    fastest_lap_time VARCHAR(20),
    average_speed DECIMAL(10, 3),
    race_id INTEGER REFERENCES races(race_id),
    status_id INTEGER REFERENCES status(status_id),
    CONSTRAINT fk_race_results_race_natural FOREIGN KEY (season, round) REFERENCES races(season, round),
    CONSTRAINT uk_race_results_season_round_driver UNIQUE (season, round, driver_id)
);

CREATE TABLE lap_times (
    lap_time_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    lap_number INTEGER NOT NULL,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    position INTEGER,
    time VARCHAR(20),
    CONSTRAINT fk_lap_times_race FOREIGN KEY (season, round) REFERENCES races(season, round),
    CONSTRAINT uk_lap_times_season_round_driver_lap UNIQUE (season, round, driver_id, lap_number)
);

CREATE TABLE pit_stops (
    pit_stop_id SERIAL PRIMARY KEY,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    driver_id VARCHAR(50) NOT NULL REFERENCES drivers(driver_id),
    lap INTEGER NOT NULL,
    stop INTEGER NOT NULL,
    time TIME,
    duration DECIMAL(8, 3),
    CONSTRAINT fk_pit_stops_race FOREIGN KEY (season, round) REFERENCES races(season, round),
    CONSTRAINT uk_pit_stops_season_round_driver_stop UNIQUE (season, round, driver_id, stop)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_races_season_round ON races(season, round);
CREATE INDEX idx_race_results_composite ON race_results(season, round, driver_id);
CREATE INDEX idx_lap_times_race ON lap_times(season, round);
CREATE INDEX idx_pit_stops_driver ON pit_stops(driver_id);
