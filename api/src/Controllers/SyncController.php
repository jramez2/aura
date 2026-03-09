<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class SyncController {

    /**
     * POST /v1/sync
     * Motor de sincronización masiva para modo Offline
     */
    public function syncOffline() {
        $usuarioId = AuthMiddleware::validateToken();
        $input = json_decode(file_get_contents("php://input"), true);

        if (!isset($input['cambios']) || !is_array($input['cambios'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "No se recibieron cambios válidos"]);
            return;
        }

        $db = (new Database())->getConnection();
        $resultados = [
            "aplicados" => 0,
            "errores" => 0,
            "detalles" => []
        ];

        $db->beginTransaction();

        try {
            foreach ($input['cambios'] as $cambio) {
                // Estructura esperada por cambio: { accion: 'crear|editar|eliminar', tabla: 'gastos', data: {...} }
                $accion = $cambio['accion'] ?? '';
                $tabla = $cambio['tabla'] ?? '';
                $data = $cambio['data'] ?? [];

                if ($tabla === 'gastos') {
                    $res = $this->procesarCambioGasto($db, $usuarioId, $accion, $data);
                    if ($res['success']) {
                        $resultados['aplicados']++;
                    } else {
                        $resultados['errores']++;
                        $resultados['detalles'][] = $res['error'];
                    }
                }
            }

            $db->commit();
            
            echo json_encode([
                "status" => "success",
                "message" => "Sincronización completada",
                "resumen" => $resultados
            ]);

        } catch (\Exception $e) {
            $db->rollBack();
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Fallo crítico en sincronización: " . $e->getMessage()]);
        }
    }

    private function procesarCambioGasto($db, $usuarioId, $accion, $data) {
        try {
            switch ($accion) {
                case 'crear':
                    // Usamos IdentificadorLocal para evitar duplicados si la petición se re-envía
                    $query = "INSERT INTO Gastos (UsuarioId, IdentificadorLocal, CategoriaGastoId, Monto, Descripcion, FechaGasto, CreadoEn) 
                              VALUES (:uid, :localId, :cat, :monto, :desc, :fecha, NOW())
                              ON DUPLICATE KEY UPDATE Monto = VALUES(Monto), Descripcion = VALUES(Descripcion)";
                    
                    $stmt = $db->prepare($query);
                    $stmt->execute([
                        ':uid' => $usuarioId,
                        ':localId' => $data['id_local'] ?? uniqid('off_'),
                        ':cat' => $data['categoria_id'],
                        ':monto' => $data['monto'],
                        ':desc' => $data['descripcion'] ?? '',
                        ':fecha' => $data['fecha'] ?? date('Y-m-d H:i:s')
                    ]);
                    break;

                case 'editar':
                    $query = "UPDATE Gastos SET Monto = :monto, Descripcion = :desc, CategoriaGastoId = :cat, ActualizadoEn = NOW() 
                              WHERE (GastoId = :id OR IdentificadorLocal = :localId) AND UsuarioId = :uid";
                    $stmt = $db->prepare($query);
                    $stmt->execute([
                        ':uid' => $usuarioId,
                        ':id' => $data['id'] ?? null,
                        ':localId' => $data['id_local'] ?? null,
                        ':monto' => $data['monto'],
                        ':desc' => $data['descripcion'],
                        ':cat' => $data['categoria_id']
                    ]);
                    break;

                case 'eliminar':
                    $query = "UPDATE Gastos SET EliminadoEn = NOW() WHERE (GastoId = :id OR IdentificadorLocal = :localId) AND UsuarioId = :uid";
                    $stmt = $db->prepare($query);
                    $stmt->execute([
                        ':uid' => $usuarioId,
                        ':id' => $data['id'] ?? null,
                        ':localId' => $data['id_local'] ?? null
                    ]);
                    break;
            }
            return ["success" => true];
        } catch (\Exception $e) {
            return ["success" => false, "error" => $e->getMessage()];
        }
    }
}
