# Requisitos Funcionales y No Funcionales

## 1. Actores

| Actor                | Descripción                                                                                     | Responsabilidades                                                                                     |
|----------------------|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| **Cliente Bancario** | Usuario final que interactúa con el sistema para gestionar sus cuentas bancarias.              | - Crear cuentas bancarias.
- Consultar información de cuentas.
- Actualizar datos de cuentas.
- Eliminar cuentas.
- Realizar transferencias entre cuentas.
- Consultar movimientos y saldos. |
| **Sistema Bancario** | Sistema interno que gestiona la información de las cuentas y ejecuta operaciones financieras. | - Validar operaciones financieras.
- Aplicar políticas de negocio (ej. saldo mínimo).
- Registrar transacciones.
- Generar reportes de operaciones. |
| **Servicio de Autenticación** | Servicio externo encargado de validar la identidad de los usuarios.                          | - Autenticar usuarios mediante credenciales.
- Generar tokens de sesión.
- Validar permisos de acceso. |
| **Servicio de Notificaciones** | Servicio externo encargado de enviar notificaciones a los usuarios.                           | - Enviar notificaciones por correo electrónico.
- Enviar notificaciones por SMS.
- Registrar eventos de notificación. |

---

## 2. Operaciones CRUD

### 2.1. Creación de Cuentas (`POST /cuentas-bancarias`)

**Descripción**: Permite a un cliente bancario crear una nueva cuenta.

**Requisitos Funcionales**:
- El cliente debe proporcionar los siguientes datos obligatorios:
  - `tipoCuenta` (ej. "AHORROS", "CORRIENTE", "INVERSION").
  - `moneda` (ej. "COP", "USD", "EUR").
  - `titular` (objeto con `identificacion`, `nombre`, `apellido` y `tipoIdentificacion`).
  - `saldoInicial` (valor numérico mayor o igual a 0).
- El sistema debe validar:
  - Que el `saldoInicial` cumpla con el saldo mínimo requerido para el tipo de cuenta.
  - Que el `titular` no tenga una cuenta activa del mismo tipo y moneda.
  - Que el `tipoIdentificacion` sea válido (ej. "CC", "CE", "NIT", "PASAPORTE").
- El sistema debe generar:
  - Un `numeroCuenta` único (formato: 12 dígitos numéricos).
  - Una `fechaApertura` (timestamp en formato ISO 8601).
  - Un `estado` inicial (ej. "ACTIVA", "PENDIENTE", "BLOQUEADA").

**Requisitos No Funcionales**:
- **Idempotencia**: La operación debe ser idempotente. Si se recibe una solicitud con la misma `Idempotency-Key`, el sistema debe retornar la respuesta original sin crear una nueva cuenta.
- **Latencia**: Máximo 200ms para el 95% de las solicitudes.
- **Disponibilidad**: 99.95% mensual.
- **Seguridad**: Los datos del titular deben ser cifrados en tránsito (TLS 1.2+) y en reposo.

**Ejemplo de Solicitud**:
```json
{
  "tipoCuenta": "AHORROS",
  "moneda": "COP",
  "titular": {
    "identificacion": "123456789",
    "nombre": "Juan",
    "apellido": "Pérez",
    "tipoIdentificacion": "CC"
  },
  "saldoInicial": 100000
}
```

**Ejemplo de Respuesta Exitosa (201 Created)**:
```json
{
  "numeroCuenta": "123456789012",
  "tipoCuenta": "AHORROS",
  "moneda": "COP",
  "titular": {
    "identificacion": "123456789",
    "nombre": "Juan",
    "apellido": "Pérez",
    "tipoIdentificacion": "CC"
  },
  "saldo": 100000,
  "fechaApertura": "2023-10-01T12:00:00Z",
  "estado": "ACTIVA"
}
```

