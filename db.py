import mysql.connector
from mysql.connector import Error
import os

DB_CONFIG = {
    'host':     os.environ.get('MYSQLHOST', 'localhost'),
    'user':     os.environ.get('MYSQLUSER', 'root'),
    'password': os.environ.get('MYSQLPASSWORD', '112233'),
    'database': os.environ.get('MYSQLDATABASE', 'biblioapp'),
    'port':     int(os.environ.get('MYSQLPORT', 3306)),
    'charset':  'utf8mb4',
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