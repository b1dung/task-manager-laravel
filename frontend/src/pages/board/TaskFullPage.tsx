import { useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { projectsApi } from '@/api/projects'
import { TaskDetailModal } from './components/TaskDetailModal'

/** Same key derivation as BoardPage (kept in sync). */
function getProjectKey(name?: string | null): string {
  const words = (name ?? '').trim().split(/[\s\-_]+/).filter(Boolean)
  if (words.length >= 2) return words.map((w) => w[0] ?? '').join('').toUpperCase().slice(0, 5)
  return (words[0] ?? 'TASK').slice(0, 5).toUpperCase()
}

/** Jira-style full-page task view at /projects/:projectId/tasks/:taskId. */
export function TaskFullPage() {
  const { projectId = '', taskId = '' } = useParams<{ projectId: string; taskId: string }>()
  const navigate = useNavigate()

  const { data: project } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectsApi.get(projectId),
    enabled: !!projectId,
    staleTime: 10 * 60_000,
  })
  const projectKey = project ? getProjectKey(project.name) : 'TASK'

  const handleClose = useCallback(() => {
    // Return to wherever the user came from (List/Board); fall back to the board
    // when opened via a direct link with no in-app history.
    const idx = (window.history.state as { idx?: number } | null)?.idx ?? 0
    if (idx > 0) navigate(-1)
    else navigate(`/projects/${projectId}/tasks`)
  }, [navigate, projectId])
  const handleOpenTask = useCallback(
    (id: string) => navigate(`/projects/${projectId}/tasks/${id}`),
    [navigate, projectId],
  )

  return (
    <TaskDetailModal
      variant="page"
      task={null}
      taskId={taskId}
      projectId={projectId}
      projectKey={projectKey}
      open
      onClose={handleClose}
      onOpenTask={handleOpenTask}
    />
  )
}
