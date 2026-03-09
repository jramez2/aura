<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class GastosController {

    // GET /v1/gastos
    public function index() {
        // Validar token y obtener ID de usuario
        $usuarioId = AuthMiddleware::validateToken();
        
        $db = (new Database())->getConnection();
        
        $anio = isset($_GET['anio']) ? intval($_GET['anio']) : date('Y');
        $mes = isset($_GET['mes']) ? intval($_GET['mes']) : date('m');

        // Filtramos para traer solo los que NO tengan fecha de eliminación y correspondan al periodo
        $query = "SELECT g.*, c.Nombre as CategoriaNombre 
                  FROM Gastos g 
                  LEFT JOIN CategoriasGasto c ON g.CategoriaGastoId = c.CategoriaGastoId
                  WHERE g.UsuarioId = :usuarioId 
                    AND g.EliminadoEn IS NULL
                    AND YEAR(g.FechaGasto) = :anio
                    AND MONTH(g.FechaGasto) = :mes
                  ORDER BY g.FechaGasto DESC";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(":usuarioId", $usuarioId);
        $stmt->bindParam(":anio", $anio);
        $stmt->bindParam(":mes", $mes);
        $stmt->execute();
        
        $gastos = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            "status" => "success",
            "count" => count($gastos),
            "data" => $gastos
        ]);
    }

    // POST /v1/gastos/eliminar/{id}
    public function delete($id = null) {
        $usuarioId = AuthMiddleware::validateToken();
        
        // Si no viene en URL partimos de que pueda venir en el cuerpo
        $data = json_decode(file_get_contents("php://input"));
        if (empty($id) && isset($data->gasto_id)) {
            $id = $data->gasto_id;
        }

        if (empty($id)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "ID de gasto no proporcionado"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        try {
            // Realizamos un Borrado Lógico (Update)
            $query = "UPDATE Gastos SET EliminadoEn = NOW() WHERE GastoId = :gastoId AND UsuarioId = :usuarioId";
            $stmt = $db->prepare($query);
            $stmt->bindParam(":gastoId", $id);
            $stmt->bindParam(":usuarioId", $usuarioId);
            
            $stmt->execute();

            if($stmt->rowCount() > 0) {
                echo json_encode(["status" => "success", "message" => "Gasto eliminado (lógicamente) correctamente"]);
            } else {
                http_response_code(404);
                echo json_encode(["status" => "error", "message" => "Gasto no encontrado o no pertenece al usuario"]);
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al eliminar: " . $e->getMessage()]);
        }
    }

    // POST /v1/gastos
    public function store() {
        $usuarioId = AuthMiddleware::validateToken();
        
        $data = json_decode(file_get_contents("php://input"));
        
        if(empty($data->monto) || empty($data->categoria_id)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Monto y CategoriaId son requeridos"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        try {
            $query = "INSERT INTO Gastos (UsuarioId, CategoriaGastoId, Monto, Descripcion, FechaGasto, CreadoEn) 
                      VALUES (:usuarioId, :catId, :monto, :desc, :fecha, NOW())";
            
            $stmt = $db->prepare($query);
            
            $fecha = isset($data->fecha) ? $data->fecha : date('Y-m-d H:i:s');
            $descripcion = isset($data->descripcion) ? $data->descripcion : "";
            
            $stmt->bindParam(":usuarioId", $usuarioId);
            $stmt->bindParam(":catId", $data->categoria_id);
            $stmt->bindParam(":monto", $data->monto);
            $stmt->bindParam(":desc", $descripcion);
            $stmt->bindParam(":fecha", $fecha);
            
            if($stmt->execute()) {
                http_response_code(201);
                echo json_encode(["status" => "success", "message" => "Gasto registrado correctamente"]);
            } else {
                throw new \Exception("Error al insertar el registro");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al guardar el gasto: " . $e->getMessage()]);
        }
    }
    // PUT /v1/gastos/{id}
    public function update($id = null) {
        $usuarioId = AuthMiddleware::validateToken();
        
        $data = json_decode(file_get_contents("php://input"));
        
        // Si no viene en URL partimos de que pueda venir en el cuerpo (para POST /actualizar)
        if (empty($id) && isset($data->gasto_id)) {
            $id = $data->gasto_id;
        }

        if (empty($id)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "ID de gasto no proporcionado"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        try {
            // Primero verificamos que el gasto exista y pertenezca al usuario
            $check = $db->prepare("SELECT GastoId FROM Gastos WHERE GastoId = :id AND UsuarioId = :uid AND EliminadoEn IS NULL");
            $check->execute(['id' => $id, 'uid' => $usuarioId]);
            
            if ($check->rowCount() === 0) {
                http_response_code(404);
                echo json_encode(["status" => "error", "message" => "Gasto no encontrado o no tienes permiso"]);
                return;
            }

            // Construcción dinámica del query de actualización para permitir actualización parcial
            $fields = [];
            $params = [':id' => $id, ':uid' => $usuarioId];

            if (isset($data->monto)) { $fields[] = "Monto = :monto"; $params[':monto'] = $data->monto; }
            if (isset($data->categoria_id)) { $fields[] = "CategoriaGastoId = :catId"; $params[':catId'] = $data->categoria_id; }
            if (isset($data->descripcion)) { $fields[] = "Descripcion = :desc"; $params[':desc'] = $data->descripcion; }
            if (isset($data->fecha)) { $fields[] = "FechaGasto = :fecha"; $params[':fecha'] = $data->fecha; }
            
            // Siempre actualizamos la fecha de modificación
            $fields[] = "ActualizadoEn = NOW()";

            if (empty($fields)) {
                echo json_encode(["status" => "success", "message" => "Nada que actualizar"]);
                return;
            }

            $query = "UPDATE Gastos SET " . implode(', ', $fields) . " WHERE GastoId = :id AND UsuarioId = :uid";
            $stmt = $db->prepare($query);
            
            if($stmt->execute($params)) {
                echo json_encode(["status" => "success", "message" => "Gasto actualizado correctamente"]);
            } else {
                throw new \Exception("Error al ejecutar la actualización");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al actualizar: " . $e->getMessage()]);
        }
    }

    // PUT /v1/gastos/restaurar/{id}
    public function restore($id) {
        $usuarioId = AuthMiddleware::validateToken();
        
        if (empty($id)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "ID de gasto no proporcionado"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        try {
            $query = "UPDATE Gastos SET EliminadoEn = NULL WHERE GastoId = :id AND UsuarioId = :uid";
            $stmt = $db->prepare($query);
            $stmt->bindParam(":id", $id);
            $stmt->bindParam(":uid", $usuarioId);
            
            if($stmt->execute()) {
                if($stmt->rowCount() > 0) {
                    echo json_encode(["status" => "success", "message" => "Gasto restaurado correctamente"]);
                } else {
                    http_response_code(404);
                    echo json_encode(["status" => "error", "message" => "Gasto no encontrado o ya estaba activo"]);
                }
            } else {
                throw new \Exception("Error al ejecutar la restauración");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al restaurar: " . $e->getMessage()]);
        }
    }
}
