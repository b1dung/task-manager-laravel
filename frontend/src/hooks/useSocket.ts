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

let echo: Echo<'reverb'> | Echo<'pusher'> | null = null

/** Lazily create the shared Echo client (Pusher cloud or self-hosted Reverb). */
function ensureEcho(accessToken: string): Echo<'reverb'> | Echo<'pusher'> {
  window.Pusher = Pusher
  const apiUrl = import.meta.env.VITE_API_URL ?? '/api/v1'
  const authHeaders = { Authorization: `Bearer ${accessToken}`, Accept: 'application/json' }
  // Pick transport: explicit VITE_BROADCASTER, else infer (Pusher cloud if a Pusher key is set, otherwise self-hosted Reverb).
  const broadcaster = import.meta.env.VITE_BROADCASTER ?? (import.meta.env.VITE_PUSHER_APP_KEY ? 'pusher' : 'reverb')

  if (broadcaster === 'pusher') {
    // Production: Pusher cloud (key + cluster). Host/port are derived from the cluster by pusher-js.
    echo ??= new Echo({ broadcaster: 'pusher', key: import.meta.env.VITE_PUSHER_APP_KEY ?? '', cluster: import.meta.env.VITE_PUSHER_CLUSTER ?? 'mt1', forceTLS: true, authEndpoint: `${apiUrl}/broadcasting/auth`, auth: { headers: authHeaders } })
  } else {
    // Local / self-hosted Reverb.
    const wsHost = import.meta.env.VITE_REVERB_HOST ?? window.location.hostname
    echo ??= new Echo({ broadcaster: 'reverb', key: import.meta.env.VITE_REVERB_APP_KEY ?? 'local-key', wsHost, wsPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080), wssPort: Number(import.meta.env.VITE_REVERB_PORT ?? 443), forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https', enabledTransports: ['ws', 'wss'], authEndpoint: `${apiUrl}/broadcasting/auth`, auth: { headers: authHeaders } })
  }
  return echo
}

/** Subscribe to a private channel and expose a small on/off adapter. */
function usePrivateChannel(channelName?: string): RealtimeSocket | null {
  const accessToken = useAuthStore((s) => s.accessToken)
  const [socket, setSocket] = useState<RealtimeSocket | null>(null)

  useEffect(() => {
    if (!accessToken || import.meta.env.MODE === 'test' || !channelName) return

    const client = ensureEcho(accessToken)
    const channel = client.private(channelName)
    const adapter: RealtimeSocket = { on: (event, handler) => channel.listen(`.${event}`, handler), off: (event, handler) => channel.stopListening(`.${event}`, handler) }
    let active = true
    queueMicrotask(() => { if (active) setSocket(adapter) })

    return () => {
      active = false
      echo?.leave(channelName)
      setSocket(null)
    }
  }, [accessToken, channelName])

  return socket
}

/** Realtime for a project board (channel `project.{projectId}`). */
export function useSocket(projectId?: string): RealtimeSocket | null {
  return usePrivateChannel(projectId ? `project.${projectId}` : undefined)
}

/** Realtime for the current user (channel `user.{userId}`) — notifications etc. */
export function useUserSocket(userId?: string): RealtimeSocket | null {
  return usePrivateChannel(userId ? `user.${userId}` : undefined)
}
