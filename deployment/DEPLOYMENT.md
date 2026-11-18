markdown
Guía de Despliegue - API de Gestión de Cuentas Bancarias

Requisitos Previos
• Docker (versión 20.10+)
• Docker Compose (versión 1.29+)
• Git
• Puerto 8080 disponible
• PostgreSQL (opcional, si usas contenedor)

Estructura del Despliegue

Variables de Entorno
`env
API_PORT=8080
API_ENV=production
DB_HOST=postgres
DB_PORT=5432
DB_NAME=bank_accounts
DB_USER=postgres
DB_PASSWORD=secure_password
LOG_LEVEL=info
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60
`

Pasos de Despliegue Local

1. Clonar el Repositorio
`bash
git clone <tu-repo-url>
cd challenge-api
`

2. Levantar los Servicios
`bash
docker-compose up -d
`

3. Verificar que el Servicio Está Corriendo
`bash
curl http://localhost:8080/health
`

4. Ver los Logs
`bash
docker-compose logs -f api
`

Despliegue en Producción

Consideraciones de Seguridad
• Usar variables de entorno para secretos
• Habilitar HTTPS/TLS
• Configurar rate limiting
• Implementar autenticación API Key
• Logging y auditoría habilitados

Scaling
• Usar un balanceador de carga (nginx, HAProxy)
• Múltiples réplicas de la de datos con replicación

Monitoreo en Producción
• Alertas por latencia > 200ms
• Alertas por tasa de errores > 1%
• Disponibilidad mínima 99.9%

Rollback
En caso de fallo:
`bash
docker-compose down
Revertir a versión anterior
git checkout <previous-version>
docker-compose up -d
`

Soporte
Para problemas, revisar logs:
`bash
docker-compose logs api