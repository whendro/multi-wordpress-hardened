FROM wordpress:6.7-php8.3-fpm-alpine

RUN apk add --no-cache shadow bash && rm -rf /var/cache/apk/*

# Ensure www-data is uid/gid 1000
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Hardened PHP config
COPY php/hardened.ini /usr/local/etc/php/conf.d/99-hardened.ini
COPY php/www.conf     /usr/local/etc/php-fpm.d/www.conf

# Strict permissions on WP core
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chown -R www-data:www-data /var/www/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php-fpm -t || exit 1

USER www-data
EXPOSE 9000
