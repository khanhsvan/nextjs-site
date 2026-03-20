# API Endpoint List

## Auth APIs

- `POST /auth/register`
  - Request: `email`, `password`, optional `name`, required `acceptedTosVersion`
  - Response: user summary, hashed-password placeholder in scaffold, email verification token, ToS acceptance timestamp
- `POST /auth/login`
  - Request: `email`, `password`
  - Response: user summary, access token, refresh token
- `POST /auth/logout`
  - Response: `{ success: true }`
- `POST /auth/refresh`
  - Request: `refreshToken`
  - Response: rotated access token and refresh token
- `GET /auth/verify-email?token=...`
  - Response: `{ verified: boolean }`

## User APIs

- `GET /users/me`
  - Response: current profile and subscription state
- `PATCH /users/me`
  - Request: editable profile fields
  - Response: updated profile

## Legal / Compliance APIs

- `GET /licenses/verify/:licenseId`
  - Response: authenticity flag and license details
- `GET /legal/terms`
  - Response: active ToS version
- `GET /legal/terms/versions`
  - Response: version history
- `GET /legal/copyright-policy`
  - Response: public copyright and takedown policy
- `POST /dmca-requests`
  - Request: reporter info, content URL, reason
  - Response: request status plus auto-disable marker for disputed content

## Video APIs

- `GET /video/:id`
  - Requires JWT
  - Response: secure playable URL for the main HLS manifest
- `GET /videos`
  - Query: optional `type=MOVIE|SERIES`
  - Response: catalog list with preview/access metadata
- `GET /videos/:slug`
  - Response: video detail plus episodes for series
- `GET /series/:seriesId/episodes`
  - Response: ordered episode list
- `GET /videos/:id/playback`
  - Response: `PlaybackAuthorizationResponse`
  - Behavior:
    - the NestJS API builds a protected playback URL from private storage metadata
    - returned manifest URLs include short-lived token query parameters
    - response includes a watermark string suitable for dynamic overlay
    - guest receives preview manifest for premium content
    - free logged-in user receives full access to free titles
    - subscriber receives full premium manifest

## Proxy Streaming APIs

- `GET /stream/:id`
  - Response: proxied default playlist
- `GET /stream/:id/*`
  - Response: proxied manifest, playlist, `.ts` segment, or MP4 object
  - Protection: requires `token` and `expires` query params validated per request
  - Streaming: forwards HTTP `Range` for partial-content playback

## Watch History APIs

- `POST /watch-history`
  - Request: `videoId`, optional `episodeId`, `progressSeconds`
  - Response: upsert confirmation and timestamp
- `GET /watch-history/continue`
  - Response: partially watched items for resume watching

## Subscription APIs

- `POST /subscriptions/checkout`
  - Response: Stripe Checkout URL
- `POST /subscriptions/portal`
  - Response: Stripe Billing Portal URL
- `GET /subscriptions/me`
  - Response: active subscription details

## Payment APIs

- `POST /payments/webhooks/stripe`
  - Request: raw Stripe webhook payload and signature header
  - Response: acknowledgement for webhook handling

## Admin APIs

- `GET /admin/licenses`
  - Response: license list with status, territory, validity, digital signature, and attachment target
- `POST /admin/licenses`
  - Request: license metadata and attached video ID
  - Response: created license with generated digital signature
- `GET /admin/compliance/overview`
  - Response: valid/expired license counts and DMCA review summary
- `GET /admin/access-logs`
  - Response: video access log entries with user ID, IP, and timestamp
- `GET /admin/dmca-requests`
  - Response: takedown request list
- `PATCH /admin/dmca-requests/:id/:status`
  - Response: updated request status
- `POST /admin/videos`
  - Request: metadata for movie or series container
  - Response: created video with `PENDING` processing status
- `POST /admin/videos/:id/upload-url`
  - Response: upload target metadata; in a private-storage deployment this should evolve into a storage-server ingest handoff
- `POST /admin/videos/:id/publish`
  - Response: publish confirmation
- `PATCH /admin/videos/:id`
  - Request: partial metadata update
  - Response: updated payload
- `DELETE /admin/videos/:id`
  - Response: deletion confirmation
- `POST /admin/episodes`
  - Request: episode metadata for a series
  - Response: created episode
- `GET /admin/users`
  - Response: user/admin list with subscription states
- `PATCH /admin/users/:id`
  - Request: role or account changes
  - Response: updated user record
- `GET /admin/analytics/overview`
  - Response: views, watch time, unique viewers, active subscribers, recent activity
