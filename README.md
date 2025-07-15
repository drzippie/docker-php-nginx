# Docker PHP-FPM 8.4 & Nginx 1.26 on Alpine Linux
PHP-FPM 8.4 & Nginx 1.26 container image for Docker, built on [Alpine Linux](https://www.alpinelinux.org/) with Swoole support.

Repository: https://github.com/drzippie/docker-php-nginx  
Original repository: https://github.com/TrafeX/docker-php-nginx


* Built on the lightweight and secure Alpine Linux distribution
* Multi-platform, supporting AMD64, ARMv6, ARMv7, ARM64
* Very small Docker image size (+/-40MB)
* Uses PHP 8.4 for the best performance, low CPU usage & memory footprint
* **Includes Swoole 6.0.2** for high-performance async/coroutine applications
* **Includes ImageMagick** with PHP Imagick extension for advanced image manipulation
* **Complete Composer Support** with ZIP extension, writable directories, and global commands
* Optimized for 100 concurrent users
* Optimized to only use resources when there's traffic (by using PHP-FPM's `on-demand` process manager)
* The services Nginx, PHP-FPM and supervisord run under a non-privileged user (nobody) to make it more secure
* The logs of all the services are redirected to the output of the Docker container (visible with `docker logs -f <container name>`)
* Follows the KISS principle (Keep It Simple, Stupid) to make it easy to understand and adjust the image to your needs

[![Docker Pulls](https://img.shields.io/docker/pulls/drzippie/php-nginx.svg)](https://hub.docker.com/r/drzippie/php-nginx/)
![nginx 1.26](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)
![php 8.4](https://img.shields.io/badge/php-8.4-brightgreen.svg)
![swoole 6.0.2](https://img.shields.io/badge/swoole-6.0.2-blue.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

## About this fork
This repository is a fork of [TrafeX/docker-php-nginx](https://github.com/TrafeX/docker-php-nginx) with the following enhancements:

* **Swoole Integration**: Added Swoole 6.0.2 for high-performance async/coroutine applications
* **ImageMagick Support**: Added ImageMagick with PHP Imagick extension for image manipulation
* **Complete Composer Support**: Full Composer functionality with ZIP extension and writable directories
* **Enhanced Documentation**: Comprehensive guides for Swoole, ImageMagick, Composer, and deployment
* **Manual Deployment**: Streamlined build process without CI/CD automation
* **Production Focus**: Optimized for production deployment with clear versioning

## Goal of this project
The goal of this container image is to provide a production-ready Nginx and PHP-FPM container with Swoole support that follows
the best practices and is easy to understand and modify to your needs.

## Usage

Start the Docker container:

    docker run -p 80:8080 drzippie/php-nginx

See the PHP info on http://localhost, or the static html page on http://localhost/test.html

Or mount your own code to be served by PHP-FPM & Nginx

    docker run -p 80:8080 -v ~/my-codebase:/var/www/html drzippie/php-nginx

## Versioning
Major or minor changes are published as releases with corresponding changelogs.
The `latest` tag and dated tags are updated manually to include the latest patches from Alpine Linux.

## Configuration
In [config/](config/) you'll find the default configuration files for Nginx, PHP and PHP-FPM.
If you want to extend or customize that you can do so by mounting a configuration file in the correct folder;

Nginx configuration:

    docker run -v "`pwd`/nginx-server.conf:/etc/nginx/conf.d/server.conf" drzippie/php-nginx

PHP configuration:

    docker run -v "`pwd`/php-setting.ini:/etc/php84/conf.d/settings.ini" drzippie/php-nginx

PHP-FPM configuration:

    docker run -v "`pwd`/php-fpm-settings.conf:/etc/php84/php-fpm.d/server.conf" drzippie/php-nginx

_Note; Because `-v` requires an absolute path I've added `pwd` in the example to return the absolute path to the current directory_

## Documentation and examples
To modify this container to your specific needs please see the following examples;

* [Composer support](docs/composer-support.md)
* [ImageMagick support](docs/imagemagick-support.md)
* [Swoole support](docs/swoole-support.md)
* [Adding xdebug support](docs/xdebug-support.md)
* [Getting the real IP of the client behind a load balancer](docs/real-ip-behind-loadbalancer.md)
* [Sending e-mails](docs/sending-emails.md)
* [Enabling HTTPS/SSL](docs/enable-https.md)