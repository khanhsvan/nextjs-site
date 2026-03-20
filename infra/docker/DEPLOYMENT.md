# Deployment Guide

## Local Docker Setup

1. Copy values from the root `.env.example` into a real `.env`.
2. Set `STORAGE_BASE_URL` to your private storage server, such as `http://storage.internal:8080`.
3. Set `STORAGE_AUTH_TYPE`, `STORAGE_SECRET`, and `STORAGE_PROXY_MODE` based on how your storage provider authenticates requests.
4. Ensure the storage server contains HLS files such as `/videos/movie1/index.m3u8` and segment files.
5. Run `docker compose -f infra/docker/docker-compose.yml up --build`.
6. Open the web app at `http://localhost:3000`, the API at `http://localhost:4000`, and MailHog at `http://localhost:8025`.

## Required Services

- PostgreSQL for application data
- Redis for BullMQ queues
- A private web storage server reachable by fixed IP or internal hostname
- HLS assets stored as `.m3u8` playlists and `.ts` segments
- Stripe for subscriptions and webhook callbacks
- SMTP-compatible provider for email verification

## Production Notes

- Put the web and API behind a reverse proxy or load balancer.
- Run the worker as a separate long-running process so FFmpeg jobs do not compete with API latency.
- The main NestJS API should issue short-lived playable URLs through `/video/:id`.
- Use `/stream/:id` proxy mode when the storage provider cannot validate your token format natively.
- Forward HTTP `Range` headers in proxy mode for MP4 and large segment compatibility.
- Keep legal pages publicly accessible even if the main catalog or admin pages require auth.
- Point Stripe webhooks to `/payments/webhooks/stripe` and verify with `STRIPE_WEBHOOK_SECRET`.
- Avoid exposing raw storage URLs unless your private storage server supports native token validation.
- Persist Docker volumes or move PostgreSQL/Redis to managed services when you leave local or single-VPS deployment.

## Recommended Environment Variables

- `DATABASE_URL`
- `REDIS_HOST` and `REDIS_PORT`
- `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET`
- `STORAGE_BASE_URL`
- `STORAGE_AUTH_TYPE`
- `STORAGE_SECRET`
- `STORAGE_PROXY_MODE`
- `STORAGE_TOKEN_TTL_SECONDS`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`

## Scale-Out Path

- Split API and worker into separate deployment units.
- Switch to direct signed storage URLs only if your storage provider can validate tokens without the app proxy.
- Move from local Docker PostgreSQL/Redis to managed equivalents.
- Add retention and cleanup rules on the private storage server for stale source uploads and failed transcode artifacts.
