# WordPress Support

This Docker image provides excellent support for WordPress with all necessary PHP extensions, optimized Nginx configuration, and modern development tools.

## What's Included for WordPress

- **PHP 8.4**: Latest PHP version with excellent WordPress performance
- **Essential PHP Extensions**: All WordPress requirements included
  - `gd` - Image processing and thumbnails
  - `mysqli` & `pdo_mysql` - MySQL database connectivity
  - `zip` - Plugin and theme installation
  - `mbstring` - String handling for internationalization
  - `xml` & `simplexml` - XML processing
  - `curl` - HTTP requests and API calls
  - `openssl` - HTTPS and security
  - `session` - User session management
  - `fileinfo` - File type detection
- **ImageMagick**: Advanced image processing for WordPress media
- **Composer**: Modern PHP dependency management
- **Optimized Nginx**: Pre-configured for WordPress permalinks

## Quick Start

### Basic WordPress Setup

```bash
# Create network
docker network create wordpress-net

# Start MySQL database
docker run -d \
  --name wordpress-db \
  --network wordpress-net \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wppass \
  -v mysql-data:/var/lib/mysql \
  mysql:8.0

# Start WordPress
docker run -d \
  --name wordpress \
  --network wordpress-net \
  -p 80:8080 \
  -v wordpress-files:/var/www/html \
  -e WORDPRESS_DB_HOST=wordpress-db \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  drzippie/php-nginx
```

### Download and Setup WordPress

```bash
# Download WordPress
docker exec wordpress wget https://wordpress.org/latest.tar.gz
docker exec wordpress tar -xzf latest.tar.gz --strip-components=1
docker exec wordpress rm latest.tar.gz

# Set proper permissions
docker exec wordpress chown -R nobody:nobody /var/www/html
```

## Docker Compose Setup

### Complete WordPress Stack

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - wordpress-net

  wordpress:
    image: drzippie/php-nginx:latest
    ports:
      - "80:8080"
    volumes:
      - wordpress_files:/var/www/html
      - ./wp-content:/var/www/html/wp-content
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
    depends_on:
      - db
    networks:
      - wordpress-net

volumes:
  mysql_data:
  wordpress_files:

networks:
  wordpress-net:
```

### WordPress Development Environment

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - wordpress-net

  wordpress:
    image: drzippie/php-nginx:latest
    ports:
      - "80:8080"
    volumes:
      - ./wordpress:/var/www/html
      - composer-cache:/.composer
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
      PHP_MEMORY_LIMIT: 512M
      WP_DEBUG: 1
      WP_DEBUG_LOG: 1
    depends_on:
      - db
    networks:
      - wordpress-net

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    ports:
      - "8080:80"
    environment:
      PMA_HOST: db
      PMA_USER: wpuser
      PMA_PASSWORD: wppassword
    depends_on:
      - db
    networks:
      - wordpress-net

volumes:
  mysql_data:
  composer-cache:

networks:
  wordpress-net:
```

## WordPress Configuration

### wp-config.php Setup

Create `wp-config.php` with environment variables:

```php
<?php
// Database settings
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD'));
define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Security keys (generate at https://api.wordpress.org/secret-key/1.1/salt/)
define('AUTH_KEY',         'your-auth-key-here');
define('SECURE_AUTH_KEY',  'your-secure-auth-key-here');
define('LOGGED_IN_KEY',    'your-logged-in-key-here');
define('NONCE_KEY',        'your-nonce-key-here');
define('AUTH_SALT',        'your-auth-salt-here');
define('SECURE_AUTH_SALT', 'your-secure-auth-salt-here');
define('LOGGED_IN_SALT',   'your-logged-in-salt-here');
define('NONCE_SALT',       'your-nonce-salt-here');

// WordPress debugging (for development)
define('WP_DEBUG', getenv('WP_DEBUG') === '1');
define('WP_DEBUG_LOG', getenv('WP_DEBUG_LOG') === '1');
define('WP_DEBUG_DISPLAY', false);

// WordPress table prefix
$table_prefix = 'wp_';

// Absolute path to WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
?>
```

### Custom PHP Configuration

Create `custom-php.ini` for WordPress optimization:

