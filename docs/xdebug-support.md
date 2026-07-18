# Enabling Xdebug

Xdebug is **already installed** in the base image but **disabled by default** (it
adds overhead you don't want in production). To enable it you only need to add an
Xdebug ini file into the PHP config directory — no need to install anything.

## Enable via a mounted config

Create the following file `xdebug.ini`:

```ini
zend_extension=xdebug.so
xdebug.mode=develop,debug
xdebug.discover_client_host=true
xdebug.start_with_request=yes
xdebug.trigger_value=PHPSTORM
xdebug.log_level=0

xdebug.var_display_max_children=10
xdebug.var_display_max_data=10
xdebug.var_display_max_depth=10

xdebug.client_host=host.docker.internal
xdebug.client_port=9003
```

Mount it at runtime:

```bash
docker run -p 80:8080 \
  -v "$(pwd)/xdebug.ini:/etc/php84/conf.d/xdebug.ini" \
  drzippie/php-nginx
```

## Enable in a derived image

```Dockerfile
FROM drzippie/php-nginx:latest

# Add Xdebug configuration (the extension is already present in the base image)
COPY xdebug.ini ${PHP_INI_DIR}/conf.d/xdebug.ini
```

> Note: the base image ships the package's default loader renamed to
> `50_xdebug.ini.disabled` so Xdebug stays off until you supply your own ini.
