-- 1. Eliminar duplicados manteniendo solo el registro más reciente (o mayor monto)
DELETE p1 FROM Presupuestos p1
INNER JOIN Presupuestos p2 
WHERE p1.PresupuestoId < p2.PresupuestoId 
  AND p1.UsuarioId = p2.UsuarioId 
  AND p1.CategoriaGastoId = p2.CategoriaGastoId 
  AND p1.Anio = p2.Anio 
  AND p1.Mes = p2.Mes;

-- 2. Agregar la restricción de unicidad para evitar que esto vuelva a pasar
-- Esto hará que ON DUPLICATE KEY UPDATE funcione correctamente
ALTER TABLE Presupuestos 
ADD UNIQUE KEY `Idx_Presupuesto_Unico` (UsuarioId, CategoriaGastoId, Anio, Mes);
