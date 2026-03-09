<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class IAController {

    /**
     * GET /v1/ia/analisis
     * Genera un análisis financiero asistido por "inteligencia" de reglas
     */
    public function analisisFinanciero() {
        $usuarioId = AuthMiddleware::validateToken();
        $db = (new Database())->getConnection();

        try {
            $month = date('m');
            $year = date('Y');
            
            // 1. Obtener gastos detallados con su Sección (Padre)
            $query = "SELECT g.Monto, c.Nombre as Categoria, p.Nombre as Seccion
                      FROM Gastos g 
                      JOIN CategoriasGasto c ON g.CategoriaGastoId = c.CategoriaGastoId
                      LEFT JOIN CategoriasGasto p ON c.CategoriaPadreId = p.CategoriaGastoId
                      WHERE g.UsuarioId = :uid 
                      AND MONTH(g.FechaGasto) = :month 
                      AND YEAR(g.FechaGasto) = :year
                      AND g.EliminadoEn IS NULL";
            
            $stmt = $db->prepare($query);
            $stmt->execute(['uid' => $usuarioId, 'month' => $month, 'year' => $year]);
            $gastos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // 2. Obtener comparativa de presupuesto desde la Vista
            $stmtPres = $db->prepare("SELECT * FROM Vista_ComparativoPresupuesto WHERE UsuarioId = :uid AND Anio = :year AND Mes = :month");
            $stmtPres->execute(['uid' => $usuarioId, 'year' => $year, 'month' => $month]);
            $comparativo = $stmtPres->fetchAll(PDO::FETCH_ASSOC);

            $totalMes = 0;
            $porSeccion = [];
            foreach ($gastos as $g) {
                $totalMes += (float)$g['Monto'];
                $sec = $g['Seccion'] ?? 'Otros';
                $porSeccion[$sec] = ($porSeccion[$sec] ?? 0) + (float)$g['Monto'];
            }

            // 3. Generar "Aura Insights" (Motor de reglas con presupuesto)
            $insights = $this->generarInsights($totalMes, $porSeccion, $comparativo);

            echo json_encode([
                "status" => "success",
                "data" => [
                    "resumen_mes" => [
                        "total" => $totalMes,
                        "mes_nombre" => date('F'),
                        "num_transacciones" => count($gastos)
                    ],
                    "distribucion_por_seccion" => $porSeccion,
                    "presupuesto_vs_real" => $comparativo,
                    "aura_insights" => $insights,
                    "ia_status" => "Brain Model v2.0 (Budget-Aware) Active"
                ]
            ]);

        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error en la IA: " . $e->getMessage()]);
        }
    }

    private function generarInsights($total, $porSeccion, $comparativo) {
        $tips = [];

        // Regla 1: Alerta de Presupuesto Excedido por Sección
        foreach ($comparativo as $item) {
            if ($item['Real_Gastado'] > $item['Presupuestado'] && $item['Presupuestado'] > 0) {
                $tips[] = [
                    "tipo" => "alerta",
                    "titulo" => "Exceso en " . $item['Categoria'],
                    "mensaje" => "Has superado tu presupuesto en " . $item['Categoria'] . " por $" . number_format($item['Real_Gastado'] - $item['Presupuestado'], 2)
                ];
            }
        }

        // Regla 2: Dominio de Alimentos (Sección ALIMENTOS)
        if (isset($porSeccion['ALIMENTOS']) && $porSeccion['ALIMENTOS'] > ($total * 0.4)) {
            $tips[] = [
                "tipo" => "optimización",
                "titulo" => "Fuga en Alimentación",
                "mensaje" => "La sección de Alimentos representa más del 40% de tus gastos totales. ¡Ojo con las comidas fuera!"
            ];
        }

        // Regla 3: Capacidad de ahorro
        if ($total > 0 && $total < 5000) {
            $tips[] = [
                "tipo" => "felicitación",
                "titulo" => "Excelente Control",
                "mensaje" => "Tus gastos están muy bien controlados este mes. ¡Sigue así!"
            ];
        }

        $tips[] = [
            "tipo" => "aura_tip",
            "titulo" => "Hábito Financiero",
            "mensaje" => "Recuerda que lo que no se mide, no se puede mejorar. Sigue registrando cada gasto."
        ];

        return $tips;
    }
}
