-- Script de Reestructuración Total AuraApp - Limpieza y Ajuste de Presupuesto
-- ADVERTENCIA: Este script limpia datos de Gastos, Presupuestos y Categorías para reacomodar todo.

-- 1. Desactivar validaciones de llaves foráneas para poder limpiar todo
SET FOREIGN_KEY_CHECKS = 0;

-- 2. Limpieza profunda de tablas relacionadas con el flujo mensual
DELETE FROM Gastos;
DELETE FROM Presupuestos;
DELETE FROM CategoriasGasto;
DELETE FROM TiposPeriodo;

-- Reiniciar contadores (opcional)
ALTER TABLE CategoriasGasto AUTO_INCREMENT = 1;
ALTER TABLE TiposPeriodo AUTO_INCREMENT = 1;

-- 3. Restaurar Tipos de Periodo básicos
INSERT INTO TiposPeriodo (TipoPeriodoId, Nombre) VALUES 
(1, 'Mensual'),
(2, 'Anual'),
(3, 'Semanal'),
(4, 'Quincenal');

-- 4. Actualización de CategoriasGasto (11 Secciones de la Imagen)
-- Secciones Principales (Padres)
INSERT INTO CategoriasGasto (CategoriaGastoId, Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
(1, 'CASA', 'home-outline', NULL, 1),
(2, 'SERVICIOS', 'flash-outline', NULL, 1),
(3, 'ALIMENTOS', 'restaurant-outline', NULL, 1),
(4, 'AUTOMÓVIL', 'car-outline', NULL, 1),
(5, 'ENTRETENIMIENTO', 'game-controller-outline', NULL, 1),
(6, 'VIAJES', 'airplane-outline', NULL, 1),
(7, 'PERSONALES', 'person-outline', NULL, 1),
(8, 'HIJOS', 'people-outline', NULL, 1),
(9, 'MASCOTAS', 'paw-outline', NULL, 1),
(10, 'SEGUROS', 'shield-checkmark-outline', NULL, 1),
(11, 'PRÉSTAMOS', 'cash-outline', NULL, 1);

-- Subcategorías por sección
-- 1. CASA
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Renta/Hipoteca', 'key-outline', 1, 1),
('Mantenimiento', 'construct-outline', 1, 1),
('Limpieza', 'water-outline', 1, 1),
('Decoración', 'color-palette-outline', 1, 1),
('Reparaciones', 'hammer-outline', 1, 1),
('Jardinería', 'leaf-outline', 1, 1),
('Otros CASA', 'ellipsis-horizontal-outline', 1, 1);

-- 2. SERVICIOS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Gas', 'flame-outline', 2, 1),
('Luz', 'bulb-outline', 2, 1),
('Agua', 'water-outline', 2, 1),
('Teléfono', 'call-outline', 2, 1),
('Internet', 'wifi-outline', 2, 1),
('Cable', 'tv-outline', 2, 1),
('Tintorería', 'shirt-outline', 2, 1),
('Otros SERVICIOS', 'ellipsis-horizontal-outline', 2, 1);

-- 3. ALIMENTOS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Supermercado', 'cart-outline', 3, 1),
('Comidas Fuera', 'fast-food-outline', 3, 1),
('Otros ALIMENTOS', 'ellipsis-horizontal-outline', 3, 1);

-- 4. AUTOMÓVIL
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Gasolina', 'speedometer-outline', 4, 1),
('Lavado', 'shiny-outline', 4, 1),
('Mantenimiento AUTO', 'build-outline', 4, 1),
('Estacionamiento', 'pin-outline', 4, 1),
('Otros AUTO', 'ellipsis-horizontal-outline', 4, 1);

-- 5. ENTRETENIMIENTO
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Cine / Estadio / Teatro', 'ticket-outline', 5, 1),
('Música / Videojuegos', 'musical-notes-outline', 5, 1),
('Descargas de Internet', 'download-outline', 5, 1),
('Fiestas / Bar', 'wine-outline', 5, 1),
('Otros ENTRETENIMIENTO', 'ellipsis-horizontal-outline', 5, 1);

-- 6. VIAJES
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Hotel', 'bed-outline', 6, 1),
('Transporte VIAJE', 'bus-outline', 6, 1),
('Comidas VIAJE', 'restaurant-outline', 6, 1),
('Entretenimiento VIAJE', 'camera-outline', 6, 1),
('Otros VIAJES', 'ellipsis-horizontal-outline', 6, 1);

-- 7. PERSONALES
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Alimentos PERS', 'pizza-outline', 7, 1),
('Ropa', 'shirt-outline', 7, 1),
('Celular', 'phone-portrait-outline', 7, 1),
('Salud (Médico / Farmacia)', 'medkit-outline', 7, 1),
('Bienestar (Gym / Yoga)', 'fitness-outline', 7, 1),
('Servicios (Estética / Uñas)', 'brush-outline', 7, 1),
('Cosméticos', 'color-wand-outline', 7, 1),
('Hobbies', 'heart-outline', 7, 1),
('Otros PERSONALES', 'ellipsis-horizontal-outline', 7, 1);

-- 8. HIJOS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Escuela', 'school-outline', 8, 1),
('Dinero Extra', 'cash-outline', 8, 1),
('Celular HIJOS', 'phone-portrait-outline', 8, 1),
('Cuidado (Niñera)', 'people-circle-outline', 8, 1),
('Libros / Útiles Escolares', 'book-outline', 8, 1),
('Clases', 'library-outline', 8, 1),
('Juguetes / Juegos', 'game-controller-outline', 8, 1),
('Otros HIJOS', 'ellipsis-horizontal-outline', 8, 1);

-- 9. MASCOTAS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Alimentos MASCOTAS', 'nutrition-outline', 9, 1),
('Salud MASCOTAS', 'bandage-outline', 9, 1),
('Juguetes MASCOTAS', 'football-outline', 9, 1),
('Paseo', 'walk-outline', 9, 1),
('Pensión', 'home-outline', 9, 1),
('Otros MASCOTAS', 'ellipsis-horizontal-outline', 9, 1);

-- 10. SEGUROS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Seguro de Auto', 'car-sport-outline', 10, 1),
('Seguro de Vivienda', 'business-outline', 10, 1),
('Seguro de Vida', 'heart-half-outline', 10, 1),
('Seguro de Gastos Médicos', 'pulse-outline', 10, 1),
('Otros SEGUROS', 'ellipsis-horizontal-outline', 10, 1);

-- 11. PRÉSTAMOS
INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, EsSistema) VALUES
('Hipoteca PREST', 'home-outline', 11, 1),
('Mensualidad Auto', 'car-outline', 11, 1),
('Tarjeta Crédito 1', 'card-outline', 11, 1),
('Tarjeta Crédito 2', 'card-outline', 11, 1),
('Préstamo 1', 'cash-outline', 11, 1),
('Préstamo 2', 'cash-outline', 11, 1),
('Otros PRÉSTAMOS', 'ellipsis-horizontal-outline', 11, 1);

