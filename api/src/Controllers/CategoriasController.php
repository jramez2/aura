<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class CategoriasController {

    // GET /v1/categorias
    public function index() {
        $usuarioId = AuthMiddleware::validateToken();
        $db = (new Database())->getConnection();

        try {
            // Traer categorías del sistema y del usuario
            $query = "SELECT * FROM CategoriasGasto 
                      WHERE (EsSistema = 1 OR UsuarioId = :uid)
                      ORDER BY CategoriaPadreId ASC, Nombre ASC";
            $stmt = $db->prepare($query);
            $stmt->execute(['uid' => $usuarioId]);
            $categorias = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode(["status" => "success", "data" => $categorias]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    // POST /v1/categorias
    public function store() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));

        if (empty($data->nombre)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Nombre es requerido"]);
            return;
        }

        $db = (new Database())->getConnection();

        try {
            $query = "INSERT INTO CategoriasGasto (Nombre, Icono, CategoriaPadreId, UsuarioId, EsSistema, CreadoEn) 
                      VALUES (:nombre, :icono, :padreId, :uid, 0, NOW())";
            $stmt = $db->prepare($query);
            
            $padreId = !empty($data->categoria_padre_id) ? $data->categoria_padre_id : null;
            $icono = !empty($data->icono) ? $data->icono : 'tag-outline';

            $stmt->execute([
                'nombre' => $data->nombre,
                'icono' => $icono,
                'padreId' => $padreId,
                'uid' => $usuarioId
            ]);

            $id = $db->lastInsertId();
            
            // Si es una subcategoría (hija), inicializamos el presupuesto para el mes actual
            if ($padreId) {
                $anio = date('Y');
                $mes = date('m');
                $db->prepare("INSERT IGNORE INTO Presupuestos (UsuarioId, CategoriaGastoId, Monto, Anio, Mes, TipoPeriodoId) 
                             VALUES (?, ?, 0, ?, ?, 1)")
                   ->execute([$usuarioId, $id, $anio, $mes]);
            }

            echo json_encode(["status" => "success", "message" => "Categoría creada", "id" => $id]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    // POST /v1/categorias/actualizar
    public function update() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));

        if (empty($data->id) || empty($data->nombre)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "ID y Nombre son requeridos"]);
            return;
        }

        $db = (new Database())->getConnection();

        try {
            // Verificar propiedad
            $check = $db->prepare("SELECT EsSistema FROM CategoriasGasto WHERE CategoriaGastoId = ? AND (UsuarioId = ? OR EsSistema = 1)");
            $check->execute([$data->id, $usuarioId]);
            $cat = $check->fetch();

            if (!$cat) {
                http_response_code(403);
                echo json_encode(["status" => "error", "message" => "No tienes permiso para editar esta categoría"]);
                return;
            }

            if ($cat['EsSistema'] == 1) {
                http_response_code(403);
                echo json_encode(["status" => "error", "message" => "No se pueden editar categorías del sistema"]);
                return;
            }

            $query = "UPDATE CategoriasGasto SET Nombre = :nombre, Icono = :icono WHERE CategoriaGastoId = :id AND UsuarioId = :uid";
            $stmt = $db->prepare($query);
            $stmt->execute([
                'nombre' => $data->nombre,
                'icono' => $data->icono ?? 'tag-outline',
                'id' => $data->id,
                'uid' => $usuarioId
            ]);

            echo json_encode(["status" => "success", "message" => "Categoría actualizada"]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    // POST /v1/categorias/eliminar
    public function delete() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));

        if (empty($data->id)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "ID es requerido"]);
            return;
        }

        $db = (new Database())->getConnection();

        try {
            // 1. Verificar si es de sistema
            $check = $db->prepare("SELECT EsSistema, CategoriaPadreId FROM CategoriasGasto WHERE CategoriaGastoId = ? AND UsuarioId = ?");
            $check->execute([$data->id, $usuarioId]);
            $cat = $check->fetch();

            if (!$cat) {
                http_response_code(404);
                echo json_encode(["status" => "error", "message" => "Categoría no encontrada o es de sistema"]);
                return;
            }

            // 2. Si es padre, verificar si tiene hijos
            if ($cat['CategoriaPadreId'] === null) {
                $checkHijos = $db->prepare("SELECT COUNT(*) FROM CategoriasGasto WHERE CategoriaPadreId = ?");
                $checkHijos->execute([$data->id]);
                if ($checkHijos->fetchColumn() > 0) {
                    http_response_code(400);
                    echo json_encode(["status" => "error", "message" => "No se puede eliminar una sección que tiene subcategorías"]);
                    return;
                }
            }

            // 3. Verificar si tiene gastos asociados
            $checkGastos = $db->prepare("SELECT COUNT(*) FROM Gastos WHERE CategoriaGastoId = ? AND EliminadoEn IS NULL");
            $checkGastos->execute([$data->id]);
            if ($checkGastos->fetchColumn() > 0) {
                http_response_code(400);
                echo json_encode(["status" => "error", "message" => "No se puede eliminar: existen gastos asociados a esta categoría"]);
                return;
            }

            // 4. Eliminar presupuestos asociados
            $db->prepare("DELETE FROM Presupuestos WHERE CategoriaGastoId = ?")->execute([$data->id]);

            // 5. Eliminar categoría
            $db->prepare("DELETE FROM CategoriasGasto WHERE CategoriaGastoId = ? AND UsuarioId = ?")
               ->execute([$data->id, $usuarioId]);

            echo json_encode(["status" => "success", "message" => "Categoría eliminada"]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }
}
