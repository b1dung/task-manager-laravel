import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { useSocket, useUserSocket } from '@/hooks/useSocket'
import { useAuthStore } from '@/stores/useAuthStore'

// Every per-project mutation the backend broadcasts on `project.{id}`. We don't
// care about the payload — on any of these we invalidate every query that
// references the active project, so EVERY mounted page of that project refetches
// authoritative data and can't drift out of sync with the others.
const PROJECT_EVENTS = [
  'task:created', 'task:updated', 'task:moved', 'task:deleted',
  'column:changed', 'member:changed', 'sprint:changed',
  'label:changed', 'requester:changed', 'attachment:changed',
  'comment:added', 'comment:updated', 'comment:deleted', 'tasklink:changed',
]

/**
 * Site-wide realtime sync. Mounted once in AppLayout so it stays alive across
 * page navigation. Subscribes to the active project channel + the user channel
 * and invalidates the relevant React Query caches whenever data changes anywhere.
 */
export function RealtimeSync() {
  const qc = useQueryClient()
  const { pathname } = useLocation()
  const projectId = pathname.match(/^\/projects\/([^/]+)/)?.[1]
  const userId = useAuthStore((s) => s.user?.id)

  const projectSocket = useSocket(projectId)
  const userSocket = useUserSocket(userId)

  // Project channel: any change → invalidate all queries holding this projectId.
  useEffect(() => {
    if (!projectSocket || !projectId) return
    const invalidate = () =>
      qc.invalidateQueries({
        predicate: (q) => Array.isArray(q.queryKey) && q.queryKey.includes(projectId),
      })
    PROJECT_EVENTS.forEach((e) => projectSocket.on(e, invalidate))
    return () => PROJECT_EVENTS.forEach((e) => projectSocket.off(e, invalidate))
  }, [projectSocket, projectId, qc])

  // User channel: notifications fire across projects; refresh My Tasks too since a
  // task assigned/changed elsewhere won't reach us via the project channel.
  useEffect(() => {
    if (!userSocket) return
    const onNotification = () => {
      qc.invalidateQueries({ queryKey: ['notifications'] })
      qc.invalidateQueries({ queryKey: ['my-tasks'] })
    }
    userSocket.on('notification:new', onNotification)
    return () => userSocket.off('notification:new', onNotification)
  }, [userSocket, qc])

  return null
}