-- 5. Ajustes finales de estructura
ALTER TABLE Presupuestos ADD COLUMN IF NOT EXISTS Anio INT AFTER MonedaId;
ALTER TABLE Presupuestos ADD COLUMN IF NOT EXISTS Mes INT AFTER Anio;
ALTER TABLE Presupuestos ADD UNIQUE KEY IF NOT EXISTS `Idx_Presupuesto_Unico` (UsuarioId, CategoriaGastoId, Anio, Mes);

-- 6. Vista de Comparativo
DROP VIEW IF EXISTS Vista_ComparativoPresupuesto;
CREATE VIEW Vista_ComparativoPresupuesto AS
SELECT 
    p.UsuarioId,
    p.Anio,
    p.Mes,
    sec.Nombre AS Seccion,
    cat.Nombre AS Categoria,
    p.Monto AS Presupuestado,
    COALESCE(SUM(g.Monto), 0) AS Real_Gastado,
    (p.Monto - COALESCE(SUM(g.Monto), 0)) AS Diferencia,
    CASE 
        WHEN p.Monto = 0 THEN 0 
        ELSE (COALESCE(SUM(g.Monto), 0) / p.Monto) * 100 
    END AS Porcentaje_Ejecucion
FROM Presupuestos p
JOIN CategoriasGasto cat ON p.CategoriaGastoId = cat.CategoriaGastoId
JOIN CategoriasGasto sec ON cat.CategoriaPadreId = sec.CategoriaGastoId
LEFT JOIN Gastos g ON p.UsuarioId = g.UsuarioId 
    AND p.CategoriaGastoId = g.CategoriaGastoId 
    AND YEAR(g.FechaGasto) = p.Anio 
    AND MONTH(g.FechaGasto) = p.Mes
    AND g.EliminadoEn IS NULL
GROUP BY p.UsuarioId, p.Anio, p.Mes, cat.CategoriaGastoId;

-- 7. Procedimiento de Inicialización (Con copia de mes anterior)
DROP PROCEDURE IF EXISTS Sp_InicializarPresupuestoUsuario;
DELIMITER //
CREATE PROCEDURE Sp_InicializarPresupuestoUsuario(IN p_UsuarioId BIGINT, IN p_Anio INT, IN p_Mes INT)
BEGIN
    DECLARE v_AnioPrev INT;
    DECLARE v_MesPrev INT;
    
    -- Calcular mes anterior
    IF p_Mes = 1 THEN
        SET v_MesPrev = 12;
        SET v_AnioPrev = p_Anio - 1;
    ELSE
        SET v_MesPrev = p_Mes - 1;
        SET v_AnioPrev = p_Anio;
    END IF;

    -- Insertar intentando copiar montos del mes anterior
    INSERT IGNORE INTO Presupuestos (UsuarioId, CategoriaGastoId, Monto, MonedaId, Anio, Mes, TipoPeriodoId)
    SELECT 
        p_UsuarioId, 
        cat.CategoriaGastoId, 
        COALESCE(prev.Monto, 0.00), 
        COALESCE(prev.MonedaId, (SELECT MonedaPreferidaId FROM Usuarios WHERE UsuarioId = p_UsuarioId LIMIT 1), 1),
        p_Anio, 
        p_Mes, 
        1 -- Mensual
    FROM CategoriasGasto cat
    LEFT JOIN Presupuestos prev ON prev.UsuarioId = p_UsuarioId 
        AND prev.CategoriaGastoId = cat.CategoriaGastoId 
        AND prev.Anio = v_AnioPrev 
        AND prev.Mes = v_MesPrev
    WHERE cat.CategoriaPadreId IS NOT NULL AND cat.EsSistema = 1;
END //
DELIMITER ;

-- Reactivar validaciones de integridad
SET FOREIGN_KEY_CHECKS = 1;
