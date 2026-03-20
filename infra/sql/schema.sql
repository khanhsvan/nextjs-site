CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE user_role AS ENUM ('guest', 'user', 'moderator', 'owner', 'admin');
CREATE TYPE video_type AS ENUM ('MOVIE', 'SERIES');
CREATE TYPE video_access_tier AS ENUM ('FREE', 'PREMIUM');
CREATE TYPE video_processing_status AS ENUM ('PENDING', 'PROCESSING', 'READY', 'FAILED');
CREATE TYPE subscription_status AS ENUM ('INCOMPLETE', 'ACTIVE', 'PAST_DUE', 'CANCELED', 'EXPIRED', 'TRIALING');
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED');
CREATE TYPE watch_event_type AS ENUM ('START', 'HEARTBEAT', 'COMPLETE', 'PREVIEW_LOCK');
CREATE TYPE license_status AS ENUM ('VALID', 'EXPIRED', 'PENDING');
CREATE TYPE dmca_request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'UNDER_REVIEW');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT,
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'user',
  is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  accepted_tos_version TEXT,
  accepted_tos_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL,
  user_agent TEXT,
  ip_address TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type video_type NOT NULL,
  access_tier video_access_tier NOT NULL DEFAULT 'FREE',
  category TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  preview_duration_seconds INTEGER NOT NULL DEFAULT 180,
  thumbnail_url TEXT,
  visibility BOOLEAN NOT NULL DEFAULT FALSE,
  processing_status video_processing_status NOT NULL DEFAULT 'PENDING',
  is_under_review BOOLEAN NOT NULL DEFAULT FALSE,
  license_id UUID,
  published_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE episodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  episode_number INTEGER NOT NULL,
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT episodes_series_order_unique UNIQUE (video_id, season_number, episode_number)
);

CREATE TABLE video_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE CASCADE,
  source_object_key TEXT NOT NULL,
  master_playlist_key TEXT,
  preview_playlist_key TEXT,
  thumbnail_object_key TEXT,
  processing_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE licenses (
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

ALTER TABLE videos
  ADD CONSTRAINT videos_license_fk FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE SET NULL;

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stripe_customer_id TEXT NOT NULL,
  stripe_subscription_id TEXT NOT NULL UNIQUE,
  stripe_price_id TEXT NOT NULL,
  status subscription_status NOT NULL,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
  canceled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  stripe_invoice_id TEXT,
  stripe_payment_intent_id TEXT,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'usd',
  status payment_status NOT NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE watch_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE CASCADE,
  progress_seconds INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  last_watched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX watch_history_movie_unique
  ON watch_history (user_id, video_id)
  WHERE episode_id IS NULL;

CREATE UNIQUE INDEX watch_history_episode_unique
  ON watch_history (user_id, video_id, episode_id)
  WHERE episode_id IS NOT NULL;

CREATE TABLE watch_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  episode_id UUID REFERENCES episodes(id) ON DELETE CASCADE,
  event_type watch_event_type NOT NULL,
  watched_seconds INTEGER NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tos_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE dmca_requests (
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

CREATE TABLE content_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
  ip_address TEXT,
  request_path TEXT NOT NULL,
  user_agent TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE video_tags (
  video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (video_id, tag_id)
);

CREATE INDEX videos_type_access_idx ON videos (type, access_tier);
CREATE INDEX episodes_video_idx ON episodes (video_id);
CREATE INDEX subscriptions_user_status_idx ON subscriptions (user_id, status);
CREATE INDEX watch_events_video_idx ON watch_events (video_id, created_at DESC);
CREATE INDEX licenses_status_idx ON licenses (status, validity_end);
CREATE INDEX dmca_requests_status_idx ON dmca_requests (status, created_at DESC);
CREATE INDEX content_access_logs_video_idx ON content_access_logs (video_id, requested_at DESC);
