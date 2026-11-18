markdown
Configuración de Seguridad - API de Gestión de Cuentas Bancarias

1. Autenticación - API Key

Implementación en tu API
Todas las solicitudes deben incluir un header X-API-Key:

`bash
curl -H "X-API-Key: your-secret-key" http://localhost:8080/accounts
`

Ejemplo en código (Express/Node)
`javascript
const apiKeyMiddleware = (req, res, next) => {
const apiKey = req.headers['x-api-key'];
const validKey = process.env.API_KEY;

if (!apiKey || apiKey !== validKey) {
return res.status(401).json({ error: 'Unauthorized' });
}
next();
};

app.use(apiKeyMiddleware);
`

Ejemplo en código (Spring Boot/Java)
`java
@Component
public class ApiKeyFilter extends OncePerRequestFilter {

@Override
protected void doFilterInternal(HttpServletRequest request,
HttpServletResponse response,
FilterChain filterChain) throws ServletException, IOException {
String apiKey = request.getHeader("X-API-Key");
String validKey = System.getenv("API_KEY");

if (apiKey == null || !apiKey.equals(validKey)) {
response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
response.getWriter().write("Unauthorized");
return;
}

filterChain.doFilter(request, response);
}
}
2. Headers de Seguridad

Agregar estos headers a TODAS las respuestas:

`javascript
// Express.js ejemplo
app.use((req, res, next) => {
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
res.setHeader('X-XSS-Protection', '1; mode=block');
res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
res.setHeader('Content-Security-Policy', "default-src 'self'");
next();
});
`

Headers explicados
Header	Propósito
--------	--------Type-Options: nosniff	Prevenir MIME type sniffing
X-Frame-Options: DENY	Prevenir clickjacking
X-XSS-Protection: 1; mode=block	Protección contra XSS
Strict-Transport-Security	Forzar HTTPS
Content-Security-Policy	Controlar fuentes de contenido


3. Rate Limiting

Limitar solicitudes por cliente para prevenir abuso:

``javascript
// Express.js con express-rate-limit
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
windowMs: 60 * 1000, // 1 minuto
max: 1000, // 1000 solicitudes por minuto
message: 'Demasiadas solicitudes',
standardHeaders: true,
legacyHeaders: false,
});

app.use(limiter);
`

Respuesta cuando se alcanza el límite
`json
{
"error": "Demasiadas solicitudes",
"retryAfter": 60
}
`


4. Validación de Entrada

Validar y sanitizar todos los inputs:

`javascript
// Ejemplo: Validar crear cuenta
const validateCreateAccount = (req, res, next) => {
const { accountType, initialBalance, currency } = req.body;

// Validar tipos
if (!['savings', 'checking', 'fixed
return res.status(422).json({ error: 'Invalid account type' });
}

// Validar saldo mínimo
if (initialBalance < 0) {
return res.status(422).json({ error: 'Invalid balance' });
}

// Validar moneda
if (!['USD', 'EUR', 'COP'].includes(currency)) {
return res.status(422).json({ error: 'Invalid currency' });
}

next();
};

app.post('/accounts', validateCreateAccount, createAccount);
`


5. Manejo de Errores Seguro

NO exponer detalles internos en los errores:

❌ MAL
`json
{
"error": "Error en SQL: database connection failed at line 42"
}
`

✅ BIEN
`json
{
"error": "Internal server error",
"requestId": "abc-123-def"
}
`


6. Logging y Auditoría

Registrar todas las operaciones sensibles:

`javascript
const auditLog = (userId, action, resource, result) => {
console.log({
timestamp: new Date().toISOString,
requestId: req.id
});
};

// Uso
auditLog('user-123', 'CREATE', 'account', 'success');
auditLog('user-123', 'DELETE', 'account-456', 'failed');
`


7. HTTPS/TLS en Producción

Configurar SSL/TLS:

`javascript
const https = require('https');
const fs = require('fs');

const options = {
key: fs.readFileSync('path/to/private-key.pem'),
cert: fs.readFileSync('path/to/certificate.pem')
};

https.createServer(options, app).listen(8080);
`


8. Variables de Entorno Seguras

Guardar NUNCA en código:

`env
.env (NUNCA commitar este archivo)
API_KEY=your-secret-key-here
DB_PASSWORD=secure_database_password
JWT_SECRET=your-jwt-secret
`

`bash
.gitignore
.env
.env.local
*.pem
`


Checklist de Seguridad

• [ ] Autenticación API Key implementada
• [ ] Headers de seguridad configurados
• [ ] Rate limiting activado
• [ ] Validación de entrada implementada
• [ ] Manejo de errores seguro
• [ ] Auditoría habilitada
• [ ] HTTPS/TLS en producción
• [ ] Variables de entorno no en código
• [ ] Logs monitoreados
• [ ] Pruebas de seguridad realizadas
`