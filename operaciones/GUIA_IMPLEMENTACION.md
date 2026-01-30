# GUÍA DE IMPLEMENTACIÓN Y EJECUCIÓN: DATA WAREHOUSE F1

Esta guía proporciona las instrucciones paso a paso para desplegar la estructura del modelo estrella en Supabase y ejecutar el proceso de carga de datos (ETL).

---

## 1. REQUISITOS PREVIOS

Antes de comenzar, asegúrate de tener instalado y configurado lo siguiente:

*   **Python 3.10+**: [Descargar Python](https://www.python.org/downloads/)
*   **Cuenta en Supabase**: Un proyecto creado con una base de datos PostgreSQL activa.
*   **Librerías de Python**:
    ```powershell
    pip install pandas sqlalchemy psycopg2-binary numpy
    ```

---

## 2. PASO 1: CONFIGURACIÓN DE LA BASE DE DATOS (SUPABASE)

Antes de cargar datos, debemos crear la estructura física de las tablas.

1.  Accede al **SQL Editor** de tu proyecto en Supabase.
2.  Copia el contenido del archivo `operaciones/star_schema.sql`.
3.  Pégalo en el editor y haz clic en **Run**.
    *   *Nota: Esto creará las tablas `dim_drivers`, `dim_constructors`, `dim_status`, `dim_races` y `fact_results`.*

---

## 3. PASO 2: PREPARACIÓN DEL SCRIPT ETL

Debes configurar el script de Python para que tenga acceso a tu base de datos.

1.  Abre el archivo `cargar_f1_supabase.py`.
2.  Localiza la variable `DB_URL` (línea 10).
3.  Reemplaza los marcadores de posición con tus credenciales reales:
    ```python
    DB_URL = "postgresql://postgres:[TU_PASSWORD]@db.[TU_PROYECTO_REF].supabase.co:5432/postgres"
    ```
    *   **Password**: La contraseña que definiste al crear el proyecto en Supabase.
    *   **Project Ref**: El código único de tu proyecto (se encuentra en la URL de Supabase).

---

## 4. PASO 3: EJECUCIÓN DE LA CARGA DE DATOS

Una vez configurado, ejecuta el cargador automático:

1.  Abre una terminal o consola en la carpeta raíz del proyecto.
2.  Ejecuta el comando:
    ```powershell
    python cargar_f1_supabase.py
    ```
3.  **Monitorea la consola**: El script te informará sobre cada fase:
    *   Conexión con Supabase.
    *   Transformación de cada dimensión.
    *   Carga de las dimensiones.
    *   Mapeo de llaves subrogadas.
    *   Carga final de la tabla de hechos.

---

## 5. PASO 4: VALIDACIÓN DE DATOS

Para confirmar que todo se cargó correctamente, puedes ejecutar estas consultas en el SQL Editor de Supabase:

*   **Conteo de resultados**:
    ```sql
    SELECT COUNT(*) FROM fact_results; -- Debería devolver ~26,000+ registros
    ```
*   **Prueba de relación (JOIN)**:
    ```sql
    SELECT r.race_name, d.full_name, f.points_earned
    FROM fact_results f
    JOIN dim_races r ON f.race_key = r.race_key
    JOIN dim_drivers d ON f.driver_key = d.driver_key
    LIMIT 10;
    ```

---

## 6. SOLUCIÓN DE PROBLEMAS COMUNES

*   **Error de Conexión**: Verifica que el puerto `5432` esté abierto y que tu contraseña sea correcta. Asegúrate de no tener caracteres especiales en la contraseña que puedan romper la URL (si los tienes, usa codificación URL).
*   **Llaves duplicadas**: Si ejecutas el script dos veces sin limpiar las tablas, podrías duplicar dimensiones. Usa este comando para reiniciar:
    ```sql
    TRUNCATE dim_drivers, dim_constructors, dim_status, dim_races, fact_results CASCADE;
    ```
*   **Falta de memoria**: Si el script falla por memoria, puedes reducir el tamaño del CSV de entrada eliminando temporadas antiguas, aunque el script actual está optimizado para el volumen total.
