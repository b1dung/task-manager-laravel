import { useEffect, useState } from 'react'
import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { useAuthStore } from '@/stores/useAuthStore'

declare global { interface Window { Pusher: typeof Pusher } }

type Handler<T> = (payload: T) => void
export interface RealtimeSocket {
  on: <T>(event: string, handler: Handler<T>) => void
  off: <T>(event: string, handler: Handler<T>) => void
}

let echo: Echo<'reverb'> | null = null

export function useSocket(projectId?: string) {
  const accessToken = useAuthStore((s) => s.accessToken)
  const [socket, setSocket] = useState<RealtimeSocket | null>(null)

  useEffect(() => {
    if (!accessToken || import.meta.env.MODE === 'test') return

    window.Pusher = Pusher
    const apiUrl = import.meta.env.VITE_API_URL ?? '/api/v1'
    const wsHost = import.meta.env.VITE_REVERB_HOST ?? window.location.hostname
    echo ??= new Echo({ broadcaster: 'reverb', key: import.meta.env.VITE_REVERB_APP_KEY ?? 'local-key', wsHost, wsPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080), wssPort: Number(import.meta.env.VITE_REVERB_PORT ?? 443), forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https', enabledTransports: ['ws', 'wss'], authEndpoint: `${apiUrl}/broadcasting/auth`, auth: { headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/json' } } })
    if (!projectId) return
    const channel = echo.private(`project.${projectId}`)
    const adapter: RealtimeSocket = { on: (event, handler) => channel.listen(`.${event}`, handler), off: (event, handler) => channel.stopListening(`.${event}`, handler) }
    let active = true
    queueMicrotask(() => { if (active) setSocket(adapter) })

    return () => {
      active = false
      echo?.leave(`project.${projectId}`)
      setSocket(null)
    }
  }, [accessToken, projectId])

  return socket
}
