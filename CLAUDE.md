# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Docker base image** project that provides a lightweight PHP 8.4 + Nginx 1.26 web server stack on Alpine Linux. The image is designed for production use and follows security best practices. It's optimized for 100 concurrent users with on-demand resource allocation.

## Architecture

### Core Components
- **Nginx 1.26**: Web server listening on port 8080 (non-privileged)
- **PHP 8.4 + PHP-FPM**: Process manager with on-demand scaling (0-100 workers)
- **Supervisord**: Process supervisor managing both services as PID 1
- **Alpine Linux 3.21**: Minimal base OS (~40MB total image size)

### Process Communication Flow
```
Client → Nginx (port 8080) → PHP-FPM (Unix socket) → Response
```
- **Socket Communication**: Nginx ↔ PHP-FPM via Unix socket (`/run/php-fpm.sock`)
- **Security Model**: All processes run as `nobody` user for security
- **Logging**: All logs redirect to stdout/stderr for Docker container visibility
- **Health Monitoring**: `/fmp-ping` endpoint for container health checks

### Multi-Architecture Support
The image supports AMD64, ARMv6, ARMv7, and ARM64 architectures through Docker Buildx.

## Common Development Commands

### Building and Testing
```bash
# Build the image (single architecture)
docker build -t drzippie/php-nginx .

# Build for specific architecture (AMD64)
docker buildx build --platform linux/amd64 -t drzippie/php-nginx .

# Run automated smoke tests
docker-compose -f docker-compose.test.yml up --build

# Run container locally
docker run -p 80:8080 drzippie/php-nginx

# Mount custom code for development
docker run -p 80:8080 -v ~/my-app:/var/www/html drzippie/php-nginx

# Test specific PHP version response
curl --silent --fail http://localhost:8080 | grep 'PHP 8.4'
```

### Manual Testing
Use the smoke test to verify the build:
```bash
# Run the same test that was used in CI
docker-compose -f docker-compose.test.yml up --build
```

### Testing Endpoints
- Main application: `http://localhost/` (shows phpinfo)
- Static test: `http://localhost/test.html`
- Health check: `http://localhost/fmp-ping` (internal use)
- FPM status: `http://localhost/fpm-status` (if enabled)

## Key Configuration Files

### Docker Configuration
- `Dockerfile`: Main image build definition with PHP 8.4 + essential extensions (including ImageMagick)
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
- **On-demand PHP-FPM**: Process spawning only when needed (0-100 workers)
- **Worker Recycling**: Processes recycled after 1000 requests to prevent memory leaks
- **Gzip Compression**: Enabled with optimized MIME types based on CloudFlare recommendations
- **Asset Caching**: 5-day cache headers for static files
- **OPcache**: Enabled for PHP bytecode caching
- **Idle Timeout**: 10-second timeout for efficient resource usage

## Configuration Architecture

### Layered Configuration System
The project uses a layered approach where base configurations can be overridden:

**Base Layer** (built into image):
- Core security settings and performance optimizations
- Default PHP-FPM pool configuration with on-demand scaling
- Nginx routing rules and FastCGI integration

**Override Layer** (runtime mounting):
- Custom Nginx server blocks
- PHP configuration overrides
- PHP-FPM pool customizations

### Critical Configuration Relationships
- **Supervisord** manages both Nginx and PHP-FPM as child processes
- **PHP-FPM** configured for socket-based communication with Nginx
- **Nginx** uses try_files pattern: file → directory → index.php
- **Security headers** set at Nginx level (CSP, HSTS, etc.)

## Extension Documentation

The `docs/` directory contains guides for common customizations:
- `imagemagick-support.md`: ImageMagick image manipulation capabilities
- `composer-support.md`: Adding Composer dependency management
- `xdebug-support.md`: Enabling Xdebug for development  
- `enable-https.md`: SSL/HTTPS configuration
- `sending-emails.md`: Email sending capabilities
- `real-ip-behind-loadbalancer.md`: Load balancer integration
- `swoole-support.md`: Swoole async/coroutine PHP framework

## Development Workflow

### Testing Strategy
- **Smoke Tests**: Basic HTTP response verification via `run_tests.sh`
- **Container Health**: Uses `/fmp-ping` endpoint for health checks
- **Manual Testing**: Use `docker-compose.test.yml` for local verification

### Build Process
- **Multi-stage**: Composer support through multi-stage builds
- **Package Installation**: Single RUN command for optimal layer caching
- **Security Focus**: All processes run as `nobody` user

## Image Versioning

- `latest` tag: Auto-updated weekly with Alpine patches
- Releases: Major/minor changes published with changelogs
- Multi-platform: Supports AMD64, ARMv6, ARMv7, ARM64

## Build and Deployment Guidelines

### Docker Hub Deployment
- Always build for AMD64 architecture
- Upload image to Docker Hub at `drzippie/php-nginx`
- Tag builds with:
  * `latest` tag for current version
  * Current date tag for versioning