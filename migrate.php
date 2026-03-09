<?php
$host = "localhost";
$db_name = "u110295808_aurafin";
$username = "u110295808_aurafin";
$password = "Tepic2026$$##";

try {
    $db = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Alter table
    try {
        $db->exec("ALTER TABLE `CategoriasGasto` ADD `UsuarioId` BIGINT(20) NULL DEFAULT NULL AFTER `CategoriaPadreId` ");
        echo "Table altered.\n";
    } catch (Exception $e) {
        echo "Alter Table: " . $e->getMessage() . " (Maybe already exists?)\n";
    }

    // 2. Drop and Create View
    $db->exec("DROP VIEW IF EXISTS `Vista_ComparativoPresupuesto` ");
    $db->exec("CREATE VIEW `Vista_ComparativoPresupuesto` AS 
    SELECT 
        `p`.`UsuarioId` AS `UsuarioId`, 
        `p`.`Anio` AS `Anio`, 
        `p`.`Mes` AS `Mes`, 
        `cat`.`CategoriaGastoId` AS `CategoriaGastoId`,
        `sec`.`CategoriaGastoId` AS `SeccionId`,
        `sec`.`Nombre` AS `Seccion`, 
        `cat`.`Nombre` AS `Categoria`, 
        `p`.`Monto` AS `Presupuestado`, 
        COALESCE(SUM(`g`.`Monto`), 0) AS `Real_Gastado`, 
        `p`.`Monto` - COALESCE(SUM(`g`.`Monto`), 0) AS `Diferencia`, 
        CASE WHEN `p`.`Monto` = 0 THEN 0 ELSE COALESCE(SUM(`g`.`Monto`), 0) / `p`.`Monto` * 100 END AS `Porcentaje_Ejecucion` 
    FROM `Presupuestos` `p` 
    JOIN `CategoriasGasto` `cat` ON `p`.`CategoriaGastoId` = `cat`.`CategoriaGastoId`
    JOIN `CategoriasGasto` `sec` ON `cat`.`CategoriaPadreId` = `sec`.`CategoriaGastoId`
    LEFT JOIN `Gastos` `g` ON `p`.`UsuarioId` = `g`.`UsuarioId` 
        AND `p`.`CategoriaGastoId` = `g`.`CategoriaGastoId` 
        AND YEAR(`g`.`FechaGasto`) = `p`.`Anio` 
        AND MONTH(`g`.`FechaGasto`) = `p`.`Mes` 
        AND `g`.`EliminadoEn` IS NULL
    GROUP BY `p`.`UsuarioId`, `p`.`Anio`, `p`.`Mes`, `cat`.`CategoriaGastoId` ");
    echo "View created.\n";

    // 3. Sp
    $db->exec("DROP PROCEDURE IF EXISTS `Sp_InicializarPresupuestoUsuario` ");
    $db->exec("CREATE PROCEDURE `Sp_InicializarPresupuestoUsuario` (IN `p_UsuarioId` BIGINT, IN `p_Anio` INT, IN `p_Mes` INT)   BEGIN
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
    END");
    echo "Procedure updated.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
