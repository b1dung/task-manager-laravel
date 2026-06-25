import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { authApi } from '@/api/auth'
import { usersApi } from '@/api/users'
import { useAuthStore } from '@/stores/useAuthStore'
import { useTranslation } from 'react-i18next'
import { currentAppLanguage } from '@/i18n'

export function OAuthCallbackPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()

  useEffect(() => {
    const token = new URLSearchParams(window.location.hash.slice(1)).get('accessToken')
    window.history.replaceState(null, '', '/auth/callback')
    if (!token) {
      navigate('/login', { replace: true })
      return
    }
    useAuthStore.getState().setTokens(token, '')
    authApi.me()
      .then((user) => {
        const language = currentAppLanguage()
        useAuthStore.getState().setAuth({ ...user, language }, token, '')
        if (user.language !== language) void usersApi.update(user.id, { language })
        navigate('/projects', { replace: true })
      })
      .catch(() => navigate('/login', { replace: true }))
  }, [navigate])

  return <div className="flex min-h-full items-center justify-center text-sm text-fg-muted">{t('auth.signingIn')}</div>
}
