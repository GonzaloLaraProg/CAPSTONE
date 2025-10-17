-- ================================================
-- ACURED - BASE DE DATOS FINAL 2025
-- ================================================
-- Motor: PostgreSQL 13+
-- Autor: Equipo de Desarrollo ACURED
-- Versión: vFinal 2025-10
-- Descripción: Script limpio, normalizado y optimizado.

SET client_min_messages = WARNING;
SET search_path = public;

-- ================================================
-- BLOQUE 1: LIMPIEZA COMPLETA
-- ================================================
DROP TABLE IF EXISTS 
    foro_post,
    foro_tema,
    soporte_ticket,
    notificacion,
    curriculum_terapeuta,
    servicio_centro,
    interaccion_ia,
    transaccion_pago,
    suscripcion_usuario,
    plan_suscripcion,
    factura,
    pago,
    detalle_cita_tratamiento,
    cita,
    sesion_terapeutica,
    historial_medico,
    respuesta_formulario,
    campo_formulario,
    formulario,
    tratamiento,
    centro_medico,
    paciente,
    usuario_preferencia,
    usuario_credenciales,
    usuario,
    rol_usuario,
    metodo_pago,
    especialidad,
    certificacion,
    pais,
    auditoria
CASCADE;

-- ================================================
-- BLOQUE 2: CATÁLOGOS BASE
-- ================================================
CREATE TABLE rol_usuario (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE metodo_pago (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE especialidad (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE certificacion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    institucion VARCHAR(200),
    descripcion TEXT
);

CREATE TABLE pais (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    codigo_iso CHAR(3) NOT NULL UNIQUE
);
CREATE INDEX idx_pais_nombre ON pais(nombre);
CREATE INDEX idx_pais_codigo_iso ON pais(codigo_iso);

-- ================================================
-- BLOQUE 3: USUARIOS Y AUTENTICACIÓN
-- ================================================
CREATE TABLE usuario (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    apellido VARCHAR(150) NOT NULL,
    rut VARCHAR(20),
    email VARCHAR(200) UNIQUE NOT NULL,
    telefono VARCHAR(30),
    direccion VARCHAR(300),
    rol_id INT REFERENCES rol_usuario(id) ON DELETE SET NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);
CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_usuario_rol ON usuario(rol_id);

CREATE TABLE usuario_credenciales (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    hash_password VARCHAR(400) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);
CREATE INDEX idx_usuario_credenciales_usuario_id ON usuario_credenciales(usuario_id);

CREATE TABLE usuario_preferencia (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    idioma VARCHAR(10),
    tema VARCHAR(50),
    notificaciones BOOLEAN DEFAULT TRUE
);

-- ================================================
-- BLOQUE 4: MÓDULO CLÍNICO Y OPERATIVO
-- ================================================
CREATE TABLE paciente (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    fecha_nacimiento DATE,
    genero VARCHAR(20),
    observaciones TEXT
);
CREATE INDEX idx_paciente_usuario ON paciente(usuario_id);

CREATE TABLE centro_medico (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion VARCHAR(300),
    telefono VARCHAR(50),
    email VARCHAR(150),
    pais_id INT REFERENCES pais(id) ON DELETE SET NULL,
    sitio_web VARCHAR(250)
);
CREATE INDEX idx_centro_nombre ON centro_medico(nombre);

CREATE TABLE tratamiento (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    duracion_min INT,
    precio NUMERIC(12,2),
    especialidad_id INT REFERENCES especialidad(id) ON DELETE SET NULL
);
CREATE INDEX idx_tratamiento_nombre ON tratamiento(nombre);

CREATE TABLE cita (
    id SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES paciente(id) ON DELETE CASCADE,
    terapeuta_id INT REFERENCES usuario(id) ON DELETE SET NULL,
    centro_id INT REFERENCES centro_medico(id) ON DELETE SET NULL,
    fecha TIMESTAMP NOT NULL,
    estado VARCHAR(50) DEFAULT 'pendiente' CHECK (estado IN ('pendiente','confirmada','cancelada','completada')),
    motivo TEXT
);
CREATE INDEX idx_cita_paciente ON cita(paciente_id);
CREATE INDEX idx_cita_fecha ON cita(fecha);

CREATE TABLE detalle_cita_tratamiento (
    id SERIAL PRIMARY KEY,
    cita_id INT REFERENCES cita(id) ON DELETE CASCADE,
    tratamiento_id INT REFERENCES tratamiento(id) ON DELETE SET NULL,
    observacion TEXT
);

CREATE TABLE sesion_terapeutica (
    id SERIAL PRIMARY KEY,
    cita_id INT REFERENCES cita(id) ON DELETE CASCADE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notas TEXT
);

CREATE TABLE historial_medico (
    id SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES paciente(id) ON DELETE CASCADE,
    descripcion TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    url_archivo TEXT
);
CREATE INDEX idx_historial_paciente ON historial_medico(paciente_id);

CREATE TABLE formulario (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    tipo VARCHAR(100)
);

CREATE TABLE campo_formulario (
    id SERIAL PRIMARY KEY,
    formulario_id INT REFERENCES formulario(id) ON DELETE CASCADE,
    pregunta TEXT NOT NULL,
    tipo_campo VARCHAR(50),
    alternativas TEXT
);

CREATE TABLE respuesta_formulario (
    id SERIAL PRIMARY KEY,
    formulario_id INT REFERENCES formulario(id) ON DELETE CASCADE,
    paciente_id INT REFERENCES paciente(id) ON DELETE CASCADE,
    respuestas JSONB,
    fecha_respuesta TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_respuesta_paciente ON respuesta_formulario(paciente_id);

-- ================================================
-- BLOQUE 5: PAGOS, PLANES Y SUSCRIPCIONES
-- ================================================
CREATE TABLE pago (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE SET NULL,
    monto NUMERIC(12,2) NOT NULL,
    metodo_id INT REFERENCES metodo_pago(id) ON DELETE SET NULL,
    estado VARCHAR(50) DEFAULT 'pendiente' CHECK (estado IN ('pendiente','pagado','fallido','reembolsado')),
    comprobante_transferencia TEXT,
    metodo_detalle VARCHAR(100),
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_pago_usuario ON pago(usuario_id);

CREATE TABLE factura (
    id SERIAL PRIMARY KEY,
    pago_id INT REFERENCES pago(id) ON DELETE CASCADE,
    numero VARCHAR(50) UNIQUE,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto_total NUMERIC(12,2)
);
CREATE INDEX idx_factura_fecha ON factura(fecha_emision);

CREATE TABLE plan_suscripcion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(12,2) NOT NULL,
    duracion_dias INT NOT NULL
);

CREATE TABLE suscripcion_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    plan_id INT REFERENCES plan_suscripcion(id) ON DELETE CASCADE,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP,
    estado VARCHAR(50) DEFAULT 'activa' CHECK (estado IN ('activa','vencida','cancelada'))
);
CREATE INDEX idx_suscripcion_estado ON suscripcion_usuario(estado);

CREATE TABLE transaccion_pago (
    id SERIAL PRIMARY KEY,
    pago_id INT REFERENCES pago(id) ON DELETE CASCADE,
    referencia VARCHAR(150),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50)
);

-- ================================================
-- BLOQUE 6: EXTENSIONES FUNCIONALES
-- ================================================
CREATE TABLE servicio_centro (
    id SERIAL PRIMARY KEY,
    centro_id INT REFERENCES centro_medico(id) ON DELETE CASCADE,
    tratamiento_id INT REFERENCES tratamiento(id) ON DELETE CASCADE,
    disponible BOOLEAN DEFAULT TRUE,
    precio NUMERIC(12,2),
    duracion_min INT
);

CREATE TABLE curriculum_terapeuta (
    id SERIAL PRIMARY KEY,
    terapeuta_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    institucion VARCHAR(200),
    cargo VARCHAR(150),
    descripcion TEXT,
    fecha_inicio DATE,
    fecha_fin DATE
);

CREATE TABLE notificacion (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notificacion_usuario ON notificacion(usuario_id);

CREATE TABLE soporte_ticket (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE SET NULL,
    asunto VARCHAR(200),
    mensaje TEXT NOT NULL,
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta TIMESTAMP,
    respuesta TEXT
);

CREATE TABLE foro_tema (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    usuario_id INT REFERENCES usuario(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_foro_tema_usuario ON foro_tema(usuario_id);

CREATE TABLE foro_post (
    id SERIAL PRIMARY KEY,
    tema_id INT REFERENCES foro_tema(id) ON DELETE CASCADE,
    usuario_id INT REFERENCES usuario(id),
    contenido TEXT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_foro_post_tema ON foro_post(tema_id);

CREATE TABLE interaccion_ia (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuario(id) ON DELETE CASCADE,
    pregunta TEXT,
    respuesta TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- BLOQUE 7: AUDITORÍA
-- ================================================
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    tabla VARCHAR(100),
    operacion VARCHAR(50),
    usuario_id INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);