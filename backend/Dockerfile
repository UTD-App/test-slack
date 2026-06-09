# UTD Base Project — Laravel API (يخدم الـ Stac + الـ manifest للـ UTD Studio).
#
# الـ chat package متربط كـ path repo (../../chatPackageV2/backend). علشان كده
# الـ build context هنا = الـ backend بس (صغير)، والـ package بيتـ mount وقت التشغيل
# عبر docker-compose، والـ composer install بيتعمل في الـ entrypoint (لما الـ package
# يكون متاح على /chatPackageV2/backend). راجع: utdStack/docs/default-screens-sync/SPEC-03.
FROM php:8.2-cli

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip libzip-dev libonig-dev default-mysql-client \
    && docker-php-ext-install pdo_mysql mbstring bcmath zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# كود الـ base فقط (الـ vendor بيتركّب في الـ entrypoint بعد ما الـ chat package يتـ mount)
COPY . /app

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["serve"]
