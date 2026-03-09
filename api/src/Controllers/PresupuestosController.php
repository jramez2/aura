<?php
namespace App\Controllers;

use App\Config\Database;
use App\Middleware\AuthMiddleware;
use PDO;

class PresupuestosController {

    // GET /v1/presupuestos/comparativo?anio=2026&mes=03
    public function getComparativo() {
        $usuarioId = AuthMiddleware::validateToken();
        
        $anio = isset($_GET['anio']) ? $_GET['anio'] : date('Y');
        $mes = isset($_GET['mes']) ? $_GET['mes'] : date('m');
        
        $db = (new Database())->getConnection();
        
        try {
            // 1. Calcular mes anterior para copiar montos
            $mesPrev  = $mes == 1  ? 12       : $mes - 1;
            $anioPrev = $mes == 1  ? $anio - 1 : $anio;

            // 2. Inicializar presupuesto para el periodo solicitado.
            //    Copia los montos del mes anterior cuando existen; si no, inserta con 0.
            //    Incluye categorías del sistema Y las personalizadas del usuario.
            //    INSERT IGNORE evita sobreescribir registros ya capturados.
            $initSql = "
                INSERT IGNORE INTO Presupuestos 
                    (UsuarioId, CategoriaGastoId, Monto, MonedaId, Anio, Mes, TipoPeriodoId)
                SELECT
                    :uid,
                    cat.CategoriaGastoId,
                    COALESCE(prev.Monto, 0.00),
                    COALESCE(
                        prev.MonedaId,
                        (SELECT MonedaPreferidaId FROM Usuarios WHERE UsuarioId = :uid2 LIMIT 1),
                        1
                    ),
                    :anio,
                    :mes,
                    1
                FROM CategoriasGasto cat
                LEFT JOIN Presupuestos prev
                       ON prev.UsuarioId        = :uid3
                      AND prev.CategoriaGastoId = cat.CategoriaGastoId
                      AND prev.Anio             = :anioPrev
                      AND prev.Mes              = :mesPrev
                WHERE cat.CategoriaPadreId IS NOT NULL
                  AND (cat.EsSistema = 1 OR cat.UsuarioId = :uid4)
            ";
            $initStmt = $db->prepare($initSql);
            $initStmt->execute([
                'uid'     => $usuarioId,
                'uid2'    => $usuarioId,
                'uid3'    => $usuarioId,
                'uid4'    => $usuarioId,
                'anio'    => $anio,
                'mes'     => $mes,
                'anioPrev' => $anioPrev,
                'mesPrev'  => $mesPrev,
            ]);

            // 3. Consultamos TODAS las secciones (padres) del usuario/sistema
            // y les unimos sus categorías (hijos) y el presupuesto del periodo.
            // Nota: PDO emulado no permite repetir el mismo nombre de parámetro,
            // por eso se usan aliases únicos (uid2, uid3, etc.).
            $query = "SELECT 
                        sec.CategoriaGastoId  AS SeccionId,
                        sec.Nombre            AS Seccion,
                        sec.EsSistema         AS SeccionEsSistema,
                        cat.CategoriaGastoId,
                        cat.Nombre            AS Categoria,
                        cat.EsSistema,
                        COALESCE(p.Monto, 0)  AS MontoPresupuestado,
                        COALESCE((
                            SELECT SUM(Monto) FROM Gastos 
                            WHERE  CategoriaGastoId = cat.CategoriaGastoId 
                              AND  UsuarioId         = :uid_sub
                              AND  YEAR(FechaGasto)  = :anio_sub
                              AND  MONTH(FechaGasto) = :mes_sub
                              AND  EliminadoEn IS NULL
                        ), 0) AS MontoReal
                      FROM CategoriasGasto sec
                      LEFT JOIN CategoriasGasto cat ON cat.CategoriaPadreId = sec.CategoriaGastoId
                      LEFT JOIN Presupuestos p 
                             ON p.CategoriaGastoId = cat.CategoriaGastoId 
                            AND p.UsuarioId        = :uid_join
                            AND p.Anio             = :anio_join
                            AND p.Mes              = :mes_join
                      WHERE sec.CategoriaPadreId IS NULL 
                        AND (sec.EsSistema = 1 OR sec.UsuarioId = :uid_where)
                      ORDER BY sec.Nombre, cat.Nombre";
            
            $stmt = $db->prepare($query);
            $stmt->execute([
                'uid_sub'   => $usuarioId,
                'anio_sub'  => $anio,
                'mes_sub'   => $mes,
                'uid_join'  => $usuarioId,
                'anio_join' => $anio,
                'mes_join'  => $mes,
                'uid_where' => $usuarioId,
            ]);
            $datos = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Agrupar por sección
            $agrupado = [];
            foreach ($datos as $row) {
                $seccionId = $row['SeccionId'];
                if (!isset($agrupado[$seccionId])) {
                    $agrupado[$seccionId] = [
                        "SeccionId"   => $seccionId,
                        "Seccion"     => $row['Seccion'],
                        "EsSistema"   => (bool) $row['SeccionEsSistema'],
                        "Items"       => []
                    ];
                }
                // Solo añadir a Items si hay una categoría hija real
                if ($row['CategoriaGastoId']) {
                    $row['EsSistema'] = (bool) $row['EsSistema'];
                    $agrupado[$seccionId]["Items"][] = $row;
                }
            }
            
            echo json_encode([
                "status" => "success",
                "anio" => $anio,
                "mes" => $mes,
                "data" => array_values($agrupado)
            ]);
            
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al consultar presupuesto: " . $e->getMessage()]);
        }
    }

    // POST /v1/presupuestos/capturar
    public function store() {
        $usuarioId = AuthMiddleware::validateToken();
        $data = json_decode(file_get_contents("php://input"));
        
        if(empty($data->categoria_id) || !isset($data->monto)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "CategoriaId y Monto son requeridos"]);
            return;
        }

        $db = (new Database())->getConnection();
        
        $anio = isset($data->anio) ? $data->anio : date('Y');
        $mes = isset($data->mes) ? $data->mes : date('m');
        
        try {
            // Insertamos o actualizamos (UPSERT)
            $query = "INSERT INTO Presupuestos (UsuarioId, CategoriaGastoId, Monto, Anio, Mes, TipoPeriodoId) 
                      VALUES (:uid, :catId, :monto, :anio, :mes, 1)
                      ON DUPLICATE KEY UPDATE Monto = :monto_upd";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(":uid", $usuarioId);
            $stmt->bindParam(":catId", $data->categoria_id);
            $stmt->bindParam(":monto", $data->monto);
            $stmt->bindParam(":monto_upd", $data->monto);
            $stmt->bindParam(":anio", $anio);
            $stmt->bindParam(":mes", $mes);
            
            if($stmt->execute()) {
                echo json_encode(["status" => "success", "message" => "Presupuesto actualizado correctamente"]);
            } else {
                throw new \Exception("No se pudo guardar el presupuesto");
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Error al guardar: " . $e->getMessage()]);
        }
    }
}
