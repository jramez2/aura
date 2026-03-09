<?php
namespace App\Controllers;

use App\Config\Database;
use PDO;

class AdminController {
    
    // GET /v1/admin/dashboard
    public function getDashboard() {
        try {
            $db = (new Database())->getConnection();

            // 1. Usuarios Totales
            $stmt = $db->query("SELECT COUNT(*) as total FROM Usuarios");
            $totalUsers = $stmt->fetch()['total'];

            // 2. Usuarios Premium (Plan 2)
            $stmt = $db->query("SELECT COUNT(*) as total FROM Usuarios WHERE PlanUsuarioId = 2");
            $premiumUsers = $stmt->fetch()['total'];

            // 3. Gastos Registrados Totales (No eliminados)
            $stmt = $db->query("SELECT COUNT(*) as total FROM Gastos WHERE EliminadoEn IS NULL");
            $totalExpenses = $stmt->fetch()['total'];

            // 4. Ingresos MRR (Sumatoria de precios mensuales de planes de usuarios activos)
            $stmt = $db->query("SELECT SUM(p.PrecioMensual) as mrr 
                               FROM Usuarios u 
                               JOIN PlanesUsuario p ON u.PlanUsuarioId = p.PlanUsuarioId");
            $mrrTotal = $stmt->fetch()['mrr'] ?? 0;

            // 5. Datos para Gráfico de Distribución (Gastos por Categoría)
            $stmt = $db->query("SELECT c.Nombre, COUNT(g.GastoId) as cantidad 
                               FROM CategoriasGasto c 
                               LEFT JOIN Gastos g ON c.CategoriaGastoId = g.CategoriaGastoId AND g.EliminadoEn IS NULL
                               GROUP BY c.CategoriaGastoId");
            $categoriesRaw = $stmt->fetchAll();
            $catLabels = [];
            $catData = [];
            foreach($categoriesRaw as $row) {
                $catLabels[] = $row['Nombre'];
                $catData[] = (int)$row['cantidad'];
            }

            // 6. Crecimiento de Usuarios (Últimos 6 meses simplificados por ahora)
            // En un dashboard real esto sería una consulta agrupada por mes
            $userGrowth = [0, 0, 0, 0, 0, $totalUsers]; // Mock incremental básico basado en el total actual

            // 7. Últimos Usuarios Registrados
            $stmt = $db->query("SELECT u.NombreMostrar as name, u.Email as email, u.CreadoEn as date, 
                                      p.Nombre as plan, 
                                      (SELECT COUNT(*) FROM Gastos WHERE UsuarioId = u.UsuarioId) as expenses
                               FROM Usuarios u 
                               JOIN PlanesUsuario p ON u.PlanUsuarioId = p.PlanUsuarioId
                               ORDER BY u.CreadoEn DESC LIMIT 5");
            $recentUsersRaw = $stmt->fetchAll();
            $recentUsers = [];
            foreach($recentUsersRaw as $user) {
                $recentUsers[] = [
                    "name" => $user['name'],
                    "email" => $user['email'],
                    "date" => date('d M Y', strtotime($user['date'])),
                    "plan" => $user['plan'],
                    "expenses" => (int)$user['expenses'],
                    "status" => "Activo"
                ];
            }

            $data = [
                "status" => "success",
                "data" => [
                    "metrics" => [
                        "total_users" => (int)$totalUsers,
                        "total_expenses" => (int)$totalExpenses,
                        "premium_users" => (int)$premiumUsers,
                        "mrr" => (float)$mrrTotal
                    ],
                    "charts" => [
                        "userGrowth" => $userGrowth,
                        "expensesCategories" => $catData,
                        "expensesLabels" => $catLabels
                    ],
                    "recent_users" => $recentUsers
                ]
            ];

            http_response_code(200);
            header('Content-Type: application/json');
            echo json_encode($data);

        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error en Dashboard: " . $e->getMessage()]);
        }
    }
}
