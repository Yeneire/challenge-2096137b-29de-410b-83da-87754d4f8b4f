# Proceso de Gestión de Cuentas Bancarias

```bpmn
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
                  id="Definitions_1"
                  targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_GestionCuentasBancarias" isExecutable="false">
    <bpmn:startEvent id="StartEvent_1" name="Solicitud de gestión de cuenta">
      <bpmn:outgoing>Flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="StartEvent_1" targetRef="Gateway_1" />
    
    <bpmn:exclusiveGateway id="Gateway_1" name="Tipo de operación">
      <bpmn:incoming>Flow_1</bpmn:incoming>
      <bpmn:outgoing>Flow_2</bpmn:outgoing>
      <bpmn:outgoing>Flow_3</bpmn:outgoing>
      <bpmn:outgoing>Flow_4</bpmn:outgoing>
      <bpmn:outgoing>Flow_5</bpmn:outgoing>
    </bpmn:exclusiveGateway>
    
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Gateway_1" targetRef="Task_1">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
        ${operationType == 'CREATE'}
      </bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_3" sourceRef="Gateway_1" targetRef="Task_2">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
        ${operationType == 'READ'}
      </bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_4" sourceRef="Gateway_1" targetRef="Task_3">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
        ${operationType == 'UPDATE'}
      </bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_5" sourceRef="Gateway_1" targetRef="Task_4">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">
        ${operationType == 'DELETE'}
      </bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    
    <bpmn:task id="Task_1" name="Crear cuenta bancaria">
      <bpmn:incoming>Flow_2</bpmn:incoming>
      <bpmn:outgoing>Flow_6</bpmn:outgoing>
      <bpmn:documentation>Validar datos del cliente y crear nueva cuenta bancaria</bpmn:documentation>
    </bpmn:task>
    <bpmn:task id="Task_2" name="Consultar cuenta bancaria">
      <bpmn:incoming>Flow_3</bpmn:incoming>
      <bpmn:outgoing>Flow_7</bpmn:outgoing>
      <bpmn:documentation>Recuperar información de una cuenta existente</bpmn:documentation>
    </bpmn:task>
    <bpmn:task id="Task_3" name="Actualizar cuenta bancaria">
      <bpmn:incoming>Flow_4</bpmn:incoming>
      <bpmn:outgoing>Flow_8</bpmn:outgoing>
      <bpmn:documentation>Modificar información de una cuenta existente</bpmn:documentation>
    </bpmn:task>
    <bpmn:task id="Task_4" name="Eliminar cuenta bancaria">
      <bpmn:incoming>Flow_5</bpmn:incoming>
      <bpmn:outgoing>Flow_9</bpmn:outgoing>
      <bpmn:documentation>Marcar cuenta como inactiva (soft delete)</bpmn:documentation>
    </bpmn:task>
    
    <bpmn:sequenceFlow id="Flow_6" sourceRef="Task_1" targetRef="EndEvent_1" />
    <bpmn:sequenceFlow id="Flow_7" sourceRef="Task_2" targetRef="EndEvent_1" />
    <bpmn:sequenceFlow id="Flow_8" sourceRef="Task_3" targetRef="EndEvent_1" />
    <bpmn:sequenceFlow id="Flow_9" sourceRef="Task_4" targetRef="EndEvent_1" />
    
    <bpmn:endEvent id="EndEvent_1" name="Fin del proceso">
      <bpmn:incoming>Flow_6</bpmn:incoming>
      <bpmn:incoming>Flow_7</bpmn:incoming>
      <bpmn:incoming>Flow_8</bpmn:incoming>
      <bpmn:incoming>Flow_9</bpmn:incoming>
    </bpmn:endEvent>
    
    <!-- Subproceso para validación de datos -->
    <bpmn:subProcess id="SubProcess_1" name="Validación de datos" triggeredByEvent="false">
      <bpmn:incoming>Flow_10</bpmn:incoming>
      <bpmn:outgoing>Flow_11</bpmn:outgoing>
      <bpmn:startEvent id="StartEvent_2" name="Inicio validación">
        <bpmn:outgoing>Flow_12</bpmn:outgoing>
      </bpmn:startEvent>
      <bpmn:sequenceFlow id="Flow_12" sourceRef="StartEvent_2" targetRef="Task_5" />
      
      <bpmn:task id="Task_5" name="Validar identidad del cliente">
        <bpmn:incoming>Flow_12</bpmn:incoming>
        <bpmn:outgoing>Flow_13</bpmn:outgoing>
      </bpmn:task>
      <bpmn:sequenceFlow id="Flow_13" sourceRef="Task_5" targetRef="Task_6" />
      
      <bpmn:task id="Task_6" name="Validar capacidad financiera">
        <bpmn:incoming>Flow_13</bpmn:incoming>
        <bpmn:outgoing>Flow_14</bpmn:outgoing>
      </bpmn:task>
      <bpmn:sequenceFlow id="Flow_14" sourceRef="Task_6" targetRef="EndEvent_2" />
      
      <bpmn:endEvent id="EndEvent_2" name="Fin validación">
        <bpmn:incoming>Flow_14</bpmn:incoming>
      </bpmn:endEvent>
    </bpmn:subProcess>
    
    <!-- Manejo de errores -->
    <bpmn:intermediateThrowEvent id="ErrorEvent_1" name="Error en validación">
      <bpmn:incoming>Flow_15</bpmn:incoming>
      <bpmn:errorEventDefinition errorRef="Error_1" />
    </bpmn:intermediateThrowEvent>
    
    <bpmn:error id="Error_1" name="Datos inválidos" errorCode="400" />
    
    <bpmn:sequenceFlow id="Flow_10" sourceRef="Task_1" targetRef="SubProcess_1" />
    <bpmn:sequenceFlow id="Flow_11" sourceRef="SubProcess_1" targetRef="Task_7" />
    <bpmn:sequenceFlow id="Flow_15" sourceRef="SubProcess_1" targetRef="ErrorEvent_1" />
    
    <bpmn:task id="Task_7" name="Registrar auditoría">
      <bpmn:incoming>Flow_11</bpmn:incoming>
      <bpmn:outgoing>Flow_6</bpmn:outgoing>
      <bpmn:documentation>Registrar todas las operaciones en el sistema de auditoría</bpmn:documentation>
    </bpmn:task>
  </bpmn:process>
  
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_GestionCuentasBancarias">
      <bpmndi:BPMNShape id="_BPMNShape_StartEvent_2" bpmnElement="StartEvent_1">
        <dc:Bounds x="100" y="100" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_1_di" bpmnElement="Gateway_1">
        <dc:Bounds x="200" y="80" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_1_di" bpmnElement="Task_1">
        <dc:Bounds x="300" y="50" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_2_di" bpmnElement="Task_2">
        <dc:Bounds x="300" y="150" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_3_di" bpmnElement="Task_3">
        <dc:Bounds x="300" y="250" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_4_di" bpmnElement="Task_4">
        <dc:Bounds x="300" y="350" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="500" y="200" width="36" height="36" />
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```

