markdown
Configuración de Monitoreo - API de Gestión de Cuentas Bancarias

1. Métricas Clave a Monitorear

Métricas de Rendimiento
• Latencia (Respuesta Time): Tiempo que tarda en responder
• Target: < 200ms (percentil 95)
• Crítico: > 500ms

• Throughput: Solicitudes procesadas por segundo
• Target: 1000 req/s
• Crítico: < 500 req/s

• Tasa de Errores: Porcentaje de requests que fallan
• Target: < 1%
• Crítico: > 5%

Métricas de Disponibilidad
• Uptime: Porcentaje de tiempo que el servicio está disponible
• Target: 99.9% (SLA)
• Crítico: < 99%

• Error 5xx Rate: Errores del servidor
• Target: 0%
• Crítico: > 1%

Métricas de Recurso
• CPU Usage: Consumo de CPU
• Normal: < 70%
• Crítico: > 90%

• Memory Usage: Consumo de memoria
• Normal: < 70%
• Crítico: > 90%

• Disk Usage: Espacio en disco
• Normal: < 70%
• Crítico: > 90%


2. Configuración de Alertas

Estructura de Alerta
`json
{
"alert_name": "High Latency",
"metric": "response_time_p95",
"threshold": 200,
"comparison": "greater_than",
"duration": "5 minutes",
"severity": "critical",
"notification_channels": ["email", "slack", "pagerduty"]
}
`

Alertas Críticas

Métrica	Umbral	Duración	Acción
Latencia P95	> 200ms	5 min	Escalar a On-Call
Tasa de Errores	> 1%	5 min	Escalar a On-Call
Error 5xx	> 5	1 min	Escalar a On-Call
CPU	> 90%	5 min	Auto-scale + Alerta
Memory	> 90%	5 min	Auto-scale + Alerta
Disk	> 90%	10 min	Alerta crítica
DB Connection Pool	> 95%	2 min	Escalar a DBA
API Key Inválida	> 10/min	1 min	Alerta de seguridad


3. Implementación de Monitoreo

Opción A: Prometheus + Grafana

Prometheus Configuration (prometheus.yml)
`yaml
global:
scrape_interval: 15s
evaluation_interval: 15s

scrape_configs:
• job_name: 'api'
static_configs:
• targets: ['localhost:8080']
metrics_path: '/metrics'
`

Docker Compose con Prometheus
`yaml
services:
prometheus:
image: prom/prometheus:latest
ports:
• "9090:9090"
volumes:
• ./prometheus.yml:/etc/prometheus/prometheus.yml
• prometheus_data:/prometheus
command:
• '--config.file=/etc/prometheus/prometheus.yml'

volumes:
prometheus_data:
`

Métricas a exponer desde tu API (Express.js)
`javascript
const prometheus = require('prom-client');

// Crear métrica de latencia
const httpRequestDuration = new prometheus.Histogram({
name: 'http_request_duration_ms',
help: 'Duration of HTTP requests in ms',
labelNames: ['method', 'route', 'status_code'],
buckets: [50, 100, 200, 500, 1000]
});

// Middleware para medir
app.use((req, res, next) => {
const start = Date.now();

res.on('finish', () => {
const duration = Date.now() - start;
httpRequestDuration
.labels(req.method, req.route.path, res.statusCode)
.observe(duration);
});

next();
});

// Exponer endpoint de métricas
app.get('/metrics', (req, res) => {
res.set('Content-Type', prometheus.register.contentType);
res.end(prometheus.register.metrics());
});
`


Opción B: Cloud Providers

AWS CloudWatch
`bash
Ver logs
aws logs tail /aws/api/logs --follow

Crear métrica personalizada
aws cloudwatch put-metric-data \
--namespace BankAPI \
--metric-name ResponseTime \
--value 150 \
--unit Milliseconds
`

Google Cloud Monitoring
`bash
Crear alerta
gcloud alpha monitoring policies create \
--notification-channels=CHANNEL_ID \
--display-name="High Latency Alert" \
--condition-display-name="Response Time > 200ms"
`


4. Logging Estructurado

Log Format (JSON)
`javascript
const logger = (level, message, metadata) => {
console.log(JSON.stringify({
timestamp: new Date().toISOString(),
level,
message,
requestId: metadata.requestId,
userId: metadata.userId,
endpoint: metadata.endpoint,
statusCode: metadata.statusCode,
duration: metadata.duration,
environment: process.env.API_ENV
}));
};

// Uso
logger('info', 'Account created', {
requestId: 'req-123',
userId: 'user-456',
endpoint: 'POST /accounts',
statusCode: 201,
duration: 45
});
`

