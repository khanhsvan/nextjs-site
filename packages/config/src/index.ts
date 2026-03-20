import { SubscriptionStatus, UserRole, VideoAccessTier } from '@netflix-mini/types';
import crypto from 'node:crypto';

export const PREVIEW_DURATION_SECONDS = 180;

export const ACCESS_TTL_SECONDS = 60 * 5;

const STORAGE_SECRET = process.env.STORAGE_SECRET ?? 'dev-storage-secret';

export function isSubscriber(status: SubscriptionStatus | null | undefined): boolean {
  return status === SubscriptionStatus.ACTIVE || status === SubscriptionStatus.TRIALING;
}

export function canAccessVideo(options: {
  role?: UserRole | null;
  subscriptionStatus?: SubscriptionStatus | null;
  accessTier: VideoAccessTier;
}) {
  if (options.accessTier === VideoAccessTier.FREE) {
    return {
      allowed:
        options.role === UserRole.USER ||
        options.role === UserRole.MODERATOR ||
        options.role === UserRole.OWNER ||
        options.role === UserRole.ADMIN
    };
  }

  return {
    allowed:
      options.role === UserRole.ADMIN ||
      options.role === UserRole.MODERATOR ||
      options.role === UserRole.OWNER ||
      isSubscriber(options.subscriptionStatus)
  };
}

export function createMediaAccessToken(videoId: string, expiresAt: number) {
  return crypto.createHmac('sha256', STORAGE_SECRET).update(`${videoId}:${expiresAt}`).digest('hex');
}

export function validateMediaAccessToken(videoId: string, expiresAt: number, token: string) {
  if (!token || expiresAt < Math.floor(Date.now() / 1000)) {
    return false;
  }

  const expected = createMediaAccessToken(videoId, expiresAt);
  if (expected.length !== token.length) {
    return false;
  }
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(token));
}

export function createResourceAccessToken(videoId: string, resourcePath: string, expiresAt: number) {
  return crypto.createHmac('sha256', STORAGE_SECRET).update(`${videoId}:${resourcePath}:${expiresAt}`).digest('hex');
}

export function validateResourceAccessToken(videoId: string, resourcePath: string, expiresAt: number, token: string) {
  if (!token || expiresAt < Math.floor(Date.now() / 1000)) {
    return false;
  }

  const expected = createResourceAccessToken(videoId, resourcePath, expiresAt);
  if (expected.length !== token.length) {
    return false;
  }

  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(token));
}
