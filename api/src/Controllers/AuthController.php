<?php
namespace App\Controllers;

use App\Config\Database;
use PDO;

class AuthController {
    
    // Clave secreta para firmar los JWT - ¡En producción debe ir en variables de entorno!
    private $secret_key = "AuraApp_Super_Secret_Key_2026";
    
    // POST /v1/registro
    public function register() {
        try {
            // Obtenemos los datos JSON del cuerpo de la petición
            $data = json_decode(file_get_contents("php://input"));
            
            if(empty($data->email) || empty($data->password)) {
                http_response_code(400);
                echo json_encode(["status" => "error", "message" => "Email y password son obligatorios"]);
                return;
            }
            
            $db = (new Database())->getConnection();
            
            // 1. Revisar si el email ya existe
            $stmt = $db->prepare("SELECT UsuarioId FROM Usuarios WHERE Email = :email");
            $stmt->bindParam(":email", $data->email);
            $stmt->execute();
            
            if($stmt->rowCount() > 0) {
                http_response_code(409); // Conflict
                echo json_encode(["status" => "error", "message" => "El email ya está registrado"]);
                return;
            }
            
            // 2. Preparar los datos
            $passwordHash = password_hash($data->password, PASSWORD_BCRYPT);
            // Si no mandan nombre, usamos la primer parte del email
            $nombreMostrar = isset($data->nombre) ? $data->nombre : explode('@', $data->email)[0];
            
            $estadoUsuarioId = 1; // 1 = Activo 
            $planUsuarioId = 1;   // 1 = Free (SaaS Freemium)
            
            // 3. Insertar el nuevo usuario
            $query = "INSERT INTO Usuarios (Email, PasswordHash, NombreMostrar, EstadoUsuarioId, PlanUsuarioId, CreadoEn) 
                      VALUES (:email, :password, :nombre, :estado, :plan, NOW())";
            
            $insert = $db->prepare($query);
            $insert->bindParam(":email", $data->email);
            $insert->bindParam(":password", $passwordHash);
            $insert->bindParam(":nombre", $nombreMostrar);
            $insert->bindParam(":estado", $estadoUsuarioId);
            $insert->bindParam(":plan", $planUsuarioId);
            
            if($insert->execute()) {
                // 4. Inicializar Presupuesto por defecto para el mes actual
                $usuarioId = $db->lastInsertId();
                $anioActual = date('Y');
                $mesActual = date('m');
                
                $sp = $db->prepare("CALL Sp_InicializarPresupuestoUsuario(:usuarioId, :anio, :mes)");
                $sp->bindParam(":usuarioId", $usuarioId);
                $sp->bindParam(":anio", $anioActual);
                $sp->bindParam(":mes", $mesActual);
                $sp->execute();

                http_response_code(201); // Created
                echo json_encode(["status" => "success", "message" => "Usuario registrado exitosamente en AuraApp y presupuesto inicializado"]);
            } else {
                http_response_code(500);
                echo json_encode(["status" => "error", "message" => "No se pudo registrar el usuario en MySQL"]);
            }
        } catch (\PDOException $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error de BD en registro: " . $e->getMessage(), "line" => $e->getLine()]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error interno: " . $e->getMessage()]);
        }
    }
    
    // POST /v1/login
    public function login() {
        $data = json_decode(file_get_contents("php://input"));
        
        if(empty($data->email) || empty($data->password)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Email y password son obligatorios"]);
            return;
        }
        
        $db = (new Database())->getConnection();
        
        // 1. Buscar el usuario
        $stmt = $db->prepare("SELECT UsuarioId, Email, PasswordHash, NombreMostrar FROM Usuarios WHERE Email = :email");
        $stmt->bindParam(":email", $data->email);
        $stmt->execute();
        
        if($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // 2. Verificar password con el Hash de BCRYPT
            if(password_verify($data->password, $row['PasswordHash'])) {
                
                // Actualizar último login
                $update = $db->prepare("UPDATE Usuarios SET UltimoLogin = NOW() WHERE UsuarioId = :id");
                $update->bindParam(":id", $row['UsuarioId']);
                $update->execute();
                
                // 3. Generar token JWT nativo sin librerías de terceros (ideal para inicio)
                $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
                $payload = json_encode([
                    'user_id' => $row['UsuarioId'],
                    'email' => $row['Email'],
                    'iat' => time(),
                    'exp' => time() + (86400 * 7) // Token válido por 7 días
                ]);
                
                // Codificación segura para URL (Base64UrlEncode)
                $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
                $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
                
                // Firma
                $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $this->secret_key, true);
                $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
                
                $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
                
                http_response_code(200);
                echo json_encode([
                    "status" => "success",
                    "message" => "Autenticación exitosa",
                    "data" => [
                        "token" => $jwt,
                        "user" => [
                            "id" => $row['UsuarioId'],
                            "email" => $row['Email'],
                            "nombre" => $row['NombreMostrar']
                        ]
                    ]
                ]);
            } else {
                http_response_code(401);
                echo json_encode(["status" => "error", "message" => "Contraseña incorrecta"]);
            }
        } else {
            http_response_code(404);
            echo json_encode(["status" => "error", "message" => "El usuario no existe"]);
        }
    }
}
