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
}
