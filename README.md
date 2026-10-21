# Desarrollo de API y Microservicios en SOA

Como analista junior en SOA, tu tarea es diseñar y desarrollar una API REST para un servicio de gestión de cuentas bancarias. La API debe permitir la creación, lectura, actualización y eliminación de cuentas. Debes asegurarte de que la API esté bien documentada y siga patrones de bajo acoplamiento. El sistema debe manejar un volumen de 1 000 solicitudes por segundo con una latencia máxima de 200ms. Además, debes implementar mecanismos para asegurar la idempotencia de las operaciones y manejar adecuadamente los errores del dominio.

## Informacion General

| Campo | Valor |
|-------|-------|
| **Tema** | Implementación SOA - API - MicroServicios |
| **Nivel** | junior-l2 |
| **Tipo** | practical |
| **Tiempo estimado** | 40 horas |

## Fases del Reto

### Fase 0: Configuración del Proyecto

**Objetivo:** Obtener el proyecto base funcional enviando el Código Base a un asistente de IA, que lo analizará, corregirá errores y generará un ZIP listo para usar.

**Tiempo estimado:** 15-30 minutos

**Instrucciones:**

- Asegúrate de tener instalado para ejecutar el proyecto: Un IDE o editor de código.
- Copia todo el contenido del campo **Código Base** de este reto — incluyendo el texto de instrucciones que aparece al inicio.
- Abre un asistente de IA (Claude en claude.ai, ChatGPT o Gemini — se recomienda Claude), pega el contenido copiado en el chat y envíalo.
- El asistente analizará los archivos, corregirá errores y generará un archivo ZIP descargable. Descárgalo y extráelo en la carpeta donde quieras trabajar.
- Verifica que el proyecto arranca sin errores.

**Entregable:** El proyecto compila/arranca sin errores.

<details>
<summary>Pistas de conocimiento</summary>

- Copia el Código Base completo incluyendo el texto de instrucciones al inicio — esas instrucciones le indican al asistente exactamente qué hacer con los archivos.
- Si el asistente no genera el ZIP automáticamente al terminar el análisis, escríbele: "genera el ZIP ahora".
- Si el proyecto tiene errores al arrancar, comparte el mensaje de error con el mismo asistente para que lo corrija.

</details>

### Fase 1: Definición del Dominio y Requisitos

**Objetivo:** Identificar y documentar los requisitos funcionales y no funcionales del servicio de gestión de cuentas bancarias.

**Tiempo estimado:** 5 horas

**Instrucciones:**

- Identifica los actores del dominio: cliente, sistema de gestión de cuentas, auditoría de transacciones.
- Documenta las operaciones CRUD para cuentas bancarias y sus restricciones de dominio (ej. saldo mínimo, tipos de cuenta).
- Define las propiedades operativas: latencia máxima de 200ms, idempotencia por número de cuenta y operación.

**Entregable:** Documento de requisitos funcionales y no funcionales para el servicio de gestión de cuentas bancarias.

<details>
<summary>Pistas de conocimiento</summary>

- Considera las restricciones de negocio al definir las operaciones CRUD.
- Piensa en cómo la idempotencia puede ser asegurada en el dominio de las cuentas bancarias.

</details>

### Fase 2: Diseño de la API

**Objetivo:** Diseñar la estructura de la API REST siguiendo patrones de bajo acoplamiento y asegurar su correcta documentación.

**Tiempo estimado:** 10 horas

**Instrucciones:**

- Diseña los endpoints de la API para las operaciones CRUD de cuentas bancarias.
- Aplica patrones de bajo acoplamiento como el uso de recursos y verbos HTTP apropiados.
- Documenta la API utilizando OpenAPI y asegura que incluya ejemplos de solicitudes y respuestas.

**Entregable:** Especificación técnica de la API REST para el servicio de gestión de cuentas bancarias.

<details>
<summary>Pistas de conocimiento</summary>

- Revisa las mejores prácticas para el diseño de APIs REST.
- Considera cómo la documentación puede mejorar la usabilidad y mantenibilidad de la API.

</details>

### Fase 3: Implementación y Pruebas

**Objetivo:** Implementar la API y realizar pruebas para asegurar que cumple con los requisitos funcionales y no funcionales.

**Tiempo estimado:** 15 horas

**Instrucciones:**

- Implementa los endpoints de la API siguiendo el diseño definido en la fase anterior.
- Realiza pruebas unitarias y de integración para asegurar la funcionalidad y el cumplimiento de las propiedades operativas.
- Configura un entorno de pruebas que simule el volumen y latencia especificados.

**Entregable:** API REST implementada y documentada, con pruebas unitarias y de integración.

<details>
<summary>Pistas de conocimiento</summary>

- Utiliza herramientas de pruebas como Postman para validar la API.
- Considera cómo manejarías los errores del dominio durante las pruebas.

</details>

### Fase 4: Despliegue y Monitoreo

**Objetivo:** Desplegar la API en un entorno de producción y configurar el monitoreo para asegurar su funcionamiento correcto.

**Tiempo estimado:** 10 horas

**Instrucciones:**

- Despliega la API en un entorno de producción siguiendo las mejores prácticas de seguridad y escalabilidad.
- Configura el monitoreo de la API para capturar métricas de rendimiento y errores del dominio.
- Documenta el proceso de despliegue y monitoreo para futuras referencias.

**Entregable:** API desplegada en producción con monitoreo configurado y documentación del proceso de despliegue.

<details>
<summary>Pistas de conocimiento</summary>

- Revisa las mejores prácticas para el despliegue y monitoreo de APIs en producción.
- Considera cómo asegurarías la seguridad y escalabilidad de la API en producción.

</details>

## Dimensiones Evaluadas

- **queEs**: ¿Qué es una API REST y cuáles son sus componentes principales?
- **paraQueSirve**: ¿Para qué sirve la documentación de una API y cómo afecta su usabilidad?
- **comoSeUsa**: ¿Cómo se aplican patrones de bajo acoplamiento en el diseño de una API?
- **erroresComunes**: ¿Cuáles son los errores comunes al implementar una API y cómo se pueden evitar?
- **queDecisionesImplica**: ¿Qué decisiones implica el despliegue de una API en producción y cómo se pueden optimizar?

## Criterios de Evaluacion

- Identificación y documentación de requisitos funcionales y no funcionales.
- Diseño de la API siguiendo patrones de bajo acoplamiento y correcta documentación.
- Implementación y pruebas de la API para asegurar el cumplimiento de los requisitos.
- Despliegue y monitoreo de la API en un entorno de producción.

## Como trabajar con un asistente de IA

Hay dos caminos, elegi uno:

- **AGENTS.md** (recomendado) — instrucciones nativas del repo. Abri esta carpeta con tu agente local (Claude Code, Cursor, Codex, Copilot, Gemini) y las carga solo. Sabe que archivos faltan y con que comando se verifica, y completa el scaffold escribiendo en disco.
- **PROMPT_MEJORA.md** — para copiar y pegar en un chat (claude.ai, ChatGPT). Devuelve un ZIP con el proyecto. Sirve si no tenes un agente en el IDE.

Ninguno de los dos resuelve las fases del reto: eso es tu trabajo.

## Verificacion

El proyecto esta listo para trabajar cuando este comando corre sin errores:

```bash
npx --yes @redocly/cli lint api/openapi.yaml
```

---

*Reto generado automaticamente por Challenge Generator - Pragma*
