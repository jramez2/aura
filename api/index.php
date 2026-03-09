<?php
// Permisos CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Cargar clases base (Autoloader simple PSR-4 app\)
spl_autoload_register(function ($class) {
    // Convertir Namespace a ruta (App\ => src/)
    $prefix = 'App\\';
    $base_dir = __DIR__ . '/src/';
    
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    
    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';
    
    if (file_exists($file)) {
        require $file;
    }
});

use App\Core\Router;

// Cargar rutas
require_once __DIR__ . '/src/Routes/api.php';

// Obtener la URL 
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Ajuste para cuando se usa el servidor local PHP -S en la raíz del proyecto
$scriptName = dirname($_SERVER['SCRIPT_NAME']); // ej: /api
if (strpos($uri, $scriptName) === 0) {
    $uri = substr($uri, strlen($scriptName));
}

if (empty($uri)) $uri = '/';

// Despachar la ruta
Router::dispatch($_SERVER['REQUEST_METHOD'], $uri);
