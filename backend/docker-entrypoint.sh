#!/bin/sh
set -e
cd /app

# 1) .env + مفتاح التطبيق
[ -f .env ] || cp .env.example .env

# 2) تركيب التبعيات (الـ chat package متاح على /chatPackageV2/backend عبر الـ mount)
if [ ! -d vendor ] || [ ! -f vendor/autoload.php ]; then
    echo "[entrypoint] composer install…"
    composer install --no-interaction --prefer-dist --no-progress
fi

php artisan key:generate --force --no-interaction >/dev/null 2>&1 || true

# 3) انتظار قاعدة البيانات (compose: خدمة db)
echo "[entrypoint] waiting for database…"
tries=0
until php artisan migrate --force >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 30 ]; then
        echo "[entrypoint] DB not ready after 30 tries — continuing anyway."
        break
    fi
    sleep 2
done

php artisan config:clear >/dev/null 2>&1 || true

case "$1" in
    serve|"")
        echo "[entrypoint] serving on 0.0.0.0:8080"
        exec php artisan serve --host=0.0.0.0 --port=8080
        ;;
    *)
        exec "$@"
        ;;
esac