**Códigos de Error**:
- `400 Bad Request`: Datos inválidos (ej. `saldoInicial` negativo, `tipoCuenta` inexistente).
- `409 Conflict`: Cuenta duplicada para el mismo titular, tipo y moneda.
- `422 Unprocessable Entity`: Violación de reglas de negocio (ej. `saldoInicial` menor al mínimo requerido).

---

### 2.2. Consulta de Cuentas (`GET /cuentas-bancarias/{numeroCuenta}`)

**Descripción**: Permite consultar la información de una cuenta bancaria específica.

**Requisitos Funcionales**:
- El cliente debe proporcionar el `numeroCuenta` como parámetro de ruta.
- El sistema debe retornar:
  - Los datos básicos de la cuenta (`numeroCuenta`, `tipoCuenta`, `moneda`, `estado`).
  - Información del titular (`identificacion`, `nombre`, `apellido`).
  - `saldoDisponible` (valor numérico).
  - `fechaUltimaTransaccion` (timestamp en formato ISO 8601, opcional).
- El sistema debe validar:
  - Que el `numeroCuenta` exista.
  - Que el cliente tenga permisos para consultar la cuenta.

**Requisitos No Funcionales**:
- **Latencia**: Máximo 150ms para el 95% de las solicitudes.
- **Cache**: Las respuestas deben ser cacheables por 5 minutos para reducir carga en el sistema.

**Ejemplo de Respuesta Exitosa (200 OK)**:
```json
{
  "numeroCuenta": "123456789012",
  "tipoCuenta": "AHORROS",
  "moneda": "COP",
  "estado": "ACTIVA",
  "titular": {
    "identificacion": "123456789",
    "nombre": "Juan",
    "apellido": "Pérez"
  },
  "saldoDisponible": 100000,
  "fechaUltimaTransaccion": "2023-10-01T12:00:00Z"
}
```

**Códigos de Error**:
- `404 Not Found`: Cuenta no encontrada.
- `403 Forbidden`: Permisos insuficientes para consultar la cuenta.

---

### 2.3. Actualización de Cuentas (`PATCH /cuentas-bancarias/{numeroCuenta}`)

**Descripción**: Permite actualizar información de una cuenta bancaria.

**Requisitos Funcionales**:
- El cliente debe proporcionar el `numeroCuenta` como parámetro de ruta.
- El cliente puede actualizar uno o más de los siguientes campos:
  - `estado` (ej. "ACTIVA", "BLOQUEADA", "CERRADA").
  - `titular` (solo `nombre` y `apellido`).
  - `limiteSobregiro` (para cuentas corrientes, valor numérico mayor o igual a 0).
- El sistema debe validar:
  - Que el `numeroCuenta` exista.
  - Que el cliente tenga permisos para actualizar la cuenta.
  - Que los nuevos valores cumplan con las reglas de negocio (ej. `limiteSobregiro` no puede ser negativo).

**Requisitos No Funcionales**:
- **Idempotencia**: La operación debe ser idempotente. Si se recibe una solicitud con la misma `Idempotency-Key`, el sistema debe retornar la respuesta original sin realizar cambios.
- **Latencia**: Máximo 200ms para el 95% de las solicitudes.

**Ejemplo de Solicitud**:
```json
{
  "estado": "BLOQUEADA"
}
```

**Ejemplo de Respuesta Exitosa (200 OK)**:
```json
{
  "numeroCuenta": "123456789012",
  "tipoCuenta": "AHORROS",
  "moneda": "COP",
  "estado": "BLOQUEADA",
  "titular": {
    "identificacion": "123456789",
    "nombre": "Juan",
    "apellido": "Pérez"
  },
  "saldoDisponible": 100000
}
```

**Códigos de Error**:
- `400 Bad Request`: Datos inválidos (ej. `estado` inexistente).
- `404 Not Found`: Cuenta no encontrada.
- `403 Forbidden`: Permisos insuficientes para actualizar la cuenta.
- `422 Unprocessable Entity`: Violación de reglas de negocio (ej. intentar cerrar una cuenta con saldo positivo).

