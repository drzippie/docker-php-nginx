# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Docker base image** project that provides a lightweight PHP 8.4 + Nginx 1.26 web server stack on Alpine Linux. The image is designed for production use and follows security best practices.

## Architecture

### Core Components
- **Nginx 1.26**: Web server listening on port 8080 (non-privileged)
- **PHP 8.4 + PHP-FPM**: Process manager with on-demand scaling
- **Supervisord**: Process supervisor managing both services
- **Alpine Linux 3.21**: Minimal base OS (~40MB total image size)

### Process Communication
- Nginx ↔ PHP-FPM via Unix socket (`/run/php-fpm.sock`)
- All processes run as `nobody` user for security
- Logs output to stdout/stderr for container visibility

## Common Development Commands

### Building and Testing
```bash
# Build the image
docker build -t drzippie/php-nginx .

# Run automated tests
docker-compose -f docker-compose.test.yml up --build

# Run container locally
docker run -p 80:8080 drzippie/php-nginx

# Mount custom code
docker run -p 80:8080 -v ~/my-app:/var/www/html drzippie/php-nginx
```

### Testing Endpoints
- Main application: `http://localhost/`
- PHP info page: `http://localhost/` (shows phpinfo)
- Static test: `http://localhost/test.html`
- Health check: `http://localhost/fmp-ping` (internal use)

## Key Configuration Files

### Docker Configuration
- `Dockerfile`: Main image build definition with PHP 8.4 + essential extensions
- `docker-compose.test.yml`: Test environment setup
- `run_tests.sh`: Automated test script (checks PHP version response)

### Server Configuration  
- `config/nginx.conf`: Main Nginx config with gzip, security headers, logging
- `config/conf.d/default.conf`: Server block with PHP-FPM integration and routing
- `config/supervisord.conf`: Process management for nginx + php-fpm
- `config/fmp-pool.conf`: PHP-FPM pool settings (on-demand scaling, up to 100 workers)
- `config/php.ini`: PHP runtime configuration

### Application Files
- `src/index.php`: Sample PHP file showing phpinfo  
- `src/test.html`: Static HTML test file

## Development Patterns

### Configuration Mounting
When extending this image, mount custom configurations:
```bash
# Custom Nginx server config
docker run -v "`pwd`/nginx-server.conf:/etc/nginx/conf.d/server.conf" drzippie/php-nginx

# Custom PHP settings
docker run -v "`pwd`/php-setting.ini:/etc/php84/conf.d/settings.ini" drzippie/php-nginx  

# Custom PHP-FPM pool config
docker run -v "`pwd`/php-fpm-settings.conf:/etc/php84/php-fpm.d/server.conf" drzippie/php-nginx
```

### Security Features
- Non-root execution (nobody user)
- Hidden server tokens and PHP version headers
- Restricted file access patterns (denies dotfiles)
- Secure temp file locations under `/tmp`

### Performance Optimizations  
- On-demand PHP-FPM process spawning
- Gzip compression enabled with optimized MIME types
- Asset caching headers (5 days for static files)
- OPcache enabled for PHP bytecode caching

## Extension Documentation

The `docs/` directory contains guides for common customizations:
- `composer-support.md`: Adding Composer dependency management
- `xdebug-support.md`: Enabling Xdebug for development  
- `enable-https.md`: SSL/HTTPS configuration
- `sending-emails.md`: Email sending capabilities
- `real-ip-behind-loadbalancer.md`: Load balancer integration

## Image Versioning

- `latest` tag: Auto-updated weekly with Alpine patches
- Releases: Major/minor changes published with changelogs
- Multi-platform: Supports AMD64, ARMv6, ARMv7, ARM64