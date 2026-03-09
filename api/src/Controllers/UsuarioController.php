<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class UsuarioController {

    // POST /v1/usuario/perfil
    public function updateProfile() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));

        if (empty($data->nombre)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "El nombre es obligatorio"]);
            return;
        }

        $db = (new Database())->getConnection();

        try {
            $query = "UPDATE Usuarios SET NombreMostrar = :nombre WHERE UsuarioId = :id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(":nombre", $data->nombre);
            $stmt->bindParam(":id", $usuarioId);

            if ($stmt->execute()) {
                echo json_encode([
                    "status" => "success", 
                    "message" => "Perfil actualizado correctamente",
                    "data" => ["nombre" => $data->nombre]
                ]);
            } else {
                throw new \Exception("No se pudo actualizar el perfil");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }

    // POST /v1/usuario/password
    public function updatePassword() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));

        if (empty($data->currentPassword) || empty($data->newPassword)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Ambas contraseñas son obligatorias"]);
            return;
        }

        $db = (new Database())->getConnection();

        try {
            // 1. Verificar contraseña actual
            $stmt = $db->prepare("SELECT PasswordHash FROM Usuarios WHERE UsuarioId = :id");
            $stmt->bindParam(":id", $usuarioId);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!password_verify($data->currentPassword, $user['PasswordHash'])) {
                http_response_code(401);
                echo json_encode(["status" => "error", "message" => "La contraseña actual es incorrecta"]);
                return;
            }

            // 2. Actualizar con la nueva
            $newHash = password_hash($data->newPassword, PASSWORD_BCRYPT);
            $update = $db->prepare("UPDATE Usuarios SET PasswordHash = :hash WHERE UsuarioId = :id");
            $update->bindParam(":hash", $newHash);
            $update->bindParam(":id", $usuarioId);

            if ($update->execute()) {
                echo json_encode(["status" => "success", "message" => "Contraseña actualizada correctamente"]);
            } else {
                throw new \Exception("No se pudo actualizar la contraseña");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }
}
