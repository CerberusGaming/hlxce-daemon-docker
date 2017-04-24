FROM alpine:3.5

ENV HLXCE_VERSION=1_6_19 \
    DB_NAME=hlxce \
    DB_USERNAME=hlxce \
    DB_PASSWORD=hlxce \
    DB_HOST=db

COPY docker-hlxce-daemon-entrypoint /usr/local/bin/

WORKDIR /home/hlxce/

RUN set -x \
        && runDeps=' \
            perl \
            bash \
            su-exec \
            perl-dbd-mysql \
            perl-dbi \
            dcron \
        ' \
        && apk add --no-cache --virtual .build-deps \
            $runDeps \
            wget \
            curl \
            tar \
            ca-certificates \
            make \
        \
        && cpan install Geo::IP::PurePerl \
        && addgroup -S hlxce \
        && adduser -S -h /home/hlxce/ -s /bin/sh -g hlxce hlxce \
        && rm -rf /var/cache/apk/* \
        && chmod +x /usr/local/bin/docker-hlxce-daemon-entrypoint \
        && curl -L https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition/downloads/hlxce_${HLXCE_VERSION}.tar.gz -o hlxce.tar.gz \
        && tar -zxvf hlxce.tar.gz --strip-components=1 scripts/ \
        && rm -rf hlxce.tar.gz \
        && chmod +x hlstats-awards.pl hlstats.pl hlstats-resolve.pl run_hlstats \
        && echo '*/5 * * * * cd /home/hlxce/ && su-exec hlxce ./run_hlstats start >/dev/null 2>&1 \
        15 00 * * * cd /home/hlxce/ && su-exec hlxce ./hlstats-awards.pl >/dev/null 2>&1 \
        ' >> /root/daemon.txt \
        && chmod +x GeoLiteCity/install_binary.sh \
        && exec GeoLiteCity/install_binary.sh \
        && chown hlxce:hlxce -R . \
	    && apk add --virtual .httpd-rundeps $runDeps \
	    && apk del .build-deps

EXPOSE 27500/udp

ENTRYPOINT ["docker-hlxce-daemon-entrypoint"]