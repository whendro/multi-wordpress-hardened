FROM wordpress:6.7-php8.3-fpm-alpine

RUN apk add --no-cache shadow bash && rm -rf /var/cache/apk/*

# Ensure www-data is uid/gid 1000 (matches typical host uid for bind mounts)
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Hardened PHP config
# Build context is multi-wordpress-hardened/_template/ — php/ dir lives alongside this Dockerfile
COPY php/hardened.ini /usr/local/etc/php/conf.d/99-hardened.ini
COPY php/www.conf     /usr/local/etc/php-fpm.d/www.conf

# Replace the base image's www.conf entirely (it sets clear_env=yes with broken env[] lines)
RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf

# Strict permissions on WP core (image defaults — site wp_data is a bind mount at runtime)
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chown -R www-data:www-data /var/www/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD php-fpm -t 2>&1 | grep -q "test is successful" || exit 1

# Do NOT set USER here — the WordPress entrypoint runs as root then drops to www-data
# USER www-data
EXPOSE 9000