Ejemplo de logs importantes

`json
// 1. Request entry
{
"timestamp": "2026-11-18T10:30:00Z",
"level": "info request",
"requestId": "req-abc123",
"method": "POST",
"endpoint": "/accounts",
"userId": "user-123"
}

// 2. Database operation
{
"timestamp": "2026-11-18T10:30:01Z",
"level": "info",
"message": "Database query executed",
"requestId": "req-abc123",
"query": "INSERT INTO accounts",
"duration": 25
}

// 3. Response sent
{
"timestamp": "2026-11-18T10:30:02Z",
"level": "info",
"message": "Response sent",
"requestId": "req-abc123",
"statusCode": 201,
"totalDuration": 85
}

// 4. Error occurred
{
"timestamp": "2026-11-18T10:35:00Z",
"level": "error",
"message": "Database connection failed",
"requestId": "req-def456",
"error": "",
"statusCode": 500
}
`


5. Dashboard de Monitoreo (Grafana)

Paneles Recomendados

1. Request Latency (P50, P95, P99)
• Gráfico de líneas
• Actualización cada 15s
req/s)**
• Gráfico de barras
• Mostrar por endpoint

3. Error Rate
• Gráfico de líneas
• Mostrar por código de error (4xx vs 5xx)

4. Resource Usage
• CPU, Memory, Disk
• Gráfico de gauge

5. Database Connections
• Pool utilizado vs disponible
• Alerta si > 95%

Ejemplo de Query Prometheus
`promql
Latencia promedio último minuto
rate(http_request_duration_ms_sum[1m]) / rate(http_request_duration_ms_count[1m])

Tasa de errores (5xx)
rate(http_requests_total{status=~"5.."}[5m])

CPU Usage
process_resident_memory_bytes / 1024 / 1024
`


6. Runbook de Respuesta a Alertas

Alerta: High Latency (> 200ms)

Paso 1: Investigar
`bash
Ver logs de lentitud
grep "duration" logs/api.log | tail -20

Verificar CPU stats bank_api

Verificar conexiones DB
SELECT count(*) FROM pg_stat_activity;
`

Paso 2: Diagnóstico
• ¿CPU > 80%? → Activar auto-scaling
• ¿Conexiones DB > 95%? → Contactar DBA
• ¿Queries lentas? → Revisar índices

Paso 3: Mitigación
`bash
Opción 1: Reiniciar servicio
docker-compose restart api

Opción 2: Scale up
docker-compose up -d --scale api=3

Opción 3: Activar caché
redis-cli FLUSHDB
`


Alerta: High Error Rate (> 1%)

Paso 1: Investigar
`bash
Ver errores recientes
grep "level.*error" logs/api.log | tail -50

Contar por tipo de error
grep "statusCode" logs/api.log | jq '.statusCode' | sort | uniq -c
`

Paso 2:óstico
• ¿5xx errors? → Problema del servidor
• ¿4xx errors? → Problema del cliente
• ¿DB errors? → Revisar conexión DB

Paso 3: Mitigación
`bash
Revisar BD
docker exec bank_db psql -U postgres -c "SELECT version();"

Ver logs del contenedor
docker logs bank_api --tail 100
`


7. Checklist de Monitoreo

• [ ] Prometheus/CloudWatch configurado
• [ ] Métricas principales expuestas
• [ ] Alertas configuradas para umbrales críticos
• [ ] Dashboard de Grafana/Console creado
• [ ] Logs estructurados en JSON
• [ ] Runbooks de respuesta documentados
• [ ] Notificaciones configuradas (email/Slack)
• [ ] On-Call rotation establecida
• [ ] Prueba de alerta realizada
• [ ] Documentación de troubleshooting disponible


8. SLA (Service Level Agreement)

`
Objetivo deibilidad: 99.9%
├─ Tiempo de inactividad permitido por año: 8 horas 45 minutos
├─ Tiempo de inactividad permitido por mes: 43.2 minutos
└─ Tiempo de inactividad permitido por día: 1.44 minutos

Objetivos de Rendimiento:
├─ Latencia P95: < 200ms
├─ Tasa de errores: < 1%
└─ Throughput: 1000+ req/s

Escalación de Alertas:
├─ Severidad: Low (1 hora) → Medium (30 min) → Critical (5 min)
└─ Team: On-Call Engineer → Tech Lead → Engineering Manager