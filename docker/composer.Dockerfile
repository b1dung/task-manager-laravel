# Composer CLI on the project's exact PHP 8.3 + extensions.
# Avoids platform-req errors (ext-gd, ext-intl, …) that the bare composer image hits.
# Build:  docker build -t crm-composer:latest - < docker/composer.Dockerfile
FROM crm-comcom-laravel-app:latest
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENTRYPOINT ["composer"]
