# Análisis de Riesgo para la Integración del Servicio de Gestión de Cuentas

## 1. Introducción
Este documento identifica los modos de falla potenciales en la integración del servicio de gestión de cuentas bancarias, evalúa su impacto y propone estrategias de mitigación. El análisis sigue la metodología FMEA (Failure Modes and Effects Analysis) adaptada a sistemas distribuidos.

## 2. Alcance
- **Sistema**: API REST de gestión de cuentas bancarias
- **Interfaces**: HTTP/REST, headers de idempotencia, payloads JSON
- **Protocolos**: HTTP/1.1 con TLS 1.2+, JSON Schema Draft 2020-12
- **Volumen**: 1,000 solicitudes/segundo con latencia < 200ms
- **Estándares**: RFC 7807 (Problem Details), BIAN Service Landscape, ISO 20022

## 3. Modos de Falla y Análisis

### 3.1. Fallas en la Capa de Contrato
| Modo de Falla                     | Causa Raíz                                                                 | Impacto                                                                                     | Severidad (1-10) | Probabilidad (1-10) | Riesgo | Mitigación                                                                                     |
|------------------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|------------------|----------------------|--------|-----------------------------------------------------------------------------------------------|
| Esquema OpenAPI desactualizado    | Cambios en el dominio no reflejados en el contrato                         | Inconsistencia entre documentación y implementación, errores en clientes generados        | 7                | 5                    | 35     | Pipeline CI/CD con validación automática del contrato contra implementación (Redocly lint)    |
| Payloads con tipos incorrectos    | Mapeo de datos incorrecto entre sistemas origen/destino                    | Rechazo de transacciones válidas o procesamiento de datos inválidos                         | 8                | 4                    | 32     | Validación estricta de schemas con JSON Schema Draft 2020-12 y ejemplos en cada endpoint      |
| Headers faltantes o inválidos     | Falta de documentación o implementación incorrecta de headers              | Rechazo de solicitudes, falta de idempotencia                                               | 6                | 6                    | 36     | Middleware de validación de headers obligatorios (Idempotency-Key, Content-Type)            |

### 3.2. Fallas en la Capa de Negocio
| Modo de Falla                     | Causa Raíz                                                                 | Impacto                                                                                     | Severidad | Probabilidad | Riesgo | Mitigación                                                                                     |
|------------------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|------------|--------------|--------|-----------------------------------------------------------------------------------------------|
| Fondos insuficientes no detectados| Lógica de validación incorrecta en transacciones de débito                 | Sobre-giro de cuentas, pérdidas financieras para el banco                                  | 9          | 3            | 27     | Validación síncrona del saldo antes de procesar transacciones + compensación con reservas    |
| Duplicación de operaciones        | Falta de idempotencia en endpoints POST/PATCH                              | Creación de cuentas duplicadas, actualizaciones inconsistentes                             | 8          | 5            | 40     | Implementación de idempotencia con cache de claves (TTL 24h) y UUIDv4 obligatorio            |
| Inconsistencia en estados de cuenta| Transacciones no atomicicas entre sistemas                                | Estados de cuenta incorrectos visibles para clientes                                       | 9          | 4            | 36     | Saga pattern con compensación para operaciones multi-sistema + eventual consistency          |
| Falta de trazabilidad             | Logs incompletos o no correlacionados                                      | Dificultad para auditar operaciones, incumplimiento de regulaciones                        | 7          | 6            | 42     | Headers de correlación (X-Request-ID) + logs estructurados con contexto completo              |

### 3.3. Fallas en la Capa de Infraestructura
| Modo de Falla                     | Causa Raíz                                                                 | Impacto                                                                                     | Severidad | Probabilidad | Riesgo | Mitigación                                                                                     |
|------------------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|------------|--------------|--------|-----------------------------------------------------------------------------------------------|
| Latencia > 200ms                  | Sobrecarga en el servicio o dependencias lentas                            | Degradación de experiencia de usuario, posibles timeouts en clientes                       | 6          | 7            | 42     | Circuit breaker (Resilience4j) + caching con Redis (TTL 5s) para consultas frecuentes        |
| Servicio no disponible            | Fallo en el despliegue o dependencias caídas                               | Interrupción del servicio, pérdida de operaciones                                           | 10         | 2            | 20     | Alta disponibilidad con réplicas en múltiples zonas + health checks                          |
| Pérdida de datos                  | Fallo en la persistencia sin mecanismos de recuperación                    | Inconsistencia permanente en cuentas, incumplimiento de regulaciones                       | 10         | 1            | 10     | Transacciones ACID en base de datos + replica asíncrona en otra región                       |
| Ataques de denegación de servicio | Alto volumen de solicitudes maliciosas                                     | Inaccesibilidad del servicio para usuarios legítimos                                        | 8          | 5            | 40     | Rate limiting (100 req/min por cliente) + WAF con reglas OWASP                               |

