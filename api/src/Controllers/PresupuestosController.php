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
            // Consultamos la vista comparativa y unimos con CategoriasGasto para obtener el ID faltante
            // Aliaseamos las columnas para que coincidan con lo que espera el frontend (MontoPresupuestado y MontoReal)
            $query = "SELECT v.UsuarioId, v.Anio, v.Mes, v.Seccion, v.Categoria, 
                             v.Presupuestado AS MontoPresupuestado, 
                             v.Real_Gastado AS MontoReal, 
                             cat.CategoriaGastoId 
                      FROM Vista_ComparativoPresupuesto v
                      JOIN CategoriasGasto cat ON v.Categoria = cat.Nombre
                      JOIN CategoriasGasto sec ON v.Seccion = sec.Nombre AND cat.CategoriaPadreId = sec.CategoriaGastoId
                      WHERE v.UsuarioId = :uid AND v.Anio = :anio AND v.Mes = :mes
                      ORDER BY v.Seccion, v.Categoria";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(":uid", $usuarioId);
            $stmt->bindParam(":anio", $anio);
            $stmt->bindParam(":mes", $mes);
            $stmt->execute();
            
            $datos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Si no hay datos para este mes/año, inicializamos automáticamente
            if (empty($datos)) {
                $initQuery = "CALL Sp_InicializarPresupuestoUsuario(:uid, :anio, :mes)";
                $initStmt = $db->prepare($initQuery);
                $initStmt->bindParam(":uid", $usuarioId);
                $initStmt->bindParam(":anio", $anio);
                $initStmt->bindParam(":mes", $mes);
                $initStmt->execute();

                // Intentamos consultar de nuevo tras inicializar
                $stmt->execute();
                $datos = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
            
            // Agrupar por sección para facilitar el despliegue en el frontend (como en la imagen)
            $agrupado = [];
            foreach ($datos as $row) {
                $seccion = $row['Seccion'];
                if (!isset($agrupado[$seccion])) {
                    $agrupado[$seccion] = [
                        "Seccion" => $seccion,
                        "Items" => []
                    ];
                }
                $agrupado[$seccion]["Items"][] = $row;
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
