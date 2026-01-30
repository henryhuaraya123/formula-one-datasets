import pandas as pd
from sqlalchemy import create_engine
import numpy as np

# ============================================================================
# CONFIGURACIÓN DE CONEXIÓN A SUPABASE
# ============================================================================
# Formato: postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
# IMPORTANTE: Reemplazar con tus credenciales reales
DB_URL = "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

def cargar_datos():
    try:
        engine = create_engine(DB_URL)
        print("Conexión establecida con Supabase.")

        # 1. LEER ARCHIVOS CSV
        print("Leyendo archivos CSV...")
        df_drivers = pd.read_csv('drivers.csv').replace(r'\N', np.nan)
        df_constructors = pd.read_csv('constructors.csv').replace(r'\N', np.nan)
        df_status = pd.read_csv('status.csv').replace(r'\N', np.nan)
        df_races = pd.read_csv('races.csv').replace(r'\N', np.nan)
        df_circuits = pd.read_csv('circuits.csv').replace(r'\N', np.nan)
        df_results = pd.read_csv('race_results.csv').replace(r'\N', np.nan)

        # 2. TRANSFORMACIÓN: DIM_DRIVERS
        print("Transformando dim_drivers...")
        dim_drivers = pd.DataFrame({
            'driver_id': df_drivers['driverId'],
            'full_name': df_drivers['givenName'] + ' ' + df_drivers['familyName'],
            'driver_code': df_drivers['code'],
            'nationality': df_drivers['nationality'],
            'date_of_birth': pd.to_datetime(df_drivers['dateOfBirth'], errors='coerce')
        })

        # 3. TRANSFORMACIÓN: DIM_CONSTRUCTORS
        print("Transformando dim_constructors...")
        dim_constructors = pd.DataFrame({
            'constructor_id': df_constructors['constructorId'],
            'constructor_name': df_constructors['constructorName'], # Corregido de 'name'
            'nationality': df_constructors['nationality']
        })

        # 4. TRANSFORMACIÓN: DIM_STATUS
        print("Transformando dim_status...")
        dim_status = pd.DataFrame({
            'status_id': df_status['statusId'],
            'status_description': df_status['status']
        })

        # 5. TRANSFORMACIÓN: DIM_RACES (Denormalizada)
        print("Transformando dim_races...")
        # Unir races con circuits
        df_races_merged = pd.merge(df_races, df_circuits, on='circuitId', how='left')
        
        # Generamos un race_id si no existe (algunos datasets de Ergast lo tienen, otros no)
        # En este csv no parece estar, así que usamos un hash o combinación
        if 'raceId' not in df_races_merged.columns:
            df_races_merged['raceId'] = df_races_merged['season'] * 1000 + df_races_merged['round']

        dim_races = pd.DataFrame({
            'race_id': df_races_merged['raceId'],
            'race_name': df_races_merged['raceName'],
            'season': df_races_merged['season'],
            'round': df_races_merged['round'],
            'race_date': pd.to_datetime(df_races_merged['date'], errors='coerce'),
            'circuit_name': df_races_merged['circuitName_x'],
            'circuit_country': df_races_merged['country']
        })

        # 6. CARGAR DIMENSIONES Y OBTENER SURROGATE KEYS
        print("Cargando dimensiones a Supabase...")
        dim_drivers.to_sql('dim_drivers', engine, if_exists='append', index=False)
        dim_constructors.to_sql('dim_constructors', engine, if_exists='append', index=False)
        dim_status.to_sql('dim_status', engine, if_exists='append', index=False)
        dim_races.to_sql('dim_races', engine, if_exists='append', index=False)

        # 7. MAPEANDO LLAVES NATURALES A SURROGATE KEYS PARA FACT_RESULTS
        print("Obteniendo llaves generadas para el mapeo...")
        new_drivers = pd.read_sql('SELECT driver_key, driver_id FROM dim_drivers', engine)
        new_constructors = pd.read_sql('SELECT constructor_key, constructor_id FROM dim_constructors', engine)
        new_status = pd.read_sql('SELECT status_key, status_id FROM dim_status', engine)
        new_races = pd.read_sql('SELECT race_key, race_id FROM dim_races', engine)

        # Preparar tabla de hechos
        print("Preparando fact_results...")
        df_results['raceId'] = df_results['season'] * 1000 + df_results['round']
        
        # Mapear statusId: Unir results con df_status para obtener statusId (por descripción)
        df_results_mapped = pd.merge(df_results, df_status[['statusId', 'status']], left_on='status', right_on='status', how='left')
        
        # Unir con las llaves de Supabase
        fact_results = df_results_mapped.merge(new_drivers, left_on='driverId', right_on='driver_id', how='left') \
                                        .merge(new_constructors, left_on='constructorId', right_on='constructor_id', how='left') \
                                        .merge(new_status, left_on='statusId', right_on='status_id', how='left') \
                                        .merge(new_races, left_on='raceId', right_on='race_id', how='left')

        # Limpiar métricas
        fact_results['grid_position'] = pd.to_numeric(fact_results['grid'], errors='coerce')
        fact_results['final_position'] = pd.to_numeric(fact_results['position'], errors='coerce')
        fact_results['points_earned'] = pd.to_numeric(fact_results['points'], errors='coerce')
        fact_results['laps_completed'] = pd.to_numeric(fact_results['laps'], errors='coerce')
        fact_results['fastest_lap_rank'] = pd.to_numeric(fact_results['fastestLapRank'], errors='coerce')
        fact_results['average_speed'] = pd.to_numeric(fact_results['averageSpeed'], errors='coerce')

        # Seleccionar columnas finales
        fact_to_load = fact_results[[
            'race_key', 'driver_key', 'constructor_key', 'status_key',
            'grid_position', 'final_position', 'points_earned', 
            'laps_completed', 'fastest_lap_rank', 'average_speed'
        ]].dropna(subset=['race_key', 'driver_key', 'constructor_key', 'status_key'])

        # 8. CARGAR TABLA DE HECHOS
        print(f"Cargando {len(fact_to_load)} registros a fact_results...")
        fact_to_load.to_sql('fact_results', engine, if_exists='append', index=False)

        print("¡Proceso ETL completado con éxito!")

    except Exception as e:
        print(f"Error durante el proceso: {e}")

if __name__ == "__main__":
    cargar_datos()

