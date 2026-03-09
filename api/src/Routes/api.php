<?php
use App\Core\Router;

// ==========================================
// Rutas Públicas - Comprobación de salud API
// ==========================================
Router::get('/v1', function() {
    echo json_encode(["status" => "success", "message" => "AuraApp API v1 Working"]);
});

// Inicialización de Base de Datos (Correr una sola vez)
Router::get('/v1/setup/seed', 'SetupController@seed');

// ==========================================
// Admin Endpoints
// ==========================================
// Generar datos para el panel de Control (Dashboard Admin)
Router::get('/v1/admin/dashboard', 'AdminController@getDashboard');

// ==========================================
// User Authentication Endpoints
// ==========================================
Router::post('/v1/registro', 'AuthController@register');
Router::post('/v1/login', 'AuthController@login');
Router::post('/v1/usuario/perfil', 'UsuarioController@updateProfile');
Router::post('/v1/usuario/password', 'UsuarioController@updatePassword');

// ==========================================
// Gastos Endpoints
// ==========================================
Router::get('/v1/gastos', 'GastosController@index');
Router::post('/v1/gastos', 'GastosController@store');
Router::put('/v1/gastos/{id}', 'GastosController@update');
Router::post('/v1/gastos/actualizar', 'GastosController@update');
Router::post('/v1/gastos/eliminar/{id}', 'GastosController@delete');
Router::post('/v1/gastos/eliminar', 'GastosController@delete');
Router::delete('/v1/gastos/eliminar/{id}', 'GastosController@delete');
Router::put('/v1/gastos/restaurar/{id}', 'GastosController@restore');

// ==========================================
// Presupuestos Endpoints
// ==========================================
// Obtener comparativa Mes/Año Real vs Presupuestado
Router::get('/v1/presupuestos/comparativo', 'PresupuestosController@getComparativo');
// Guardar/Actualizar monto presupuestado para una categoría
Router::post('/v1/presupuestos/capturar', 'PresupuestosController@store');

// ==========================================
// Sincronización e IA
// ==========================================
Router::post('/v1/sync', 'SyncController@syncOffline');
Router::get('/v1/ia/analisis', 'IAController@analisisFinanciero');
