import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'
import { authApi } from '@/api/auth'
import { Button, Input } from '@/components/ui'

export function ForgotPasswordPage() {
  const { t } = useTranslation()
  const [email, setEmail] = useState('')
  const mutation = useMutation({ mutationFn: () => authApi.forgotPassword(email) })

  return (
    <div className="flex min-h-full items-center justify-center p-4">
      <div className="w-full max-w-sm space-y-5">
        <h1 className="text-2xl font-semibold text-fg">{t('password.forgotTitle')}</h1>
        {mutation.isSuccess ? (
          <p className="text-sm text-fg-muted">{t('password.forgotSent')}</p>
        ) : (
          <form className="space-y-4" onSubmit={(event) => { event.preventDefault(); mutation.mutate() }}>
            <Input label={t('auth.email')} type="email" value={email} onChange={(event) => setEmail(event.target.value)} required autoComplete="email" />
            <Button type="submit" className="w-full" loading={mutation.isPending}>{t('password.sendInstructions')}</Button>
          </form>
        )}
        <Link className="block text-center text-sm text-accent hover:underline" to="/login">{t('password.backToLogin')}</Link>
      </div>
    </div>
  )
}
