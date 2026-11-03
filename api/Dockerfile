# =============================================================================
#  ATOMIX API - Java 21 + Spring Boot
#  Multi-stage build com imagens Alpine (menores e mais rápidas)
# =============================================================================

# ---------- Estágio 1: build com Maven ----------
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /build

# Baixa as dependências primeiro para aproveitar o cache de camadas
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Compila e empacota o .jar (testes rodam fora do container)
COPY src ./src
RUN mvn -B -q clean package -DskipTests \
 && cp target/*.jar /build/app.jar

# ---------- Estágio 2: runtime somente com JRE ----------
FROM eclipse-temurin:21-jre-alpine

LABEL org.opencontainers.image.title="atomix-api" \
      org.opencontainers.image.description="API REST ATOMIX - Challenge FIAP 2026 / Marinha do Brasil" \
      org.opencontainers.image.authors="Gianluca K. Araujo (RM566765), Ruan Ribeiro (RM567693)"

# Usuário e grupo SEM privilégios administrativos
RUN addgroup -S atomix && adduser -S -G atomix -H -s /sbin/nologin atomix

# Diretório padrão do projeto
WORKDIR /app

COPY --from=build --chown=atomix:atomix /build/app.jar /app/app.jar

USER atomix

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -Djava.security.egd=file:/dev/./urandom" \
    TZ=America/Sao_Paulo

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
