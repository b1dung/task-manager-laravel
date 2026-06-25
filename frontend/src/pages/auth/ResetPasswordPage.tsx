import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { authApi } from '@/api/auth'
import { Button, Input } from '@/components/ui'

export function ResetPasswordPage() {
  const { t } = useTranslation()
  const [params] = useSearchParams()
  const token = params.get('token') ?? ''
  const [password, setPassword] = useState('')
  const mutation = useMutation({ mutationFn: () => authApi.resetPassword(token, password) })

  return (
    <div className="flex min-h-full items-center justify-center p-4">
      <div className="w-full max-w-sm space-y-5">
        <h1 className="text-2xl font-semibold text-fg">{t('password.resetTitle')}</h1>
        {mutation.isSuccess ? (
          <p className="text-sm text-success">{t('password.resetSuccess')}</p>
        ) : (
          <form className="space-y-4" onSubmit={(event) => { event.preventDefault(); mutation.mutate() }}>
            <Input label={t('account.newPassword')} type="password" minLength={8} value={password} onChange={(event) => setPassword(event.target.value)} required autoComplete="new-password" />
            {mutation.isError && <p className="text-sm text-danger">{t('password.invalidLink')}</p>}
            <Button type="submit" className="w-full" disabled={!token || password.length < 8} loading={mutation.isPending}>{t('password.changePassword')}</Button>
          </form>
        )}
        <Link className="block text-center text-sm text-accent hover:underline" to="/login">{t('auth.login')}</Link>
      </div>
    </div>
  )
}
