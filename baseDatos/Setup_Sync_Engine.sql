-- AuraApp: Soporte para Sincronización Inteligente
-- Ejecuta esto en tu base de datos remota MySQL

-- Asegurarnos de que Gastos tenga un campo UUID y SincronizadoID para conflictos
-- Nota: Si los campos ya existen en tu SQL original, este script solo asegura consistencia.

ALTER TABLE `Gastos` 
ADD COLUMN IF NOT EXISTS `IdentificadorLocal` VARCHAR(100) NULL COMMENT 'ID generado por el celular para evitar duplicados' AFTER `GastoId`,
ADD COLUMN IF NOT EXISTS `Version` INT DEFAULT 1 AFTER `EliminadoEn`;

-- Tabla de registro de sincronizaciones (Opcional si ya existe)
CREATE TABLE IF NOT EXISTS `Sincronizaciones` (
  `SincronizacionId` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `UsuarioId` BIGINT NOT NULL,
  `Dispositivo` VARCHAR(100),
  `UltimaSincronizacion` DATETIME,
  `Resultado` TEXT,
  FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`UsuarioId`)
);
