<?php
namespace App\Core;

class Router {
    private static $routes = [];

    public static function get($route, $callback) {
        self::$routes['GET'][$route] = $callback;
    }

    public static function post($route, $callback) {
        self::$routes['POST'][$route] = $callback;
    }

    public static function delete($route, $callback) {
        self::$routes['DELETE'][$route] = $callback;
    }

    public static function put($route, $callback) {
        self::$routes['PUT'][$route] = $callback;
    }

    public static function dispatch($method, $uri) {
        // Limpiar URI y normalizar
        $uri = rtrim($uri, '/');
        if (empty($uri)) $uri = '/';

        if (isset(self::$routes[$method])) {
            foreach (self::$routes[$method] as $route => $callback) {
                // Convertir parámetros {param} a regex
                $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '([^/]+)', $route);
                $pattern = "@^" . $pattern . "$@";
                
                if (preg_match($pattern, $uri, $matches)) {
                    array_shift($matches); // Remover la coincidencia completa
                    
                    // Si es una función anónima, se llama directo
                    if (is_callable($callback)) {
                        call_user_func_array($callback, $matches);
                        return;
                    }
                    
                    // Si es formato Controlador@Metodo
                    if (is_string($callback) && strpos($callback, '@') !== false) {
                        list($controllerName, $methodName) = explode('@', $callback);
                        $controllerClass = "App\\Controllers\\" . $controllerName;
                        
                        if (class_exists($controllerClass)) {
                            $controller = new $controllerClass();
                            if (method_exists($controller, $methodName)) {
                                call_user_func_array([$controller, $methodName], $matches);
                                return;
                            } else {
                                self::sendError(500, "Método $methodName no encontrado en $controllerClass");
                                return;
                            }
                        } else {
                            self::sendError(500, "Controlador $controllerClass no encontrado");
                            return;
                        }
                    }
                }
            }
        }
        
        self::sendError(404, "Ruta no encontrada: $method $uri");
    }

    private static function sendError($status, $message) {
        http_response_code($status);
        echo json_encode(["status" => "error", "message" => $message]);
    }
}
