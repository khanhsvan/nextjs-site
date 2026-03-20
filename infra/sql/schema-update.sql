-- Incremental schema update for existing databases.
-- Target: current private-storage + DRM/compliance architecture.
-- Recommended usage:
--   psql -U postgres -d netflix_mini -f infra/sql/schema-update.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'license_status') THEN
    CREATE TYPE license_status AS ENUM ('VALID', 'EXPIRED', 'PENDING');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dmca_request_status') THEN
    CREATE TYPE dmca_request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'UNDER_REVIEW');
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'moderator'
  ) THEN
    NULL;
  ELSE
    ALTER TYPE user_role ADD VALUE 'moderator';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'owner'
  ) THEN
    NULL;
  ELSE
    ALTER TYPE user_role ADD VALUE 'owner';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS accepted_tos_version TEXT,
  ADD COLUMN IF NOT EXISTS accepted_tos_at TIMESTAMPTZ;

ALTER TABLE videos
  ADD COLUMN IF NOT EXISTS is_under_review BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS license_id UUID;

ALTER TABLE video_assets
  ADD COLUMN IF NOT EXISTS storage_base_url TEXT,
  ADD COLUMN IF NOT EXISTS storage_auth_type TEXT,
  ADD COLUMN IF NOT EXISTS source_path TEXT,
  ADD COLUMN IF NOT EXISTS master_playlist_path TEXT,
  ADD COLUMN IF NOT EXISTS preview_playlist_path TEXT,
  ADD COLUMN IF NOT EXISTS thumbnail_path TEXT;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'source_object_key'
  ) THEN
    UPDATE video_assets
    SET source_path = COALESCE(source_path, source_object_key)
    WHERE source_object_key IS NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'master_playlist_key'
  ) THEN
    UPDATE video_assets
    SET master_playlist_path = COALESCE(master_playlist_path, master_playlist_key)
    WHERE master_playlist_key IS NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'preview_playlist_key'
  ) THEN
    UPDATE video_assets
    SET preview_playlist_path = COALESCE(preview_playlist_path, preview_playlist_key)
    WHERE preview_playlist_key IS NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'thumbnail_object_key'
  ) THEN
    UPDATE video_assets
    SET thumbnail_path = COALESCE(thumbnail_path, thumbnail_object_key)
    WHERE thumbnail_object_key IS NOT NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'source_object_key'
  ) THEN
    ALTER TABLE video_assets DROP COLUMN source_object_key;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'master_playlist_key'
  ) THEN
    ALTER TABLE video_assets DROP COLUMN master_playlist_key;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'preview_playlist_key'
  ) THEN
    ALTER TABLE video_assets DROP COLUMN preview_playlist_key;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'video_assets' AND column_name = 'thumbnail_object_key'
  ) THEN
    ALTER TABLE video_assets DROP COLUMN thumbnail_object_key;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  license_code TEXT NOT NULL UNIQUE,
  content_title TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  issuer_organization TEXT NOT NULL,
  validity_start TIMESTAMPTZ NOT NULL,
  validity_end TIMESTAMPTZ NOT NULL,
  territory TEXT[] NOT NULL DEFAULT '{}',
  status license_status NOT NULL DEFAULT 'PENDING',
  digital_signature TEXT NOT NULL,
  license_file_path TEXT NOT NULL,
  attached_video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_name = 'videos' AND constraint_name = 'videos_license_fk'
  ) THEN
    ALTER TABLE videos
      ADD CONSTRAINT videos_license_fk
      FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS tos_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS dmca_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_name TEXT NOT NULL,
  reporter_email TEXT NOT NULL,
  content_url TEXT NOT NULL,
  reason TEXT NOT NULL,
  status dmca_request_status NOT NULL DEFAULT 'PENDING',
  affected_video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
  processed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS content_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
  ip_address TEXT,
  request_path TEXT NOT NULL,
  user_agent TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS licenses_status_idx
  ON licenses (status, validity_end);

CREATE INDEX IF NOT EXISTS dmca_requests_status_idx
  ON dmca_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS content_access_logs_video_idx
  ON content_access_logs (video_id, requested_at DESC);

-- Optional defaults for new storage architecture.
UPDATE video_assets
SET storage_auth_type = COALESCE(storage_auth_type, 'token')
WHERE storage_auth_type IS NULL;
