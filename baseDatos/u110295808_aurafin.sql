-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 09-03-2026 a las 19:10:09
-- Versión del servidor: 11.8.3-MariaDB-log
-- Versión de PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `u110295808_aurafin`
--

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `Sp_InicializarPresupuestoUsuario`$$
CREATE DEFINER=`u110295808_aurafin`@`127.0.0.1` PROCEDURE `Sp_InicializarPresupuestoUsuario` (IN `p_UsuarioId` BIGINT, IN `p_Anio` INT, IN `p_Mes` INT)   BEGIN
    DECLARE v_AnioPrev INT;
    DECLARE v_MesPrev INT;
    
    IF p_Mes = 1 THEN
        SET v_MesPrev = 12;
        SET v_AnioPrev = p_Anio - 1;
    ELSE
        SET v_MesPrev = p_Mes - 1;
        SET v_AnioPrev = p_Anio;
    END IF;

    INSERT IGNORE INTO Presupuestos (UsuarioId, CategoriaGastoId, Monto, MonedaId, Anio, Mes, TipoPeriodoId)
    SELECT 
        p_UsuarioId, 
        cat.CategoriaGastoId, 
        COALESCE(prev.Monto, 0.00), 
        COALESCE(prev.MonedaId, (SELECT MonedaPreferidaId FROM Usuarios WHERE UsuarioId = p_UsuarioId LIMIT 1), 1),
        p_Anio, 
        p_Mes, 
        1 
    FROM CategoriasGasto cat
    LEFT JOIN Presupuestos prev ON prev.UsuarioId = p_UsuarioId 
        AND prev.CategoriaGastoId = cat.CategoriaGastoId 
        AND prev.Anio = v_AnioPrev 
        AND prev.Mes = v_MesPrev
    WHERE cat.CategoriaPadreId IS NOT NULL 
      AND (cat.EsSistema = 1 OR cat.UsuarioId = p_UsuarioId);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `AportacionesMeta`
--

