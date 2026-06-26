import { forwardRef, useState, type InputHTMLAttributes } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { cn } from '@/lib/utils'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, leftIcon, rightIcon, id, type, ...props }, ref) => {
    // Password fields get a built-in show/hide toggle (login, register, account, …).
    const [show, setShow] = useState(false)
    const isPassword = type === 'password'
    const effectiveType = isPassword ? (show ? 'text' : 'password') : type

    const right = isPassword ? (
      <button
        type="button"
        tabIndex={-1}
        onClick={() => setShow((v) => !v)}
        aria-label={show ? 'Hide password' : 'Show password'}
        className="text-fg-subtle hover:text-fg transition-colors"
      >
        {show ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
      </button>
    ) : rightIcon

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label htmlFor={id} className="text-sm font-medium text-fg-muted">
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <span className="absolute left-2.5 top-1/2 -translate-y-1/2 text-fg-subtle">
              {leftIcon}
            </span>
          )}
          <input
            ref={ref}
            id={id}
            type={effectiveType}
            className={cn(
              'w-full h-9 rounded-lg border border-border bg-bg-elevated px-3 text-sm text-fg',
              'placeholder:text-fg-subtle transition-colors',
              'focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent',
              'disabled:opacity-50 disabled:cursor-not-allowed',
              leftIcon && 'pl-8',
              right && 'pr-9',
              error && 'border-danger focus:ring-danger',
              className,
            )}
            {...props}
          />
          {right && (
            <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-fg-subtle">
              {right}
            </span>
          )}
        </div>
        {error && <p className="text-xs text-danger">{error}</p>}
      </div>
    )
  },
)
Input.displayName = 'Input'