```ini
; WordPress optimizations
memory_limit = 512M
max_execution_time = 300
max_input_vars = 3000
upload_max_filesize = 64M
post_max_size = 64M
max_file_uploads = 20

; Session configuration
session.save_handler = files
session.save_path = /tmp

; OPcache optimizations for WordPress
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
```

Mount this configuration:
```bash
docker run -v $(pwd)/custom-php.ini:/etc/php84/conf.d/wordpress.ini drzippie/php-nginx
```

## WordPress-Optimized Nginx Configuration

Create `wordpress-nginx.conf`:

```nginx
server {
    listen [::]:8080 default_server;
    listen 8080 default_server;
    server_name _;

    root /var/www/html;
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # WordPress permalink handling
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    # WordPress admin and login protection
    location ~ ^/(wp-admin|wp-login\.php) {
        # Rate limiting for admin pages
        limit_req zone=login burst=5 nodelay;
        
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/run/php-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
            include fastcgi_params;
            
            # Increased timeouts for admin operations
            fastcgi_read_timeout 300;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
        }
    }

    # PHP file handling
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    # WordPress uploads and content caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|zip)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Deny access to sensitive WordPress files
    location ~* /(?:uploads|files)/.*\.php$ {
        deny all;
    }

    location ~* /(?:wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt)$ {
        deny all;
    }

    # WordPress XML-RPC protection
    location = /xmlrpc.php {
        limit_req zone=xmlrpc burst=5 nodelay;
        
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_pass unix:/run/php-fpm.sock;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # WordPress specific denials
    location ~* /(?:\.htaccess|\.htpasswd|\.user\.ini|\.git|\.hg|\.bzr|\.svn) {
        deny all;
    }

    # Health check endpoints
    location ~ ^/(fmp-status|fmp-ping)$ {
        access_log off;
        allow 127.0.0.1;
        deny all;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm.sock;
    }
}

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=xmlrpc:10m rate=1r/m;
```

## WordPress with Composer

### Modern WordPress Development

Create `composer.json` for WordPress development:

```json
{
    "name": "my-wordpress-project",
    "description": "WordPress project with Composer",
    "type": "project",
    "repositories": [
        {
            "type": "composer",
            "url": "https://wpackagist.org"
        }
    ],
    "require": {
        "php": ">=8.0",
        "johnpbloch/wordpress-core": "^6.0",
        "wpackagist-plugin/akismet": "^5.0",
        "wpackagist-theme/twentytwentythree": "*"
    },
    "require-dev": {
        "squizlabs/php_codesniffer": "^3.7",
        "phpunit/phpunit": "^9.0"
    },
    "extra": {
        "wordpress-install-dir": "wp",
        "installer-paths": {
            "wp-content/plugins/{$name}/": ["type:wordpress-plugin"],
            "wp-content/themes/{$name}/": ["type:wordpress-theme"],
            "wp-content/mu-plugins/{$name}/": ["type:wordpress-muplug"]
        }
    },
    "scripts": {
        "post-install-cmd": [
            "php -r \"copy('wp/wp-config-sample.php', 'wp-config.php');\""
        ]
    }
}
```

### Docker Compose for Composer WordPress

```yaml
version: '3.8'

services:
  composer:
    image: drzippie/php-nginx:latest
    working_dir: /app
    volumes:
      - ./:/app
      - composer-cache:/.composer
    command: composer install --optimize-autoloader
    user: "1000:1000"

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
    volumes:
      - mysql_data:/var/lib/mysql

  wordpress:
    image: drzippie/php-nginx:latest
    ports:
      - "80:8080"
    volumes:
      - ./:/var/www/html
      - composer-cache:/.composer
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
    depends_on:
      - db
      - composer

volumes:
  mysql_data:
  composer-cache:
```

## WordPress Multisite

### Nginx Configuration for Multisite

For WordPress multisite with subdirectories:

