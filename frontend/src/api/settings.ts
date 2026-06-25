import { apiClient } from './client'
import type { UserTimezone } from '@/lib/timezones'

export interface SiteSettings {
  timezone: UserTimezone
}

export const settingsApi = {
  get: () =>
    apiClient.get<{ success: true; data: SiteSettings }>('/settings').then((r) => r.data.data),
  update: (dto: { timezone: UserTimezone }) =>
    apiClient.put<{ success: true; data: SiteSettings }>('/settings', dto).then((r) => r.data.data),
}
