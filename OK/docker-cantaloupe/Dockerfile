FROM debian:buster

ENV CANTALOUPE_VERSION=4.1.5

EXPOSE 8182

VOLUME /imageroot

# Update packages and install tools
RUN apt-get update -qy && apt-get dist-upgrade -qy && \
    apt-get install -qy --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless && \
    apt-get -qqy autoremove && apt-get -qqy autoclean

# Run non privileged
RUN adduser --system cantaloupe

#COPY Cantaloupe-$CANTALOUPE_VERSION.zip .
COPY ZIP/cantaloupe-4.1.5 /cantaloupe/cantaloupe-4.1.5
COPY delegates.rb /cantaloupe/delegates.rb

# Get and unpack Cantaloupe release archive
#RUN unzip Cantaloupe-$CANTALOUPE_VERSION.zip \
RUN ln -s /cantaloupe/cantaloupe-4.1.5 /cantaloupe/cantaloupe \
    && mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /cantaloupe /var/log/cantaloupe /var/cache/cantaloupe \
    && cp -rs /cantaloupe/cantaloupe-4.1.5/deps/Linux-x86-64/* /usr/


USER cantaloupe
CMD ["sh", "-c", "java -Dcantaloupe.config=/cantaloupe/cantaloupe/cantaloupe.properties.sample -jar /cantaloupe/cantaloupe/cantaloupe-${CANTALOUPE_VERSION}.war"]


