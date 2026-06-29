# project-x server setup (queue worker + scheduler)

The GitHub Actions deploy (`.github/workflows/deploy.yml`) ships code, runs
migrations, caches config/routes/views, reloads php-fpm/nginx, restarts queue
workers, and health-checks `/api/health`. Two pieces of **server-side**
infrastructure must be installed ONCE (they are not provisioned by CI):

## 1. Queue worker (supervisor)

Without a running worker, every queued job (notifications, push, AI translation,
reel video processing) silently never runs when `QUEUE_CONNECTION` is
`redis`/`database`.

```bash
sudo apt-get install -y supervisor
sudo cp deploy/supervisor/project-x-worker.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start project-x-worker:*
```

The deploy's `php artisan queue:restart` step then makes workers pick up new code
on every release.

## 2. Scheduler (cron)

Without this, the monthly financial rollover (`monthly_update`) and the daily
prune jobs never fire.

```bash
sudo cp deploy/cron/project-x-scheduler /etc/cron.d/project-x-scheduler
sudo chmod 644 /etc/cron.d/project-x-scheduler
```

## 3. Required env

Ensure the production `.env` follows `backend/.env.production.example`:
`QUEUE_CONNECTION=redis` (or `database`), `CACHE_DRIVER=redis`,
`SESSION_DRIVER=redis`, `APP_DEBUG=false`, `APP_ENV=production`. With a
multi-server setup the scheduler's `onOneServer` lock needs a shared cache
(redis), otherwise the monthly rollover can apply more than once.

## Verify

```bash
sudo supervisorctl status              # workers RUNNING
php artisan schedule:list              # tasks listed with next-due times
curl -i http://localhost/api/health    # 200 when DB reachable, 503 otherwise
php artisan queue:failed               # inspect any failed jobs
```
