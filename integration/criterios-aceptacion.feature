# language: es
@gestion-cuentas
Feature: Gestión de cuentas bancarias
  Como cliente del banco
  Quiero gestionar mis cuentas bancarias mediante una API REST
  Para poder realizar operaciones básicas de manera segura y eficiente

  Background:
    Given el sistema de gestión de cuentas está disponible
    And existen las siguientes cuentas registradas:
      | accountId | accountType | balance | status   | customerId |
      | 12345     | AHORROS     | 1000.50 | ACTIVA   | cust-1     |
      | 67890     | CORRIENTE   | 500.25  | ACTIVA   | cust-2     |
    And el cliente "cust-1" tiene permisos para operar la cuenta "12345"

  @smoke
  Scenario: Crear una nueva cuenta bancaria exitosamente
    Given el cliente "cust-3" no tiene cuentas registradas
    When el cliente envía una solicitud POST a "/cuentas" con los siguientes datos:
      """
      {
        "customerId": "cust-3",
        "accountType": "AHORROS",
        "initialBalance": 0.00,
        "currency": "COP"
      }
      """
    And la solicitud incluye el header "Idempotency-Key" con valor "uuid-create-1"
    Then el sistema responde con el código de estado HTTP 201
    And el cuerpo de la respuesta contiene:
      """
      {
        "accountId": "@string@",
        "accountType": "AHORROS",
        "balance": 0.00,
        "status": "ACTIVA",
        "customerId": "cust-3",
        "createdAt": "@datetime@",
        "currency": "COP"
      }
      """
    And el sistema registra la operación en el log de auditoría

  @error-handling
  Scenario: Crear cuenta con datos inválidos devuelve error 400
    When el cliente envía una solicitud POST a "/cuentas" con los siguientes datos:
      """
      {
        "customerId": "",
        "accountType": "INVALID",
        "initialBalance": -100.00
      }
      """
    Then el sistema responde con el código de estado HTTP 400
    And el cuerpo de la respuesta contiene:
      """
      {
        "type": "https://api.bancolombia.com/errors/invalid-request",
        "title": "Solicitud inválida",
        "status": 400,
        "detail": "Los datos proporcionados no cumplen con el esquema requerido.",
        "errors": [
          {
            "field": "customerId",
            "message": "Debe ser un string no vacío"
          },
          {
            "field": "accountType",
            "message": "Debe ser uno de: AHORROS, CORRIENTE, CDT"
          },
          {
            "field": "initialBalance",
            "message": "Debe ser mayor o igual a 0"
          }
        ]
      }
      """

  @idempotency
  Scenario: Operación idempotente para creación de cuenta
    Given el cliente "cust-4" no tiene cuentas registradas
    When el cliente envía una solicitud POST a "/cuentas" con los mismos datos y mismo "Idempotency-Key" "uuid-create-2" dos veces
    Then la primera solicitud responde con HTTP 201
    And la segunda solicitud responde con HTTP 200
    And ambas respuestas contienen el mismo "accountId"

  Scenario: Consultar información de una cuenta existente
    Given existe la cuenta con ID "12345"
    When el cliente envía una solicitud GET a "/cuentas/12345"
    Then el sistema responde con el código de estado HTTP 200
    And el cuerpo de la respuesta contiene:
      """
      {
        "accountId": "12345",
        "accountType": "AHORROS",
        "balance": 1000.50,
        "status": "ACTIVA",
        "customerId": "cust-1",
        "createdAt": "@datetime@",
        "currency": "COP",
        "_links": {
          "self": {
            "href": "https://api.bancolombia.com/cuentas/12345"
          },
          "transactions": {
            "href": "https://api.bancolombia.com/cuentas/12345/transacciones"
          }
        }
      }
      """

  @error-handling
  Scenario: Consultar cuenta inexistente devuelve error 404
    When el cliente envía una solicitud GET a "/cuentas/99999"
    Then el sistema responde con el código de estado HTTP 404
    And el cuerpo de la respuesta contiene:
      """
      {
        "type": "https://api.bancolombia.com/errors/not-found",
        "title": "Recurso no encontrado",
        "status": 404,
        "detail": "La cuenta con ID 99999 no existe.",
        "instance": "/cuentas/99999"
      }
      """

  Scenario: Actualizar el estado de una cuenta
    Given existe la cuenta con ID "67890" y estado "ACTIVA"
    When el cliente envía una solicitud PATCH a "/cuentas/67890" con:
      """
      {
        "status": "BLOQUEADA",
        "reason": "Fraude detectado"
      }
      """
    Then el sistema responde con el código de estado HTTP 200
    And el cuerpo de la respuesta contiene:
      """
      {
        "accountId": "67890",
        "status": "BLOQUEADA",
        "reason": "Fraude detectado",
        "updatedAt": "@datetime@"
      }
      """
    And el sistema registra el cambio en el log de auditoría

  @error-handling
  Scenario: Actualizar cuenta con estado inválido devuelve error 400
    Given existe la cuenta con ID "12345"
    When el cliente envía una solicitud PATCH a "/cuentas/12345" con:
      """
      {
        "status": "INVALID_STATUS"
      }
      """
    Then el sistema responde con el código de estado HTTP 400
    And el cuerpo de la respuesta contiene:
      """
      {
        "type": "https://api.bancolombia.com/errors/invalid-request",
        "title": "Solicitud inválida",
        "status": 400,
        "detail": "El estado proporcionado no es válido.",
        "errors": [
          {
            "field": "status",
            "message": "Debe ser uno de: ACTIVA, BLOQUEADA, CERRADA"
          }
        ]
      }
      """

  @error-handling
  Scenario: Eliminar cuenta con saldo positivo devuelve error 403
    Given existe la cuenta con ID "12345" y balance 1000.50
    When el cliente envía una solicitud DELETE a "/cuentas/12345"
    Then el sistema responde con el código de estado HTTP 403
    And el cuerpo de la respuesta contiene:
      """
      {
        "type": "https://api.bancolombia.com/errors/insufficient-conditions",
        "title": "Condiciones insuficientes para la operación",
        "status": 403,
        "detail": "No se puede eliminar una cuenta con saldo positivo.",
        "accountId": "12345",
        "currentBalance": 1000.50,
        "requiredBalance": 0.00
      }
      """

  Scenario: Eliminar cuenta con saldo cero
    Given existe la cuenta con ID "67890" y balance 0.00
    When el cliente envía una solicitud DELETE a "/cuentas/67890"
    Then el sistema responde con el código de estado HTTP 204
    And el sistema marca la cuenta como "CERRADA" en la base de datos
    And el sistema registra la operación en el log de auditoría

  @performance
  Scenario: Respuesta dentro del SLA para consultas de cuentas
    Given existen 1000 cuentas en el sistema
    When el cliente envía 100 solicitudes GET concurrentes a "/cuentas/{accountId}" con diferentes IDs
    Then cada solicitud responde en menos de 200ms
    And todas las respuestas tienen código HTTP 200

  @resilience
  Scenario: Servicio tolera fallos parciales en dependencias
    Given el servicio de auditoría está caído
    When el cliente envía una solicitud POST a "/cuentas"
    Then el sistema responde con HTTP 201
    And el sistema registra el fallo de auditoría en un circuito breaker
    And el sistema encola la operación de auditoría para reprocesamiento