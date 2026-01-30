# PROYECTO: DATA WAREHOUSE FORMULA 1 - MODELO ESTRELLA

Este documento detalla la arquitectura, el diseño y la implementación de un almacén de datos (Data Warehouse) para el conjunto de datos de Formula 1, diseñado específicamente para optimizar consultas analíticas y la generación de informes en herramientas de BI (Power BI, Tableau, etc.).

---

## 1. OBJETIVO DEL PROYECTO
El objetivo principal es transformar una base de datos relacional compleja en una **Estructura de Modelo en Estrella (Star Schema)**. Este modelo simplifica las relaciones de datos, mejora el rendimiento de las consultas de agregación y facilita la interpretación de los datos por parte de usuarios finales y agentes de IA.

---

## 2. ARQUITECTURA DEL MODELO (STAR SCHEMA)

Se ha implementado un esquema de **"Estrella Pura"** alojado en **Supabase (PostgreSQL)**.

### Tabla de Hechos (Fact Table)
*   **`fact_results`**: Es el núcleo del modelo. Contiene las métricas cuantitativas observables de cada carrera.
    *   **Métricas principales**: Puntos obtenidos, posición final, posición de parrilla (grid), número de vueltas, rango de vuelta rápida y velocidad promedio.

### Tablas de Dimensiones (Dimension Tables)
Para optimizar el rendimiento y simplicidad, se aplicó **denormalización** en ciertos puntos:
1.  **`dim_drivers`**: Información biográfica y de identificación de los pilotos.
2.  **`dim_constructors`**: Detalles de las escuderías/constructores.
3.  **`dim_races`**: **Dimensión Denormalizada**. Combina datos de Carreras, Circuitos y Temporadas en una sola tabla para evitar múltiples JOINs complejos.
4.  **`dim_status`**: Catálogo descriptivo del estado final del piloto en la carrera (e.g., "Finished", "Accident", "+1 Lap").

---

## 3. JUSTIFICACIÓN DEL DISEÑO (MODELO ANALÍTICO)

Para mantener la **"Pureza de la Estrella"** y asegurar un rendimiento óptimo en herramientas de visualización, se tomaron decisiones críticas sobre la inclusión y exclusión de entidades:

| Entidad | Decisión | Justificación Técnica |
| :--- | :--- | :--- |
| **Circuitos / Temporadas** | **Denormalizadas** | Merged en `dim_races`. En un modelo estrella puro, evitamos el "copo de nieve" (Snowflake). Al aplanar estas tablas, reducimos de 3 JOINs a solo 1 para filtrar por país o año. |
| **Pilotos / Constructores** | **Incluidas** | Son los ejes centrales del análisis de rendimiento. Representan dimensiones con baja cardinalidad comparada con los hechos. |
| **Status (Estado)** | **Incluida** | Fundamental para separar el rendimiento deportivo (puntos) de los fallos mecánicos o incidentes. |
| **Lap Times (Tiempos)** | **Descartada** | Aportaría millones de registros a una granularidad distinta. Para este modelo de "Resultados", se decidió mantener una granularidad de *1 fila = 1 piloto por carrera*. |
| **Pit Stops / Qualifying** | **Descartadas** | Se consideran procesos de negocio distintos. Incluirlos en la misma estrella de resultados complicaría el modelo. Se recomiendan como "Estrellas" independientes si se requiere ese análisis. |

---

## 4. DICCIONARIO DE DATOS DETALLADO

### 3.1 Tabla de Hechos: `fact_results`
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `fact_result_key` | PK (SERIAL) | Identificador único interno del hecho. |
| `race_key` | FK | Llave subrogada hacia `dim_races`. |
| `driver_key` | FK | Llave subrogada hacia `dim_drivers`. |
| `constructor_key` | FK | Llave subrogada hacia `dim_constructors`. |
| `status_key` | FK | Llave subrogada hacia `dim_status`. |
| `grid_position` | INTEGER | Posición de salida en la parrilla. |
| `final_position` | INTEGER | Posición final en la carrera (NULL si no terminó). |
| `points_earned` | DECIMAL | Puntos otorgados al piloto en esa carrera. |
| `laps_completed` | INTEGER | Número total de vueltas completadas. |
| `fastest_lap_rank` | INTEGER | Ranking de la vuelta más rápida en la carrera. |
| `average_speed` | DECIMAL | Velocidad promedio registrada (km/h). |

### 3.2 Dimensiones Clave
*   **`dim_races`**: Incluye `race_name`, `season` (año), `round`, `race_date`, `circuit_name` y `circuit_country`.
*   **`dim_drivers`**: Incluye `full_name` (concatenación de nombre y apellido), `driver_code`, `nationality` y `date_of_birth`.
*   **`dim_constructors`**: Incluye `constructor_name` y `nationality`.
*   **`dim_status`**: Incluye `status_description`.

---

## 4. PROCESO ETL (EXTRACT, TRANSFORM, LOAD)

Se desarrolló un script robuso en Python (`cargar_f1_supabase.py`) que automatiza la migración desde archivos CSV hacia Supabase.

### Fases del ETL:
1.  **Extracción**: Lectura de 6 archivos CSV (`drivers`, `constructors`, `status`, `races`, `circuits`, `race_results`).
2.  **Limpieza de Datos**:
    *   Tratamiento de nulos: Conversión de caracteres `\N` (propios del dataset Ergast) a valores `NULL` reales de base de datos.
    *   Tipado: Conversión forzada de métricas a formatos numéricos (`int`, `float`) para cálculos precisos.
3.  **Transformación**:
    *   **Denormalización**: Unión de carreras con sus circuitos correspondientes antes de la carga.
    *   **Ingeniería de Características**: Creación de campos como `full_name`.
4.  **Carga y Generación de Llaves**:
    *   Se cargan primero las dimensiones para que la DB genere las **Llaves Subrogadas** (Surrogate Keys).
    *   El script recupera esas llaves y mapea las llaves naturales de los CSV para insertar los registros en la tabla de hechos con integridad referencial perfecta.

---

## 5. RECURSOS TÉCNICOS ADJUNTOS
*   **`schema.sql`**: Script SQL de las relaciones originales.
*   **`star_schema.sql`**: Script SQL para crear la estructura formato estrella en Supabase.
*   **`analisis.ipynb`**: Notebook con la exploración inicial y validación de calidad de los datos.
*   **`cargar_f1_supabase.py`**: Motor de carga del Data Warehouse.

---

## 6. INSTRUCCIONES PARA EL REPORTE
*   **Contexto**: El sistema está diseñado para permitir análisis históricos de rendimiento de pilotos y escuderías por temporada y país.
*   **Destacar**: La eficiencia del modelo estrella reduciendo la complejidad de las consultas (de ~8 tablas relacionales a solo 1 hecho y 4 dimensiones).
*   **Conclusiones Técnica**: El uso de llaves subrogadas protege el modelo contra cambios en los IDs de origen y mejora el rendimiento de indexación.
