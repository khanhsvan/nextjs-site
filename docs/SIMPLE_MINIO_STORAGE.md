# Simple MinIO Storage Flow

This project now uses a simpler MinIO flow designed to be easier to run and maintain.

## Recommended Working Path

Use this flow for normal videos:

1. Admin creates a video record
2. Admin uploads one video file, usually `.mp4`
3. Backend uploads that file into MinIO
4. Backend stores the MinIO object path in PostgreSQL
5. Player streams the video through the backend proxy

## Best Format For Now

Recommended:

- `mp4`

Supported in a simpler and more reliable way:

- one uploaded MP4 file per movie
- one uploaded MP4 file per series placeholder

Advanced HLS support can still be added later, but the simplest working setup is MP4 through backend proxy streaming.

## Storage Path Format

Object path format:

- `<bucket>/library/<videoId>/source.mp4`

Example:

- bucket: `movie`
- object path: `library/123456/source.mp4`
- stored full path:
  - `movie/library/123456/source.mp4`

## Environment Values

Important variables:

- `STORAGE_BASE_URL`
- `STORAGE_BUCKET`
- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`

Example:

```env
STORAGE_BASE_URL=http://host.docker.internal:9000
STORAGE_BUCKET=movie
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=admin123
```

## Playback Flow

1. Frontend asks backend for playback
2. Backend checks user permission
3. Backend returns a backend stream URL
4. Browser plays from backend
5. Backend reads file from MinIO

This means:

- MinIO stays private
- browser does not need MinIO credentials
- no public storage URLs are exposed

## Upload Flow

1. Frontend creates the video record
2. Frontend uploads the file to the backend
3. Backend uploads the file to MinIO
4. Backend updates `video_assets`
5. Frontend publishes the video

## Why This Is Simpler

- no direct browser upload to MinIO
- no need to expose MinIO URLs to users
- no presigned URL dependency for playback
- MP4 works with normal browser range requests
- easier for admin users and easier to debug
