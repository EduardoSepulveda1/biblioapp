-- ── 1. CREAR Y SELECCIONAR LA BASE DE DATOS ─────────────────
DROP DATABASE IF EXISTS biblioapp;
CREATE DATABASE biblioapp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE biblioapp;

-- ── 2. TABLA: libro ─────────────────────────────────────────
CREATE TABLE libro (
  id_libro    INT           NOT NULL AUTO_INCREMENT,
  titulo      VARCHAR(200)  NOT NULL,
  autor       VARCHAR(150)  NOT NULL,
  anio        YEAR,
  isbn        VARCHAR(20)   UNIQUE,
  disponible  TINYINT(1)    NOT NULL DEFAULT 1,
  CONSTRAINT pk_libro PRIMARY KEY (id_libro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 3. TABLA: socio ─────────────────────────────────────────
CREATE TABLE socio (
  id_socio        INT           NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100)  NOT NULL,
  apellido        VARCHAR(100)  NOT NULL,
  email           VARCHAR(150)  NOT NULL UNIQUE,
  telefono        VARCHAR(20),
  fecha_registro  DATE          NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT pk_socio PRIMARY KEY (id_socio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. TABLA: prestamo ──────────────────────────────────────
CREATE TABLE prestamo (
  id_prestamo      INT   NOT NULL AUTO_INCREMENT,
  id_libro         INT   NOT NULL,
  id_socio         INT   NOT NULL,
  fecha_prestamo   DATE  NOT NULL DEFAULT (CURRENT_DATE),
  fecha_devolucion DATE,
  devuelto         TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT pk_prestamo  PRIMARY KEY (id_prestamo),
  CONSTRAINT fk_prest_libro
    FOREIGN KEY (id_libro)  REFERENCES libro(id_libro)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_prest_socio
    FOREIGN KEY (id_socio)  REFERENCES socio(id_socio)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 5. ÍNDICES ADICIONALES ───────────────────────────────────
CREATE INDEX idx_prestamo_libro  ON prestamo (id_libro);
CREATE INDEX idx_prestamo_socio  ON prestamo (id_socio);
CREATE INDEX idx_prestamo_estado ON prestamo (devuelto);
ALTER TABLE libro ADD FULLTEXT INDEX ft_titulo_autor (titulo, autor);

-- ── 6. DATOS DE PRUEBA – libros ─────────────────────────────
INSERT INTO libro (titulo, autor, anio, isbn, disponible) VALUES
  ('El nombre de la rosa',              'Umberto Eco',             1980, '978-84-350-0825-5', 1),
  ('Cien años de soledad',              'Gabriel García Márquez',  1967, '978-84-376-0494-7', 1),
  ('Don Quijote de la Mancha',          'Miguel de Cervantes',     1906, '978-84-670-5137-1', 1),
  ('1984',                              'George Orwell',           1949, '978-84-450-7695-3', 0),
  ('Rayuela',                           'Julio Cortázar',          1963, '978-84-376-0288-2', 1),
  ('La sombra del viento',              'Carlos Ruiz Zafón',       2001, '978-84-08-04364-3', 1),
  ('El principito',                     'Antoine de Saint-Exupéry',1943, '978-84-204-8318-2', 1),
  ('Ficciones',                         'Jorge Luis Borges',       1944, '978-84-206-8317-0', 0),
  ('Crimen y castigo',                  'Fiódor Dostoievski',      1966, '978-84-376-0269-1', 1),
  ('Harry Potter y la piedra filosofal','J. K. Rowling',           1997, '978-84-7888-117-7', 1);

-- ── 7. DATOS DE PRUEBA – socios ─────────────────────────────
INSERT INTO socio (nombre, apellido, email, telefono, fecha_registro) VALUES
  ('Ana',      'González', 'ana.gonzalez@email.cl',  '+56912345678', '2024-01-15'),
  ('Carlos',   'Martínez', 'carlos.mtz@email.cl',    '+56923456789', '2024-02-20'),
  ('Valentina','Rojas',    'v.rojas@correo.cl',       '+56934567890', '2024-03-10'),
  ('Felipe',   'Soto',     'felipe.soto@email.cl',   '+56945678901', '2024-04-05'),
  ('Daniela',  'Fuentes',  'daniela.f@correo.cl',    '+56956789012', '2024-05-18');

-- ── 8. DATOS DE PRUEBA – préstamos ──────────────────────────
INSERT INTO prestamo (id_libro, id_socio, fecha_prestamo, fecha_devolucion, devuelto) VALUES
  (1, 1, '2024-06-01', '2024-06-15', 1),
  (3, 2, '2024-06-10', '2024-06-25', 1),
  (7, 4, '2024-07-01', '2024-07-10', 1);

INSERT INTO prestamo (id_libro, id_socio, fecha_prestamo, fecha_devolucion, devuelto) VALUES
  (4, 3, '2024-08-01', NULL, 0),
  (8, 5, '2024-08-15', NULL, 0);

-- Sincronizar disponibilidad con préstamos activos
UPDATE libro SET disponible = 0 WHERE id_libro IN (4, 8);

-- ── 9. VISTAS ÚTILES ────────────────────────────────────────
CREATE OR REPLACE VIEW v_prestamos_activos AS
SELECT
  p.id_prestamo,
  CONCAT(s.nombre, ' ', s.apellido) AS socio,
  s.email,
  l.titulo,
  l.autor,
  p.fecha_prestamo,
  DATEDIFF(CURRENT_DATE, p.fecha_prestamo) AS dias_prestado
FROM prestamo p
JOIN libro  l ON l.id_libro = p.id_libro
JOIN socio  s ON s.id_socio = p.id_socio
WHERE p.devuelto = 0
ORDER BY p.fecha_prestamo;

CREATE OR REPLACE VIEW v_historial AS
SELECT
  p.id_prestamo,
  CONCAT(s.nombre, ' ', s.apellido) AS socio,
  l.titulo,
  p.fecha_prestamo,
  p.fecha_devolucion,
  IF(p.devuelto, 'Devuelto', 'Activo') AS estado
FROM prestamo p
JOIN libro  l ON l.id_libro = p.id_libro
JOIN socio  s ON s.id_socio = p.id_socio
ORDER BY p.fecha_prestamo DESC;

-- ── 10. PROCEDIMIENTOS ALMACENADOS ──────────────────────────
DELIMITER $$

CREATE PROCEDURE sp_registrar_prestamo(
  IN  p_id_libro INT,
  IN  p_id_socio INT,
  OUT p_resultado VARCHAR(100)
)
BEGIN
  DECLARE v_disponible TINYINT;
  SELECT disponible INTO v_disponible FROM libro WHERE id_libro = p_id_libro;
  IF v_disponible IS NULL THEN
    SET p_resultado = 'ERROR: libro no encontrado';
  ELSEIF v_disponible = 0 THEN
    SET p_resultado = 'ERROR: libro no disponible';
  ELSE
    INSERT INTO prestamo (id_libro, id_socio, fecha_prestamo, devuelto)
    VALUES (p_id_libro, p_id_socio, CURRENT_DATE, 0);
    UPDATE libro SET disponible = 0 WHERE id_libro = p_id_libro;
    SET p_resultado = CONCAT('OK: préstamo #', LAST_INSERT_ID(), ' creado');
  END IF;
END$$

CREATE PROCEDURE sp_devolver(
  IN  p_id_prestamo INT,
  OUT p_resultado   VARCHAR(100)
)
BEGIN
  DECLARE v_devuelto TINYINT;
  DECLARE v_id_libro INT;
  SELECT devuelto, id_libro INTO v_devuelto, v_id_libro
  FROM prestamo WHERE id_prestamo = p_id_prestamo;
  IF v_devuelto IS NULL THEN
    SET p_resultado = 'ERROR: préstamo no encontrado';
  ELSEIF v_devuelto = 1 THEN
    SET p_resultado = 'ERROR: préstamo ya devuelto';
  ELSE
    UPDATE prestamo SET devuelto = 1, fecha_devolucion = CURRENT_DATE
    WHERE id_prestamo = p_id_prestamo;
    UPDATE libro SET disponible = 1 WHERE id_libro = v_id_libro;
    SET p_resultado = 'OK: devolución registrada';
  END IF;
END$$

DELIMITER ;
