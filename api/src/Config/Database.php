<?php
namespace App\Config;

use PDO;
use PDOException;

class Database
{
    // Configuración base de desarrollo; Idealmente esto viviría en variables de entorno o archivo .env
    private $host = "localhost"; //31.97.208.148
    private $db_name = "u110295808_aurafin";
    private $username = "u110295808_aurafin"; // O ajustado según corresponda. "root" es seguro asumir para entorno local
    private $password = "Tepic2026$$##";

    // Conexión
    public $conn;

    public function getConnection()
    {
        $this->conn = null;

        try {
            // El modo DSN con charset utf8mb4 asegura soporte total
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4", $this->username, $this->password);

            // Atributos por defecto para la conexión
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        }
        catch (PDOException $exception) {
            http_response_code(500);
            echo json_encode([
                "status" => "error",
                "message" => "Error de conexión a la base de datos principal MySQL",
                "detail" => $exception->getMessage()
            ]);
            exit();
        }

        return $this->conn;
    }
}