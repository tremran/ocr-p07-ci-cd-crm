FROM node AS front-build

COPY ./front /src

WORKDIR /src

RUN npm ci \
    && npx @angular/cli build --optimization

FROM gradle:jdk17 AS back-build

COPY ./back /src

WORKDIR /src

RUN ./gradlew build

FROM alpine:3.19 AS front

RUN apk add caddy

COPY --from=front-build /src/dist/microcrm/browser /app/front
COPY misc/docker/Caddyfile /app/Caddyfile

WORKDIR /app

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/caddy", "run"]

FROM alpine:3.19 AS back

WORKDIR /app
RUN apk add openjdk21-jre-headless

COPY --from=back-build /src/build/libs/microcrm-0.0.1-SNAPSHOT.jar /app/back/microcrm-0.0.1-SNAPSHOT.jar

EXPOSE 4200

CMD ["java", "-jar", "/app/back/microcrm-0.0.1-SNAPSHOT.jar"]

FROM alpine:3.19 AS standalone

RUN apk add supervisor

COPY misc/docker/supervisor.ini /app/supervisor.ini

COPY --from=front / /
COPY --from=back / /

WORKDIR /app

CMD ["/usr/bin/supervisord", "-c", "/app/supervisor.ini"]



