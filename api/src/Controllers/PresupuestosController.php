<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class PresupuestosController {

    // GET /v1/presupuestos/comparativo?anio=2026&mes=03
    public function getComparativo() {
        $usuarioId = AuthMiddleware::validateToken();
        
        $anio = isset($_GET['anio']) ? $_GET['anio'] : date('Y');
        $mes = isset($_GET['mes']) ? $_GET['mes'] : date('m');
        
        $db = (new Database())->getConnection();
        
        try {
            // 1. Aseguramos que existan registros de presupuesto (con monto 0) para el periodo
            $initStmt = $db->prepare("CALL Sp_InicializarPresupuestoUsuario(:uid, :anio, :mes)");
            $initStmt->execute(['uid' => $usuarioId, 'anio' => $anio, 'mes' => $mes]);

            // 2. Consultamos TODAS las secciones (padres) del usuario/sistema
            // y les unimos sus categorías (hijos) y el presupuesto del periodo
            $query = "SELECT 
                        sec.CategoriaGastoId AS SeccionId,
                        sec.Nombre AS Seccion,
                        cat.CategoriaGastoId,
                        cat.Nombre AS Categoria,
                        COALESCE(p.Monto, 0) AS MontoPresupuestado,
                        COALESCE((SELECT SUM(Monto) FROM Gastos 
                                  WHERE CategoriaGastoId = cat.CategoriaGastoId 
                                  AND UsuarioId = :uid 
                                  AND YEAR(FechaGasto) = :anio 
                                  AND MONTH(FechaGasto) = :mes 
                                  AND EliminadoEn IS NULL), 0) AS MontoReal
                      FROM CategoriasGasto sec
                      LEFT JOIN CategoriasGasto cat ON cat.CategoriaPadreId = sec.CategoriaGastoId
                      LEFT JOIN Presupuestos p ON cat.CategoriaGastoId = p.CategoriaGastoId 
                                AND p.UsuarioId = :uid 
                                AND p.Anio = :anio 
                                AND p.Mes = :mes
                      WHERE sec.CategoriaPadreId IS NULL 
                        AND (sec.EsSistema = 1 OR sec.UsuarioId = :uid)
                      ORDER BY sec.Nombre, cat.Nombre";
            
            $stmt = $db->prepare($query);
            $stmt->execute(['uid' => $usuarioId, 'anio' => $anio, 'mes' => $mes]);
            $datos = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Agrupar por sección
            $agrupado = [];
            foreach ($datos as $row) {
                $seccionId = $row['SeccionId'];
                if (!isset($agrupado[$seccionId])) {
                    $agrupado[$seccionId] = [
                        "SeccionId" => $seccionId,
                        "Seccion" => $row['Seccion'],
                        "Items" => []
                    ];
                }
                // Solo añadir a Items si hay una categoría hija real
                if ($row['CategoriaGastoId']) {
                    $agrupado[$seccionId]["Items"][] = $row;
                }
            }
            
            echo json_encode([
                "status" => "success",
                "anio" => $anio,
                "mes" => $mes,
                "data" => array_values($agrupado)
            ]);
            
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al consultar presupuesto: " . $e->getMessage()]);
        }
    }

    // POST /v1/presupuestos/capturar
    public function store() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));
        
        if(empty($data->categoria_id) || !isset($data->monto)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "CategoriaId y Monto son requeridos"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        $anio = isset($data->anio) ? $data->anio : date('Y');
        $mes = isset($data->mes) ? $data->mes : date('m');
        
        try {
            // Insertamos o actualizamos (UPSERT)
            $query = "INSERT INTO Presupuestos (UsuarioId, CategoriaGastoId, Monto, Anio, Mes, TipoPeriodoId) 
                      VALUES (:uid, :catId, :monto, :anio, :mes, 1)
                      ON DUPLICATE KEY UPDATE Monto = :monto_upd";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(":uid", $usuarioId);
            $stmt->bindParam(":catId", $data->categoria_id);
            $stmt->bindParam(":monto", $data->monto);
            $stmt->bindParam(":monto_upd", $data->monto);
            $stmt->bindParam(":anio", $anio);
            $stmt->bindParam(":mes", $mes);
            
            if($stmt->execute()) {
                echo json_encode(["status" => "success", "message" => "Presupuesto actualizado correctamente"]);
            } else {
                throw new \Exception("No se pudo guardar el presupuesto");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al guardar: " . $e->getMessage()]);
        }
    }
}