## 4. Estrategias de Mitigación Transversales

### 4.1. Idempotencia
- **Mecanismo**: Header `Idempotency-Key` con UUIDv4 obligatorio para todas las operaciones no idempotentes por defecto (POST, PATCH)
- **Implementación**:
  - Cache distribuido (Redis) con TTL de 24 horas para almacenar respuestas idempotentes
  - Middleware que valida la existencia de la clave antes de procesar la solicitud
  - Respuesta HTTP 200 con el mismo payload para solicitudes duplicadas
- **Ejemplo de flujo**:
  ```mermaid
  sequenceDiagram
    participant Cliente
    participant API
    participant Redis
    Cliente->>API: POST /cuentas (Idempotency-Key: uuid-123)
    API->>Redis: Verificar existencia de uuid-123
    Redis-->>API: No existe
    API->>API: Procesar solicitud
    API->>Redis: Almacenar uuid-123 con respuesta
    API-->>Cliente: HTTP 201 (Creado)
    Cliente->>API: POST /cuentas (Idempotency-Key: uuid-123)
    API->>Redis: Verificar existencia de uuid-123
    Redis-->>API: Existe
    API-->>Cliente: HTTP 200 (Mismo payload)
  ```

### 4.2. Manejo de Errores
- **Estándar**: RFC 7807 (Problem Details) para todos los errores del dominio
- **Códigos de error predefinidos**:
  - `400`: Invalid-request (datos de entrada inválidos)
  - `403`: Insufficient-funds / Insufficient-conditions
  - `404`: Not-found (recurso no existe)
  - `409`: Conflict (estado inválido para la operación)
  - `429`: Too-many-requests
  - `500`: Internal-server-error (fallos no recuperables)
- **Ejemplo de respuesta**:
  ```json
  {
    "type": "https://api.bancolombia.com/errors/insufficient-funds",
    "title": "Fondos insuficientes",
    "status": 403,
    "detail": "La cuenta no tiene fondos suficientes para realizar la transacción.",
    "accountId": "12345",
    "currentBalance": 1000.50,
    "requiredAmount": 1500.00,
    "retryable": false,
    "_links": {
      "deposit": {
        "href": "https://api.bancolombia.com/cuentas/12345/depositos"
      }
    }
  }
  ```

### 4.3. Resiliencia
- **Patrones implementados**:
  1. **Circuit Breaker**: Para dependencias externas (ej. servicio de auditoría)
     - Umbral de fallos: 5 errores consecutivos
     - Tiempo de espera: 30 segundos
     - Estado: Cerrado → Abierto → Medio abierto
  2. **Retry con Backoff Exponencial**: Para operaciones recuperables (ej. fallos temporales en BD)
     - Intentos máximos: 3
     - Tiempo inicial: 100ms
     - Factor: 2
  3. **Fallback**: Para operaciones no críticas
     - Ejemplo: Si el servicio de notificaciones falla, encolar la notificación para procesamiento posterior

- **Herramientas**:
  - Resilience4j para circuit breaker y retry
  - Kafka para colas de fallback
  - Redis para caching de consultas frecuentes

### 4.4. Observabilidad
- **Métricas**:
  - Latencia por endpoint (p50, p90, p99)
  - Tasa de error por endpoint
  - Throughput (solicitudes/segundo)
  - Tamaño promedio de payloads
- **Logs**:
  - Estructurados en JSON con campos obligatorios:
    ```json
    {
      "timestamp": "ISO8601",
      "level": "INFO|WARN|ERROR",
      "requestId": "UUID",
      "accountId": "string",
      "operation": "string",
      "durationMs": number,
      "statusCode": number,
      "errorType": "string (opcional)"
    }
    ```
- **Trazas**:
  - Headers de correlación `X-Request-ID` propagados a todas las dependencias
  - Integración con Jaeger para tracing distribuido

## 5. Plan de Contingencia

| Escenario                          | Acción                                                                                     | Responsable          | Tiempo de Respuesta |
|------------------------------------|-------------------------------------------------------------------------------------------|----------------------|---------------------|
| Servicio caído                    | Failover a réplica en otra zona + notificación a DevOps                                  | Equipo de Operaciones| < 5 minutos         |
| Base de datos inaccesible          | Switch a réplica asíncrona + notificación a DBA                                          | Equipo de Datos      | < 10 minutos        |
| Ataque DDoS                        | Activar reglas WAF adicionales + escalar a equipo de Seguridad                           | Equipo de Seguridad  | < 15 minutos        |
| Contrato OpenAPI desactualizado    | Rollback a versión anterior del contrato + notificación a equipo de Desarrollo           | Equipo de Desarrollo | < 30 minutos        |
| Fuga de datos                      | Aislar el servicio + escalar a Legal y Seguridad                                          | Equipo de Seguridad  | < 1 hora            |

