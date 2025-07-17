#!/usr/bin/env sh
apk --no-cache add curl
curl --silent --fail http://app:8080 | grep 'PHP 8.4'
php -m | grep apcu
php -m | grep redis
