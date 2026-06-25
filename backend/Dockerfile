# Production image for the Laravel API (php-fpm). Build context = backend/
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
# ext-gd is only needed at runtime (app stage installs it); the composer image
# lacks it, so ignore the platform req here for phpspreadsheet.
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction \
    --ignore-platform-req=ext-gd
COPY . .
# Drop any stale package cache (a dev-built packages.php would reference
# dev-only providers like Laravel\Pail and break --no-dev discovery).
RUN rm -f bootstrap/cache/*.php \
    && composer dump-autoload --optimize --no-dev

FROM php:8.3-fpm-alpine AS app
RUN apk add --no-cache libpng-dev libzip-dev oniguruma-dev icu-dev $PHPIZE_DEPS \
    && docker-php-ext-install pdo_mysql gd zip bcmath pcntl intl \
    && pecl install redis && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS
WORKDIR /var/www/html
# Let php-fpm workers inherit container env (compose env_file) so Laravel reads
# DB/Redis/Reverb config without a mounted .env file.
RUN echo "clear_env = no" >> /usr/local/etc/php-fpm.d/www.conf
# Raise PHP upload limits to 250 MB for task attachments.
COPY docker/php-upload.ini /usr/local/etc/php/conf.d/zz-upload.ini
COPY --from=vendor /app /var/www/html
RUN chown -R www-data:www-data storage bootstrap/cache \
    && php artisan storage:link || true
USER www-data
EXPOSE 9000
CMD ["php-fpm"]
