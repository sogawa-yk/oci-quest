FROM --platform=${BUILDPLATFORM:-linux/amd64} maven:3.9-eclipse-temurin-21 AS catalogue-builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

FROM --platform=$TARGETPLATFORM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/target/catalogue-1.0.0.jar app.jar

ENV CATALOGUE_DATABASE_URL=jdbc:oracle:thin:@localhost:1521/XEPDB1 \
    CATALOGUE_DATABASE_USER=catalogue \
    CATALOGUE_DATABASE_PASSWORD=default

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]