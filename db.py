import mysql.connector
from mysql.connector import Error

# ── Configuración ────────────────────────────────────────────
# Ajusta user y password según tu instalación de MySQL
DB_CONFIG = {
    'host':      'localhost',
    'user':      'root',
    'password':  '112233',           # <-- cambia por tu contraseña
    'database':  'biblioapp',
    'charset':   'utf8mb4',
    'collation': 'utf8mb4_unicode_ci',
}

def get_connection():
    """Retorna una conexión activa a la base de datos."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"[DB] Error de conexión: {e}")
        return None
