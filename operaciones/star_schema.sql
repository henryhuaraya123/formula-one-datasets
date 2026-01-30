-- ============================================================================
-- MODELO EN ESTRELLA (STAR SCHEMA) PURO - FORMULA 1
-- ============================================================================
-- Este diseño sigue la arquitectura de estrella más simple:
-- UNA tabla central (Hechos) rodeada de tablas secundarias (Dimensiones).
-- ============================================================================

-- 1. DIMENSIONES (Tablas de contexto, no tienen llaves foráneas)
-- -----------------------------------------------------

CREATE TABLE dim_drivers (
    driver_key SERIAL PRIMARY KEY,
    driver_id VARCHAR(50) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    driver_code VARCHAR(3),
    nationality VARCHAR(100),
    date_of_birth DATE
);

CREATE TABLE dim_constructors (
    constructor_key SERIAL PRIMARY KEY,
    constructor_id VARCHAR(50) NOT NULL,
    constructor_name VARCHAR(255) NOT NULL,
    nationality VARCHAR(100)
);

CREATE TABLE dim_status (
    status_key SERIAL PRIMARY KEY,
    status_id INTEGER NOT NULL,
    status_description VARCHAR(255) NOT NULL
);

-- Denormalizamos Circuito y Temporada aquí para mantener la estrella simple
CREATE TABLE dim_races (
    race_key SERIAL PRIMARY KEY,
    race_id INTEGER NOT NULL,
    race_name VARCHAR(255) NOT NULL,
    season INTEGER NOT NULL,
    round INTEGER NOT NULL,
    race_date DATE NOT NULL,
    circuit_name VARCHAR(255),
    circuit_country VARCHAR(100)
);

-- 2. TABLA DE HECHOS (La única tabla central con llaves foráneas)
-- -----------------------------------------------------

CREATE TABLE fact_results (
    fact_result_key SERIAL PRIMARY KEY,
    
    -- Llaves Foráneas (Hacia las dimensiones)
    race_key INTEGER NOT NULL,
    driver_key INTEGER NOT NULL,
    constructor_key INTEGER NOT NULL,
    status_key INTEGER NOT NULL,
    
    -- Métricas (Hechos)
    grid_position INTEGER,
    final_position INTEGER,
    points_earned DECIMAL(5, 2),
    laps_completed INTEGER,
    fastest_lap_rank INTEGER,
    average_speed DECIMAL(10, 3),
    
    -- Restricciones de relación (Definen las líneas de la estrella)
    CONSTRAINT fk_dim_race FOREIGN KEY (race_key) REFERENCES dim_races(race_key),
    CONSTRAINT fk_dim_driver FOREIGN KEY (driver_key) REFERENCES dim_drivers(driver_key),
    CONSTRAINT fk_dim_constructor FOREIGN KEY (constructor_key) REFERENCES dim_constructors(constructor_key),
    CONSTRAINT fk_dim_status FOREIGN KEY (status_key) REFERENCES dim_status(status_key)
);
