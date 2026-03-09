<?php
namespace App\Middleware;

use Exception;

class AuthMiddleware {
    private static $secret_key = "AuraApp_Super_Secret_Key_2026";

    public static function validateToken() {
        $headers = getallheaders();
        $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';

        if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            $jwt = $matches[1];
            
            try {
                $tokenParts = explode('.', $jwt);
                if (count($tokenParts) != 3) throw new Exception("Token inválido");

                $header = $tokenParts[0];
                $payload = $tokenParts[1];
                $signatureProvided = $tokenParts[2];

                // Validar firma
                $base64UrlHeader = str_replace(['-', '_'], ['+', '/'], $header);
                $base64UrlPayload = str_replace(['-', '_'], ['+', '/'], $payload);
                
                $signature = hash_hmac('sha256', $header . "." . $payload, self::$secret_key, true);
                $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

                if ($base64UrlSignature !== $signatureProvided) {
                    throw new Exception("Firma de token no coincide");
                }

                $payloadData = json_decode(base64_decode($base64UrlPayload), true);
                
                // Verificar expiración
                if ($payloadData['exp'] < time()) {
                    throw new Exception("Token expirado");
                }

                return $payloadData['user_id'];

            } catch (Exception $e) {
                http_response_code(401);
                echo json_encode(["status" => "error", "message" => "No autorizado: " . $e->getMessage()]);
                exit();
            }
        }

        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Token no proporcionado o formato inválido"]);
        exit();
    }
}
