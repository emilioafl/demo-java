FROM amazoncorretto:17.0.14-alpine3.21
LABEL author="Emilio Flores" \
      maintainer="Emilio Flores"

ARG TIMEZONE=America/Guayaquil
ENV TZ=${TIMEZONE}

RUN apk update && apk upgrade && apk add --no-cache \
    tzdata=2025b-r0 \
    curl=8.12.1-r1 \
    dumb-init=1.2.5-r3 \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1000 devsu \
    && adduser -u 1000 -G devsu -D devsu \
    && mkdir -p /app /logs \
    && chown -R devsu:devsu /app /logs \
    && chmod -R 775 /app /logs \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apk del tzdata

COPY --chown=devsu:devsu target/*.jar /app/app.jar
COPY --chown=devsu:devsu src/main/resources/application.properties /app/application.properties

USER devsu
WORKDIR /app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/actuator/health || exit 1

ENTRYPOINT ["dumb-init", "java", "-jar", "app.jar", "-Dspring.config.location=/app/application.properties"]