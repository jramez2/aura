-- AuraApp: Migración para Borrado Lógico en Gastos
-- Ejecuta esto en tu phpMyAdmin o cliente SQL remoto

ALTER TABLE `Gastos` 
ADD `EliminadoEn` DATETIME NULL DEFAULT NULL 
AFTER `ActualizadoEn`;

-- Opcional: Crear un índice para mejorar la velocidad de las consultas que filtran por eliminados
CREATE INDEX `IdxGastosEliminado` ON `Gastos` (`EliminadoEn`);
