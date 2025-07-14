# Swoole Support

## What is Swoole?

Swoole is a high-performance, event-driven asynchronous and concurrent networking engine for PHP. It enables PHP developers to write high-performance, scalable TCP/UDP services, HTTP/WebSocket servers, and microservices.

## Features

The Docker image includes Swoole 6.0.2 with the following capabilities:

- **Asynchronous Programming**: Non-blocking I/O and coroutines
- **WebSocket Server**: Built-in WebSocket protocol support
- **HTTP/2 Support**: Modern HTTP protocol implementation
- **TCP/UDP Server**: Create custom network services
- **Coroutines**: Lightweight concurrency without threads
- **Connection Pooling**: For databases and other resources

## Configuration

Swoole is installed as a PHP extension (`php84-pecl-swoole`) and is automatically loaded. You can verify the installation:

```php
<?php
if (extension_loaded('swoole')) {
    echo "Swoole version: " . swoole_version() . "\n";
}
```

## Example Usage

### Basic HTTP Server

Create a simple Swoole HTTP server:

```php
<?php
// server.php
$http = new Swoole\Http\Server("0.0.0.0", 9501);

$http->on('request', function ($request, $response) {
    $response->header("Content-Type", "text/plain");
    $response->end("Hello from Swoole!\n");
});

$http->start();
```

Run with:
```bash
docker run -p 9501:9501 -v "$PWD/server.php:/var/www/html/server.php" drzippie/php-nginx php /var/www/html/server.php
```

### WebSocket Server

```php
<?php
// websocket.php
$ws = new Swoole\WebSocket\Server("0.0.0.0", 9502);

$ws->on('open', function ($ws, $request) {
    echo "Connection open: {$request->fd}\n";
});

$ws->on('message', function ($ws, $frame) {
    echo "Received: {$frame->data}\n";
    $ws->push($frame->fd, "Server: {$frame->data}");
});

$ws->on('close', function ($ws, $fd) {
    echo "Connection close: {$fd}\n";
});

$ws->start();
```

## Important Considerations

### Running with Nginx

When using Swoole's built-in HTTP server, you typically don't need Nginx as Swoole handles HTTP requests directly. However, you can use Nginx as a reverse proxy for Swoole applications:

1. **Standalone Swoole**: Run Swoole server on a different port (e.g., 9501)
2. **With Nginx**: Configure Nginx to proxy requests to Swoole

Example Nginx configuration for proxying to Swoole:

```nginx
location /swoole {
    proxy_pass http://127.0.0.1:9501;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Process Management

Since Swoole creates its own process manager, when running Swoole applications:

1. Don't use PHP-FPM for Swoole scripts
2. Run Swoole directly with the PHP CLI
3. Consider using supervisord to manage Swoole processes

### Memory and Performance

- Swoole uses persistent memory between requests
- Global variables maintain state across requests
- Memory usage is more efficient than traditional PHP-FPM
- Ideal for long-running services and real-time applications

## Included Extensions

The Swoole installation includes support for:

- OpenSSL (HTTPS/WSS)
- HTTP/2
- MySQL coroutine client
- PostgreSQL coroutine client
- Sockets
- cURL coroutine client
- Brotli compression

## Docker Usage Examples

### Running a Swoole Application

```bash
# Development
docker run -it --rm \
  -p 9501:9501 \
  -v "$PWD:/var/www/html" \
  drzippie/php-nginx \
  php /var/www/html/swoole-server.php

# Production with custom supervisor config
docker run -d \
  -p 80:8080 \
  -p 9501:9501 \
  -v "$PWD/swoole-supervisor.conf:/etc/supervisor/conf.d/swoole.conf" \
  -v "$PWD:/var/www/html" \
  drzippie/php-nginx
```

### Supervisor Configuration for Swoole

Create a `swoole-supervisor.conf`:

```ini
[program:swoole]
command=/usr/bin/php /var/www/html/server.php
process_name=%(program_name)s
numprocs=1
directory=/var/www/html
autostart=true
autorestart=true
user=nobody
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
```

## Resources

- [Swoole Documentation](https://www.swoole.com/docs)
- [Swoole GitHub Repository](https://github.com/swoole/swoole-src)
- [Swoole Examples](https://github.com/swoole/swoole-src/tree/master/examples)