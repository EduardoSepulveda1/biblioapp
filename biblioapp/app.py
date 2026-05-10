from flask import Flask, render_template, request, redirect, url_for, flash
import db

app = Flask(__name__)
app.secret_key = 'biblioapp-2024'


# ────────────────────────────────────────────────────────────
# DASHBOARD
# ────────────────────────────────────────────────────────────
@app.route('/')
def index():
    conn   = db.get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT
            (SELECT COUNT(*) FROM libro)                       AS total_libros,
            (SELECT COUNT(*) FROM libro WHERE disponible = 1)  AS libros_disponibles,
            (SELECT COUNT(*) FROM socio)                       AS total_socios,
            (SELECT COUNT(*) FROM prestamo WHERE devuelto = 0) AS prestamos_activos
    """)
    stats = cursor.fetchone()
    cursor.close()
    conn.close()
    return render_template('index.html', stats=stats)


# ────────────────────────────────────────────────────────────
# LIBROS
# ────────────────────────────────────────────────────────────
@app.route('/libros')
def libros():
    conn   = db.get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM libro ORDER BY titulo")
    lista  = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('libros.html', libros=lista)


@app.route('/libros/agregar', methods=['POST'])
def agregar_libro():
    titulo = request.form['titulo']
    autor  = request.form['autor']
    anio   = request.form.get('anio') or None
    isbn   = request.form.get('isbn') or None

    conn   = db.get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO libro (titulo, autor, anio, isbn) VALUES (%s, %s, %s, %s)",
            (titulo, autor, anio, isbn)
        )
        conn.commit()
        flash('Libro agregado correctamente.', 'success')
    except Exception as e:
        flash(f'Error al agregar libro: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('libros'))


@app.route('/libros/eliminar/<int:id_libro>', methods=['POST'])
def eliminar_libro(id_libro):
    conn   = db.get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM libro WHERE id_libro = %s", (id_libro,))
        conn.commit()
        flash('Libro eliminado.', 'success')
    except Exception as e:
        flash(f'No se puede eliminar (puede tener préstamos): {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('libros'))


# ────────────────────────────────────────────────────────────
# SOCIOS
# ────────────────────────────────────────────────────────────
@app.route('/socios')
def socios():
    conn   = db.get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM socio ORDER BY apellido, nombre")
    lista  = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('socios.html', socios=lista)


@app.route('/socios/agregar', methods=['POST'])
def agregar_socio():
    nombre   = request.form['nombre']
    apellido = request.form['apellido']
    email    = request.form['email']
    telefono = request.form.get('telefono') or None

    conn   = db.get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO socio (nombre, apellido, email, telefono) VALUES (%s, %s, %s, %s)",
            (nombre, apellido, email, telefono)
        )
        conn.commit()
        flash('Socio registrado correctamente.', 'success')
    except Exception as e:
        flash(f'Error al registrar socio: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('socios'))


# ────────────────────────────────────────────────────────────
# PRÉSTAMOS
# ────────────────────────────────────────────────────────────
@app.route('/prestamos')
def prestamos():
    conn   = db.get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM v_prestamos_activos")
    activos = cursor.fetchall()

    cursor.execute("SELECT * FROM v_historial")
    historial = cursor.fetchall()

    cursor.execute("SELECT id_libro, titulo FROM libro WHERE disponible = 1 ORDER BY titulo")
    libros_disp = cursor.fetchall()

    cursor.execute("SELECT id_socio, nombre, apellido FROM socio ORDER BY apellido")
    lista_socios = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('prestamos.html',
                           activos=activos,
                           historial=historial,
                           libros_disponibles=libros_disp,
                           socios=lista_socios)


@app.route('/prestamos/registrar', methods=['POST'])
def registrar_prestamo():
    id_libro = int(request.form['id_libro'])
    id_socio = int(request.form['id_socio'])

    conn   = db.get_connection()
    cursor = conn.cursor()
    try:
        # Llama al stored procedure y captura el parámetro OUT
        cursor.execute(
            "CALL sp_registrar_prestamo(%s, %s, @res)",
            (id_libro, id_socio)
        )
        conn.commit()
        cursor.execute("SELECT @res")
        resultado = cursor.fetchone()[0]
        cat = 'success' if str(resultado).startswith('OK') else 'danger'
        flash(resultado, cat)
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('prestamos'))


@app.route('/prestamos/devolver/<int:id_prestamo>', methods=['POST'])
def devolver(id_prestamo):
    conn   = db.get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("CALL sp_devolver(%s, @res)", (id_prestamo,))
        conn.commit()
        cursor.execute("SELECT @res")
        resultado = cursor.fetchone()[0]
        cat = 'success' if str(resultado).startswith('OK') else 'danger'
        flash(resultado, cat)
    except Exception as e:
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('prestamos'))


if __name__ == '__main__':
    app.run(debug=True, port=5000)
