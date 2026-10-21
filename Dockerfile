ARG ALPINE_VERSION=3.24
# Where the php84 packages come from: "alpine" (official repo, default) or
# "build" (compile PHP_VERSION ourselves with Alpine's APKBUILD, for urgent
# security releases not yet packaged by Alpine). Example:
#   docker buildx build --build-arg PHP_SOURCE=build \
#     --build-arg PHP_VERSION=8.4.27 --build-arg PHP_SHA256=<sha256 from php.net> .
ARG PHP_SOURCE=alpine

FROM alpine:${ALPINE_VERSION} AS php-pkgs-alpine
RUN mkdir -p /packages /keys

FROM alpine:${ALPINE_VERSION} AS php-pkgs-build
ARG ALPINE_VERSION
ARG PHP_VERSION
ARG PHP_SHA256
RUN test -n "$PHP_VERSION" && test -n "$PHP_SHA256" && \
    apk add --no-cache alpine-sdk curl && \
    abuild-keygen -a -n && \
    mkdir -p /keys && cp ~/.abuild/*.rsa.pub /keys/ && cp /keys/* /etc/apk/keys/
WORKDIR /aports
RUN curl -fsSL "https://gitlab.alpinelinux.org/alpine/aports/-/archive/${ALPINE_VERSION}-stable/aports.tar.gz?path=community/php84" \
    | tar -xz --strip-components=1
WORKDIR /aports/community/php84
# pkgrel=100 makes our build win over the same version in the official repo
RUN sed -i -e "s/^pkgver=.*/pkgver=${PHP_VERSION}/" -e 's/^pkgrel=.*/pkgrel=100/' \
      -e '/^pkgrel=/a options="!check"' APKBUILD && \
    export SRCDEST=/distfiles REPODEST=/packages && \
    abuild -F checksum && \
    echo "${PHP_SHA256}  /distfiles/php-${PHP_VERSION}.tar.xz" | sha256sum -c - && \
    apk update && abuild -F -r

FROM php-pkgs-${PHP_SOURCE} AS php-pkgs

FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Tim de Pater <code@trafex.nl>"
LABEL Description="Lightweight container with Nginx 1.30 & PHP 8.4 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
# (php84 packages built in php-pkgs take precedence when PHP_SOURCE=build)
RUN --mount=type=bind,from=php-pkgs,source=/,target=/php-pkgs \
  cp /php-pkgs/keys/* /etc/apk/keys/ 2>/dev/null; \
  REPO=""; [ -d /php-pkgs/packages/community ] && REPO="--repository /php-pkgs/packages/community"; \
  apk add --no-cache $REPO \
  curl \
  git \
  imagemagick \
  nginx \
  nodejs \
  npm \
  php84 \
  php84-bcmath \
  php84-ctype \
  php84-curl \
  php84-dom \
  php84-exif \
  php84-fileinfo \
  php84-fpm \
  php84-gd \
  php84-iconv \
  php84-intl \
  php84-mbstring \
  php84-mysqli \
  php84-opcache \
  php84-openssl \
  php84-pdo \
  php84-pdo_mysql \
  php84-pdo_pgsql \
  php84-pdo_sqlite \
  php84-pecl-apcu \
  php84-pecl-imagick \
  php84-pecl-redis \
  php84-pecl-xdebug \
  php84-pgsql \
  php84-phar \
  php84-session \
  php84-simplexml \
  php84-sockets \
  php84-tidy \
  php84-tokenizer \
  php84-xml \
  php84-xmlreader \
  php84-xmlwriter \
  php84-zip \
  php84-pecl-swoole \
  supervisor

RUN ln -s /usr/bin/php84 /usr/bin/php

# Disable Xdebug by default (the package auto-loads it). It ships installed but
# inactive: mount an ini into ${PHP_INI_DIR}/conf.d/ to enable it. See docs/xdebug-support.md
RUN find /etc/php84/conf.d -name '*xdebug*.ini' -exec sh -c \
    'mv "$1" "${1}.disabled"' _ {} \;

# Set up Composer environment and directories
ENV COMPOSER_HOME=/.composer
ENV HOME=/home/nobody
ENV COMPOSER_CACHE_DIR=/.composer/cache

# Create directories for nobody user
RUN mkdir -p /home/nobody /.composer /.composer/cache && \
    chown -R nobody:nobody /home/nobody /.composer

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
ENV PHP_INI_DIR=/etc/php84
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/supervisord.conf
COPY config/supervisor/ /etc/supervisor/conf.d/

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# add composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
