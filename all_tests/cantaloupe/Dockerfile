FROM maven:3-eclipse-temurin-21 as build

ARG VERSION=5.0.7
ENV VERSION=${VERSION}

RUN apt-get update -q -y && apt-get install -q -y patch unzip

WORKDIR /build

# Télécharger Cantaloupe
RUN wget -q https://github.com/cantaloupe-project/cantaloupe/archive/refs/tags/v${VERSION}.zip -O cantaloupe.zip \
    && unzip cantaloupe.zip

WORKDIR /build/cantaloupe-${VERSION}

# Appliquer les patchs
COPY patches/*.diff ./
RUN patch -p1 -i log_exif_errors.diff || echo "No patch needed"

RUN mvn clean package -DskipTests


FROM openjdk:21-slim

ARG VERSION=5.0.7
ARG LIBJPEGTURBO=2.1.2
ARG DELEGATE_VERSION=0.3.0

ENV VERSION=${VERSION}
ENV LIBJPEGTURBO=${LIBJPEGTURBO}
ENV DELEGATE_VERSION=${DELEGATE_VERSION}

ENV CANTALOUPE_PROPERTIES="/etc/cantaloupe.properties"
ENV JAVA_OPTS=""

EXPOSE 80

RUN apt-get update && apt-get install -y curl unzip gettext-base jq libopenjp2-tools cmake nasm netcat-openbsd

# libjpeg-turbo
RUN curl -L "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${LIBJPEGTURBO}.zip" > /tmp/libjpegturbo.zip \
  && unzip /tmp/libjpegturbo.zip -d /tmp \
  && cd /tmp/libjpeg-turbo-${LIBJPEGTURBO} \
  && cmake -G"Unix Makefiles" -DWITH_JAVA=1 \
  && make \
  && mkdir -p /opt/libjpeg-turbo/lib/ \
  && cp libturbojpeg.so /opt/libjpeg-turbo/lib/libturbojpeg.so

# Récupérer Cantaloupe compilé
COPY --from=build /build/cantaloupe-${VERSION}/target/cantaloupe-${VERSION}.zip /tmp/cantaloupe.zip

RUN mkdir -p /usr/local/ \
  && cd /usr/local \
  && unzip /tmp/cantaloupe.zip -d /usr/local \
  && ln -s cantaloupe-${VERSION} cantaloupe \
  && rm /tmp/cantaloupe.zip \
  && cp /usr/local/cantaloupe-${VERSION}/deps/Linux-x86-64/lib/* /lib

RUN adduser --system --home /opt/cantaloupe cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe /opt/cantaloupe \
  && chown -R cantaloupe /var/log/cantaloupe /var/cache/cantaloupe /opt/cantaloupe

# Script delegate multi-buckets
RUN curl -L "https://gitlab.teklia.com/api/v4/projects/272/packages/generic/multi-s3-buckets-delegate/${DELEGATE_VERSION}/multi-s3-buckets-delegate-${DELEGATE_VERSION}.jar" > /usr/local/cantaloupe/multi-s3-buckets-delegate-${DELEGATE_VERSION}.jar

USER cantaloupe
CMD java $JAVA_OPTS -cp /usr/local/cantaloupe/cantaloupe-${VERSION}.jar:/usr/local/cantaloupe/multi-s3-buckets-delegate-${DELEGATE_VERSION}.jar -Dcantaloupe.config=$CANTALOUPE_PROPERTIES edu.illinois.library.cantaloupe.StandaloneEntry
