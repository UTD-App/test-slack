#!/bin/bash

# UTD App — Backend Deployment Script
# Usage: bash deploy.sh [--seed]

set -e

echo "🚀 UTD App Deployment Starting..."

# Pull latest code
echo "📥 Pulling latest from GitHub..."
git pull origin main

# Install/update dependencies
echo "📦 Installing composer dependencies..."
composer install --no-interaction --optimize-autoloader --no-dev

# Clear caches
echo "🧹 Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Run migrations
echo "🗄️ Running migrations..."
php artisan migrate --force

# Seed languages if --seed flag passed
if [[ "$1" == "--seed" ]]; then
    echo "🌱 Seeding languages and translations..."
    php artisan db:seed --class=LanguageSeeder --force
fi

# Optimize for production
echo "⚡ Optimizing..."
php artisan config:cache
php artisan route:cache

# Fix permissions
echo "🔒 Fixing permissions..."
chmod -R 755 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Publish Filament assets
echo "🎨 Publishing assets..."
php artisan filament:assets 2>/dev/null || true

echo "✅ Deployment complete!"
