<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class ReportesController {

    // GET /v1/reportes/consolidado?anio=2026&mes_inicio=1&mes_fin=12
    public function getConsolidado() {
        $usuarioId = AuthMiddleware::validateToken();
        
        $anio = isset($_GET['anio']) ? intval($_GET['anio']) : date('Y');
        $mesInicio = isset($_GET['mes_inicio']) ? intval($_GET['mes_inicio']) : 1;
        $mesFin = isset($_GET['mes_fin']) ? intval($_GET['mes_fin']) : 12;
        
        $db = (new Database())->getConnection();
        
        try {
            // 1. Obtener todas las secciones y categorías del usuario
            $catQuery = "SELECT 
                            sec.CategoriaGastoId AS SeccionId,
                            sec.Nombre AS Seccion,
                            cat.CategoriaGastoId,
                            cat.Nombre AS Categoria
                         FROM CategoriasGasto sec
                         JOIN CategoriasGasto cat ON cat.CategoriaPadreId = sec.CategoriaGastoId
                         WHERE sec.CategoriaPadreId IS NULL 
                           AND (sec.EsSistema = 1 OR sec.UsuarioId = :uid)
                         ORDER BY sec.Nombre, cat.Nombre";
            
            $stmt = $db->prepare($catQuery);
            $stmt->execute(['uid' => $usuarioId]);
            $categorias = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // 2. Obtener todos los presupuestos para el rango seleccionado
            $presQuery = "SELECT CategoriaGastoId, Mes, Monto 
                          FROM Presupuestos 
                          WHERE UsuarioId = :uid AND Anio = :anio AND Mes BETWEEN :m_ini AND :m_fin";
            $stmt = $db->prepare($presQuery);
            $stmt->execute(['uid' => $usuarioId, 'anio' => $anio, 'm_ini' => $mesInicio, 'm_fin' => $mesFin]);
            $presupuestos = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Map presupuestos: [catId][mes] = monto
            $presMap = [];
            foreach ($presupuestos as $p) {
                $presMap[$p['CategoriaGastoId']][$p['Mes']] = floatval($p['Monto']);
            }

            // 3. Obtener todos los gastos reales del periodo
            $gastosQuery = "SELECT CategoriaGastoId, MONTH(FechaGasto) as Mes, SUM(Monto) as TotalReal
                            FROM Gastos
                            WHERE UsuarioId = :uid AND YEAR(FechaGasto) = :anio 
                              AND MONTH(FechaGasto) BETWEEN :m_ini AND :m_fin
                              AND EliminadoEn IS NULL
                            GROUP BY CategoriaGastoId, Mes";
            $stmt = $db->prepare($gastosQuery);
            $stmt->execute(['uid' => $usuarioId, 'anio' => $anio, 'm_ini' => $mesInicio, 'm_fin' => $mesFin]);
            $reales = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Map reales: [catId][mes] = monto
            $realMap = [];
            foreach ($reales as $r) {
                $realMap[$r['CategoriaGastoId']][$r['Mes']] = floatval($r['TotalReal']);
            }

            // 4. Estructurar la data para el frontend
            $periodo = [];
            for ($m = $mesInicio; $m <= $mesFin; $m++) {
                $periodo[] = $m;
            }

            $reporte = [
                "anio" => $anio,
                "mes_inicio" => $mesInicio,
                "mes_fin" => $mesFin,
                "meses" => $periodo,
                "data" => []
            ];

            // Agrupar por Secciones
            $secciones = [];
            foreach ($categorias as $c) {
                $sid = $c['SeccionId'];
                if (!isset($secciones[$sid])) {
                    $secciones[$sid] = [
                        "Id" => $sid,
                        "Nombre" => $c['Seccion'],
                        "Categorias" => [],
                        "Totales" => array_fill_keys($periodo, ["P" => 0, "R" => 0])
                    ];
                }

                $catId = $c['CategoriaGastoId'];
                $valoresCat = [];
                foreach ($periodo as $m) {
                    $pVal = $presMap[$catId][$m] ?? 0;
                    $rVal = $realMap[$catId][$m] ?? 0;
                    $valoresCat[$m] = [
                        "P" => $pVal,
                        "R" => $rVal,
                        "D" => $pVal - $rVal
                    ];
                    
                    // Sumar a totales de sección
                    $secciones[$sid]["Totales"][$m]["P"] += $pVal;
                    $secciones[$sid]["Totales"][$m]["R"] += $rVal;
                }

                $secciones[$sid]["Categorias"][] = [
                    "Id" => $catId,
                    "Nombre" => $c['Categoria'],
                    "Meses" => $valoresCat
                ];
            }

            $reporte["data"] = array_values($secciones);

            echo json_encode(["status" => "success", "data" => $reporte]);

        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
    }
}