---

### 2.4. Eliminación de Cuentas (`DELETE /cuentas-bancarias/{numeroCuenta}`)

**Descripción**: Permite eliminar una cuenta bancaria.

**Requisitos Funcionales**:
- El cliente debe proporcionar el `numeroCuenta` como parámetro de ruta.
- El sistema debe validar:
  - Que el `numeroCuenta` exista.
  - Que el cliente tenga permisos para eliminar la cuenta.
  - Que la cuenta no tenga saldo positivo.
  - Que la cuenta no tenga transacciones pendientes.
- El sistema debe marcar la cuenta como "ELIMINADA" y no permitir operaciones posteriores.

**Requisitos No Funcionales**:
- **Idempotencia**: La operación debe ser idempotente. Si se recibe una solicitud con la misma `Idempotency-Key`, el sistema debe retornar la respuesta original.
- **Latencia**: Máximo 200ms para el 95% de las solicitudes.

**Ejemplo de Respuesta Exitosa (204 No Content)**:
```
(No hay cuerpo en la respuesta)
```

**Códigos de Error**:
- `400 Bad Request`: La cuenta no puede ser eliminada (ej. saldo positivo).
- `404 Not Found`: Cuenta no encontrada.
- `403 Forbidden`: Permisos insuficientes para eliminar la cuenta.

---

### 2.5. Consulta de Movimientos (`GET /cuentas-bancarias/{numeroCuenta}/movimientos`)

**Descripción**: Permite consultar los movimientos de una cuenta bancaria.

**Requisitos Funcionales**:
- El cliente debe proporcionar el `numeroCuenta` como parámetro de ruta.
- El cliente puede filtrar los movimientos por:
  - `fechaInicio` (timestamp en formato ISO 8601).
  - `fechaFin` (timestamp en formato ISO 8601).
  - `tipoMovimiento` (ej. "DEPOSITO", "RETIRO", "TRANSFERENCIA").
- El sistema debe retornar:
  - Una lista paginada de movimientos con los siguientes campos:
    - `idMovimiento` (UUID).
    - `tipoMovimiento`.
    - `monto` (valor numérico).
    - `fecha` (timestamp en formato ISO 8601).
    - `descripcion` (texto).
    - `saldoDespues` (valor numérico).
  - Información de paginación (`totalItems`, `totalPages`, `currentPage`).

**Requisitos No Funcionales**:
- **Latencia**: Máximo 300ms para el 95% de las solicitudes.
- **Cache**: Las respuestas deben ser cacheables por 2 minutos para reducir carga en el sistema.

**Ejemplo de Respuesta Exitosa (200 OK)**:
```json
{
  "movimientos": [
    {
      "idMovimiento": "550e8400-e29b-41d4-a716-446655440000",
      "tipoMovimiento": "DEPOSITO",
      "monto": 100000,
      "fecha": "2023-10-01T12:00:00Z",
      "descripcion": "Depósito inicial",
      "saldoDespues": 100000
    }
  ],
  "paginacion": {
    "totalItems": 1,
    "totalPages": 1,
    "currentPage": 1
  }
}
```

**Códigos de Error**:
- `404 Not Found`: Cuenta no encontrada.
- `403 Forbidden`: Permisos insuficientes para consultar los movimientos.

---

## 3. Restricciones de Dominio

### 3.1. Saldo Mínimo

| Tipo de Cuenta | Saldo Mínimo Requerido |
|----------------|-------------------------|
| AHORROS        | 50,000 COP              |
| CORRIENTE      | 0 COP                   |
| INVERSION      | 1,000,000 COP           |

### 3.2. Límites de Transacciones

| Tipo de Cuenta | Límite Diario de Retiros | Límite Mensual de Transferencias |
|----------------|--------------------------|-----------------------------------|
| AHORROS        | 2,000,000 COP           | 10,000,000 COP                    |
| CORRIENTE      | 5,000,000 COP           | 50,000,000 COP                    |
| INVERSION      | 10,000,000 COP          | 100,000,000 COP                   |

