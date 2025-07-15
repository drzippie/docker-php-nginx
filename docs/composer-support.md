# Composer Support

This Docker image includes [Composer](https://getcomposer.org/) with full support for global commands, caching, and proper file permissions.

## What's Included

- **Composer 2.x**: Latest stable version from official Composer image
- **PHP ZIP Extension**: Improves package installation performance
- **Writable .composer Directory**: Global configuration and cache support
- **Proper Permissions**: All directories writable by the nobody user
- **Environment Variables**: Pre-configured for optimal Composer usage

## Environment Variables

The image sets the following Composer-related environment variables:

- `COMPOSER_HOME=/.composer` - Global Composer configuration directory
- `HOME=/home/nobody` - User home directory
- `COMPOSER_CACHE_DIR=/.composer/cache` - Composer cache directory

## Basic Usage

### Install Dependencies
```bash
# Run composer install in your project
docker run -v $(pwd):/var/www/html drzippie/php-nginx composer install --optimize-autoloader --no-interaction
```

### Global Composer Commands
```bash
# Install global packages
docker run -v composer-cache:/.composer drzippie/php-nginx composer global require phpunit/phpunit

# List global packages
docker run -v composer-cache:/.composer drzippie/php-nginx composer global show
```

### With Persistent Cache
```bash
# Use named volume for persistent cache
docker run -v $(pwd):/var/www/html -v composer-cache:/.composer drzippie/php-nginx composer install
```

## Docker Compose Usage

### Basic Web Application with Composer
```yaml
version: '3.8'
services:
  web:
    image: drzippie/php-nginx
    ports:
      - "80:8080"
    volumes:
      - ./app:/var/www/html
      - composer-cache:/.composer
    command: >
      sh -c "composer install --optimize-autoloader --no-interaction &&
             /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"

volumes:
  composer-cache:
```

### Development Environment
```yaml
version: '3.8'
services:
  app:
    image: drzippie/php-nginx
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
      - composer-cache:/.composer
    environment:
      - COMPOSER_MEMORY_LIMIT=-1
    
volumes:
  composer-cache:
```

## Building with Composer

### Multi-stage Build (Recommended)
```Dockerfile
FROM composer AS composer

# Install dependencies
COPY composer.json composer.lock ./
RUN composer install --optimize-autoloader --no-interaction --no-progress --no-dev

# Copy source code
COPY . .

# Final stage
FROM drzippie/php-nginx:latest
COPY --chown=nobody --from=composer /app /var/www/html
```

### Single-stage Build
```Dockerfile
FROM drzippie/php-nginx:latest

# Switch to root to install dependencies
USER root

# Copy composer files
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --optimize-autoloader --no-interaction --no-progress --no-dev

# Copy application code
COPY --chown=nobody . .

# Switch back to nobody user
USER nobody
```

## Advanced Usage

### Custom Composer Configuration
```bash
# Mount custom composer configuration
docker run -v $(pwd):/var/www/html \
  -v $(pwd)/composer-config.json:/.composer/config.json \
  drzippie/php-nginx composer install
```

### Memory Limits
```bash
# Increase memory limit for large projects
docker run -e COMPOSER_MEMORY_LIMIT=-1 \
  -v $(pwd):/var/www/html \
  drzippie/php-nginx composer install
```

### Parallel Downloads
```bash
# Enable parallel downloads (faster installation)
docker run -v $(pwd):/var/www/html \
  drzippie/php-nginx composer install --prefer-dist --optimize-autoloader
```

## Troubleshooting

### Permission Issues
If you encounter permission issues, ensure your source code has proper permissions:
```bash
# Fix ownership of source files
sudo chown -R 65534:65534 /path/to/your/project
```

### Cache Issues
```bash
# Clear Composer cache
docker run -v composer-cache:/.composer drzippie/php-nginx composer clear-cache

# Remove cache volume entirely
docker volume rm composer-cache
```

### Memory Issues
```bash
# Increase PHP memory limit
docker run -e PHP_MEMORY_LIMIT=512M \
  -v $(pwd):/var/www/html \
  drzippie/php-nginx composer install
```

## Performance Tips

1. **Use named volumes** for `.composer` directory to persist cache across containers
2. **Enable ZIP extension** (included by default) for faster package extraction
3. **Use `--prefer-dist`** flag for faster downloads
4. **Optimize autoloader** with `--optimize-autoloader` flag
5. **Use `--no-dev`** in production builds to exclude development dependencies

## Security Considerations

- All Composer operations run as `nobody` user (UID 65534)
- Global Composer directory has restricted permissions
- No root privileges required for package installation
- Cache directory is isolated from application code
