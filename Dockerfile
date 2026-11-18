dockerfile
Usar imagen base de Java/Node (según tu stack)
FROM openjdk:17-jdk-slim

Establecer directorio de trabajo
WORKDIR /app

Copiar el código fuente
COPY . .

Compilar la aplicación (ajusta según tu build)
RUN ./gradlew build -x test

Exponer puerto
EXPOSE 8080

Comando para ejecutar
ENTRYPOINT ["java", "-jar", "build/libs/api.jar"]