DROP TABLE IF EXISTS `AportacionesMeta`;
CREATE TABLE `AportacionesMeta` (
  `AportacionMetaId` bigint(20) NOT NULL,
  `MetaAhorroId` bigint(20) DEFAULT NULL,
  `Monto` decimal(12,2) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `CategoriasGasto`
--

DROP TABLE IF EXISTS `CategoriasGasto`;
CREATE TABLE `CategoriasGasto` (
  `CategoriaGastoId` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL,
  `Icono` varchar(100) DEFAULT NULL,
  `CategoriaPadreId` int(11) DEFAULT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `EsSistema` tinyint(1) DEFAULT 0,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `CategoriasGasto`
--

INSERT INTO `CategoriasGasto` (`CategoriaGastoId`, `Nombre`, `Icono`, `CategoriaPadreId`, `UsuarioId`, `EsSistema`, `CreadoEn`) VALUES
(1, 'CASA', 'home-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(2, 'SERVICIOS', 'flash-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(3, 'ALIMENTOS', 'restaurant-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(4, 'AUTOMÓVIL', 'car-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(5, 'ENTRETENIMIENTO', 'game-controller-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(6, 'VIAJES', 'airplane-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(7, 'PERSONALES', 'person-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(8, 'HIJOS', 'people-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(9, 'MASCOTAS', 'paw-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(10, 'SEGUROS', 'shield-checkmark-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(11, 'PRÉSTAMOS', 'cash-outline', NULL, NULL, 1, '2026-03-09 04:06:46'),
(12, 'Renta/Hipoteca', 'key-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(13, 'Mantenimiento', 'construct-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(14, 'Limpieza', 'water-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(15, 'Decoración', 'color-palette-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(16, 'Reparaciones', 'hammer-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(17, 'Jardinería', 'leaf-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(18, 'Otros CASA', 'ellipsis-horizontal-outline', 1, NULL, 1, '2026-03-09 04:06:46'),
(19, 'Gas', 'flame-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(20, 'Luz', 'bulb-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(21, 'Agua', 'water-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(22, 'Teléfono', 'call-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(23, 'Internet', 'wifi-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(24, 'Cable', 'tv-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(25, 'Tintorería', 'shirt-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(26, 'Otros SERVICIOS', 'ellipsis-horizontal-outline', 2, NULL, 1, '2026-03-09 04:06:46'),
(27, 'Supermercado', 'cart-outline', 3, NULL, 1, '2026-03-09 04:06:46'),
(28, 'Comidas Fuera', 'fast-food-outline', 3, NULL, 1, '2026-03-09 04:06:46'),
(29, 'Otros ALIMENTOS', 'ellipsis-horizontal-outline', 3, NULL, 1, '2026-03-09 04:06:46'),
(30, 'Gasolina', 'speedometer-outline', 4, NULL, 1, '2026-03-09 04:06:46'),
(31, 'Lavado', 'shiny-outline', 4, NULL, 1, '2026-03-09 04:06:46'),
(32, 'Mantenimiento AUTO', 'build-outline', 4, NULL, 1, '2026-03-09 04:06:46'),
(33, 'Estacionamiento', 'pin-outline', 4, NULL, 1, '2026-03-09 04:06:46'),
(34, 'Otros AUTO', 'ellipsis-horizontal-outline', 4, NULL, 1, '2026-03-09 04:06:46'),
(35, 'Cine / Estadio / Teatro', 'ticket-outline', 5, NULL, 1, '2026-03-09 04:06:46'),
(36, 'Música / Videojuegos', 'musical-notes-outline', 5, NULL, 1, '2026-03-09 04:06:46'),
(37, 'Descargas de Internet', 'download-outline', 5, NULL, 1, '2026-03-09 04:06:46'),
(38, 'Fiestas / Bar', 'wine-outline', 5, NULL, 1, '2026-03-09 04:06:46'),
(39, 'Otros ENTRETENIMIENTO', 'ellipsis-horizontal-outline', 5, NULL, 1, '2026-03-09 04:06:46'),
(40, 'Hotel', 'bed-outline', 6, NULL, 1, '2026-03-09 04:06:46'),
(41, 'Transporte VIAJE', 'bus-outline', 6, NULL, 1, '2026-03-09 04:06:46'),
(42, 'Comidas VIAJE', 'restaurant-outline', 6, NULL, 1, '2026-03-09 04:06:46'),
(43, 'Entretenimiento VIAJE', 'camera-outline', 6, NULL, 1, '2026-03-09 04:06:46'),
(44, 'Otros VIAJES', 'ellipsis-horizontal-outline', 6, NULL, 1, '2026-03-09 04:06:46'),
(45, 'Alimentos PERS', 'pizza-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(46, 'Ropa', 'shirt-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(47, 'Celular', 'phone-portrait-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(48, 'Salud (Médico / Farmacia)', 'medkit-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(49, 'Bienestar (Gym / Yoga)', 'fitness-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(50, 'Servicios (Estética / Uñas)', 'brush-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(51, 'Cosméticos', 'color-wand-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(52, 'Hobbies', 'heart-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(53, 'Otros PERSONALES', 'ellipsis-horizontal-outline', 7, NULL, 1, '2026-03-09 04:06:46'),
(54, 'Escuela', 'school-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(55, 'Dinero Extra', 'cash-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(56, 'Celular HIJOS', 'phone-portrait-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(57, 'Cuidado (Niñera)', 'people-circle-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(58, 'Libros / Útiles Escolares', 'book-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(59, 'Clases', 'library-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(60, 'Juguetes / Juegos', 'game-controller-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(61, 'Otros HIJOS', 'ellipsis-horizontal-outline', 8, NULL, 1, '2026-03-09 04:06:46'),
(62, 'Alimentos MASCOTAS', 'nutrition-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(63, 'Salud MASCOTAS', 'bandage-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(64, 'Juguetes MASCOTAS', 'football-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(65, 'Paseo', 'walk-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(66, 'Pensión', 'home-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(67, 'Otros MASCOTAS', 'ellipsis-horizontal-outline', 9, NULL, 1, '2026-03-09 04:06:46'),
(68, 'Seguro de Auto', 'car-sport-outline', 10, NULL, 1, '2026-03-09 04:06:46'),
(69, 'Seguro de Vivienda', 'business-outline', 10, NULL, 1, '2026-03-09 04:06:46'),
(70, 'Seguro de Vida', 'heart-half-outline', 10, NULL, 1, '2026-03-09 04:06:46'),
(71, 'Seguro de Gastos Médicos', 'pulse-outline', 10, NULL, 1, '2026-03-09 04:06:46'),
(72, 'Otros SEGUROS', 'ellipsis-horizontal-outline', 10, NULL, 1, '2026-03-09 04:06:46'),
(73, 'Hipoteca PREST', 'home-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(74, 'Mensualidad Auto', 'car-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(75, 'Tarjeta Crédito 1', 'card-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(76, 'Tarjeta Crédito 2', 'card-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(77, 'Préstamo 1', 'cash-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(78, 'Préstamo 2', 'cash-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(79, 'Otros PRÉSTAMOS', 'ellipsis-horizontal-outline', 11, NULL, 1, '2026-03-09 04:06:46'),
(80, 'Compras en linea', 'tag-outline', NULL, 8, 0, '2026-03-09 19:03:42');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `CiclosFacturacion`
--

DROP TABLE IF EXISTS `CiclosFacturacion`;
CREATE TABLE `CiclosFacturacion` (
  `CicloFacturacionId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `DispositivosUsuario`
--

DROP TABLE IF EXISTS `DispositivosUsuario`;
CREATE TABLE `DispositivosUsuario` (
  `DispositivoUsuarioId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `UuidDispositivo` varchar(120) DEFAULT NULL,
  `NombreDispositivo` varchar(120) DEFAULT NULL,
  `Plataforma` varchar(50) DEFAULT NULL,
  `UltimaSincronizacion` datetime DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `EstadosSincronizacion`
--

DROP TABLE IF EXISTS `EstadosSincronizacion`;
CREATE TABLE `EstadosSincronizacion` (
  `EstadoSincronizacionId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `EstadosUsuario`
--

DROP TABLE IF EXISTS `EstadosUsuario`;
CREATE TABLE `EstadosUsuario` (
  `EstadoUsuarioId` int(11) NOT NULL,
  `Nombre` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `EstadosUsuario`
--

INSERT INTO `EstadosUsuario` (`EstadoUsuarioId`, `Nombre`) VALUES
(1, 'Activo'),
(2, 'Inactivo'),
(3, 'Suspendido');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `EventosSincronizacion`
--

DROP TABLE IF EXISTS `EventosSincronizacion`;
CREATE TABLE `EventosSincronizacion` (
  `EventoSincronizacionId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `DispositivoUsuarioId` bigint(20) DEFAULT NULL,
  `NombreEntidad` varchar(100) DEFAULT NULL,
  `EntidadId` bigint(20) DEFAULT NULL,
  `TipoEventoId` int(11) DEFAULT NULL,
  `Payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`Payload`)),
  `CreadoEn` datetime DEFAULT current_timestamp(),
  `ProcesadoEn` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Gastos`
--

DROP TABLE IF EXISTS `Gastos`;
CREATE TABLE `Gastos` (
  `GastoId` bigint(20) NOT NULL,
  `IdentificadorLocal` varchar(100) DEFAULT NULL COMMENT 'ID generado por el celular para evitar duplicados',
  `UsuarioId` bigint(20) DEFAULT NULL,
  `CategoriaGastoId` int(11) DEFAULT NULL,
  `MetodoPagoId` int(11) DEFAULT NULL,
  `Monto` decimal(12,2) DEFAULT NULL,
  `MonedaId` int(11) DEFAULT NULL,
  `Descripcion` varchar(255) DEFAULT NULL,
  `FechaGasto` datetime DEFAULT NULL,
  `NombreLugar` varchar(150) DEFAULT NULL,
  `Latitud` decimal(10,6) DEFAULT NULL,
  `Longitud` decimal(10,6) DEFAULT NULL,
  `DispositivoUsuarioId` bigint(20) DEFAULT NULL,
  `EstadoSincronizacionId` int(11) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp(),
  `ActualizadoEn` datetime DEFAULT NULL,
  `EliminadoEn` datetime DEFAULT NULL,
  `Version` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Gastos`
--

INSERT INTO `Gastos` (`GastoId`, `IdentificadorLocal`, `UsuarioId`, `CategoriaGastoId`, `MetodoPagoId`, `Monto`, `MonedaId`, `Descripcion`, `FechaGasto`, `NombreLugar`, `Latitud`, `Longitud`, `DispositivoUsuarioId`, `EstadoSincronizacionId`, `CreadoEn`, `ActualizadoEn`, `EliminadoEn`, `Version`) VALUES
(1, NULL, 8, 28, NULL, 600.00, NULL, 'Desayuno en Maye Niñas y Esme', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 05:42:34', NULL, NULL, 1),
(2, NULL, 8, 30, NULL, 250.00, NULL, 'Gasolina', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 06:09:59', NULL, NULL, 1),
(3, NULL, 8, 42, NULL, 440.00, NULL, 'Tacos compostela ', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 06:31:48', NULL, NULL, 1),
(4, NULL, 8, 44, NULL, 250.00, NULL, 'Gasolina', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 06:37:24', NULL, NULL, 1),
(5, NULL, 9, 53, NULL, 12.00, NULL, 'Copias INE', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 16:44:46', '2026-03-09 19:01:01', NULL, 1),
(6, NULL, 8, 31, NULL, 145.00, NULL, 'Lavado en avenida rey nayar Tepic', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 16:51:01', '2026-03-09 17:01:14', NULL, 1),
(7, NULL, 8, 36, NULL, 130.00, NULL, 'compra soriana audífonos', '2026-03-08 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 17:08:16', NULL, NULL, 1),
(8, NULL, 8, 16, NULL, 200.00, NULL, 'xxx', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 17:08:35', '2026-03-09 17:08:41', '2026-03-09 17:08:50', 1),
(9, NULL, 9, 34, NULL, 1166.00, NULL, 'Licencia Manejo', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 19:01:28', NULL, NULL, 1),
(10, NULL, 9, 27, NULL, 88.00, NULL, 'Desayuno', '2026-03-09 00:00:00', NULL, NULL, NULL, NULL, NULL, '2026-03-09 19:02:32', NULL, NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Hogares`
--

DROP TABLE IF EXISTS `Hogares`;
CREATE TABLE `Hogares` (
  `HogarId` bigint(20) NOT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `UsuarioPropietarioId` bigint(20) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `InsightsIa`
--

DROP TABLE IF EXISTS `InsightsIa`;
CREATE TABLE `InsightsIa` (
  `InsightIaId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `TipoInsightId` int(11) DEFAULT NULL,
  `Titulo` varchar(200) DEFAULT NULL,
  `Descripcion` text DEFAULT NULL,
  `PuntajeConfianza` decimal(5,2) DEFAULT NULL,
  `Leido` tinyint(1) DEFAULT 0,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `LogsActividad`
--

DROP TABLE IF EXISTS `LogsActividad`;
CREATE TABLE `LogsActividad` (
  `LogActividadId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `TipoActividadId` int(11) DEFAULT NULL,
  `NombreEntidad` varchar(100) DEFAULT NULL,
  `EntidadId` bigint(20) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `MetasAhorro`
--

DROP TABLE IF EXISTS `MetasAhorro`;
CREATE TABLE `MetasAhorro` (
  `MetaAhorroId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `MontoObjetivo` decimal(12,2) DEFAULT NULL,
  `MontoActual` decimal(12,2) DEFAULT NULL,
  `MonedaId` int(11) DEFAULT NULL,
  `FechaObjetivo` date DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `MetodosPago`
--

DROP TABLE IF EXISTS `MetodosPago`;
CREATE TABLE `MetodosPago` (
  `MetodoPagoId` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL,
  `Icono` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `MiembrosHogar`
--

DROP TABLE IF EXISTS `MiembrosHogar`;
CREATE TABLE `MiembrosHogar` (
  `MiembroHogarId` bigint(20) NOT NULL,
  `HogarId` bigint(20) DEFAULT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `RolHogarId` int(11) DEFAULT NULL,
  `FechaIngreso` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Monedas`
--

DROP TABLE IF EXISTS `Monedas`;
CREATE TABLE `Monedas` (
  `MonedaId` int(11) NOT NULL,
  `Codigo` varchar(10) DEFAULT NULL,
  `Nombre` varchar(50) DEFAULT NULL,
  `Simbolo` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Monedas`
--

INSERT INTO `Monedas` (`MonedaId`, `Codigo`, `Nombre`, `Simbolo`) VALUES
(1, 'MXN', 'Peso Mexicano', '$'),
(2, 'USD', 'Dólar Estadounidense', '$'),
(3, 'EUR', 'Euro', '€');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `NivelesScore`
--

DROP TABLE IF EXISTS `NivelesScore`;
CREATE TABLE `NivelesScore` (
  `NivelScoreId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `PatronesGasto`
--

DROP TABLE IF EXISTS `PatronesGasto`;
CREATE TABLE `PatronesGasto` (
  `PatronGastoId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `TipoPatronGastoId` int(11) DEFAULT NULL,
  `Descripcion` text DEFAULT NULL,
  `PuntajeConfianza` decimal(5,2) DEFAULT NULL,
  `DetectadoEn` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `PerfilesFinancieros`
--

DROP TABLE IF EXISTS `PerfilesFinancieros`;
CREATE TABLE `PerfilesFinancieros` (
  `PerfilFinancieroId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `IngresoMensualEstimado` decimal(12,2) DEFAULT NULL,
  `PromedioGastosMensual` decimal(12,2) DEFAULT NULL,
  `TasaAhorro` decimal(6,2) DEFAULT NULL,
  `PuntajeRiesgo` int(11) DEFAULT NULL,
  `UltimoAnalisis` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `PlanesUsuario`
--

DROP TABLE IF EXISTS `PlanesUsuario`;
CREATE TABLE `PlanesUsuario` (
  `PlanUsuarioId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL,
  `PrecioMensual` decimal(10,2) DEFAULT NULL,
  `MaximoPresupuestos` int(11) DEFAULT NULL,
  `MaximoDispositivos` int(11) DEFAULT NULL,
  `LimiteInsightsIa` int(11) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `PlanesUsuario`
--

INSERT INTO `PlanesUsuario` (`PlanUsuarioId`, `Nombre`, `PrecioMensual`, `MaximoPresupuestos`, `MaximoDispositivos`, `LimiteInsightsIa`, `CreadoEn`) VALUES
(1, 'BÁSICO', 0.00, 3, 1, 10, '2026-03-07 07:39:07'),
(2, 'Premium', 9.99, 99, 5, 100, '2026-03-07 07:41:08');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Presupuestos`
--

DROP TABLE IF EXISTS `Presupuestos`;
CREATE TABLE `Presupuestos` (
  `PresupuestoId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `CategoriaGastoId` int(11) DEFAULT NULL,
  `Monto` decimal(12,2) DEFAULT NULL,
  `MonedaId` int(11) DEFAULT NULL,
  `Anio` int(11) DEFAULT NULL,
  `Mes` int(11) DEFAULT NULL,
  `TipoPeriodoId` int(11) DEFAULT NULL,
  `FechaInicio` date DEFAULT NULL,
  `FechaFin` date DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Presupuestos`
--

INSERT INTO `Presupuestos` (`PresupuestoId`, `UsuarioId`, `CategoriaGastoId`, `Monto`, `MonedaId`, `Anio`, `Mes`, `TipoPeriodoId`, `FechaInicio`, `FechaFin`, `CreadoEn`) VALUES
(1, 8, 12, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(2, 8, 13, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(3, 8, 14, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(4, 8, 15, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(5, 8, 16, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(6, 8, 17, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(7, 8, 18, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(8, 8, 19, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(9, 8, 20, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(10, 8, 21, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(11, 8, 22, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(12, 8, 23, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(13, 8, 24, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(14, 8, 25, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(15, 8, 26, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(18, 8, 29, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(20, 8, 31, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(21, 8, 32, 200.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(22, 8, 33, 50.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(23, 8, 34, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(24, 8, 35, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(25, 8, 36, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(26, 8, 37, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(27, 8, 38, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(28, 8, 39, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(29, 8, 40, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(30, 8, 41, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(31, 8, 42, 500.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(32, 8, 43, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(33, 8, 44, 300.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(34, 8, 45, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(35, 8, 46, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(36, 8, 47, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(37, 8, 48, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(38, 8, 49, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(39, 8, 50, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(40, 8, 51, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(41, 8, 52, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(42, 8, 53, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(43, 8, 54, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(44, 8, 55, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(45, 8, 56, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(46, 8, 57, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(47, 8, 58, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(48, 8, 59, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(49, 8, 60, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(50, 8, 61, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(51, 8, 62, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(52, 8, 63, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(53, 8, 64, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(54, 8, 65, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(55, 8, 66, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(56, 8, 67, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(57, 8, 68, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(58, 8, 69, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(59, 8, 70, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(60, 8, 71, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(61, 8, 72, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(62, 8, 73, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(63, 8, 74, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(64, 8, 75, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(65, 8, 76, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(66, 8, 77, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(67, 8, 78, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(68, 8, 79, 0.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 04:49:20'),
(130, 8, 28, 1200.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 05:07:55'),
(131, 8, 27, 2000.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 05:08:10'),
(132, 8, 30, 1200.00, NULL, 2026, 3, 1, NULL, NULL, '2026-03-09 05:15:12'),
(134, 8, 12, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(135, 8, 13, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(136, 8, 14, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(137, 8, 15, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(138, 8, 16, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(139, 8, 17, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(140, 8, 18, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(141, 8, 19, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(142, 8, 20, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(143, 8, 21, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(144, 8, 22, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(145, 8, 23, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(146, 8, 24, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(147, 8, 25, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(148, 8, 26, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(149, 8, 27, 2000.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(150, 8, 28, 1000.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(151, 8, 29, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(152, 8, 30, 1200.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(153, 8, 31, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(154, 8, 32, 200.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(155, 8, 33, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(156, 8, 34, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(157, 8, 35, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(158, 8, 36, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(159, 8, 37, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(160, 8, 38, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(161, 8, 39, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(162, 8, 40, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(163, 8, 41, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(164, 8, 42, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(165, 8, 43, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(166, 8, 44, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(167, 8, 45, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(168, 8, 46, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(169, 8, 47, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(170, 8, 48, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(171, 8, 49, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(172, 8, 50, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(173, 8, 51, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(174, 8, 52, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(175, 8, 53, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(176, 8, 54, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(177, 8, 55, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(178, 8, 56, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(179, 8, 57, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(180, 8, 58, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(181, 8, 59, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(182, 8, 60, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(183, 8, 61, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(184, 8, 62, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(185, 8, 63, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(186, 8, 64, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(187, 8, 65, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(188, 8, 66, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(189, 8, 67, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(190, 8, 68, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(191, 8, 69, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(192, 8, 70, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(193, 8, 71, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(194, 8, 72, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(195, 8, 73, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(196, 8, 74, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(197, 8, 75, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(198, 8, 76, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(199, 8, 77, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(200, 8, 78, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(201, 8, 79, 0.00, 1, 2026, 4, 1, NULL, NULL, '2026-03-09 05:36:45'),
(262, 8, 12, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(263, 8, 13, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(264, 8, 14, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(265, 8, 15, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(266, 8, 16, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(267, 8, 17, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(268, 8, 18, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(269, 8, 19, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(270, 8, 20, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(271, 8, 21, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(272, 8, 22, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(273, 8, 23, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(274, 8, 24, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(275, 8, 25, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(276, 8, 26, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(277, 8, 27, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(278, 8, 28, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(279, 8, 29, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(280, 8, 30, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(281, 8, 31, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(282, 8, 32, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(283, 8, 33, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(284, 8, 34, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(285, 8, 35, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(286, 8, 36, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(287, 8, 37, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(288, 8, 38, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(289, 8, 39, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(290, 8, 40, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(291, 8, 41, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(292, 8, 42, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(293, 8, 43, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(294, 8, 44, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(295, 8, 45, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(296, 8, 46, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(297, 8, 47, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(298, 8, 48, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(299, 8, 49, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(300, 8, 50, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(301, 8, 51, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(302, 8, 52, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(303, 8, 53, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(304, 8, 54, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(305, 8, 55, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(306, 8, 56, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(307, 8, 57, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(308, 8, 58, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(309, 8, 59, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(310, 8, 60, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(311, 8, 61, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(312, 8, 62, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(313, 8, 63, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(314, 8, 64, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(315, 8, 65, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(316, 8, 66, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(317, 8, 67, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(318, 8, 68, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(319, 8, 69, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(320, 8, 70, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(321, 8, 71, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(322, 8, 72, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(323, 8, 73, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(324, 8, 74, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(325, 8, 75, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(326, 8, 76, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(327, 8, 77, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(328, 8, 78, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(329, 8, 79, 0.00, 1, 2026, 1, 1, NULL, NULL, '2026-03-09 06:19:30'),
(389, 8, 12, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(390, 8, 13, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(391, 8, 14, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(392, 8, 15, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(393, 8, 16, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(394, 8, 17, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(395, 8, 18, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(396, 8, 19, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(397, 8, 20, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(398, 8, 21, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(399, 8, 22, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(400, 8, 23, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(401, 8, 24, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(402, 8, 25, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(403, 8, 26, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(404, 8, 27, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(405, 8, 28, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(406, 8, 29, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(407, 8, 30, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(408, 8, 31, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(409, 8, 32, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(410, 8, 33, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(411, 8, 34, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(412, 8, 35, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(413, 8, 36, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(414, 8, 37, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(415, 8, 38, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(416, 8, 39, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(417, 8, 40, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(418, 8, 41, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(419, 8, 42, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(420, 8, 43, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(421, 8, 44, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(422, 8, 45, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(423, 8, 46, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(424, 8, 47, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(425, 8, 48, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(426, 8, 49, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(427, 8, 50, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(428, 8, 51, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(429, 8, 52, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(430, 8, 53, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(431, 8, 54, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(432, 8, 55, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(433, 8, 56, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(434, 8, 57, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(435, 8, 58, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(436, 8, 59, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(437, 8, 60, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(438, 8, 61, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(439, 8, 62, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(440, 8, 63, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(441, 8, 64, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(442, 8, 65, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(443, 8, 66, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(444, 8, 67, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(445, 8, 68, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(446, 8, 69, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(447, 8, 70, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(448, 8, 71, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(449, 8, 72, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(450, 8, 73, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(451, 8, 74, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(452, 8, 75, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(453, 8, 76, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(454, 8, 77, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(455, 8, 78, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(456, 8, 79, 0.00, 1, 2026, 2, 1, NULL, NULL, '2026-03-09 06:19:33'),
(518, 9, 12, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(519, 9, 13, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(520, 9, 14, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(521, 9, 15, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(522, 9, 16, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(523, 9, 17, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(524, 9, 18, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(525, 9, 19, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(526, 9, 20, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(527, 9, 21, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(528, 9, 22, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(529, 9, 23, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(530, 9, 24, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(531, 9, 25, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(532, 9, 26, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(533, 9, 27, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(534, 9, 28, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(535, 9, 29, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(536, 9, 30, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(537, 9, 31, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(538, 9, 32, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(539, 9, 33, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(540, 9, 34, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(541, 9, 35, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(542, 9, 36, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(543, 9, 37, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(544, 9, 38, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(545, 9, 39, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(546, 9, 40, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(547, 9, 41, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(548, 9, 42, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(549, 9, 43, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(550, 9, 44, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(551, 9, 45, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(552, 9, 46, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(553, 9, 47, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(554, 9, 48, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(555, 9, 49, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(556, 9, 50, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(557, 9, 51, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(558, 9, 52, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(559, 9, 53, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(560, 9, 54, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(561, 9, 55, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(562, 9, 56, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(563, 9, 57, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(564, 9, 58, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(565, 9, 59, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(566, 9, 60, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(567, 9, 61, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(568, 9, 62, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(569, 9, 63, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(570, 9, 64, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(571, 9, 65, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(572, 9, 66, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(573, 9, 67, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(574, 9, 68, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(575, 9, 69, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(576, 9, 70, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(577, 9, 71, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(578, 9, 72, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(579, 9, 73, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(580, 9, 74, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(581, 9, 75, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(582, 9, 76, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(583, 9, 77, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(584, 9, 78, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57'),
(585, 9, 79, 0.00, 1, 2026, 3, 1, NULL, NULL, '2026-03-09 16:43:57');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Retos`
--

DROP TABLE IF EXISTS `Retos`;
CREATE TABLE `Retos` (
  `RetoId` int(11) NOT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `Descripcion` text DEFAULT NULL,
  `PuntosRecompensa` int(11) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `RetosUsuario`
--

DROP TABLE IF EXISTS `RetosUsuario`;
CREATE TABLE `RetosUsuario` (
  `RetoUsuarioId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `RetoId` int(11) DEFAULT NULL,
  `Progreso` int(11) DEFAULT NULL,
  `CompletadoEn` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `RolesHogar`
--

DROP TABLE IF EXISTS `RolesHogar`;
CREATE TABLE `RolesHogar` (
  `RolHogarId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ScoresFinancieros`
--

DROP TABLE IF EXISTS `ScoresFinancieros`;
CREATE TABLE `ScoresFinancieros` (
  `ScoreFinancieroId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `Score` int(11) DEFAULT NULL,
  `NivelScoreId` int(11) DEFAULT NULL,
  `CalculadoEn` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Sincronizaciones`
--

DROP TABLE IF EXISTS `Sincronizaciones`;
CREATE TABLE `Sincronizaciones` (
  `SincronizacionId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) NOT NULL,
  `Dispositivo` varchar(100) DEFAULT NULL,
  `UltimaSincronizacion` datetime DEFAULT NULL,
  `Resultado` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Suscripciones`
--

DROP TABLE IF EXISTS `Suscripciones`;
CREATE TABLE `Suscripciones` (
  `SuscripcionId` bigint(20) NOT NULL,
  `UsuarioId` bigint(20) DEFAULT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `Monto` decimal(12,2) DEFAULT NULL,
  `MonedaId` int(11) DEFAULT NULL,
  `CicloFacturacionId` int(11) DEFAULT NULL,
  `FechaUltimoCargo` date DEFAULT NULL,
  `FechaProximoCargo` date DEFAULT NULL,
  `Activa` tinyint(1) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `TiposActividad`
--

DROP TABLE IF EXISTS `TiposActividad`;
CREATE TABLE `TiposActividad` (
  `TipoActividadId` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `TiposEvento`
--

DROP TABLE IF EXISTS `TiposEvento`;
CREATE TABLE `TiposEvento` (
  `TipoEventoId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `TiposInsight`
--

DROP TABLE IF EXISTS `TiposInsight`;
CREATE TABLE `TiposInsight` (
  `TipoInsightId` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `TiposPatronGasto`
--

DROP TABLE IF EXISTS `TiposPatronGasto`;
CREATE TABLE `TiposPatronGasto` (
  `TipoPatronGastoId` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `TiposPeriodo`
--

DROP TABLE IF EXISTS `TiposPeriodo`;
CREATE TABLE `TiposPeriodo` (
  `TipoPeriodoId` int(11) NOT NULL,
  `Nombre` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `TiposPeriodo`
--

INSERT INTO `TiposPeriodo` (`TipoPeriodoId`, `Nombre`) VALUES
(1, 'Mensual'),
(2, 'Anual'),
(3, 'Semanal'),
(4, 'Quincenal');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Usuarios`
--

DROP TABLE IF EXISTS `Usuarios`;
CREATE TABLE `Usuarios` (
  `UsuarioId` bigint(20) NOT NULL,
  `Email` varchar(150) DEFAULT NULL,
  `PasswordHash` varchar(255) DEFAULT NULL,
  `NombreMostrar` varchar(120) DEFAULT NULL,
  `EstadoUsuarioId` int(11) DEFAULT NULL,
  `PlanUsuarioId` int(11) DEFAULT NULL,
  `MonedaPreferidaId` int(11) DEFAULT NULL,
  `ZonaHoraria` varchar(80) DEFAULT NULL,
  `CreadoEn` datetime DEFAULT current_timestamp(),
  `UltimoLogin` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `Usuarios`
--

INSERT INTO `Usuarios` (`UsuarioId`, `Email`, `PasswordHash`, `NombreMostrar`, `EstadoUsuarioId`, `PlanUsuarioId`, `MonedaPreferidaId`, `ZonaHoraria`, `CreadoEn`, `UltimoLogin`) VALUES
(7, 'juan@cloud.com', '$2y$10$ay7SRwE2QpxsMfP7yocWMO3qynjFgINNSqL1HkyJwsS6lV3ZjazOC', 'Juan Carlos', 1, 1, NULL, NULL, '2026-03-07 07:41:16', '2026-03-07 07:42:49'),
(8, 'jramez@gmail.com', '$2y$10$c.ApqNapqkzlm0voSrE35eO8qwFc/O.H4.R6KE8uiFURacrdFjIuW', 'Jesus Ramirez Meza', 1, 1, NULL, NULL, '2026-03-09 04:49:20', '2026-03-09 16:36:35'),
(9, 'juanjosetorresj@gmail.com', '$2y$10$4mDF3xhzYtO5C.aEOl0oLOcczubmuQLEjEj.zmNXeZ0n6Ci1eqDXS', 'Juan José Torres Jáuregui ', 1, 1, NULL, NULL, '2026-03-09 16:43:56', '2026-03-09 19:05:09');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `Vista_ComparativoPresupuesto`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `Vista_ComparativoPresupuesto`;
CREATE TABLE `Vista_ComparativoPresupuesto` (
`UsuarioId` bigint(20)
,`Anio` int(11)
,`Mes` int(11)
,`CategoriaGastoId` int(11)
,`SeccionId` int(11)
,`Seccion` varchar(100)
,`Categoria` varchar(100)
,`Presupuestado` decimal(12,2)
,`Real_Gastado` decimal(34,2)
,`Diferencia` decimal(35,2)
,`Porcentaje_Ejecucion` decimal(43,6)
);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `AportacionesMeta`
--
ALTER TABLE `AportacionesMeta`
  ADD PRIMARY KEY (`AportacionMetaId`),
  ADD KEY `IdxAportacionesMeta` (`MetaAhorroId`);

--
-- Indices de la tabla `CategoriasGasto`
--
ALTER TABLE `CategoriasGasto`
  ADD PRIMARY KEY (`CategoriaGastoId`),
  ADD KEY `CategoriaPadreId` (`CategoriaPadreId`);

--
-- Indices de la tabla `CiclosFacturacion`
--
ALTER TABLE `CiclosFacturacion`
  ADD PRIMARY KEY (`CicloFacturacionId`);

--
-- Indices de la tabla `DispositivosUsuario`
--
ALTER TABLE `DispositivosUsuario`
  ADD PRIMARY KEY (`DispositivoUsuarioId`),
  ADD KEY `IdxDispositivosUsuario` (`UsuarioId`),
  ADD KEY `IdxDispositivosUuid` (`UuidDispositivo`);

--
-- Indices de la tabla `EstadosSincronizacion`
--
ALTER TABLE `EstadosSincronizacion`
  ADD PRIMARY KEY (`EstadoSincronizacionId`);

--
-- Indices de la tabla `EstadosUsuario`
--
ALTER TABLE `EstadosUsuario`
  ADD PRIMARY KEY (`EstadoUsuarioId`);

--
-- Indices de la tabla `EventosSincronizacion`
--
ALTER TABLE `EventosSincronizacion`
  ADD PRIMARY KEY (`EventoSincronizacionId`),
  ADD KEY `IdxEventosUsuario` (`UsuarioId`),
  ADD KEY `IdxEventosDispositivo` (`DispositivoUsuarioId`),
  ADD KEY `IdxEventosEntidad` (`NombreEntidad`,`EntidadId`),
  ADD KEY `IdxEventosTipo` (`TipoEventoId`),
  ADD KEY `IdxEventosCreado` (`CreadoEn`);

--
-- Indices de la tabla `Gastos`
--
ALTER TABLE `Gastos`
  ADD PRIMARY KEY (`GastoId`),
  ADD KEY `IdxGastosUsuario` (`UsuarioId`),
  ADD KEY `IdxGastosUsuarioFecha` (`UsuarioId`,`FechaGasto`),
  ADD KEY `IdxGastosUsuarioCategoria` (`UsuarioId`,`CategoriaGastoId`),
  ADD KEY `IdxGastosCategoria` (`CategoriaGastoId`),
  ADD KEY `IdxGastosMetodoPago` (`MetodoPagoId`),
  ADD KEY `IdxGastosMoneda` (`MonedaId`),
  ADD KEY `IdxGastosDispositivo` (`DispositivoUsuarioId`),
  ADD KEY `IdxGastosSincronizacion` (`EstadoSincronizacionId`),
  ADD KEY `IdxGastosFecha` (`FechaGasto`),
  ADD KEY `IdxGastosUsuarioFechaCategoria` (`UsuarioId`,`FechaGasto`,`CategoriaGastoId`),
  ADD KEY `IdxGastosEliminado` (`EliminadoEn`);

--
-- Indices de la tabla `Hogares`
--
ALTER TABLE `Hogares`
  ADD PRIMARY KEY (`HogarId`),
  ADD KEY `IdxHogaresPropietario` (`UsuarioPropietarioId`);

--
-- Indices de la tabla `InsightsIa`
--
ALTER TABLE `InsightsIa`
  ADD PRIMARY KEY (`InsightIaId`),
  ADD KEY `IdxInsightsUsuario` (`UsuarioId`),
  ADD KEY `IdxInsightsTipo` (`TipoInsightId`),
  ADD KEY `IdxInsightsUsuarioLeido` (`UsuarioId`,`Leido`),
  ADD KEY `IdxInsightsCreado` (`CreadoEn`);

--
-- Indices de la tabla `LogsActividad`
--
ALTER TABLE `LogsActividad`
  ADD PRIMARY KEY (`LogActividadId`),
  ADD KEY `IdxLogsUsuario` (`UsuarioId`),
  ADD KEY `IdxLogsTipo` (`TipoActividadId`),
  ADD KEY `IdxLogsEntidad` (`NombreEntidad`,`EntidadId`),
  ADD KEY `IdxLogsFecha` (`CreadoEn`);

--
-- Indices de la tabla `MetasAhorro`
--
ALTER TABLE `MetasAhorro`
  ADD PRIMARY KEY (`MetaAhorroId`),
  ADD KEY `MonedaId` (`MonedaId`),
  ADD KEY `IdxMetasUsuario` (`UsuarioId`);

--
-- Indices de la tabla `MetodosPago`
--
ALTER TABLE `MetodosPago`
  ADD PRIMARY KEY (`MetodoPagoId`);

--
-- Indices de la tabla `MiembrosHogar`
--
ALTER TABLE `MiembrosHogar`
  ADD PRIMARY KEY (`MiembroHogarId`),
  ADD KEY `RolHogarId` (`RolHogarId`),
  ADD KEY `IdxMiembrosHogar` (`HogarId`),
  ADD KEY `IdxMiembrosUsuario` (`UsuarioId`);

--
-- Indices de la tabla `Monedas`
--
ALTER TABLE `Monedas`
  ADD PRIMARY KEY (`MonedaId`);

--
-- Indices de la tabla `NivelesScore`
--
ALTER TABLE `NivelesScore`
  ADD PRIMARY KEY (`NivelScoreId`);

--
-- Indices de la tabla `PatronesGasto`
--
ALTER TABLE `PatronesGasto`
  ADD PRIMARY KEY (`PatronGastoId`),
  ADD KEY `IdxPatronesUsuario` (`UsuarioId`),
  ADD KEY `IdxPatronesTipo` (`TipoPatronGastoId`);

--
-- Indices de la tabla `PerfilesFinancieros`
--
ALTER TABLE `PerfilesFinancieros`
  ADD PRIMARY KEY (`PerfilFinancieroId`),
  ADD UNIQUE KEY `IdxPerfilUsuario` (`UsuarioId`);

--
-- Indices de la tabla `PlanesUsuario`
--
ALTER TABLE `PlanesUsuario`
  ADD PRIMARY KEY (`PlanUsuarioId`);

--
-- Indices de la tabla `Presupuestos`
--
ALTER TABLE `Presupuestos`
  ADD PRIMARY KEY (`PresupuestoId`),
  ADD UNIQUE KEY `Idx_Presupuesto_Unico` (`UsuarioId`,`CategoriaGastoId`,`Anio`,`Mes`),
  ADD KEY `MonedaId` (`MonedaId`),
  ADD KEY `IdxPresupuestosUsuario` (`UsuarioId`),
  ADD KEY `IdxPresupuestosCategoria` (`CategoriaGastoId`),
  ADD KEY `IdxPresupuestosPeriodo` (`TipoPeriodoId`),
  ADD KEY `IdxPresupuestosUsuarioCategoria` (`UsuarioId`,`CategoriaGastoId`);

--
-- Indices de la tabla `Retos`
--
ALTER TABLE `Retos`
  ADD PRIMARY KEY (`RetoId`);

--
-- Indices de la tabla `RetosUsuario`
--
ALTER TABLE `RetosUsuario`
  ADD PRIMARY KEY (`RetoUsuarioId`),
  ADD KEY `IdxRetosUsuario` (`UsuarioId`),
  ADD KEY `IdxRetosReto` (`RetoId`);

--
-- Indices de la tabla `RolesHogar`
--
ALTER TABLE `RolesHogar`
  ADD PRIMARY KEY (`RolHogarId`);

--
-- Indices de la tabla `ScoresFinancieros`
--
ALTER TABLE `ScoresFinancieros`
  ADD PRIMARY KEY (`ScoreFinancieroId`),
  ADD KEY `IdxScoreUsuario` (`UsuarioId`),
  ADD KEY `IdxScoreNivel` (`NivelScoreId`);

--
-- Indices de la tabla `Sincronizaciones`
--
ALTER TABLE `Sincronizaciones`
  ADD PRIMARY KEY (`SincronizacionId`),
  ADD KEY `UsuarioId` (`UsuarioId`);

--
-- Indices de la tabla `Suscripciones`
--
ALTER TABLE `Suscripciones`
  ADD PRIMARY KEY (`SuscripcionId`),
  ADD KEY `MonedaId` (`MonedaId`),
  ADD KEY `IdxSuscripcionesUsuario` (`UsuarioId`),
  ADD KEY `IdxSuscripcionesProximoCargo` (`FechaProximoCargo`),
  ADD KEY `IdxSuscripcionesCiclo` (`CicloFacturacionId`);

--
-- Indices de la tabla `TiposActividad`
--
ALTER TABLE `TiposActividad`
  ADD PRIMARY KEY (`TipoActividadId`);

--
-- Indices de la tabla `TiposEvento`
--
ALTER TABLE `TiposEvento`
  ADD PRIMARY KEY (`TipoEventoId`);

--
-- Indices de la tabla `TiposInsight`
--
ALTER TABLE `TiposInsight`
  ADD PRIMARY KEY (`TipoInsightId`);

--
-- Indices de la tabla `TiposPatronGasto`
--
ALTER TABLE `TiposPatronGasto`
  ADD PRIMARY KEY (`TipoPatronGastoId`);

--
-- Indices de la tabla `TiposPeriodo`
--
ALTER TABLE `TiposPeriodo`
  ADD PRIMARY KEY (`TipoPeriodoId`);

--
-- Indices de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  ADD PRIMARY KEY (`UsuarioId`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD KEY `MonedaPreferidaId` (`MonedaPreferidaId`),
  ADD KEY `IdxUsuariosEmail` (`Email`),
  ADD KEY `IdxUsuariosPlan` (`PlanUsuarioId`),
  ADD KEY `IdxUsuariosEstado` (`EstadoUsuarioId`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `AportacionesMeta`
--
ALTER TABLE `AportacionesMeta`
  MODIFY `AportacionMetaId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `CategoriasGasto`
--
ALTER TABLE `CategoriasGasto`
  MODIFY `CategoriaGastoId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT de la tabla `CiclosFacturacion`
--
ALTER TABLE `CiclosFacturacion`
  MODIFY `CicloFacturacionId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `DispositivosUsuario`
--
ALTER TABLE `DispositivosUsuario`
  MODIFY `DispositivoUsuarioId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `EstadosSincronizacion`
--
ALTER TABLE `EstadosSincronizacion`
  MODIFY `EstadoSincronizacionId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `EstadosUsuario`
--
ALTER TABLE `EstadosUsuario`
  MODIFY `EstadoUsuarioId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `EventosSincronizacion`
--
ALTER TABLE `EventosSincronizacion`
  MODIFY `EventoSincronizacionId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `Gastos`
--
ALTER TABLE `Gastos`
  MODIFY `GastoId` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `Hogares`
--
ALTER TABLE `Hogares`
  MODIFY `HogarId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `InsightsIa`
--
ALTER TABLE `InsightsIa`
  MODIFY `InsightIaId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `LogsActividad`
--
ALTER TABLE `LogsActividad`
  MODIFY `LogActividadId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `MetasAhorro`
--
ALTER TABLE `MetasAhorro`
  MODIFY `MetaAhorroId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `MetodosPago`
--
ALTER TABLE `MetodosPago`
  MODIFY `MetodoPagoId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `MiembrosHogar`
--
ALTER TABLE `MiembrosHogar`
  MODIFY `MiembroHogarId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `Monedas`
--
ALTER TABLE `Monedas`
  MODIFY `MonedaId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `NivelesScore`
--
ALTER TABLE `NivelesScore`
  MODIFY `NivelScoreId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `PatronesGasto`
--
ALTER TABLE `PatronesGasto`
  MODIFY `PatronGastoId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `PerfilesFinancieros`
--
ALTER TABLE `PerfilesFinancieros`
  MODIFY `PerfilFinancieroId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `PlanesUsuario`
--
ALTER TABLE `PlanesUsuario`
  MODIFY `PlanUsuarioId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `Presupuestos`
--
ALTER TABLE `Presupuestos`
  MODIFY `PresupuestoId` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=646;

--
-- AUTO_INCREMENT de la tabla `Retos`
--
ALTER TABLE `Retos`
  MODIFY `RetoId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `RetosUsuario`
--
ALTER TABLE `RetosUsuario`
  MODIFY `RetoUsuarioId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `RolesHogar`
--
ALTER TABLE `RolesHogar`
  MODIFY `RolHogarId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `ScoresFinancieros`
--
ALTER TABLE `ScoresFinancieros`
  MODIFY `ScoreFinancieroId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `Sincronizaciones`
--
ALTER TABLE `Sincronizaciones`
  MODIFY `SincronizacionId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `Suscripciones`
--
ALTER TABLE `Suscripciones`
  MODIFY `SuscripcionId` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `TiposActividad`
--
ALTER TABLE `TiposActividad`
  MODIFY `TipoActividadId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `TiposEvento`
--
ALTER TABLE `TiposEvento`
  MODIFY `TipoEventoId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `TiposInsight`
--
ALTER TABLE `TiposInsight`
  MODIFY `TipoInsightId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `TiposPatronGasto`
--
ALTER TABLE `TiposPatronGasto`
  MODIFY `TipoPatronGastoId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `TiposPeriodo`
--
ALTER TABLE `TiposPeriodo`
  MODIFY `TipoPeriodoId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  MODIFY `UsuarioId` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

-- --------------------------------------------------------

--
-- Estructura para la vista `Vista_ComparativoPresupuesto`
--
DROP TABLE IF EXISTS `Vista_ComparativoPresupuesto`;

DROP VIEW IF EXISTS `Vista_ComparativoPresupuesto`;
CREATE ALGORITHM=UNDEFINED DEFINER=`u110295808_aurafin`@`127.0.0.1` SQL SECURITY DEFINER VIEW `Vista_ComparativoPresupuesto`  AS SELECT `p`.`UsuarioId` AS `UsuarioId`, `p`.`Anio` AS `Anio`, `p`.`Mes` AS `Mes`, `cat`.`CategoriaGastoId` AS `CategoriaGastoId`, `sec`.`CategoriaGastoId` AS `SeccionId`, `sec`.`Nombre` AS `Seccion`, `cat`.`Nombre` AS `Categoria`, `p`.`Monto` AS `Presupuestado`, coalesce(sum(`g`.`Monto`),0) AS `Real_Gastado`, `p`.`Monto`- coalesce(sum(`g`.`Monto`),0) AS `Diferencia`, CASE WHEN `p`.`Monto` = 0 THEN 0 ELSE coalesce(sum(`g`.`Monto`),0) / `p`.`Monto` * 100 END AS `Porcentaje_Ejecucion` FROM (((`Presupuestos` `p` join `CategoriasGasto` `cat` on(`p`.`CategoriaGastoId` = `cat`.`CategoriaGastoId`)) join `CategoriasGasto` `sec` on(`cat`.`CategoriaPadreId` = `sec`.`CategoriaGastoId`)) left join `Gastos` `g` on(`p`.`UsuarioId` = `g`.`UsuarioId` and `p`.`CategoriaGastoId` = `g`.`CategoriaGastoId` and year(`g`.`FechaGasto`) = `p`.`Anio` and month(`g`.`FechaGasto`) = `p`.`Mes` and `g`.`EliminadoEn` is null)) GROUP BY `p`.`UsuarioId`, `p`.`Anio`, `p`.`Mes`, `cat`.`CategoriaGastoId` ;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `AportacionesMeta`
--
ALTER TABLE `AportacionesMeta`
  ADD CONSTRAINT `AportacionesMeta_ibfk_1` FOREIGN KEY (`MetaAhorroId`) REFERENCES `MetasAhorro` (`MetaAhorroId`);

--
-- Filtros para la tabla `CategoriasGasto`
--
ALTER TABLE `CategoriasGasto`
  ADD CONSTRAINT `CategoriasGasto_ibfk_1` FOREIGN KEY (`CategoriaPadreId`) REFERENCES `CategoriasGasto` (`CategoriaGastoId`);

--
-- Filtros para la tabla `DispositivosUsuario`
--
ALTER TABLE `DispositivosUsuario`
  ADD CONSTRAINT `DispositivosUsuario_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`);

--
-- Filtros para la tabla `EventosSincronizacion`
--
ALTER TABLE `EventosSincronizacion`
  ADD CONSTRAINT `EventosSincronizacion_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `EventosSincronizacion_ibfk_2` FOREIGN KEY (`DispositivoUsuarioId`) REFERENCES `DispositivosUsuario` (`DispositivoUsuarioId`),
  ADD CONSTRAINT `EventosSincronizacion_ibfk_3` FOREIGN KEY (`TipoEventoId`) REFERENCES `TiposEvento` (`TipoEventoId`);

--
-- Filtros para la tabla `Gastos`
--
ALTER TABLE `Gastos`
  ADD CONSTRAINT `Gastos_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `Gastos_ibfk_2` FOREIGN KEY (`CategoriaGastoId`) REFERENCES `CategoriasGasto` (`CategoriaGastoId`),
  ADD CONSTRAINT `Gastos_ibfk_3` FOREIGN KEY (`MetodoPagoId`) REFERENCES `MetodosPago` (`MetodoPagoId`),
  ADD CONSTRAINT `Gastos_ibfk_4` FOREIGN KEY (`MonedaId`) REFERENCES `Monedas` (`MonedaId`),
  ADD CONSTRAINT `Gastos_ibfk_5` FOREIGN KEY (`DispositivoUsuarioId`) REFERENCES `DispositivosUsuario` (`DispositivoUsuarioId`),
  ADD CONSTRAINT `Gastos_ibfk_6` FOREIGN KEY (`EstadoSincronizacionId`) REFERENCES `EstadosSincronizacion` (`EstadoSincronizacionId`);

--
-- Filtros para la tabla `Hogares`
--
ALTER TABLE `Hogares`
  ADD CONSTRAINT `Hogares_ibfk_1` FOREIGN KEY (`UsuarioPropietarioId`) REFERENCES `Usuarios` (`UsuarioId`);

--
-- Filtros para la tabla `InsightsIa`
--
ALTER TABLE `InsightsIa`
  ADD CONSTRAINT `InsightsIa_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `InsightsIa_ibfk_2` FOREIGN KEY (`TipoInsightId`) REFERENCES `TiposInsight` (`TipoInsightId`);

--
-- Filtros para la tabla `LogsActividad`
--
ALTER TABLE `LogsActividad`
  ADD CONSTRAINT `LogsActividad_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `LogsActividad_ibfk_2` FOREIGN KEY (`TipoActividadId`) REFERENCES `TiposActividad` (`TipoActividadId`);

--
-- Filtros para la tabla `MetasAhorro`
--
ALTER TABLE `MetasAhorro`
  ADD CONSTRAINT `MetasAhorro_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `MetasAhorro_ibfk_2` FOREIGN KEY (`MonedaId`) REFERENCES `Monedas` (`MonedaId`);

--
-- Filtros para la tabla `MiembrosHogar`
--
ALTER TABLE `MiembrosHogar`
  ADD CONSTRAINT `MiembrosHogar_ibfk_1` FOREIGN KEY (`HogarId`) REFERENCES `Hogares` (`HogarId`),
  ADD CONSTRAINT `MiembrosHogar_ibfk_2` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `MiembrosHogar_ibfk_3` FOREIGN KEY (`RolHogarId`) REFERENCES `RolesHogar` (`RolHogarId`);

--
-- Filtros para la tabla `PatronesGasto`
--
ALTER TABLE `PatronesGasto`
  ADD CONSTRAINT `PatronesGasto_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `PatronesGasto_ibfk_2` FOREIGN KEY (`TipoPatronGastoId`) REFERENCES `TiposPatronGasto` (`TipoPatronGastoId`);

--
-- Filtros para la tabla `PerfilesFinancieros`
--
ALTER TABLE `PerfilesFinancieros`
  ADD CONSTRAINT `PerfilesFinancieros_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`);

--
-- Filtros para la tabla `Presupuestos`
--
ALTER TABLE `Presupuestos`
  ADD CONSTRAINT `Presupuestos_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `Presupuestos_ibfk_2` FOREIGN KEY (`CategoriaGastoId`) REFERENCES `CategoriasGasto` (`CategoriaGastoId`),
  ADD CONSTRAINT `Presupuestos_ibfk_3` FOREIGN KEY (`MonedaId`) REFERENCES `Monedas` (`MonedaId`),
  ADD CONSTRAINT `Presupuestos_ibfk_4` FOREIGN KEY (`TipoPeriodoId`) REFERENCES `TiposPeriodo` (`TipoPeriodoId`);

--
-- Filtros para la tabla `RetosUsuario`
--
ALTER TABLE `RetosUsuario`
  ADD CONSTRAINT `RetosUsuario_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `RetosUsuario_ibfk_2` FOREIGN KEY (`RetoId`) REFERENCES `Retos` (`RetoId`);

--
-- Filtros para la tabla `ScoresFinancieros`
--
ALTER TABLE `ScoresFinancieros`
  ADD CONSTRAINT `ScoresFinancieros_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `ScoresFinancieros_ibfk_2` FOREIGN KEY (`NivelScoreId`) REFERENCES `NivelesScore` (`NivelScoreId`);

--
-- Filtros para la tabla `Sincronizaciones`
--
ALTER TABLE `Sincronizaciones`
  ADD CONSTRAINT `Sincronizaciones_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`);

--
-- Filtros para la tabla `Suscripciones`
--
ALTER TABLE `Suscripciones`
  ADD CONSTRAINT `Suscripciones_ibfk_1` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`),
  ADD CONSTRAINT `Suscripciones_ibfk_2` FOREIGN KEY (`MonedaId`) REFERENCES `Monedas` (`MonedaId`),
  ADD CONSTRAINT `Suscripciones_ibfk_3` FOREIGN KEY (`CicloFacturacionId`) REFERENCES `CiclosFacturacion` (`CicloFacturacionId`);

--
-- Filtros para la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  ADD CONSTRAINT `Usuarios_ibfk_1` FOREIGN KEY (`EstadoUsuarioId`) REFERENCES `EstadosUsuario` (`EstadoUsuarioId`),
  ADD CONSTRAINT `Usuarios_ibfk_2` FOREIGN KEY (`PlanUsuarioId`) REFERENCES `PlanesUsuario` (`PlanUsuarioId`),
  ADD CONSTRAINT `Usuarios_ibfk_3` FOREIGN KEY (`MonedaPreferidaId`) REFERENCES `Monedas` (`MonedaId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
