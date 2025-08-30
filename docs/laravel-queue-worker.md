# Laravel Queue Worker with Supervisor

This guide shows how to add a Laravel queue worker using supervisor's new multi-configuration support. With the updated supervisor configuration, you can easily add custom processes by mounting additional configuration files.

## Overview

The Docker image now supports loading multiple supervisor configuration files from `/etc/supervisor/conf.d/`. This allows you to add Laravel queue workers, scheduled tasks, or any other background processes without modifying the base image.

## Creating a Laravel Queue Worker Configuration

### 1. Create the Supervisor Configuration

Create a file named `laravel-queue.conf`:

```ini
[program:laravel-queue]
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
stopwaitsecs=10
```

### 2. Advanced Queue Worker Configuration

For production environments, you might want a more robust configuration:

```ini
[program:laravel-queue]
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600 --queue=default,emails,processing
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
stopwaitsecs=10
startsecs=1
startretries=3
numprocs=2
process_name=%(program_name)s_%(process_num)02d
```

This configuration:
- Runs 2 queue worker processes (`numprocs=2`)
- Handles multiple queues: `default`, `emails`, `processing`
- Automatically restarts failed processes
- Gives each process 10 seconds to gracefully shutdown
- Names processes with unique identifiers

### 3. Environment-Specific Configuration

For different environments, you can create specific configurations:

**laravel-queue-production.conf:**
```ini
[program:laravel-queue-high]
command=php /var/www/html/artisan queue:work --sleep=1 --tries=3 --max-time=3600 --queue=high
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
numprocs=3
priority=999

[program:laravel-queue-default]
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600 --queue=default
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
numprocs=2
priority=900

[program:laravel-queue-low]
command=php /var/www/html/artisan queue:work --sleep=5 --tries=1 --max-time=1800 --queue=low
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
numprocs=1
priority=800
```

## Docker Deployment

### Using Docker Run

Mount your queue worker configuration:

```bash
docker run -d \
  --name laravel-app \
  -p 80:8080 \
  -v /path/to/your/laravel:/var/www/html \
  -v /path/to/laravel-queue.conf:/etc/supervisor/conf.d/laravel-queue.conf \
  drzippie/php-nginx
```

### Using Docker Compose

Create a `docker-compose.yml`:

```yaml
services:
  app:
    image: drzippie/php-nginx
    ports:
      - "80:8080"
    volumes:
      - ./laravel-app:/var/www/html
      - ./config/laravel-queue.conf:/etc/supervisor/conf.d/laravel-queue.conf
    environment:
      - APP_ENV=production
      - QUEUE_CONNECTION=redis
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  database:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

### Using Docker Compose Override

For development, use `docker-compose.override.yml`:

```yaml
services:
  app:
    volumes:
      - ./config/laravel-queue-dev.conf:/etc/supervisor/conf.d/laravel-queue.conf
    environment:
      - APP_ENV=local
      - APP_DEBUG=true
```

## Laravel Configuration

### Queue Configuration

Ensure your Laravel `.env` file is configured for queues:

```env
QUEUE_CONNECTION=redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_DB=0
```

### Job Example

Create a simple job for testing:

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ProcessEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $timeout = 120;

    public function __construct(
        public string $email,
        public string $subject,
        public string $message
    ) {
        $this->onQueue('emails');
    }

    public function handle(): void
    {
        Log::info('Processing email job', [
            'email' => $this->email,
            'subject' => $this->subject,
        ]);

        // Simulate email processing
        sleep(2);

        Log::info('Email processed successfully');
    }
}
```

## Monitoring and Management

### View Running Processes

Check supervisor status inside the container:

```bash
docker exec -it your-container-name supervisorctl status
```

### Control Queue Workers

```bash
# Restart all queue workers
docker exec -it your-container-name supervisorctl restart laravel-queue:*

# Stop queue workers
docker exec -it your-container-name supervisorctl stop laravel-queue:*

# Start queue workers
docker exec -it your-container-name supervisorctl start laravel-queue:*

# View logs
docker logs your-container-name
```

### Health Checks

Add a health check to your Docker Compose:

```yaml
services:
  app:
    # ... other config
    healthcheck:
      test: ["CMD", "supervisorctl", "status", "laravel-queue"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Troubleshooting

### Common Issues

1. **Permission Issues**: Ensure the queue worker runs as `nobody` user
2. **Database Connections**: Make sure Laravel can connect to the database from the queue worker
3. **Memory Limits**: Monitor memory usage, restart workers periodically using `--max-time`
4. **Failed Jobs**: Check the `failed_jobs` table in your database

### Debug Configuration

For debugging, create a verbose queue configuration:

```ini
[program:laravel-queue-debug]
command=php /var/www/html/artisan queue:work --sleep=1 --tries=1 --verbose
directory=/var/www/html
user=nobody
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
```

### Log Analysis

View queue worker logs:

```bash
# Follow logs in real-time
docker logs -f your-container-name

# Filter for queue-related logs
docker logs your-container-name 2>&1 | grep "laravel-queue"
```

## Best Practices

1. **Resource Management**: Use `--max-time` and `--max-jobs` to prevent memory leaks
2. **Queue Separation**: Use different queues for different job types
3. **Process Scaling**: Adjust `numprocs` based on your application needs
4. **Graceful Shutdown**: Always set appropriate `stopwaitsecs` values
5. **Monitoring**: Implement proper logging and monitoring for queue health
6. **Error Handling**: Configure proper retry mechanisms and failed job handling

## Related Configuration

- [Redis Support](redis-support.md) - For Redis-based queues
- [Swoole Support](swoole-support.md) - For high-performance async processing
- [Composer Support](composer-support.md) - For Laravel dependency management