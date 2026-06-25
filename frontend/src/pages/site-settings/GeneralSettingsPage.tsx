import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { settingsApi } from '@/api/settings'
import { Button } from '@/components/ui'
import { useToast } from '@/hooks/useToast'
import {
  currentTimePreview, DEFAULT_TIMEZONE, TIMEZONE_LABELS, TIMEZONE_OPTIONS, type UserTimezone,
} from '@/lib/timezones'

/**
 * Global, site-wide settings (owner/admin only — gated by `manage_settings`).
 * The General section holds the shared display timezone used everywhere in the
 * web app and in exports.
 */
export function GeneralSettingsPage() {
  const { t } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()

  const { data: settings } = useQuery({ queryKey: ['site-settings'], queryFn: settingsApi.get })
  const saved = (settings?.timezone ?? DEFAULT_TIMEZONE) as UserTimezone
  const [draft, setDraft] = useState<UserTimezone | null>(null)
  const timezone = draft ?? saved

  const { mutate: save, isPending } = useMutation({
    mutationFn: () => settingsApi.update({ timezone }),
    onSuccess: (data) => {
      qc.setQueryData(['site-settings'], data)
      qc.invalidateQueries({ queryKey: ['site-settings'] })
      setDraft(null)
      toast.success(t('settings.saved'))
    },
    onError: () => toast.error(t('settings.saveFailed')),
  })

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <div className="px-6 py-4 border-b border-border shrink-0">
        <h1 className="text-base font-semibold text-fg">{t('settings.title')}</h1>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin p-6">
        <div className="max-w-2xl rounded-xl border border-border bg-bg-surface">
          <div className="px-5 py-3.5 border-b border-border">
            <h2 className="text-sm font-semibold text-fg">{t('settings.general')}</h2>
            <p className="text-xs text-fg-muted mt-0.5">{t('settings.generalDesc')}</p>
          </div>

          <div className="px-5 py-4 space-y-3">
            <div>
              <label className="text-xs font-medium text-fg-muted mb-1.5 block">{t('settings.timezone')}</label>
              <select
                value={timezone}
                onChange={(e) => setDraft(e.target.value as UserTimezone)}
                className="h-9 w-full max-w-sm rounded-lg border border-border bg-bg-elevated px-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
              >
                {TIMEZONE_OPTIONS.map((tz) => <option key={tz} value={tz}>{TIMEZONE_LABELS[tz]}</option>)}
              </select>
              <p className="text-xs text-fg-subtle mt-1">{currentTimePreview(timezone, new Date(), t('settings.currentTime'))}</p>
              <p className="text-xs text-fg-subtle mt-0.5">{t('settings.timezoneDesc')}</p>
            </div>

            <Button variant="primary" size="sm" loading={isPending} disabled={timezone === saved} onClick={() => save()}>
              {t('settings.save')}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
