# AuraApp

## Documento Técnico de Arquitectura y Alcance (Versión Inicial)

Fecha: Marzo 2026

---

# 1. Introducción

AuraApp es una plataforma orientada a la **gestión inteligente de gastos personales** mediante una aplicación móvil conectada a una API central. El sistema está diseñado bajo un modelo **SaaS Freemium**, permitiendo crecimiento escalable y monetización futura.

El objetivo del sistema es permitir a los usuarios:

* Registrar gastos diarios
* Categorizar gastos
* Analizar hábitos financieros
* Obtener recomendaciones mediante IA
* Sincronizar datos entre múltiples dispositivos

El proyecto se ha diseñado considerando desde el inicio:

* escalabilidad
* sincronización offline
* soporte multiusuario
* integración con IA
* modelo SaaS

---

# 2. Arquitectura General del Sistema

La arquitectura de AuraApp se divide en cuatro componentes principales:

1. Aplicación móvil
2. API backend
3. Base de datos
4. Panel administrativo y herramientas de prueba

Arquitectura general:

Cliente móvil
↓
API REST (PHP)
↓
Base de datos MySQL
↓
Servicios de análisis e IA

También se incorpora un esquema híbrido de almacenamiento:

* SQLite en el dispositivo
* MySQL en el servidor

Esto permite funcionamiento **offline-first**.

---

# 3. Modelo de Datos

La base de datos fue diseñada pensando en:

* escalabilidad
* análisis financiero
* IA
* sincronización
* modelo SaaS multiusuario

Se optó por:

* claves foráneas en lugar de ENUM
* nombres en español
* notación PascalCase

Esto mejora:

* mantenibilidad
* claridad semántica
* extensibilidad del modelo

---

# 4. Base de Datos Principal (MySQL)

MySQL fue elegido por:

* amplia adopción
* estabilidad
* compatibilidad con hosting compartido
* facilidad de administración

El servidor MySQL contiene la información global del sistema.

Tablas principales:

Usuario
Contiene las cuentas del sistema.

Campos principales:

IdUsuario
Email
PasswordHash
FechaCreacion

---

Categoria

Lista de categorías de gasto.

Ejemplo:

Comida
Transporte
Entretenimiento

---

Gasto

Tabla principal del sistema.

Campos:

IdGasto
IdUsuario
IdCategoria
Monto
Descripcion
FechaGasto

Permite registrar cada gasto realizado por el usuario.

---

# 5. Base de Datos Local (SQLite)

La aplicación móvil utilizará SQLite para almacenamiento local.

Objetivos:

* permitir uso sin internet
* mejorar rendimiento
* evitar dependencia constante del servidor

La app registra cambios localmente y posteriormente sincroniza.

Ventajas del enfoque:

* experiencia offline
* menor latencia
* reducción de consumo de red

---

# 6. Motor de Sincronización

El sistema utiliza un modelo de sincronización inspirado en arquitecturas utilizadas por aplicaciones como:

Notion
Linear
Figma

El cliente registra operaciones locales:

insert
update
delete

Estas operaciones se envían al servidor mediante el endpoint:

POST /api/v1/sync

El servidor procesa las operaciones y devuelve el estado actualizado.

Beneficios:

* consistencia de datos
* sincronización entre dispositivos
* tolerancia a desconexión

---

# 7. Arquitectura de la API

La API fue desarrollada en PHP utilizando:

* PHP 8+
* arquitectura modular
* router propio
* middleware
* JWT para autenticación

Estructura del proyecto:

api/

public
src

Config
Controllers
Core
Middleware
Routes
Utils

---

public/index.php

Es el punto de entrada del sistema.

Todas las solicitudes HTTP pasan por este archivo.

Este patrón se denomina:

Front Controller Pattern.

---

# 8. Router

El router permite mapear rutas HTTP a controladores.

Ejemplo:

POST /api/v1/login → AuthController@login

Esto permite separar:

* lógica de negocio
* rutas
* controladores

Beneficios:

* mantenibilidad
* claridad de código
* escalabilidad

---

# 9. Autenticación

La autenticación utiliza JWT (JSON Web Tokens).

Flujo:

1 usuario hace login
2 servidor genera token
3 cliente guarda token
4 cliente envía token en cada request

Header requerido:

Authorization: Bearer TOKEN

Ventajas:

* stateless
* escalable
* estándar moderno

---

# 10. Endpoints Actuales

Autenticación

POST /api/v1/registro
Crear usuario

POST /api/v1/login
Autenticación

---

Gastos

GET /api/v1/gastos
Lista de gastos del usuario

POST /api/v1/gastos
Crear gasto

---

IA financiera

GET /api/v1/ia/analisis

Genera un análisis simple del comportamiento financiero del usuario.

---

# 11. Panel de Pruebas (API Tester)

Se creó una interfaz web para probar la API sin herramientas externas.

Ubicación:

/tester

Funciones:

* registrar usuario
* login
* crear gasto
* listar gastos

Tecnología:

HTML
JavaScript
Fetch API

---

# 12. Panel Administrativo

El sistema también incluye un panel administrativo.

Ubicación:

/admin

Objetivo:

* monitorear la plataforma
* visualizar métricas
* analizar crecimiento

Funciones previstas:

Usuarios totales
Gastos registrados
Últimos usuarios
Estadísticas financieras

Este panel se conectará a endpoints administrativos.

Ejemplo:

GET /api/v1/admin/dashboard

---

# 13. Modelo SaaS Freemium

AuraApp está diseñado como SaaS.

Se contempla implementar:

Usuario gratuito
Usuario premium

Posibles diferencias:

Número de categorías
Exportación de datos
Reportes avanzados
IA avanzada

Esto permitirá monetización futura.

---

# 14. Integración de Inteligencia Artificial

La IA se utilizará para generar valor adicional.

Funciones previstas:

1 categorización automática de gastos
2 detección de gastos anómalos
3 predicción de gasto mensual
4 recomendaciones de ahorro

Ejemplo:

"Tu gasto en restaurantes aumentó 32% este mes."

Esto se puede implementar mediante:

modelos estadísticos
machine learning
modelos LLM

---

# 15. Seguridad

Medidas implementadas:

hash de contraseñas
JWT
control de acceso mediante middleware

Recomendaciones futuras:

rate limiting
registro de logs
protección de endpoints admin

---

# 16. Escalabilidad

El diseño permite escalar a futuro mediante:

separación API / cliente
arquitectura modular
uso de tokens
sincronización offline

Posibles evoluciones:

microservicios
caching
cola de eventos

---

# 17. Despliegue Inicial

Se utilizará hosting compartido (Hostinger).

Estructura recomendada:

public_html/

api
tester
admin

La API se accede mediante:

dominio/api/v1

---

# 18. Próximos Pasos Recomendados

1 finalizar modelo de base de datos
2 implementar motor completo de sincronización
3 crear endpoints administrativos
4 implementar sistema freemium
5 desarrollar aplicación móvil
6 implementar IA financiera avanzada

---

# 19. Objetivo del Proyecto

AuraApp busca convertirse en una plataforma que permita:

* mejorar la educación financiera
* facilitar el control de gastos
* ofrecer recomendaciones inteligentes

El sistema está diseñado desde el inicio con una arquitectura que permita crecer desde un MVP hasta una plataforma SaaS completa.

---

Fin del documento