### 3.3. Tipos de Identificación Válidos

| Código | Descripción          |
|-------|----------------------|
| CC    | Cédula de Ciudadanía |
| CE    | Cédula de Extranjería|
| NIT   | NIT                  |
| PASAPORTE | Pasaporte         |

### 3.4. Estados de Cuenta

| Estado      | Descripción                                                                 |
|-------------|-----------------------------------------------------------------------------|
| ACTIVA      | Cuenta operativa y disponible para transacciones.                          |
| PENDIENTE   | Cuenta en proceso de apertura o verificación.                              |
| BLOQUEADA   | Cuenta bloqueada por seguridad o incumplimiento de políticas.              |
| CERRADA     | Cuenta cerrada por solicitud del cliente o incumplimiento de condiciones.  |
| ELIMINADA   | Cuenta eliminada del sistema (no se puede reactivar).                      |

---

## 4. Propiedades Operativas

### 4.1. Latencia

| Operación               | Latencia Máxima (P95) |
|-------------------------|-----------------------|
| Creación de Cuentas     | 200ms                 |
| Consulta de Cuentas     | 150ms                 |
| Actualización de Cuentas| 200ms                 |
| Eliminación de Cuentas  | 200ms                 |
| Consulta de Movimientos | 300ms                 |

### 4.2. Idempotencia

- Todas las operaciones de **modificación** (POST, PATCH, DELETE) deben ser idempotentes.
- Se debe utilizar el header `Idempotency-Key` con un UUIDv4 para garantizar la idempotencia.
- El sistema debe almacenar las respuestas de las operaciones idempotentes durante **24 horas**.

### 4.3. Seguridad

- **Autenticación**: Utilizar OAuth 2.0 con tokens JWT para autenticar las solicitudes.
- **Autorización**: Validar permisos de acceso mediante roles (ej. `CLIENTE`, `ADMIN`).
- **Cifrado**: Todos los datos sensibles (ej. datos del titular) deben ser cifrados en tránsito (TLS 1.2+) y en reposo.
- **Auditoría**: Registrar todas las operaciones CRUD en un sistema de auditoría para trazabilidad.

### 4.4. Disponibilidad y Escalabilidad

- **Disponibilidad**: 99.95% mensual.
- **Escalabilidad**: El sistema debe soportar **1,000 solicitudes por segundo** con la latencia especificada.
- **Alta Disponibilidad**: Implementar balanceo de carga y replicación de datos para garantizar redundancia.

### 4.5. Observabilidad

- **Logs**: Registrar todas las solicitudes y respuestas con un nivel de detalle adecuado (ej. INFO para operaciones exitosas, ERROR para fallos).
- **Métricas**: Exponer métricas de latencia, throughput y errores mediante Prometheus.
- **Trazabilidad**: Utilizar headers como `X-Request-ID` para correlacionar solicitudes entre servicios.

---

## 5. Integración con Sistemas Externos

### 5.1. Servicio de Autenticación

- **Endpoint**: `POST /auth/token`
- **Responsabilidades**:
  - Validar credenciales del usuario.
  - Generar tokens JWT con los claims necesarios (ej. `sub`, `roles`, `exp`).
- **Requisitos No Funcionales**:
  - Latencia máxima: 100ms.
  - Disponibilidad: 99.99%.

### 5.2. Servicio de Notificaciones

- **Endpoint**: `POST /notificaciones/enviar`
- **Responsabilidades**:
  - Enviar notificaciones por correo electrónico o SMS.
  - Registrar eventos de notificación para auditoría.
- **Requisitos No Funcionales**:
  - Latencia máxima: 500ms.
  - Disponibilidad: 99.9%.

---

## 6. Ejemplos de Errores del Dominio

### 6.1. Saldo Insuficiente