```nginx
# WordPress multisite subdirectory configuration
location ~ ^(/[^/]+)?(/wp-.*) {
    try_files $uri $uri/ /index.php$is_args$args;
}

location ~ ^(/[^/]+)?(/.*\.php)$ {
    try_files $uri $uri/ /index.php$is_args$args;
}

# Multisite files handling
location ~* ^/(?<blog>[^/]+/)?files/(.*)$ {
    try_files /wp-content/blogs.dir/$blog$uri /wp-includes/ms-files.php?file=$2 ;
    access_log off;
    log_not_found off;
    expires max;
}
```

### Multisite wp-config.php

```php
// Multisite configuration
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', false); // Set to true for subdomains
define('DOMAIN_CURRENT_SITE', 'example.com');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
```

## Performance Optimization

### Redis Caching

Add Redis to your WordPress setup:

```yaml
services:
  redis:
    image: redis:7-alpine
    networks:
      - wordpress-net

  wordpress:
    # ... other configuration
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
```

Install Redis Object Cache plugin and configure:

```php
// wp-config.php
define('WP_REDIS_HOST', getenv('REDIS_HOST'));
define('WP_REDIS_PORT', getenv('REDIS_PORT'));
define('WP_CACHE', true);
```

### OPcache Configuration

Create `opcache.ini`:

```ini
; OPcache settings for WordPress
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.save_comments=1
opcache.fast_shutdown=1
```

## Security Best Practices

### File Permissions

```bash
# Set proper WordPress file permissions
docker exec wordpress find /var/www/html -type d -exec chmod 755 {} \;
docker exec wordpress find /var/www/html -type f -exec chmod 644 {} \;
docker exec wordpress chmod 600 /var/www/html/wp-config.php
```

### Security Headers

Add security headers to Nginx configuration:

```nginx
# Security headers for WordPress
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### WordPress Security Configuration

```php
// wp-config.php security settings
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);
define('FORCE_SSL_ADMIN', true);
define('WP_AUTO_UPDATE_CORE', true);

// Limit login attempts
define('WP_LOGIN_ATTEMPTS', 3);
define('WP_LOGIN_LOCK_TIME', 900); // 15 minutes
```

## SSL/HTTPS Setup

### Let's Encrypt with Certbot

```yaml
version: '3.8'

services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt

  certbot:
    image: certbot/certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
    command: certonly --webroot --webroot-path=/var/www/html --email your@email.com --agree-tos --no-eff-email -d your-domain.com

  wordpress:
    image: drzippie/php-nginx:latest
    # ... rest of configuration

volumes:
  certbot-etc:
  certbot-var:
```

## Troubleshooting

### Common Issues

**Memory Limit Errors**
```bash
# Increase PHP memory limit
docker run -e PHP_MEMORY_LIMIT=512M drzippie/php-nginx
```

**File Upload Issues**
```bash
# Check upload limits
docker exec wordpress php -i | grep -E 'upload_max_filesize|post_max_size|max_execution_time'
```

**Database Connection Errors**
```bash
# Test database connectivity
docker exec wordpress php -r "
\$link = mysqli_connect('db', 'wpuser', 'wppass', 'wordpress');
if (!\$link) {
    echo 'Connection failed: ' . mysqli_connect_error();
} else {
    echo 'Connected successfully';
    mysqli_close(\$link);
}
"
```

**Permalink Issues**
- Ensure Nginx configuration includes WordPress-friendly rewrites
- Check that `.htaccess` rules are converted to Nginx format

### Debug Mode

Enable WordPress debugging:

```php
// wp-config.php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
```

Check logs:
```bash
docker exec wordpress tail -f /var/www/html/wp-content/debug.log
```

## Backup and Maintenance

### Database Backup

```bash
# Backup WordPress database
docker exec wordpress-db mysqldump -u wpuser -p wordpress > backup.sql

# Restore database
docker exec -i wordpress-db mysql -u wpuser -p wordpress < backup.sql
```

### File Backup

```bash
# Backup WordPress files
docker run --rm -v wordpress_files:/source -v $(pwd)/backup:/backup alpine tar czf /backup/wordpress-backup.tar.gz -C /source .

# Restore files
docker run --rm -v wordpress_files:/target -v $(pwd)/backup:/backup alpine tar xzf /backup/wordpress-backup.tar.gz -C /target
```

This comprehensive guide covers everything needed to run WordPress successfully with this Docker image, from basic setup to advanced configurations for production use.