FROM node:24-alpine AS front-build

COPY ./front /src

WORKDIR /src

RUN npm ci \
    && npx @angular/cli build --optimization

FROM gradle:8.7-jdk17 AS back-build

COPY ./back /src

WORKDIR /src

RUN ./gradlew build

FROM caddy:2.11.4-alpine AS front

COPY --from=front-build /src/dist/microcrm/browser /app/front
COPY misc/docker/Caddyfile /etc/caddy/Caddyfile

WORKDIR /app

EXPOSE 80
EXPOSE 443

# CMD ["/usr/sbin/caddy", "run"]

FROM eclipse-temurin:17-jre-alpine AS back

WORKDIR /app

COPY --from=back-build /src/build/libs/microcrm-0.0.1-SNAPSHOT.jar /app/back/microcrm-0.0.1-SNAPSHOT.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/back/microcrm-0.0.1-SNAPSHOT.jar"]

FROM eclipse-temurin:17-jre-alpine AS standalone

RUN apk add supervisor

RUN apk add caddy

WORKDIR /app

COPY --from=front /app/front /app/front
COPY --from=back /app/back /app/back

COPY misc/docker/supervisor.ini /app/supervisor.ini
COPY misc/docker/Caddyfile /app/Caddyfile

EXPOSE 80
EXPOSE 443
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/app/supervisor.ini"]



