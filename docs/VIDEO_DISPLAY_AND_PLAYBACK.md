# Video Display And Playback Process

This document explains how the platform shows videos in the catalog and how playback works from the database all the way to the player.

## 1. How Videos Appear On The Website

When a user opens the homepage or a detail page, the frontend asks the backend API for video data.

Main flow:

1. The frontend calls:
   - `GET /videos`
   - `GET /videos/:slug`
   - `GET /series/:seriesId/episodes`
2. The backend checks PostgreSQL first.
3. If PostgreSQL has real video rows, the real data is returned.
4. If PostgreSQL is empty or unavailable, the system falls back to demo data.

This means:

- Real data is shown first whenever it exists.
- Demo movie and demo series are only used as a fallback for testing.

## 2. Where Video Data Comes From

The catalog data is mainly loaded from:

- `videos`
- `video_assets`
- `episodes`

Important fields:

- `videos.slug`: used for detail page URLs
- `videos.title`: display title
- `videos.description`: description text
- `videos.type`: `MOVIE` or `SERIES`
- `videos.access_tier`: `FREE` or `PREMIUM`
- `video_assets.master_playlist_path`: main storage path
- `video_assets.preview_playlist_path`: preview storage path

For a movie:

- one main video record is enough

For a series:

- one main video record represents the series
- `episodes` contains each episode entry

## 3. Demo Fallback Behavior

If the platform cannot load real catalog data from PostgreSQL, it shows built-in demo titles:

- Demo movie
- Demo series

These are useful for checking:

- homepage display
- detail page layout
- player rendering
- episode list UI
- playback flow

If real DB data exists, the platform should display the real data instead.

## 4. How Admin Upload Works

The admin upload flow is now backend-assisted.

Current process:

1. Admin opens the upload page.
2. Admin enters metadata:
   - title
   - description
   - type
   - access level
   - thumbnail
   - visibility
3. Frontend calls:
   - `POST /admin/videos`
4. Backend creates the video record in PostgreSQL.
5. Frontend uploads the selected file to:
   - `POST /admin/videos/:id/upload`
6. Backend receives the file.
7. Backend uploads the file into MinIO.
8. Backend updates `video_assets` with the MinIO object path.
9. Frontend calls:
   - `POST /admin/videos/:id/publish`
10. Backend marks the video as published/ready.

Important note:

- The browser no longer uploads directly to storage.
- The backend handles MinIO upload securely.

## 5. How Storage Works

Storage is private.

The system uses:

- MinIO as object storage
- backend proxy streaming

Objects should remain private inside MinIO.

The application stores object paths such as:

- `videos/library/<videoId>/source.mp4`
- or HLS paths like:
  - `videos/library/<videoId>/master.m3u8`
  - `videos/library/<videoId>/segment001.ts`

The first path segment is treated as the MinIO bucket name.

Example:

- bucket: `videos`
- object key: `library/abc123/source.mp4`

Combined stored path:

- `videos/library/abc123/source.mp4`

## 6. How Playback Works

The player does not receive a public MinIO URL.

Current playback flow:

1. User opens the watch page.
2. Frontend calls:
   - `GET /videos/:id/playback`
3. Backend checks:
   - login state
   - role
   - subscription
   - visibility
   - restriction rules
   - compliance review status
4. Backend returns a backend playback URL such as:
   - `/stream/:id?mode=master`
   - or preview mode when required
5. The player loads that backend URL.
6. Backend reads the real object from MinIO and streams it to the browser.

This means:

- MinIO URLs are not exposed to clients
- playback stays under backend control
- access can remain long term without presigned URL expiry

## 7. Proxy Streaming

The backend streaming layer is responsible for:

- authentication
- authorization
- private storage access
- HTTP range support
- HLS playlist rewriting

Main endpoints:

- `GET /video/:id`
- `GET /stream/:id`
- `GET /stream/:id/*`

### For MP4

The backend:

- reads the `Range` header
- requests the correct byte range from MinIO
- returns:
  - `206 Partial Content`
  - `Content-Range`
  - `Content-Length`
  - `Accept-Ranges: bytes`

This allows:

- seek
- pause/resume
- large file streaming without loading the whole file into memory

### For HLS

The backend:

1. serves the `.m3u8` file
2. rewrites segment URLs so they point back to backend `/stream/...`
3. serves `.ts` or other segment files through the backend as well

This keeps all HLS access private and controlled.

## 8. Episode Display For Series

Series pages now support episode selection.

How it works:

1. Detail page loads the series record
2. Backend returns `episodes`
3. Frontend shows an episode list
4. Watch page also shows an episode panel on the right side

Current note:

- The UI supports episode selection
- true per-episode playback depends on storing separate media files for each episode
- if multiple episodes still point to the same media path, they will look different in UI but play the same source

## 9. Access Rules Before Playback

Before a video is streamed, the backend may block playback for reasons such as:

- not logged in
- account banned
- premium content without subscription
- private video
- restricted content
- region restrictions
- verification requirement
- content under compliance review

So playback security is enforced on the backend, not only in the UI.

## 10. Demo Testing Checklist

Use this checklist to confirm the system is working:

1. Open homepage
2. Confirm:
   - real videos appear if DB has data
   - demo videos appear only when DB is empty/unavailable
3. Open a movie detail page
4. Open a series detail page
5. Confirm episode list is visible for series
6. Open watch page
7. Confirm player loads
8. Try seeking inside the player
9. Confirm admin upload creates a new DB record
10. Confirm uploaded file is stored in MinIO

## 11. Recommended Production Setup

For best production behavior:

- use HLS for long videos
- store each series episode as separate media assets
- keep MinIO buckets private
- keep `STORAGE_PROXY_MODE=true`
- use backend authentication for all playback
- optionally add Nginx in front of the API for high-volume proxy streaming

## 12. Main Files Involved

Frontend:

- `apps/web/app/(public)/page.tsx`
- `apps/web/app/(public)/videos/[slug]/page.tsx`
- `apps/web/app/(public)/watch/[videoId]/page.tsx`
- `apps/web/components/video-card.tsx`
- `apps/web/components/video-player.tsx`
- `apps/web/components/admin-upload-form.tsx`

Backend:

- `apps/api/src/modules/videos/videos.service.ts`
- `apps/api/src/modules/videos/videos.controller.ts`
- `apps/api/src/modules/streaming/streaming.service.ts`
- `apps/api/src/modules/storage/storage.service.ts`
- `apps/api/src/modules/storage/storage.controller.ts`
- `apps/api/src/modules/admin/admin.service.ts`
- `apps/api/src/modules/admin/admin.controller.ts`

Database:

- `infra/sql/schema.sql`
- `infra/sql/schema-update.sql`
