

PRAGMA foreign_keys = ON;

-- =========================
-- USUARIO LOCAL
-- =========================

CREATE TABLE Usuarios (
    UsuarioUuid TEXT PRIMARY KEY,
    Email TEXT,
    NombreMostrar TEXT,
    MonedaPreferida TEXT,
    ZonaHoraria TEXT,
    CreadoEn TEXT,
    ActualizadoEn TEXT
);

-- =========================
-- CONFIGURACION
-- =========================

CREATE TABLE ConfiguracionUsuario (
    ConfiguracionId INTEGER PRIMARY KEY AUTOINCREMENT,
    UsuarioUuid TEXT,
    Clave TEXT,
    Valor TEXT,
    FOREIGN KEY (UsuarioUuid) REFERENCES Usuarios(UsuarioUuid)
);

-- =========================
-- CATEGORIAS
-- =========================

CREATE TABLE CategoriasGasto (
    CategoriaUuid TEXT PRIMARY KEY,
    Nombre TEXT,
    Icono TEXT,
    CategoriaPadreUuid TEXT,
    EsSistema INTEGER,
    CreadoEn TEXT
);

-- =========================
-- METODOS DE PAGO
-- =========================

CREATE TABLE MetodosPago (
    MetodoPagoUuid TEXT PRIMARY KEY,
    Nombre TEXT,
    Icono TEXT
);

-- =========================
-- DISPOSITIVO
-- =========================

CREATE TABLE Dispositivo (
    DispositivoUuid TEXT PRIMARY KEY,
    Plataforma TEXT,
    Modelo TEXT,
    UltimaSincronizacion TEXT
);

-- =========================
-- GASTOS
-- =========================

CREATE TABLE Gastos (
    GastoUuid TEXT PRIMARY KEY,
    UsuarioUuid TEXT,
    CategoriaUuid TEXT,
    MetodoPagoUuid TEXT,
    Monto REAL,
    Moneda TEXT,
    Descripcion TEXT,
    FechaGasto TEXT,
    NombreLugar TEXT,
    Latitud REAL,
    Longitud REAL,
    CreadoEn TEXT,
    ActualizadoEn TEXT,
    Eliminado INTEGER DEFAULT 0,
    Sincronizado INTEGER DEFAULT 0,
    FOREIGN KEY (UsuarioUuid) REFERENCES Usuarios(UsuarioUuid),
    FOREIGN KEY (CategoriaUuid) REFERENCES CategoriasGasto(CategoriaUuid),
    FOREIGN KEY (MetodoPagoUuid) REFERENCES MetodosPago(MetodoPagoUuid)
);

-- =========================
-- PRESUPUESTOS
-- =========================

CREATE TABLE Presupuestos (
    PresupuestoUuid TEXT PRIMARY KEY,
    UsuarioUuid TEXT,
    CategoriaUuid TEXT,
    Monto REAL,
    TipoPeriodo TEXT,
    FechaInicio TEXT,
    FechaFin TEXT,
    CreadoEn TEXT,
    ActualizadoEn TEXT,
    Sincronizado INTEGER DEFAULT 0
);

-- =========================
-- METAS DE AHORRO
-- =========================

CREATE TABLE MetasAhorro (
    MetaUuid TEXT PRIMARY KEY,
    UsuarioUuid TEXT,
    Nombre TEXT,
    MontoObjetivo REAL,
    MontoActual REAL,
    Moneda TEXT,
    FechaObjetivo TEXT,
    CreadoEn TEXT,
    ActualizadoEn TEXT,
    Sincronizado INTEGER DEFAULT 0
);

-- =========================
-- APORTACIONES META
-- =========================

CREATE TABLE AportacionesMeta (
    AportacionUuid TEXT PRIMARY KEY,
    MetaUuid TEXT,
    Monto REAL,
    CreadoEn TEXT,
    Sincronizado INTEGER DEFAULT 0,
    FOREIGN KEY (MetaUuid) REFERENCES MetasAhorro(MetaUuid)
);

-- =========================
-- SUSCRIPCIONES
-- =========================

CREATE TABLE Suscripciones (
    SuscripcionUuid TEXT PRIMARY KEY,
    UsuarioUuid TEXT,
    Nombre TEXT,
    Monto REAL,
    Moneda TEXT,
    CicloFacturacion TEXT,
    FechaUltimoCargo TEXT,
    FechaProximoCargo TEXT,
    Activa INTEGER,
    CreadoEn TEXT,
    Sincronizado INTEGER DEFAULT 0
);

-- =========================
-- CACHE DE IA
-- =========================

CREATE TABLE InsightsIaCache (
    InsightUuid TEXT PRIMARY KEY,
    UsuarioUuid TEXT,
    TipoInsight TEXT,
    Titulo TEXT,
    Descripcion TEXT,
    PuntajeConfianza REAL,
    Leido INTEGER,
    CreadoEn TEXT
);

-- =========================
-- EVENTOS PENDIENTES
-- =========================

CREATE TABLE EventosPendientes (
    EventoUuid TEXT PRIMARY KEY,
    Entidad TEXT,
    EntidadUuid TEXT,
    TipoEvento TEXT,
    Payload TEXT,
    CreadoEn TEXT,
    Intentos INTEGER DEFAULT 0,
    Sincronizado INTEGER DEFAULT 0
);

-- =========================
-- VERSION DE DATOS
-- =========================

CREATE TABLE VersionDatos (
    VersionId INTEGER PRIMARY KEY AUTOINCREMENT,
    Entidad TEXT,
    VersionServidor INTEGER,
    ActualizadoEn TEXT
);

-- =========================
-- LOG LOCAL
-- =========================

CREATE TABLE LogLocal (
    LogId INTEGER PRIMARY KEY AUTOINCREMENT,
    Nivel TEXT,
    Mensaje TEXT,
    CreadoEn TEXT
);


CREATE INDEX IdxGastosUsuario
ON Gastos (UsuarioUuid);

CREATE INDEX IdxGastosFecha
ON Gastos (FechaGasto);

CREATE INDEX IdxGastosUsuarioFecha
ON Gastos (UsuarioUuid, FechaGasto);

CREATE INDEX IdxEventosPendientes
ON EventosPendientes (Sincronizado);

CREATE INDEX IdxPresupuestosUsuario
ON Presupuestos (UsuarioUuid);

CREATE INDEX IdxMetasUsuario
ON MetasAhorro (UsuarioUuid);