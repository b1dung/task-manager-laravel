import { useTranslation } from 'react-i18next'
import { currentAppLanguage, type AppLanguage } from '@/i18n'
import { LanguageFlag } from '@/layout/UserAccountMenu'

const languages: Array<{ value: AppLanguage; labelKey: string }> = [
  { value: 'en', labelKey: 'common.langEn' },
  { value: 'vi', labelKey: 'common.langVi' },
  { value: 'ja', labelKey: 'common.langJa' },
]

export function AuthLanguagePicker() {
  const { t, i18n } = useTranslation()
  const current = currentAppLanguage()

  return (
    <label className="inline-flex items-center gap-2 rounded-xl border border-border bg-bg-elevated px-3 py-2 text-xs text-fg-muted">
      <LanguageFlag language={current} size={20} />
      <span className="sr-only">{t('common.language')}</span>
      <select
        value={current}
        aria-label={t('common.language')}
        onChange={(event) => void i18n.changeLanguage(event.target.value as AppLanguage)}
        className="bg-transparent text-xs text-fg focus:outline-none"
      >
        {languages.map((language) => (
          <option key={language.value} value={language.value}>
            {t(language.labelKey)}
          </option>
        ))}
      </select>
    </label>
  )
}
