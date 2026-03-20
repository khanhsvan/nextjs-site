export enum UserRole {
  GUEST = 'guest',
  USER = 'user',
  MODERATOR = 'moderator',
  OWNER = 'owner',
  ADMIN = 'admin'
}

export enum VideoType {
  MOVIE = 'MOVIE',
  SERIES = 'SERIES'
}

export enum VideoAccessTier {
  FREE = 'FREE',
  PREMIUM = 'PREMIUM'
}

export enum VideoProcessingStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  READY = 'READY',
  FAILED = 'FAILED'
}

export enum SubscriptionStatus {
  INCOMPLETE = 'INCOMPLETE',
  ACTIVE = 'ACTIVE',
  PAST_DUE = 'PAST_DUE',
  CANCELED = 'CANCELED',
  EXPIRED = 'EXPIRED',
  TRIALING = 'TRIALING'
}

export enum LicenseStatus {
  VALID = 'VALID',
  EXPIRED = 'EXPIRED',
  PENDING = 'PENDING'
}

export enum DmcaRequestStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  UNDER_REVIEW = 'UNDER_REVIEW'
}

export enum VideoVisibility {
  PUBLIC = 'PUBLIC',
  PRIVATE = 'PRIVATE',
  RESTRICTED = 'RESTRICTED'
}

export enum RestrictionReason {
  NONE = 'NONE',
  COPYRIGHT = 'COPYRIGHT',
  DMCA = 'DMCA',
  REGION = 'REGION',
  VERIFICATION = 'VERIFICATION'
}

export enum UserPermission {
  VIEW = 'view',
  EDIT = 'edit',
  UPLOAD = 'upload',
  DELETE = 'delete',
  MODERATE = 'moderate'
}

export type LockReason = 'LOGIN_REQUIRED' | 'SUBSCRIPTION_REQUIRED' | 'PROCESSING' | 'NOT_FOUND';

export interface UserSummary {
  id: string;
  email: string;
  name: string | null;
  role: UserRole;
  isEmailVerified: boolean;
  subscriptionStatus: SubscriptionStatus | null;
  acceptedTosVersion?: string | null;
  acceptedTosAt?: string | null;
  permissions?: UserPermission[];
  isBanned?: boolean;
}

export interface AuthenticatedViewer extends UserSummary {
  region?: string;
  verifiedForRestrictedContent?: boolean;
}

export interface CatalogVideo {
  id: string;
  slug: string;
  title: string;
  description: string;
  type: VideoType;
  accessTier: VideoAccessTier;
  durationSeconds: number;
  thumbnailUrl: string;
  tags: string[];
  previewDurationSeconds: number;
  visibility?: VideoVisibility;
  restrictionReason?: RestrictionReason;
}

export interface EpisodeSummary {
  id: string;
  seriesId: string;
  title: string;
  description: string;
  durationSeconds: number;
  seasonNumber: number;
  episodeNumber: number;
  thumbnailUrl: string;
}

export interface PlaybackAuthorizationResponse {
  allowed: boolean;
  lockReason?: LockReason;
  manifestUrl?: string;
  resumeSeconds?: number;
  previewEndsAtSeconds?: number;
  message?: string;
  accessToken?: string;
  expiresAt?: number;
  watermarkText?: string;
}

export interface AnalyticsOverview {
  totalViews: number;
  uniqueViewers: number;
  totalWatchSeconds: number;
  activeSubscribers: number;
}

export interface LicenseRecord {
  id: string;
  contentTitle: string;
  ownerName: string;
  issuerOrganization: string;
  validityStart: string;
  validityEnd: string;
  territory: string[];
  status: LicenseStatus;
  signature: string;
  attachedVideoId?: string | null;
  licenseDocumentName: string;
}

export interface TosVersionRecord {
  id: string;
  version: string;
  title: string;
  content: string;
  publishedAt: string;
  isActive: boolean;
}

export interface DmcaRequestRecord {
  id: string;
  reporterName: string;
  reporterEmail: string;
  contentUrl: string;
  reason: string;
  status: DmcaRequestStatus;
  createdAt: string;
}

export interface UploadPlan {
  videoId: string;
  uploadSessionId: string;
  uploadUrl: string;
  chunkSizeBytes: number;
  resumable: boolean;
  expiresAt: number;
  requiredHeaders: Record<string, string>;
}