## 6. Cumplimiento de Estándares

### 6.1. BIAN Service Landscape
- **Servicio mapeado**: `Account Management` (BIAN Service Domain)
- **Operaciones alineadas**:
  - `OpenAccount` → POST `/cuentas`
  - `UpdateAccount` → PATCH `/cuentas/{accountId}`
  - `RetrieveAccount` → GET `/cuentas/{accountId}`
  - `CloseAccount` → DELETE `/cuentas/{accountId}`
- **Atributos**:
  - `accountId`: Identificador único de la cuenta
  - `accountType`: Categorización según BIAN (AHORROS, CORRIENTE, CDT)
  - `accountStatus`: Estados definidos por BIAN (ACTIVA, BLOQUEADA, CERRADA)

### 6.2. ISO 20022
- **Mensajes utilizados**:
  - `acmt.007`: Account modification notification
  - `acmt.008`: Account closure notification
- **Elementos de datos**:
  - `Acct`: Estructura de cuenta con `Id` y `Tp`
  - `Bal`: Balance de la cuenta
  - `Sts`: Estado de la cuenta

### 6.3. FAPI (Financial-grade API)
- **Requisitos cumplidos**:
  - Autenticación OAuth 2.0 con scope `accounts`
  - Headers de seguridad: `Authorization`, `x-fapi-interaction-id`
  - TLS 1.2+ obligatorio
  - Rate limiting por cliente

## 7. Escenarios de Prueba para Validación de Riesgos

### 7.1. Prueba de Idempotencia
**Objetivo**: Validar que operaciones duplicadas no generan efectos secundarios no deseados.

**Escenario**:
1. Enviar solicitud POST `/cuentas` con `Idempotency-Key: uuid-1`
2. Registrar el `accountId` generado
3. Enviar la misma solicitud con el mismo `Idempotency-Key`
4. Validar que:
   - La segunda respuesta es HTTP 200
   - El `accountId` es el mismo que en el paso 2
   - No se creó una nueva cuenta en la base de datos

**Herramientas**: Postman/SoapUI + consulta directa a BD

### 7.2. Prueba de Resiliencia
**Objetivo**: Validar que el servicio tolera fallos parciales en dependencias.

**Escenario**:
1. Detener el servicio de auditoría
2. Enviar solicitud POST `/cuentas`
3. Validar que:
   - La respuesta es HTTP 201
   - El circuito breaker del servicio de auditoría está en estado abierto
   - La operación de auditoría está encolada para reprocesamiento

**Herramientas**: Resilience4j + Kafka + logs

### 7.3. Prueba de Carga
**Objetivo**: Validar que el servicio cumple con el SLA de latencia bajo carga.

**Escenario**:
1. Generar 1,000 solicitudes GET `/cuentas/{accountId}` concurrentes
2. Medir latencia p99
3. Validar que:
   - Latencia p99 < 200ms
   - Tasa de error = 0%
   - Throughput >= 1,000 req/segundo

**Herramientas**: Gatling/JMeter + Prometheus/Grafana

## 8. Conclusiones
- Los riesgos más críticos están asociados a la **inconsistencia de datos** (severidad 9) y la **falta de idempotencia** (riesgo 40).
- Las estrategias de mitigación propuestas (idempotencia, circuit breaker, observabilidad) reducen significativamente el impacto de estos riesgos.
- El cumplimiento de estándares BIAN e ISO 20022 asegura la interoperabilidad con otros sistemas financieros.
- La implementación de FAPI garantiza un nivel adecuado de seguridad para una API financiera.

## 9. Recomendaciones
1. Implementar un **pipeline de CI/CD** que valide automáticamente:
   - La sintaxis del OpenAPI con `redocly lint`
   - La coherencia entre el contrato y la implementación
   - Los ejemplos de payloads en los endpoints

2. Realizar **pruebas de penetración** para validar la seguridad de la API, especialmente en:
   - Autenticación y autorización
   - Validación de headers
   - Rate limiting

3. Documentar un **runbook** para operaciones que incluya:
   - Pasos para failover manual
   - Comandos para verificar el estado de los circuit breakers
   - Procedimientos para reprocesar operaciones fallidas

4. Establecer **alertas proactivas** para:
   - Latencia > 150ms
   - Tasa de error > 1%
   - Circuit breakers abiertos

5. Realizar **simulacros de recuperación** trimestrales para validar la efectividad del plan de contingencia.