**Ejemplo**:
```json
{
  "type": "https://api.banco.com/errors/saldo-insuficiente",
  "title": "Saldo insuficiente",
  "status": 422,
  "detail": "El saldo disponible (50000 COP) es menor al saldo mínimo requerido (100000 COP) para el tipo de cuenta AHORROS.",
  "instance": "/cuentas-bancarias",
  "cuenta": {
    "numeroCuenta": "123456789012",
    "tipoCuenta": "AHORROS",
    "moneda": "COP"
  }
}
```

### 6.2. Cuenta Duplicada

**Ejemplo**:
```json
{
  "type": "https://api.banco.com/errors/cuenta-duplicada",
  "title": "Cuenta duplicada",
  "status": 409,
  "detail": "Ya existe una cuenta activa de tipo AHORROS en moneda COP para el titular con identificación 123456789.",
  "instance": "/cuentas-bancarias",
  "cuenta": {
    "tipoCuenta": "AHORROS",
    "moneda": "COP",
    "titular": {
      "identificacion": "123456789",
      "tipoIdentificacion": "CC"
    }
  }
}
```

### 6.3. Cuenta No Encontrada

**Ejemplo**:
```json
{
  "type": "https://api.banco.com/errors/cuenta-no-encontrada",
  "title": "Cuenta no encontrada",
  "status": 404,
  "detail": "No se encontró una cuenta con el número 123456789012.",
  "instance": "/cuentas-bancarias/123456789012"
}
```

---

## 7. Decisiones de Arquitectura

### 7.1. Patrón SOA y Bajo Acoplamiento

- **Razón**: Se eligió el patrón SOA para garantizar la modularidad y reutilización de servicios.
- **Implementación**: Cada operación CRUD se expone como un endpoint REST independiente, permitiendo que otros servicios consuman solo lo necesario.
- **Beneficios**:
  - Facilita la escalabilidad y el despliegue independiente de servicios.
  - Reduce el acoplamiento entre componentes.
  - Permite la reutilización de servicios en diferentes contextos.

### 7.2. Contrato Primero (OpenAPI)

- **Razón**: El diseño del contrato primero asegura que la API sea consistente y bien documentada desde el inicio.
- **Implementación**: Se utiliza OpenAPI 3.1 para definir la especificación de la API, incluyendo schemas, paths y ejemplos.
- **Beneficios**:
  - Facilita la generación automática de código cliente y servidor.
  - Mejora la comunicación entre equipos de desarrollo y stakeholders.
  - Permite validar el contrato antes de implementar la lógica.

### 7.3. Idempotencia

- **Razón**: Garantizar que las operaciones de modificación no se repliquen accidentalmente.
- **Implementación**: Uso del header `Idempotency-Key` para identificar solicitudes repetidas.
- **Beneficios**:
  - Evita duplicación de transacciones.
  - Mejora la experiencia del usuario al manejar solicitudes repetidas.

### 7.4. Manejo de Errores

- **Razón**: Proporcionar información clara y estructurada sobre los errores.
- **Implementación**: Uso de RFC 7807 (Problem Details) para estandarizar las respuestas de error.
- **Beneficios**:
  - Facilita la depuración y el manejo de errores por parte de los clientes.
  - Proporciona información consistente y útil para los desarrolladores.

### 7.5. Estandarización Financiera

- **Razón**: Asegurar que la API cumpla con estándares del sector financiero.
- **Implementación**: Uso de BIAN e ISO 20022 para definir tipos de datos y operaciones.
- **Beneficios**:
  - Facilita la integración con otros sistemas financieros.
  - Mejora la interoperabilidad y la adopción de la API.

---

## 8. Referencias

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [RFC 7807 - Problem Details for HTTP APIs](https://tools.ietf.org/html/rfc7807)
- [BIAN Service Landscape](https://www.bian.org/)
- [ISO 20022](https://www.iso20022.org/)
- [OAuth 2.0](https://oauth.net/2/)