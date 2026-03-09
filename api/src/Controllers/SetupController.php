<?php
namespace App\Controllers;

use App\Config\Database;
use PDO;

class SetupController {
    
    public function seed() {
        try {
            $db = (new Database())->getConnection();
            $results = [];

            // 1. Seed EstadosUsuario
            $db->exec("INSERT IGNORE INTO EstadosUsuario (EstadoUsuarioId, Nombre) VALUES (1, 'Activo'), (2, 'Inactivo'), (3, 'Suspendido')");
            $results[] = "EstadosUsuario populated";

            // 2. Seed PlanesUsuario
            $db->exec("INSERT IGNORE INTO PlanesUsuario (PlanUsuarioId, Nombre, PrecioMensual, MaximoPresupuestos, MaximoDispositivos, LimiteInsightsIa) 
                       VALUES (1, 'Gratis', 0.00, 3, 1, 5), (2, 'Premium', 9.99, 99, 5, 100)");
            $results[] = "PlanesUsuario populated";

            // 3. Seed Monedas
            $db->exec("INSERT IGNORE INTO Monedas (MonedaId, Codigo, Nombre, Simbolo) 
                       VALUES (1, 'MXN', 'Peso Mexicano', '$'), (2, 'USD', 'Dólar Estadounidense', '$'), (3, 'EUR', 'Euro', '€')");
            $results[] = "Monedas populated";

            // 4. Seed CategoriasGasto
            $db->exec("INSERT IGNORE INTO CategoriasGasto (CategoriaGastoId, Nombre, Icono, EsSistema) 
                       VALUES (1, 'Comida', 'fast-food', 1), (2, 'Transporte', 'bus', 1), (3, 'Entretenimiento', 'game-controller', 1), 
                              (4, 'Servicios', 'flash', 1), (5, 'Otros', 'ellipsis-horizontal', 1)");
            $results[] = "CategoriasGasto populated";

            echo json_encode(["status" => "success", "message" => "Base de datos inicializada correctamente", "details" => $results]);
            
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al inicializar: " . $e->getMessage()]);
        }
    }

    public function migrateCategories() {
        try {
            $db = (new Database())->getConnection();
            $results = [];

            // 1. Alter table
            try {
                $db->exec("ALTER TABLE `CategoriasGasto` ADD `UsuarioId` BIGINT(20) NULL DEFAULT NULL AFTER `CategoriaPadreId` ");
                $results[] = "Table altered.";
            } catch (\Exception $e) {
                $results[] = "Alter Table: " . $e->getMessage() . " (Maybe already exists?)";
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
            $results[] = "View created.";
            
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
            $results[] = "Procedure updated.";

            echo json_encode(["status" => "success", "details" => $results]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }
}
