# BiblioApp

Aplicación web de gestión de biblioteca desarrollada con **Flask + MySQL**.

Permite gestionar libros, socios y préstamos con operaciones CRUD completas.

---

## Requisitos previos

- Python 3.10 o superior
- MySQL 8.0 o superior
- pip

---

## Instalación paso a paso

### 1. Descomprimir el proyecto

Descomprime la carpeta `biblioapp` en tu directorio de trabajo.

### 2. Crear entorno virtual (recomendado)

```bash
# Crear el entorno
python -m venv venv

# Activar en Linux/Mac
source venv/bin/activate

# Activar en Windows
venv\Scripts\activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Cargar la base de datos

Abre tu cliente MySQL (Workbench, DBeaver o terminal) y ejecuta:

```bash
mysql -u root -p < schema.sql
```

O copia y pega el contenido de `schema.sql` directo en tu cliente.

### 5. Configurar la conexión

Edita el archivo `db.py` y ajusta las credenciales:

```python
DB_CONFIG = {
    'host':     'localhost',
    'user':     'root',
    'password': 'TU_PASSWORD',   # <-- cambia aquí
    'database': 'biblioapp',
}
```

### 6. Ejecutar la aplicación

```bash
python app.py
```

Abre tu navegador en: **http://localhost:5000**

---

## Estructura del proyecto

```
biblioapp/
├── app.py              ← rutas y controladores Flask
├── db.py               ← módulo de conexión a MySQL
├── schema.sql          ← script de base de datos (tablas + datos)
├── requirements.txt    ← dependencias Python
├── templates/
│   ├── base.html       ← layout base (navbar, footer)
│   ├── index.html      ← dashboard con estadísticas
│   ├── libros.html     ← gestión de libros
│   ├── socios.html     ← gestión de socios
│   └── prestamos.html  ← gestión de préstamos e historial
└── static/
    └── style.css       ← estilos personalizados
```

---

## Funcionalidades

| Módulo | Funcionalidad |
|---|---|
| Dashboard | Contadores en tiempo real: libros, socios, préstamos activos |
| Libros | Listar, agregar, eliminar (solo si no tiene préstamos activos) |
| Socios | Listar y registrar nuevos socios |
| Préstamos | Registrar préstamos, registrar devoluciones, ver historial completo |

---

## Tecnologías

- **Backend**: Python 3 + Flask 3.0
- **Base de datos**: MySQL 8.0 + mysql-connector-python
- **Frontend**: HTML5 + Bootstrap 5.3 + Jinja2
- **Lógica de negocio**: Stored Procedures en MySQL

---

## Notas

- La aplicación corre en modo `debug=True` — para producción cambiar a `False`.
- El campo `disponible` en la tabla `libro` se actualiza automáticamente vía stored procedures al registrar o devolver un préstamo.
- Los préstamos activos con más de 14 días se marcan en rojo en la interfaz.
