import { useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { settingsApi } from '@/api/settings'
import { useAuthStore } from '@/stores/useAuthStore'
import { DEFAULT_TIMEZONE, setSiteTimezone, type UserTimezone } from '@/lib/timezones'

/**
 * The site-wide display timezone (configured in global Settings → General).
 * Replaces the old per-user timezone. Also syncs the module-level value in
 * lib/timezones so the non-React formatters (formatDate/formatRelative) follow it.
 */
export function useSiteTimezone(): UserTimezone {
  const isAuthenticated = Boolean(useAuthStore((s) => s.isAuthenticated))
  const { data } = useQuery({
    queryKey: ['site-settings'],
    queryFn: settingsApi.get,
    enabled: isAuthenticated,
    staleTime: 5 * 60_000,
  })

  const timezone = (data?.timezone ?? DEFAULT_TIMEZONE) as UserTimezone

  useEffect(() => {
    setSiteTimezone(timezone)
  }, [timezone])

  return timezone
}