## Descripción del Proceso

Este diagrama BPMN representa el flujo de negocio para la gestión de cuentas bancarias en un entorno SOA. El proceso incluye:

1. **Inicio**: Recibe una solicitud de gestión de cuenta (creación, consulta, actualización o eliminación)
2. **Decisión**: Determina el tipo de operación a realizar mediante un gateway exclusivo
3. **Operaciones**:
   - Crear cuenta bancaria (con validación previa)
   - Consultar cuenta bancaria
   - Actualizar cuenta bancaria
   - Eliminar cuenta bancaria (soft delete)
4. **Validación**: Subproceso para validar datos del cliente (identidad y capacidad financiera)
5. **Auditoría**: Registro de todas las operaciones realizadas
6. **Fin**: Finalización del proceso con respuesta adecuada

## Actores y Sistemas Involucrados

| Actor/Sistema          | Rol                                                                 |
|------------------------|---------------------------------------------------------------------|
| Cliente                | Solicita operaciones sobre sus cuentas bancarias                    |
| Sistema de Gestión     | Orquesta el flujo y coordina las operaciones                       |
| Servicio de Validación | Valida identidad y capacidad financiera del cliente                |
| Sistema de Auditoría   | Registra todas las operaciones para cumplimiento normativo         |
| Base de Datos          | Almacena la información de las cuentas bancarias                   |

## Puntos de Decisión

1. **Tipo de Operación**: El gateway exclusivo determina qué operación realizar basado en el parámetro `operationType`
2. **Validación de Datos**: Solo aplica para operaciones de creación y actualización
3. **Manejo de Errores**: Cualquier fallo en la validación genera un evento de error con código 400

## Reglas de Negocio

1. **Idempotencia**: Todas las operaciones deben ser idempotentes mediante el uso de `Idempotency-Key`
2. **Consistencia**: Las operaciones de escritura deben garantizar consistencia eventual
3. **Seguridad**: Todos los datos sensibles deben ser enmascarados en las respuestas
4. **Auditoría**: Todas las operaciones deben ser registradas con timestamp y usuario
5. **Soft Delete**: La eliminación de cuentas es lógica (marcar como inactiva)

## Métricas de Rendimiento

| Métrica                     | Valor Esperado               |
|----------------------------|-----------------------------|
| Latencia máxima            | < 200ms                     |
| Throughput                 | 1,000 solicitudes/segundo   |
| Disponibilidad             | 99.95%                      |
| Tiempo de recuperación (RTO)| < 15 minutos                |

## Referencias a Estándares

- **BIAN Service Landscape**: Se alinea con el dominio "Current Account" (BIAN Service Domain: CurrentAccount)
- **ISO 20022**: Los mensajes siguen el formato de "Account Management" (camt.080, camt.081)
- **RFC 7807**: Para estructura de mensajes de error
- **FAPI**: Para mecanismos de autenticación y autorización

## Ejemplo de Flujo Completo

1. Cliente envía solicitud POST a `/cuentas-bancarias` con payload:
   ```json
   {
     "tipo_cuenta": "AHORROS",
     "moneda": "COP",
     "titular": {
       "tipo_identificacion": "CC",
       "numero_identificacion": "123456789",
       "nombre": "Juan Pérez"
     }
   }
   ```
2. Sistema valida identidad y capacidad financiera
3. Sistema crea la cuenta y registra auditoría
4. Sistema responde con:
   ```json
   {
     "id_cuenta": "a1b2c3d4-5678-90ef-ghij-klmnopqrstuv",
     "numero_cuenta": "530000123456",
     "estado": "ACTIVA",
     "fecha_creacion": "2023-11-15T10:30:00Z"
   }
   ```