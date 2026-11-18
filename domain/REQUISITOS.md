markdown
Requisitos del Servicio de Gestión de Cuentas Bancarias

1. Actores del Dominio

Actor	Descripción
Cliente	...
Sistema de Gestión de Cuentas	...
Auditoría	...

2. Operaciones CRUD

Operación	Endpoint	Restricciones
Crear cuenta	POST /accounts	Saldo mínimo...
Leer cuenta	GET /accounts/{id}	...
Actualizar	PUT /accounts/{id}	...
Eliminar	DELETE /accounts/{id}	...

3. Tipos de Cuenta

• Ahorro: saldo mínimo $50,000
• Corriente: saldo mínimo $10,000
• Plazo fijo: saldo mínimo $100,000

4. Estados de Cuenta

• Activa
• Inactiva
• Bloqueada
• Cerrada

5. Propiedades Operativas

• Latencia máxima: 200ms
• Volumen: 1000 req/s
• Idempotencia: Sí