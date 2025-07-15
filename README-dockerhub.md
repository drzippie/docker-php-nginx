# Docker PHP-FPM 8.4 & Nginx 1.26 on Alpine Linux

[![Docker Pulls](https://img.shields.io/docker/pulls/drzippie/php-nginx.svg)](https://hub.docker.com/r/drzippie/php-nginx/)
![nginx 1.26](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)
![php 8.4](https://img.shields.io/badge/php-8.4-brightgreen.svg)
![swoole 6.0.2](https://img.shields.io/badge/swoole-6.0.2-blue.svg)
![imagemagick](https://img.shields.io/badge/imagemagick-7.1.1-orange.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

Production-ready PHP-FPM 8.4 & Nginx 1.26 container built on Alpine Linux with Swoole and ImageMagick support.

## Features

* **Lightweight**: Built on Alpine Linux (~50MB total image size)
* **Multi-platform**: Supports AMD64, ARMv6, ARMv7, ARM64
* **High Performance**: PHP 8.4 with optimized configuration
* **Swoole Support**: Includes Swoole 6.0.2 for async/coroutine applications
* **ImageMagick**: Full image manipulation capabilities with PHP Imagick extension
* **Production Ready**: Optimized for 100 concurrent users
* **Security First**: All processes run as non-privileged user (nobody)
* **Resource Efficient**: Uses PHP-FPM's on-demand process manager

## Quick Start

```bash
# Run with default configuration
docker run -p 80:8080 drzippie/php-nginx

# Mount your application code
docker run -p 80:8080 -v /path/to/your/code:/var/www/html drzippie/php-nginx

# View PHP info
curl http://localhost/
```

## What's Included

### Core Components
- **Nginx 1.26**: High-performance web server
- **PHP 8.4**: Latest PHP with optimal performance
- **PHP-FPM**: Process manager with on-demand scaling
- **Supervisord**: Process supervisor managing all services

### Extensions & Tools
- **Swoole 6.0.2**: High-performance async/coroutine framework
- **ImageMagick 7.1.1**: Advanced image manipulation (205+ formats)
- **Composer**: Dependency management
- **Common PHP Extensions**: bcmath, ctype, curl, dom, fileinfo, gd, iconv, intl, mbstring, mysqli, opcache, openssl, pdo, phar, session, simplexml, sockets, tokenizer, xml, xmlreader, xmlwriter

## Usage Examples

### Basic Web Application
```bash
docker run -d \
  --name my-app \
  -p 80:8080 \
  -v /path/to/app:/var/www/html \
  drzippie/php-nginx
```

### With Custom Configuration
```bash
docker run -d \
  --name my-app \
  -p 80:8080 \
  -v /path/to/app:/var/www/html \
  -v /path/to/nginx.conf:/etc/nginx/conf.d/default.conf \
  -v /path/to/php.ini:/etc/php84/conf.d/custom.ini \
  drzippie/php-nginx
```

### Swoole Application
```bash
# For Swoole HTTP server applications
docker run -d \
  --name swoole-app \
  -p 9501:9501 \
  -v /path/to/swoole-app:/var/www/html \
  drzippie/php-nginx \
  php swoole-server.php
```

## Configuration

### Environment Variables
The container uses standard PHP and Nginx configurations optimized for production.

### Volume Mounts
- `/var/www/html` - Application code
- `/etc/nginx/conf.d/` - Nginx server configuration
- `/etc/php84/conf.d/` - PHP configuration files
- `/etc/php84/php-fpm.d/` - PHP-FPM pool configuration

### Exposed Ports
- `8080` - HTTP (Nginx)

## Performance & Security

### Optimizations
- **On-demand PHP-FPM**: Spawns workers only when needed (0-100 workers)
- **Worker Recycling**: Prevents memory leaks with request limits
- **Gzip Compression**: Optimized for web assets
- **OPcache**: Enabled for PHP bytecode caching
- **Resource Limits**: Configured for 100 concurrent users

### Security Features
- Non-root execution (nobody user)
- Hidden server tokens and version headers
- Secure file access patterns
- Restricted temporary file locations

## Common Use Cases

### Web Applications
Perfect for Laravel, Symfony, WordPress, or any PHP application requiring modern PHP features.

### Image Processing
Built-in ImageMagick support for thumbnails, watermarks, format conversion, and advanced image manipulation.

### High-Performance APIs
Swoole support enables building high-performance APIs with async/coroutine capabilities.

### Microservices
Lightweight and fast startup makes it ideal for containerized microservices.

## Health Check

The container includes a built-in health check endpoint:
```bash
curl http://localhost:8080/fmp-ping
```

## Troubleshooting

### Common Issues

**Container won't start**
- Check if port 8080 is available
- Verify volume mount paths exist and are readable

**PHP errors**
- Check logs with: `docker logs container-name`
- Verify PHP configuration with mounted php.ini

**Performance issues**
- Monitor with: `curl http://localhost:8080/fpm-status`
- Adjust PHP-FPM settings via volume mounts

## Documentation

For detailed configuration examples and advanced usage:

- [GitHub Repository](https://github.com/drzippie/docker-php-nginx)
- [ImageMagick Support](https://github.com/drzippie/docker-php-nginx/blob/master/docs/imagemagick-support.md)
- [Swoole Support](https://github.com/drzippie/docker-php-nginx/blob/master/docs/swoole-support.md)
- [Xdebug Support](https://github.com/drzippie/docker-php-nginx/blob/master/docs/xdebug-support.md)
- [HTTPS/SSL Setup](https://github.com/drzippie/docker-php-nginx/blob/master/docs/enable-https.md)

## Versioning

- `latest` - Latest stable release
- `YYYY-MM-DD` - Date-based tags for specific versions

## License

MIT License - see [LICENSE](https://github.com/drzippie/docker-php-nginx/blob/master/LICENSE) file.

## About

This image is a fork of [TrafeX/docker-php-nginx](https://github.com/TrafeX/docker-php-nginx) with enhanced features for production use including Swoole and ImageMagick support.

---

**Repository**: [drzippie/docker-php-nginx](https://github.com/drzippie/docker-php-nginx)  
**Docker Hub**: [drzippie/php-nginx](https://hub.docker.com/r/drzippie/php-nginx)