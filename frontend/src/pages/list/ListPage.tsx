import { useSiteTimezone } from '@/hooks/useSiteTimezone'
import { useMemo, useRef, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'
import { useParams, useSearchParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { X, ListTodo, ChevronDown, ChevronLeft, ChevronRight, Check } from 'lucide-react'
import { tasksApi, type Task, type UpdateTaskDto } from '@/api/tasks'
import { columnsApi, type BoardColumn } from '@/api/columns'
import { membersApi, type ProjectMember } from '@/api/members'
import { projectsApi } from '@/api/projects'
import { Avatar, EmptyState, Skeleton } from '@/components/ui'
import { TaskIcon, SubtaskIcon } from '@/components/ui/TaskIcons'
import { TaskDetailModal } from '@/pages/board/components/TaskDetailModal'
import { FilterBar } from '@/pages/board/components/FilterBar'
import { useFilterStore } from '@/stores/useFilterStore'
import { usePermissions } from '@/hooks/usePermissions'
import { useToast } from '@/hooks/useToast'
import { formatZonedDate } from '@/lib/timezones'
import { cn } from '@/lib/utils'

const PRIORITY_ICON: Record<string, { svg: string }> = {
  urgent: { svg: '/priority/highest_new.svg' },
  high: { svg: '/priority/high_new.svg' },
  medium: { svg: '/priority/medium_new.svg' },
  low: { svg: '/priority/low_new.svg' },
  lowest: { svg: '/priority/lowest_new.svg' },
}
const PAGE_SIZE = 30

function TableHeader({ children, className }: { children: ReactNode; className?: string }) {
  return <th className={cn('px-4 py-2.5 font-semibold whitespace-nowrap', className)}>{children}</th>
}

function getProjectKey(name?: string | null): string {
  const w = (name ?? '').trim().split(/\s+/).filter(Boolean)
  return w.length > 1 ? w.map((x) => x[0]).join('').toUpperCase().slice(0, 5) : (w[0] ?? 'TASK').slice(0, 5).toUpperCase()
}

// ─── Portal dropdown (avoids the scrollable table clipping the menu) ──────────
function InlineMenu({ trigger, width = 200, children }: {
  trigger: ReactNode; width?: number; children: (close: () => void) => ReactNode
}) {
  const [open, setOpen] = useState(false)
  const btnRef = useRef<HTMLButtonElement>(null)
  const [pos, setPos] = useState({ top: 0, left: 0 })
  const openMenu = () => {
    const r = btnRef.current?.getBoundingClientRect()
    if (r) setPos({ top: r.bottom + 4, left: r.left })
    setOpen(true)
  }
  return (
    <>
      <button ref={btnRef} onClick={openMenu} className="inline-flex items-center gap-1 max-w-full">
        {trigger}
      </button>
      {open && createPortal(
        <>
          <div className="fixed inset-0 z-[9998]" onClick={() => setOpen(false)} />
          <div
            className="fixed z-[9999] rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden max-h-64 overflow-y-auto scrollbar-thin"
            style={{ top: pos.top, left: pos.left, width }}
          >
            {children(() => setOpen(false))}
          </div>
        </>,
        document.body,
      )}
    </>
  )
}

function UserCell({ user }: { user: Task['assignee'] }) {
  const { t } = useTranslation()
  if (!user) return <span className="text-xs text-fg-subtle">{t('common.unassigned')}</span>
  return (
    <span className="flex items-center gap-1.5 min-w-0">
      <Avatar name={user.fullName} avatarUrl={user.avatarUrl} size="xs" className="shrink-0" />
      <span className="text-xs text-fg-muted truncate">{user.fullName}</span>
    </span>
  )
}

function AssigneeCell({ task, members, disabled, onPick }: {
  task: Task; members: ProjectMember[]; disabled: boolean; onPick: (userId: string | null) => void
}) {
  const { t } = useTranslation()
  const user = task.assignee ?? members.find((m) => m.userId === task.assigneeId)?.user ?? null
  if (disabled) return <UserCell user={user} />
  return (
    <InlineMenu width={220} trigger={<><UserCell user={user} /><ChevronDown className="w-3 h-3 text-fg-subtle shrink-0" /></>}>
      {(close) => (
        <>
          <button onClick={() => { onPick(null); close() }} className="w-full text-left px-3 py-2 text-sm text-fg-muted hover:bg-bg-subtle">
            {t('common.unassigned')}
          </button>
          {members.map((m) => (
            <button key={m.userId} onClick={() => { onPick(m.userId); close() }}
              className={cn('w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-bg-subtle', m.userId === task.assigneeId && 'bg-bg-active')}>
              <Avatar name={m.user.fullName} avatarUrl={m.user.avatarUrl} size="xs" />
              <span className="truncate">{m.user.fullName}</span>
              {m.userId === task.assigneeId && <Check className="w-3.5 h-3.5 ml-auto text-accent shrink-0" />}
            </button>
          ))}
        </>
      )}
    </InlineMenu>
  )
}

function StatusCell({ task, columns, disabled, onPick }: {
  task: Task; columns: BoardColumn[]; disabled: boolean; onPick: (columnId: string) => void
}) {
  const { t } = useTranslation()
  const col = columns.find((c) => c.id === task.columnId)
  const color = col?.color ?? '#6b7280'
  const label = col?.name ?? t('status.' + task.status)
  const badge = (
    <span className="inline-flex items-center gap-1.5 rounded border px-2 py-0.5 text-xs font-medium whitespace-nowrap"
      style={{ color, borderColor: `${color}55`, backgroundColor: `${color}1a` }}>
      {label}
    </span>
  )
  if (disabled) return badge
  return (
    <InlineMenu width={190} trigger={<>{badge}<ChevronDown className="w-3 h-3 text-fg-subtle shrink-0" /></>}>
      {(close) => columns.map((c) => (
        <button key={c.id} onClick={() => { if (c.id !== task.columnId) onPick(c.id); close() }}
          className={cn('w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-bg-subtle', c.id === task.columnId && 'bg-bg-active')}>
          <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: c.color ?? '#6b7280' }} />
          <span className="flex-1 text-left text-fg truncate">{c.name}</span>
          {c.id === task.columnId && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
        </button>
      ))}
    </InlineMenu>
  )
}

export function ListPage() {
  const { t } = useTranslation()
  const { projectId = '' } = useParams<{ projectId: string }>()
  const [searchParams, setSearchParams] = useSearchParams()
  const qc = useQueryClient()
  const toast = useToast()
  const timezone = useSiteTimezone()
  const perms = usePermissions()
  const canAssign = perms.includes('assign_tasks')
  const canUpdate = perms.includes('update_own_task')
  const { board } = useFilterStore()
  const [openTaskId, setOpenTaskId] = useState<string | null>(null)

  const columnFilter = searchParams.get('column')
  const paginationKey = JSON.stringify({ projectId, board, columnFilter })
  const [pagination, setPagination] = useState({ key: paginationKey, page: 1 })
  const page = pagination.key === paginationKey ? pagination.page : 1
  const setPage = (nextPage: number) => setPagination({ key: paginationKey, page: nextPage })

  const { data: project } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectsApi.get(projectId),
    enabled: !!projectId,
    staleTime: 10 * 60_000,
  })
  const projectKey = getProjectKey(project?.name)

  const { data: columns = [] } = useQuery({
    queryKey: ['columns', projectId],
    queryFn: () => columnsApi.list(projectId),
    enabled: !!projectId,
  })
  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
    enabled: !!projectId,
  })

  const { data: tasksResult, isLoading } = useQuery({
    queryKey: ['list-tasks', projectId, board, columnFilter, page],
    queryFn: () => tasksApi.list(projectId, {
      ...board,
      page,
      limit: PAGE_SIZE,
      columnId: columnFilter ?? undefined,
    }),
    enabled: !!projectId,
    staleTime: 0,
    refetchOnMount: 'always',
  })
  const rows = useMemo(() => tasksResult?.data ?? [], [tasksResult?.data])
  const meta = tasksResult?.meta

  const { mutate: updateTask } = useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: UpdateTaskDto }) => tasksApi.update(projectId, id, dto),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['list-tasks', projectId] }),
    onError: () => toast.error(t('taskDetail.updateFailed')),
  })

  const columnName = columnFilter ? columns.find((c) => c.id === columnFilter)?.name : null

  const clearColumn = () => setSearchParams((p) => { p.delete('column'); return p }, { replace: true })
  const fmt = (v: string | null | undefined) => (v ? formatZonedDate(v, timezone) : '—')

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <div className="px-6 py-4 border-b border-border shrink-0 space-y-3">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-base font-semibold text-fg">{t('nav.list')}</h1>
            <p className="text-xs text-fg-muted mt-0.5">{project?.name ?? t('nav.list')} · {t('board.tasksCount', { count: meta?.total ?? 0 })}</p>
          </div>
          {columnFilter && (
            <button onClick={clearColumn} className="inline-flex items-center gap-1.5 rounded-lg border border-accent/40 bg-accent/10 px-2.5 h-8 text-xs text-accent shrink-0">
              {columnName ?? t('filter.status')} <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
        <FilterBar projectId={projectId} />
      </div>

      <div className="flex-1 overflow-auto scrollbar-thin p-6">
        {isLoading ? (
          <div className="space-y-2">{[...Array(8)].map((_, i) => <Skeleton key={i} className="h-12 w-full rounded-lg" />)}</div>
        ) : rows.length === 0 ? (
          <EmptyState icon={<ListTodo className="w-12 h-12" />} title={t('myTasks.emptyTitle')} />
        ) : (
          <div className="rounded-card border border-border overflow-hidden">
            <div className="overflow-x-auto scrollbar-thin">
              <table className="w-full text-sm">
              <thead>
                <tr className="bg-bg-subtle text-left text-xs text-fg-muted">
                  <TableHeader>{t('list.colWork')}</TableHeader><TableHeader>{t('taskDetail.fAssignee')}</TableHeader><TableHeader>{t('taskDetail.reporter')}</TableHeader><TableHeader>{t('taskDetail.fPriority')}</TableHeader>
                  <TableHeader>{t('taskDetail.fStatus')}</TableHeader><TableHeader>{t('list.colCreated')}</TableHeader><TableHeader>{t('list.colUpdated')}</TableHeader><TableHeader>{t('taskDetail.fDueDate')}</TableHeader>
                </tr>
              </thead>
              <tbody>
                {rows.map((tk) => {
                  const pr = PRIORITY_ICON[tk.priority] ?? PRIORITY_ICON.medium
                  const prLabel = t('priority.' + tk.priority)
                  const overdue = tk.dueDate && tk.dueDate < new Date().toISOString().slice(0, 10) && tk.status !== 'done'
                  return (
                    <tr key={tk.id} className="border-t border-border hover:bg-bg-subtle/40">
                      <td className="px-4 py-2.5">
                        <button onClick={() => setOpenTaskId(tk.id)} className="flex items-center gap-2 min-w-0 text-left group">
                          {tk.parentTaskId ? <SubtaskIcon size={14} /> : <TaskIcon size={14} />}
                          <span className="text-xs font-mono text-fg-subtle shrink-0">{projectKey}-{tk.taskNumber ?? '—'}</span>
                          <span className="font-medium text-fg truncate group-hover:text-accent transition-colors">{tk.title}</span>
                        </button>
                      </td>
                      <td className="px-4 py-2.5">
                        <AssigneeCell task={tk} members={members} disabled={!canAssign} onPick={(userId) => updateTask({ id: tk.id, dto: { assigneeId: userId } })} />
                      </td>
                      <td className="px-4 py-2.5"><UserCell user={tk.reporter} /></td>
                      <td className="px-4 py-2.5">
                        <span className="inline-flex items-center gap-1.5 text-xs text-fg-muted whitespace-nowrap">
                          <img src={pr.svg} width={14} height={14} alt={prLabel} className="shrink-0" />{prLabel}
                        </span>
                      </td>
                      <td className="px-4 py-2.5">
                        <StatusCell task={tk} columns={columns} disabled={!canUpdate} onPick={(columnId) => updateTask({ id: tk.id, dto: { columnId } })} />
                      </td>
                      <td className="px-4 py-2.5 text-xs text-fg-muted whitespace-nowrap">{fmt(tk.createdAt)}</td>
                      <td className="px-4 py-2.5 text-xs text-fg-muted whitespace-nowrap">{fmt(tk.updatedAt)}</td>
                      <td className={cn('px-4 py-2.5 text-xs whitespace-nowrap', overdue ? 'text-danger font-medium' : 'text-fg-muted')}>{fmt(tk.dueDate)}</td>
                    </tr>
                  )
                })}
              </tbody>
              </table>
            </div>
            {meta && meta.totalPages > 1 && (
              <div className="flex items-center justify-between gap-4 border-t border-border px-4 py-3">
                <span className="text-xs text-fg-muted">
                  {((meta.page - 1) * meta.limit) + 1}–{Math.min(meta.page * meta.limit, meta.total)} / {meta.total} task
                </span>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setPage(Math.max(1, page - 1))}
                    disabled={meta.page <= 1}
                    aria-label={t('list.prevPage')}
                    className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-border text-fg-muted hover:bg-bg-subtle hover:text-fg disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                  <span className="min-w-20 text-center text-xs text-fg-muted">
                    {meta.page} / {meta.totalPages}
                  </span>
                  <button
                    type="button"
                    onClick={() => setPage(Math.min(meta.totalPages, page + 1))}
                    disabled={meta.page >= meta.totalPages}
                    aria-label={t('list.nextPage')}
                    className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-border text-fg-muted hover:bg-bg-subtle hover:text-fg disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    <ChevronRight className="h-4 w-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      <TaskDetailModal
        task={null}
        taskId={openTaskId}
        projectId={projectId}
        projectKey={projectKey}
        open={!!openTaskId}
        onClose={() => { setOpenTaskId(null); qc.invalidateQueries({ queryKey: ['list-tasks', projectId] }) }}
        onOpenTask={(id) => setOpenTaskId(id)}
      />
    </div>
  )
}
