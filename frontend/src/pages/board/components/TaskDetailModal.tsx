import { useSiteTimezone } from '@/hooks/useSiteTimezone'
/* eslint-disable react-hooks/set-state-in-effect */
import { useState, useRef, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { createPortal } from 'react-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  X, ExternalLink, MoreHorizontal, Eye, EyeOff, Share2, Lock,
  Plus, ChevronDown, ChevronRight, Bold, List, Code2,
  Link2, Check, Calendar, Flag, User, Tag,
  Zap, GitBranch, AlignLeft, CheckSquare, Trash2, Pencil,
  Italic, Underline as UnderlineIcon, Strikethrough, ListOrdered,
  Quote, FileCode, Image as ImageIcon, Highlighter,
  AlignCenter, AlignRight, Undo, Redo,
  Paperclip, Download, FileText,
} from 'lucide-react'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import TiptapUnderline from '@tiptap/extension-underline'
import TextAlign from '@tiptap/extension-text-align'
import { SecureImage } from './SecureImage'
import TiptapLink from '@tiptap/extension-link'
import Placeholder from '@tiptap/extension-placeholder'
import Highlight from '@tiptap/extension-highlight'
import { tasksApi, type Task, type UpdateTaskDto, type TaskUser } from '@/api/tasks'
import { commentsApi, type Comment } from '@/api/comments'
import { membersApi } from '@/api/members'
import { labelsApi } from '@/api/labels'
import { requestersApi } from '@/api/requesters'
import { columnsApi, type BoardColumn } from '@/api/columns'
import { attachmentsApi } from '@/api/attachments'
import { apiClient } from '@/api/client'
import { Avatar, Button, ConfirmDialog, Dropdown, Skeleton } from '@/components/ui'
import { TaskIcon, SubtaskIcon } from '@/components/ui/TaskIcons'
import { useAuthStore } from '@/stores/useAuthStore'
import { usePermissions } from '@/hooks/usePermissions'
import { useTaskStore } from '@/stores/useTaskStore'
import { useToast } from '@/hooks/useToast'
import { cn, formatRelative } from '@/lib/utils'
import { formatZonedDate, formatZonedDateTime } from '@/lib/timezones'

// ─── Types ────────────────────────────────────────────────────────────────────

interface TaskLink {
  id: string
  sourceTaskId: string
  targetTaskId: string
  linkType: 'blocks' | 'blocked_by' | 'relates_to'
  sourceTask: Task
  targetTask: Task
}

type TabType = 'all' | 'comments' | 'history' | 'worklog'

const LINK_TYPE_LABEL_KEYS: Record<string, string> = {
  blocks: 'linkTypeBlocks',
  blocked_by: 'linkTypeBlockedBy',
  relates_to: 'linkTypeRelatesTo',
}

const STATUS_CONFIG: Record<string, { color: string; bg: string; hexBg: string; hexColor: string }> = {
  todo:        { color: 'text-fg-muted',  bg: 'bg-bg-subtle',   hexBg: '#F4F5F7', hexColor: '#42526E' },
  in_progress: { color: 'text-info',      bg: 'bg-info/10',     hexBg: '#0052CC', hexColor: '#FFFFFF' },
  in_review:   { color: 'text-warning',   bg: 'bg-warning/10',  hexBg: '#6554C0', hexColor: '#FFFFFF' },
  done:        { color: 'text-success',   bg: 'bg-success/10',  hexBg: '#00875A', hexColor: '#FFFFFF' },
}

const PRIORITY_CONFIG: Record<string, { color: string; svg: string; hexColor: string }> = {
  urgent: { color: 'text-danger',   svg: '/priority/highest_new.svg', hexColor: '#F15B50' },
  high:   { color: 'text-warning',  svg: '/priority/high_new.svg',    hexColor: '#F15B50' },
  medium: { color: 'text-info',     svg: '/priority/medium_new.svg',  hexColor: '#E06C00' },
  low:    { color: 'text-fg-muted', svg: '/priority/low_new.svg',     hexColor: '#4688EC' },
  lowest: { color: 'text-fg-subtle',svg: '/priority/lowest_new.svg',  hexColor: '#8899BB' },
}

const DEFAULT_AVATAR = '/default-avatar.jpg'

// ─── Time Helpers ─────────────────────────────────────────────────────────────

// 1w=5d, 1d=8h — same convention as Jira
function parseTimeInput(input: string): number {
  const re = /(\d+(?:\.\d+)?)\s*(w|d|h|m)\b/gi
  let hours = 0
  let m: RegExpExecArray | null
  while ((m = re.exec(input)) !== null) {
    const v = parseFloat(m[1])
    switch (m[2].toLowerCase()) {
      case 'w': hours += v * 40; break
      case 'd': hours += v * 8; break
      case 'h': hours += v; break
      case 'm': hours += v / 60; break
    }
  }
  return hours
}

function formatTimeHours(totalHours: number): string {
  if (!totalHours || totalHours < 0) return '0h'
  const totalMins = Math.round(totalHours * 60)
  const w = Math.floor(totalMins / (40 * 60))
  const d = Math.floor((totalMins % (40 * 60)) / (8 * 60))
  const h = Math.floor((totalMins % (8 * 60)) / 60)
  const m = totalMins % 60
  const parts: string[] = []
  if (w) parts.push(`${w}w`)
  if (d) parts.push(`${d}d`)
  if (h) parts.push(`${h}h`)
  if (m) parts.push(`${m}m`)
  return parts.length ? parts.join(' ') : '0h'
}

// ─── Main Modal ───────────────────────────────────────────────────────────────


interface Props {
  task: Task | null
  taskId?: string | null
  projectId: string
  projectKey?: string
  open: boolean
  onClose: () => void
  onOpenTask?: (taskId: string) => void
  /** 'modal' = overlay dialog (default); 'page' = full-page Jira-style view. */
  variant?: 'modal' | 'page'
}

export function TaskDetailModal({ task, taskId, projectId, projectKey = 'TASK', open, onClose, onOpenTask, variant = 'modal' }: Props) {
  const { t: tr } = useTranslation()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const toast = useToast()
  const permissions = usePermissions()
  const canDeleteTask = permissions.includes('approve_task')
  const canArchiveTask = permissions.includes('update_own_task')
  const [tab, setTab] = useState<TabType>('comments')
  // Bumped by the "Add child task" header button to open + focus the subtask input.
  const [addSubtaskSignal, setAddSubtaskSignal] = useState(0)

  const targetId = task?.id ?? taskId
  // Reset the add-subtask signal when switching tasks so a stale "open" from one
  // task doesn't carry over and auto-open the input on every other task.
  const prevTargetRef = useRef(targetId)
  if (prevTargetRef.current !== targetId) {
    prevTargetRef.current = targetId
    if (addSubtaskSignal !== 0) setAddSubtaskSignal(0)
  }

  // Store side-effect: update store on success so TaskCard re-renders instantly
  const updateTaskInStore = useTaskStore((s) => s.updateTask)

  // freshTask is the authoritative source (has subtasks, parentTask relations from findById)
  // staleTime=0 ensures we always get fresh data including subtasks on every open
  const { data: freshTask, isLoading: isFetchingTask } = useQuery({
    queryKey: ['task', projectId, targetId],
    queryFn: () => tasksApi.get(projectId, targetId!),
    enabled: open && !!targetId,
    staleTime: 0,
  })
  // freshTask is primary (has full relations); fall back to prop for immediate display
  const t = freshTask ?? task

  const { mutate: updateTask } = useMutation({
    mutationFn: (dto: UpdateTaskDto) => tasksApi.update(projectId, t!.id, dto),
    onMutate: (dto) => {
      if (t) {
        // For (qa)assigneeId changes, look up full user object from cached members
        let enriched: Partial<Task> = dto
        type M = { userId: string; user: { id: string; fullName: string; email: string; avatarUrl: string | null } }
        const cachedMembers = qc.getQueryData<M[]>(['members', projectId]) ?? []
        if ('assigneeId' in dto) {
          enriched = { ...enriched, assignee: cachedMembers.find((m) => m.userId === dto.assigneeId)?.user ?? null }
        }
        if ('qaAssigneeId' in dto) {
          enriched = { ...enriched, qaAssignee: cachedMembers.find((m) => m.userId === dto.qaAssigneeId)?.user ?? null }
        }
        // Update query cache for immediate display in modal
        qc.setQueryData(['task', projectId, t.id], { ...t, ...enriched })
        // Update store so TaskCard re-renders optimistically
        updateTaskInStore(t.id, enriched)
      }
    },
    onSuccess: (updated) => {
      // Confirm with full server response (has assignee object, subtasks, etc.)
      updateTaskInStore(updated.id, updated)
      qc.setQueryData(['task', projectId, updated.id], updated)
      qc.setQueriesData(
        { queryKey: ['tasks', projectId] },
        (old: { data: Task[]; meta: unknown } | undefined) => {
          if (!old) return old
          return { ...old, data: old.data.map((tk) => (tk.id === updated.id ? updated : tk)) }
        },
      )
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
    },
    onError: () => {
      // Rollback: re-fetch fresh server state
      qc.invalidateQueries({ queryKey: ['task', projectId, t?.id] })
      toast.error(tr('taskDetail.updateFailed'))
    },
  })

  const [confirmAction, setConfirmAction] = useState<'delete' | 'archive' | null>(null)

  const { mutate: deleteTask, isPending: deletingTask } = useMutation({
    mutationFn: () => tasksApi.delete(projectId, t!.id),
    onSuccess: () => {
      const taskId = t!.id
      const title = t!.title
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
      setConfirmAction(null)
      onClose()
      toast.undo(tr('taskDetail.deletedUndo', { title }), () => {
        tasksApi.restore(projectId, taskId)
          .then(() => {
            qc.invalidateQueries({ queryKey: ['tasks', projectId] })
            toast.success(tr('taskDetail.restoredTask'))
          })
          .catch(() => toast.error(tr('taskDetail.undoFailed')))
      })
    },
    onError: () => toast.error(tr('taskDetail.deleteFailed')),
  })

  const { mutate: archiveTask, isPending: archivingTask } = useMutation({
    mutationFn: () => tasksApi.archive(projectId, t!.id),
    onSuccess: () => {
      const title = t!.title
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
      setConfirmAction(null)
      onClose()
      toast.success(tr('taskDetail.archivedUndo', { title }))
    },
    onError: () => toast.error(tr('taskDetail.archiveFailed')),
  })

  useEffect(() => {
    // Page variant lives inside the app layout — don't trap Escape or lock body scroll.
    if (!open || variant === 'page') return
    const handler = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    document.addEventListener('keydown', handler)
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', handler)
      document.body.style.overflow = ''
    }
  }, [open, onClose, variant])

  if (!open) return null

  const taskDisplayId = t?.taskNumber != null
    ? `${projectKey}-${t.taskNumber}`
    : t ? `${projectKey}-${(t.position ?? 0) + 1}` : '…'

  const inner = (
    <>
      {/* Header — 56px height, 24px horizontal padding */}
      <DetailHeader
        displayId={taskDisplayId}
        parentTask={t?.parentTask ?? null}
        projectKey={projectKey}
        projectId={projectId}
        taskId={t?.id ?? null}
        watcherCount={t?.watcherCount ?? 0}
        isWatching={t?.isWatching ?? false}
        onClose={onClose}
        onOpenParent={onOpenTask}
        onDelete={t && canDeleteTask ? () => setConfirmAction('delete') : undefined}
        onArchive={t && canArchiveTask ? () => setConfirmAction('archive') : undefined}
        onOpenFullPage={variant === 'modal' && t ? () => navigate(`/projects/${projectId}/tasks/${t.id}`) : undefined}
      />

      {/* Loading overlay while fetching subtask */}
      {isFetchingTask && !t && (
        <div className="flex-1 flex items-center justify-center">
          <div className="flex flex-col items-center gap-3 text-fg-muted">
            <div className="w-8 h-8 rounded-full border-2 border-accent border-t-transparent animate-spin" />
            <span className="text-sm">{tr('taskDetail.loading')}</span>
          </div>
        </div>
      )}

      {/* Body: left + right — only when task data available */}
      {t && <div className="flex flex-1 min-h-0">
          {/* Left column — scrollable, 40px horizontal / 32px vertical padding */}
          <div className="flex-1 min-w-0 scrollbar-overlay px-10 py-8 space-y-5">
            {/* Title */}
            <TitleEditor task={t} onSave={(title) => updateTask({ title })} />

            {/* Action buttons under title */}
            <div className="flex items-center gap-1.5 -mt-2">
              <button
                title={tr('taskDetail.addChildTask')}
                onClick={() => setAddSubtaskSignal((n) => n + 1)}
                className="flex items-center gap-1 px-2 py-1 rounded-md text-xs text-fg-muted border border-border hover:border-accent/50 hover:text-accent transition-colors"
              >
                <Plus className="w-3 h-3" /> {tr('taskDetail.child')}
              </button>
            </div>

            {/* Description */}
            <DescriptionEditor task={t} onSave={(description) => updateTask({ description })} />

            {/* Subtasks */}
            <SubtasksSection key={t.id} task={t} projectId={projectId} projectKey={projectKey} onSubtaskClick={onOpenTask} openAddSignal={addSubtaskSignal} />

            {/* Linked items */}
            <LinkedItemsSection task={t} projectId={projectId} />

            {/* Attachments */}
            <AttachmentsSection task={t} projectId={projectId} />

            {/* Activity tabs */}
            <div>
              <div className="flex gap-1 border-b border-border mb-4">
                {(['all', 'comments', 'history', 'worklog'] as TabType[]).map((id) => {
                  const labels = { all: tr('taskDetail.tabAll'), comments: tr('taskDetail.tabComments'), history: tr('taskDetail.tabHistory'), worklog: tr('taskDetail.tabWorklog') }
                  return (
                    <button
                      key={id}
                      onClick={() => setTab(id)}
                      className={cn(
                        'px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
                        tab === id ? 'border-accent text-accent' : 'border-transparent text-fg-muted hover:text-fg'
                      )}
                    >
                      {labels[id]}
                    </button>
                  )
                })}
              </div>

              {tab === 'all'      && <AllTab projectId={projectId} taskId={t.id} />}
              {tab === 'comments' && <CommentsTab projectId={projectId} taskId={t.id} />}
              {tab === 'history'  && <HistoryTab projectId={projectId} taskId={t.id} />}
              {tab === 'worklog'  && <WorkLogTab task={t} onUpdate={updateTask} />}
            </div>
          </div>

          {/* Right column — sticky */}
          <RightColumn
            task={t}
            projectId={projectId}
            projectKey={projectKey}
            onUpdate={updateTask}
          />
        </div>}
    </>
  )

  const dialogs = (
    <>
      <ConfirmDialog
        open={confirmAction === 'delete'}
        onClose={() => setConfirmAction(null)}
        onConfirm={() => deleteTask()}
        title={tr('taskDetail.deleteTitle')}
        message={tr('taskDetail.deleteMsg', { title: t?.title ?? '' })}
        confirmLabel={tr('taskDetail.deletePermanent')}
        requireText="delete"
        loading={deletingTask}
      />
      <ConfirmDialog
        open={confirmAction === 'archive'}
        onClose={() => setConfirmAction(null)}
        onConfirm={() => archiveTask()}
        title={tr('taskDetail.archiveTitle')}
        message={tr('taskDetail.archiveMsg', { title: t?.title ?? '' })}
        confirmLabel={tr('taskDetail.archiveConfirm')}
        requireText="archive"
        danger={false}
        loading={archivingTask}
      />
    </>
  )

  // Full-page Jira-style view — fills the app layout content area, no overlay.
  if (variant === 'page') {
    return (
      <>
        <div data-testid="task-detail-page" className="flex flex-col h-full overflow-hidden bg-bg-surface">
          {inner}
        </div>
        {dialogs}
      </>
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-[2px]" onClick={onClose} />

      {/* Panel — responsive sizing per spec */}
      <div
        data-testid="task-detail-modal"
        className={cn(
          'relative flex flex-col border border-border bg-bg-surface shadow-app-lg overflow-hidden animate-modal-enter',
          // mobile/tablet: full screen
          'w-screen h-screen rounded-none',
          // ≥1024px: 92vw × 88vh
          'lg:w-[92vw] lg:h-[88vh] lg:rounded-lg',
          // ≥1280px: min(1200px,90vw) × min(860px,90vh)
          'xl:w-[min(1200px,90vw)] xl:h-[min(860px,90vh)] xl:max-w-modal-fhd',
          // ≥1536px (2K+): min(1400px,88vw) × min(920px,88vh)
          '2xl:w-[min(1400px,88vw)] 2xl:h-[min(920px,88vh)] 2xl:max-w-modal-2k',
        )}
      >
        {inner}
      </div>

      {dialogs}
    </div>
  )
}

// ─── Watch Button (Jira-style watchers) ──────────────────────────────────────

function WatchButton({ projectId, taskId, initialCount, initialWatching }: {
  projectId: string; taskId: string | null; initialCount: number; initialWatching: boolean
}) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const meId = useAuthStore((s) => s.user?.id)
  const [open, setOpen] = useState(false)
  const [adding, setAdding] = useState(false)
  const [search, setSearch] = useState('')
  const btnRef = useRef<HTMLButtonElement>(null)
  const [pos, setPos] = useState({ top: 0, right: 0 })

  const watchersQuery = useQuery({
    queryKey: ['watchers', projectId, taskId],
    queryFn: () => tasksApi.listWatchers(projectId, taskId!),
    enabled: open && !!taskId,
  })
  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
    enabled: open && adding && !!projectId,
  })

  const watchers = watchersQuery.data
  const count = watchers ? watchers.length : initialCount
  const watching = watchers ? watchers.some((w) => w.id === meId) : initialWatching

  const applyList = (list: TaskUser[]) => {
    qc.setQueryData(['watchers', projectId, taskId], list)
    // Refresh the task payload so header count/isWatching reseed (and other pages sync).
    if (taskId) qc.invalidateQueries({ queryKey: ['task', projectId, taskId] })
  }
  const watchMut = useMutation({
    mutationFn: (userId?: string) => tasksApi.watch(projectId, taskId!, userId),
    onSuccess: applyList,
    onError: () => toast.error(tr('taskDetail.updateFailed')),
  })
  const unwatchMut = useMutation({
    mutationFn: (userId: string) => tasksApi.unwatch(projectId, taskId!, userId),
    onSuccess: applyList,
    onError: () => toast.error(tr('taskDetail.updateFailed')),
  })

  const toggle = () => {
    if (!taskId) return
    if (!open && btnRef.current) {
      const r = btnRef.current.getBoundingClientRect()
      setPos({ top: r.bottom + 6, right: Math.max(8, window.innerWidth - r.right) })
    }
    setOpen((v) => !v)
  }

  const watcherIds = new Set((watchers ?? []).map((w) => w.id))
  const q = search.trim().toLowerCase()
  const addable = members.filter((m) => !watcherIds.has(m.userId) && m.user.fullName.toLowerCase().includes(q))

  return (
    <>
      <button
        ref={btnRef}
        onClick={toggle}
        disabled={!taskId}
        title={tr('taskDetail.watch')}
        className={cn(
          'h-7 px-1.5 flex items-center gap-1 rounded-md transition-colors disabled:opacity-50',
          watching ? 'text-accent hover:bg-accent/10' : 'text-fg-subtle hover:text-fg hover:bg-bg-subtle',
        )}
      >
        <Eye className="w-3.5 h-3.5" />
        {count > 0 && <span className="text-xs font-medium tabular-nums">{count}</span>}
      </button>

      {open && taskId && createPortal(
        <>
          <div className="fixed inset-0 z-[9998]" onClick={() => { setOpen(false); setAdding(false) }} />
          <div
            className="fixed z-[9999] w-72 rounded-lg border border-border bg-bg-surface shadow-app-lg overflow-hidden"
            style={{ top: pos.top, right: pos.right }}
          >
            <div className="flex items-center justify-between gap-2 px-3 py-2 border-b border-border">
              <span className="text-xs font-semibold text-fg">{tr('taskDetail.watchers')} · {count}</span>
              <button
                onClick={() => (watching ? unwatchMut.mutate(meId!) : watchMut.mutate(undefined))}
                disabled={watchMut.isPending || unwatchMut.isPending || !meId}
                className={cn(
                  'inline-flex items-center gap-1 px-2 py-1 rounded-md text-xs font-medium transition-colors disabled:opacity-50',
                  watching ? 'border border-border text-fg-muted hover:bg-bg-subtle' : 'bg-accent text-white hover:bg-accent/90',
                )}
              >
                {watching
                  ? <><EyeOff className="w-3 h-3" /> {tr('taskDetail.stopWatching')}</>
                  : <><Eye className="w-3 h-3" /> {tr('taskDetail.startWatching')}</>}
              </button>
            </div>

            <div className="max-h-56 overflow-y-auto scrollbar-thin py-1">
              {watchersQuery.isLoading ? (
                <div className="px-3 py-3 text-xs text-fg-subtle">{tr('taskDetail.loading')}</div>
              ) : watchers && watchers.length > 0 ? (
                watchers.map((w) => (
                  <div key={w.id} className="group flex items-center gap-2 px-3 py-1.5 hover:bg-bg-subtle">
                    <Avatar name={w.fullName} avatarUrl={w.avatarUrl} size="xs" />
                    <span className="text-xs text-fg truncate flex-1">{w.fullName}{w.id === meId && ` (${tr('common.you')})`}</span>
                    <button
                      onClick={() => unwatchMut.mutate(w.id)}
                      className="opacity-0 group-hover:opacity-100 text-fg-subtle hover:text-danger transition"
                      title={tr('taskDetail.removeWatcher')}
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))
              ) : (
                <div className="px-3 py-3 text-xs text-fg-subtle">{tr('taskDetail.watchersEmpty')}</div>
              )}
            </div>

            <div className="border-t border-border">
              {!adding ? (
                <button
                  onClick={() => setAdding(true)}
                  className="w-full flex items-center gap-1.5 px-3 py-2 text-xs text-fg-muted hover:bg-bg-subtle transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" /> {tr('taskDetail.addWatcher')}
                </button>
              ) : (
                <div className="p-2">
                  <input
                    autoFocus
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder={tr('taskDetail.searchMembers')}
                    className="w-full h-8 rounded-md border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent mb-1"
                  />
                  <div className="max-h-40 overflow-y-auto scrollbar-thin">
                    {addable.length === 0 ? (
                      <div className="px-2 py-2 text-xs text-fg-subtle">{tr('taskDetail.noMembersToAdd')}</div>
                    ) : (
                      addable.map((m) => (
                        <button
                          key={m.userId}
                          onClick={() => { watchMut.mutate(m.userId); setSearch('') }}
                          className="w-full flex items-center gap-2 px-2 py-1.5 rounded-md hover:bg-bg-subtle transition-colors text-left"
                        >
                          <Avatar name={m.user.fullName} avatarUrl={m.user.avatarUrl} size="xs" />
                          <span className="text-xs text-fg truncate">{m.user.fullName}</span>
                        </button>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </>,
        document.body,
      )}
    </>
  )
}

// ─── Detail Header ────────────────────────────────────────────────────────────

function DetailHeader({ displayId, parentTask, projectKey = 'TASK', projectId, taskId, watcherCount = 0, isWatching = false, onClose, onOpenParent, onDelete, onArchive, onOpenFullPage }: {
  displayId: string
  parentTask: Task | null | undefined
  projectKey?: string
  projectId: string
  taskId: string | null
  watcherCount?: number
  isWatching?: boolean
  onClose: () => void
  onOpenParent?: (taskId: string) => void
  onDelete?: () => void
  onArchive?: () => void
  /** When set, renders the "open full page" button (modal variant only). */
  onOpenFullPage?: () => void
}) {
  const { t: tr } = useTranslation()
  const toast = useToast()

  const copyId = () => {
    navigator.clipboard.writeText(displayId)
    toast.success(tr('taskDetail.taskIdCopied'))
  }

  const parentDisplayId = parentTask?.taskNumber != null
    ? `${projectKey}-${parentTask.taskNumber}`
    : parentTask ? `${projectKey}-${(parentTask.position ?? 0) + 1}` : null

  return (
    <div className="flex items-center gap-2 h-14 px-6 border-b border-border shrink-0 bg-bg-surface">
      {/* Breadcrumb */}
      <div className="flex items-center gap-1.5 flex-1 min-w-0 text-xs text-fg-muted overflow-hidden">
        {parentTask ? (
          <>
            <button
              onClick={() => onOpenParent?.(parentTask.id)}
              title={tr('taskDetail.openParent', { id: parentDisplayId, title: parentTask.title })}
              className="flex items-center gap-1 px-1.5 py-0.5 rounded bg-bg-subtle border border-border hover:border-accent/50 hover:text-accent transition-colors font-mono shrink-0"
            >
              <CheckSquare className="w-3 h-3" />
              <span className="max-w-[120px] truncate">{parentDisplayId} {parentTask.title}</span>
            </button>
            <span className="shrink-0">/</span>
          </>
        ) : (
          <>
          </>
        )}
        <button
          onClick={copyId}
          title={tr('taskDetail.copyTaskId')}
          className="flex items-center gap-1 px-1.5 py-0.5 rounded bg-bg-subtle border border-border hover:border-accent/50 hover:text-fg transition-colors font-mono shrink-0"
        >
          <TaskIcon size={12} />
          {displayId}
        </button>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-0.5">
        <WatchButton
          projectId={projectId}
          taskId={taskId}
          initialCount={watcherCount}
          initialWatching={isWatching}
        />
        <button
          title={tr('taskDetail.share')}
          className="h-7 w-7 flex items-center justify-center rounded-md text-fg-subtle hover:text-fg hover:bg-bg-subtle transition-colors"
          onClick={() => { navigator.clipboard.writeText(window.location.href); toast.success(tr('taskDetail.linkCopied')) }}
        >
          <Share2 className="w-3.5 h-3.5" />
        </button>

        <Dropdown
          trigger={
            <button className="h-7 w-7 flex items-center justify-center rounded-md text-fg-subtle hover:text-fg hover:bg-bg-subtle transition-colors">
              <MoreHorizontal className="w-3.5 h-3.5" />
            </button>
          }
          align="right"
          items={[
            { label: tr('taskDetail.copyLink'), icon: <Link2 className="w-4 h-4" />, onClick: () => navigator.clipboard.writeText(window.location.href) },
            { label: tr('taskDetail.duplicate'), icon: <AlignLeft className="w-4 h-4" />, onClick: () => toast.info(tr('taskDetail.duplicateNotSupported')) },
            { label: tr('taskDetail.archiveConfirm'), icon: <Lock className="w-4 h-4" />, onClick: () => onArchive?.(), disabled: !onArchive },
            { label: tr('common.delete'), icon: <Trash2 className="w-4 h-4" />, onClick: () => onDelete?.(), danger: true, disabled: !onDelete },
          ]}
        />

        {onOpenFullPage && (
          <button
            title={tr('taskDetail.openFullPage')}
            onClick={onOpenFullPage}
            className="h-7 w-7 flex items-center justify-center rounded-md text-fg-subtle hover:text-fg hover:bg-bg-subtle transition-colors"
          >
            <ExternalLink className="w-3.5 h-3.5" />
          </button>
        )}

        <button
          title={tr('taskDetail.close')}
          onClick={onClose}
          className="h-7 w-7 flex items-center justify-center rounded-md text-fg-subtle hover:text-fg hover:bg-bg-subtle transition-colors"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}

// ─── Title Editor ─────────────────────────────────────────────────────────────

function TitleEditor({ task, onSave }: { task: Task; onSave: (t: string) => void }) {
  const [editing, setEditing] = useState(false)
  const [value, setValue] = useState(task.title)

  const commit = () => {
    setEditing(false)
    if (value.trim() && value !== task.title) onSave(value.trim())
    else setValue(task.title)
  }

  if (editing) {
    return (
      <textarea
        autoFocus
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); commit() }
          if (e.key === 'Escape') { setValue(task.title); setEditing(false) }
        }}
        rows={2}
        className="w-full bg-transparent border-b-2 border-accent text-2xl font-bold text-fg resize-none focus:outline-none leading-tight pb-1"
      />
    )
  }

  return (
    <h1
      className="text-2xl font-bold text-fg leading-tight cursor-pointer hover:text-accent/90 transition-colors"
      onClick={() => { setEditing(true); setValue(task.title) }}
    >
      {task.title}
    </h1>
  )
}

// ─── Description Editor ───────────────────────────────────────────────────────

function EditorToolbarBtn({ children, title, onClick, active = false, disabled = false }: {
  children: React.ReactNode; title: string; onClick: () => void; active?: boolean; disabled?: boolean
}) {
  return (
    <button
      type="button"
      title={title}
      onMouseDown={(e) => { e.preventDefault(); onClick() }}
      disabled={disabled}
      className={cn(
        'h-6 w-6 flex items-center justify-center rounded transition-colors text-sm',
        active ? 'bg-accent/20 text-accent' : 'text-fg-muted hover:text-fg hover:bg-bg-elevated',
        disabled && 'opacity-40 cursor-not-allowed',
      )}
    >
      {children}
    </button>
  )
}

function EditorToolbarSep() {
  return <div className="w-px h-4 bg-border mx-0.5 shrink-0" />
}

function DescriptionEditor({ task, onSave }: { task: Task; onSave: (d: string) => void }) {
  const { t: tr } = useTranslation()
  const [dirty, setDirty] = useState(false)
  const [pending, setPending] = useState<File[]>([])
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState<Record<number, number>>({})
  const toast = useToast()
  const qc = useQueryClient()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const attachInputRef = useRef<HTMLInputElement>(null)

  const editor = useEditor({
    extensions: [
      StarterKit,
      TiptapUnderline,
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      SecureImage.configure({ allowBase64: false, inline: false, projectId: task.projectId }),
      TiptapLink.configure({ openOnClick: false }),
      Placeholder.configure({ placeholder: tr('taskDetail.descPlaceholder') }),
      Highlight,
    ],
    content: task.description ?? '',
    onUpdate: () => setDirty(true),
  })

  // Reset when switching to a different task
  useEffect(() => {
    if (editor && !editor.isDestroyed) {
      editor.commands.setContent(task.description ?? '')
      setDirty(false)
    }
    setPending([])
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [task.id])

  const save = async () => {
    if (!editor) return
    if (pending.length > 0) {
      setUploading(true)
      setProgress({})
      const count = pending.length
      try {
        for (let i = 0; i < pending.length; i++) {
          await attachmentsApi.upload(task.projectId, task.id, pending[i], (p) =>
            setProgress((prev) => ({ ...prev, [i]: p })),
          )
        }
        await qc.invalidateQueries({ queryKey: ['task-attachments', task.projectId, task.id] })
        setPending([])
        setProgress({})
        toast.success(tr('taskDetail.filesAdded', { count }))
      } catch {
        toast.error(tr('taskDetail.uploadFailed'))
      } finally {
        setUploading(false)
      }
    }
    if (dirty) onSave(editor.getHTML())
    setDirty(false)
  }
  const cancel = () => {
    if (!editor) return
    editor.commands.setContent(task.description ?? '')
    setDirty(false)
    setPending([])
    setProgress({})
  }

  const handleAttachFiles = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files ?? [])
    if (attachInputRef.current) attachInputRef.current.value = ''
    if (files.length) setPending((prev) => [...prev, ...files])
  }

  const setLink = () => {
    const prev = editor?.getAttributes('link').href ?? ''
    const url = window.prompt(tr('taskDetail.urlPrompt'), prev)
    if (url === null) return
    if (!url) {
      editor?.chain().focus().extendMarkRange('link').unsetLink().run()
    } else {
      editor?.chain().focus().extendMarkRange('link').setLink({ href: url }).run()
    }
  }

  const handleImageFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (fileInputRef.current) fileInputRef.current.value = ''
    try {
      const att = await attachmentsApi.upload(task.projectId, task.id, file)
      editor?.chain().focus().setImage({ src: att.fileUrl }).run()
    } catch {
      toast.error(tr('taskDetail.imageUploadFailed'))
    }
  }

  if (!editor) return null

  return (
    <div>
      <p className="text-sm font-semibold text-fg mb-2">{tr('taskDetail.description')}</p>

      <div className="rounded-lg border border-border overflow-hidden focus-within:ring-2 focus-within:ring-accent transition-shadow">
        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-0.5 px-2 py-1.5 border-b border-border bg-bg-subtle">
          <EditorToolbarBtn title={tr('taskDetail.toolbarUndo')} onClick={() => editor.chain().focus().undo().run()} disabled={!editor.can().undo()}>
            <Undo className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarRedo')} onClick={() => editor.chain().focus().redo().run()} disabled={!editor.can().redo()}>
            <Redo className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarBold')} onClick={() => editor.chain().focus().toggleBold().run()} active={editor.isActive('bold')}>
            <Bold className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarItalic')} onClick={() => editor.chain().focus().toggleItalic().run()} active={editor.isActive('italic')}>
            <Italic className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarUnderline')} onClick={() => editor.chain().focus().toggleUnderline().run()} active={editor.isActive('underline')}>
            <UnderlineIcon className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarStrikethrough')} onClick={() => editor.chain().focus().toggleStrike().run()} active={editor.isActive('strike')}>
            <Strikethrough className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarHeading1')} onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()} active={editor.isActive('heading', { level: 1 })}>
            <span className="text-[10px] font-bold leading-none">H1</span>
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarHeading2')} onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()} active={editor.isActive('heading', { level: 2 })}>
            <span className="text-[10px] font-bold leading-none">H2</span>
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarBulletList')} onClick={() => editor.chain().focus().toggleBulletList().run()} active={editor.isActive('bulletList')}>
            <List className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarNumberedList')} onClick={() => editor.chain().focus().toggleOrderedList().run()} active={editor.isActive('orderedList')}>
            <ListOrdered className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarBlockquote')} onClick={() => editor.chain().focus().toggleBlockquote().run()} active={editor.isActive('blockquote')}>
            <Quote className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarInlineCode')} onClick={() => editor.chain().focus().toggleCode().run()} active={editor.isActive('code')}>
            <Code2 className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarCodeBlock')} onClick={() => editor.chain().focus().toggleCodeBlock().run()} active={editor.isActive('codeBlock')}>
            <FileCode className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarLink')} onClick={setLink} active={editor.isActive('link')}>
            <Link2 className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarInsertImage')} onClick={() => fileInputRef.current?.click()}>
            <ImageIcon className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarAttachFile')} onClick={() => attachInputRef.current?.click()}>
            <Paperclip className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarHighlight')} onClick={() => editor.chain().focus().toggleHighlight().run()} active={editor.isActive('highlight')}>
            <Highlighter className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarSep />

          <EditorToolbarBtn title={tr('taskDetail.toolbarAlignLeft')} onClick={() => editor.chain().focus().setTextAlign('left').run()} active={editor.isActive({ textAlign: 'left' })}>
            <AlignLeft className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarAlignCenter')} onClick={() => editor.chain().focus().setTextAlign('center').run()} active={editor.isActive({ textAlign: 'center' })}>
            <AlignCenter className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
          <EditorToolbarBtn title={tr('taskDetail.toolbarAlignRight')} onClick={() => editor.chain().focus().setTextAlign('right').run()} active={editor.isActive({ textAlign: 'right' })}>
            <AlignRight className="w-3.5 h-3.5" />
          </EditorToolbarBtn>
        </div>

        {/* Editor area */}
        <EditorContent
          editor={editor}
          className="min-h-[150px] max-h-[500px] overflow-y-auto scrollbar-thin px-3 py-2.5 text-sm text-fg bg-bg-elevated cursor-text"
        />
      </div>

      {/* Pending files to attach on save */}
      {pending.length > 0 && (
        <div className="flex flex-col gap-1.5 mt-2">
          {pending.map((f, i) => {
            const pct = progress[i]
            const active = uploading && pct !== undefined
            return (
              <div key={i} className="rounded-md border border-border bg-bg-subtle px-2 py-1.5 text-xs text-fg">
                <div className="flex items-center gap-1.5">
                  <Paperclip className="w-3 h-3 shrink-0 text-fg-subtle" />
                  <span className="flex-1 truncate">{f.name.normalize('NFC')}</span>
                  <span className="shrink-0 text-[11px] text-fg-subtle">{formatBytes(f.size)}</span>
                  {uploading ? (
                    <span className="shrink-0 w-9 text-right text-[11px] font-medium text-accent">{pct ?? 0}%</span>
                  ) : (
                    <button
                      onClick={() => setPending((prev) => prev.filter((_, idx) => idx !== i))}
                      className="shrink-0 text-fg-subtle hover:text-danger"
                      title={tr('taskDetail.removeFile')}
                    >
                      <X className="w-3 h-3" />
                    </button>
                  )}
                </div>
                {uploading && (
                  <div className="mt-1.5 h-1 w-full rounded-full bg-bg overflow-hidden">
                    <div
                      className={cn(
                        'h-full rounded-full bg-accent transition-all duration-200',
                        active && pct === 100 && 'bg-success',
                      )}
                      style={{ width: `${pct ?? 0}%` }}
                    />
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {(dirty || pending.length > 0) && (
        <div className="flex gap-2 mt-1.5">
          <Button variant="primary" size="sm" onClick={save} loading={uploading}>{tr('common.save')}</Button>
          <Button variant="ghost" size="sm" onClick={cancel} disabled={uploading}>{tr('common.cancel')}</Button>
        </div>
      )}

      <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleImageFile} />
      <input ref={attachInputRef} type="file" multiple className="hidden" onChange={handleAttachFiles} />
    </div>
  )
}

// ─── Attachments Section ──────────────────────────────────────────────────────

function formatBytes(bytes: number): string {
  if (!bytes) return '0 B'
  const k = 1024
  const units = ['B', 'KB', 'MB', 'GB']
  const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), units.length - 1)
  return `${(bytes / Math.pow(k, i)).toFixed(i === 0 ? 0 : 1)} ${units[i]}`
}

function AttachmentsSection({ task, projectId }: { task: Task; projectId: string }) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const currentUserId = useAuthStore((s) => s.user?.id)

  const { data: attachments = [] } = useQuery({
    queryKey: ['task-attachments', projectId, task.id],
    queryFn: () => attachmentsApi.list(projectId, task.id),
    enabled: !!projectId && !!task.id,
  })

  const { mutate: remove, isPending: removing } = useMutation({
    mutationFn: (id: string) => attachmentsApi.remove(projectId, task.id, id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['task-attachments', projectId, task.id] })
      toast.success(tr('taskDetail.fileDeleted'))
    },
    onError: () => toast.error(tr('taskDetail.fileDeleteFailed')),
  })

  const download = async (id: string, fileName: string) => {
    try {
      const blob = await attachmentsApi.download(projectId, task.id, id)
      const url = URL.createObjectURL(blob)
      const el = document.createElement('a')
      el.href = url; el.download = fileName.normalize('NFC'); el.click()
      URL.revokeObjectURL(url)
    } catch {
      toast.error(tr('taskDetail.fileDownloadFailed'))
    }
  }

  if (attachments.length === 0) return null

  return (
    <div>
      <p className="text-sm font-semibold text-fg mb-2">
        {tr('taskDetail.attachments')} <span className="text-fg-subtle font-normal">({attachments.length})</span>
      </p>
      <div className="space-y-1.5">
        {attachments.map((a) => {
          const canDelete = a.uploaderId === currentUserId
          return (
            <div
              key={a.id}
              className="group flex items-center gap-3 rounded-lg border border-border bg-bg-surface px-3 py-2 hover:bg-bg-subtle transition-colors"
            >
              {/* Thumbnail / icon */}
              <button
                type="button"
                onClick={() => download(a.id, a.fileName)}
                className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded bg-bg-subtle text-fg-subtle"
                title={tr('taskDetail.openFile')}
              >
                <FileText className="h-4 w-4" />
              </button>

              {/* Info */}
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-fg" title={a.fileName.normalize('NFC')}>{a.fileName.normalize('NFC')}</p>
                <p className="text-[11px] text-fg-subtle">{formatBytes(a.fileSize)} · {formatRelative(a.createdAt)}</p>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-1 shrink-0">
                <button
                  onClick={() => download(a.id, a.fileName)}
                  className="rounded-md p-1.5 text-fg-subtle hover:bg-bg-elevated hover:text-fg transition-colors"
                  title={tr('taskDetail.download')}
                >
                  <Download className="h-3.5 w-3.5" />
                </button>
                {canDelete && (
                  <button
                    onClick={() => remove(a.id)}
                    disabled={removing}
                    className="rounded-md p-1.5 text-fg-subtle hover:bg-danger/10 hover:text-danger transition-colors disabled:opacity-50"
                    title={tr('taskDetail.delete')}
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

// ─── Subtask Status Picker ────────────────────────────────────────────────────

function SubtaskStatusPicker({ sub, projectId, columns, onUpdate }: {
  sub: Task; projectId: string; columns: BoardColumn[]; onUpdate: () => void
}) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const btnRef = useRef<HTMLButtonElement>(null)
  const [pos, setPos] = useState({ top: 0, left: 0 })

  // Columns are the source of truth for status — the subtask's "status" pill shows
  // its actual board column, and picking another column moves it there (the backend
  // re-derives the status enum from the column name).
  const currentCol = columns.find(c => c.id === sub.columnId) ?? null
  const current = columnVisual(currentCol)
  const currentLabel = currentCol?.name ?? tr('status.' + sub.status)

  const openDropdown = (e: React.MouseEvent) => {
    e.stopPropagation()
    if (btnRef.current) {
      const r = btnRef.current.getBoundingClientRect()
      setPos({ top: r.bottom + 4, left: r.right })
    }
    setOpen(v => !v)
  }

  const moveToColumn = async (columnId: string) => {
    if (columnId !== sub.columnId) await tasksApi.update(projectId, sub.id, { columnId })
    onUpdate()
    setOpen(false)
  }

  return (
    <>
      <button
        ref={btnRef}
        onClick={openDropdown}
        style={{ backgroundColor: current.bg, color: current.fg }}
        className="w-full inline-flex items-center justify-between gap-0.5 h-[25px] px-1.5 py-0.5 rounded-[4px] text-[11px] font-medium transition-opacity hover:opacity-90"
      >
        <span className="truncate">{currentLabel}</span>
        <ChevronDown className="w-2.5 h-2.5 shrink-0" />
      </button>
      {open && createPortal(
        <>
          <div className="fixed inset-0 z-[9998]" onClick={() => setOpen(false)} />
          <div
            className="fixed z-[9999] w-44 rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden py-0.5"
            style={{ top: pos.top, left: pos.left - 176 }}
          >
            {columns.map((col) => {
              const isCurrent = col.id === sub.columnId
              return (
                <button
                  key={col.id}
                  onClick={(e) => { e.stopPropagation(); moveToColumn(col.id) }}
                  className={cn(
                    'w-full flex items-center gap-2 px-3 py-1.5 text-xs hover:bg-bg-subtle transition-colors',
                    isCurrent && 'bg-bg-subtle',
                  )}
                >
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: columnVisual(col).bg }} />
                  <span className="flex-1 text-left text-fg truncate">{col.name}</span>
                  {isCurrent && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
                </button>
              )
            })}
          </div>
        </>,
        document.body,
      )}
    </>
  )
}

// Inline assignee picker for a subtask row.
function SubtaskAssigneePicker({ sub, projectId, onUpdate }: {
  sub: Task; projectId: string; onUpdate: () => void
}) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const btnRef = useRef<HTMLButtonElement>(null)
  const [pos, setPos] = useState({ top: 0, left: 0 })
  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
  })

  const openDropdown = (e: React.MouseEvent) => {
    e.stopPropagation()
    if (btnRef.current) {
      const r = btnRef.current.getBoundingClientRect()
      setPos({ top: r.bottom + 4, left: r.right })
    }
    setOpen((v) => !v)
  }

  const pick = async (userId: string | null) => {
    if ((userId ?? null) !== (sub.assigneeId ?? null)) {
      await tasksApi.update(projectId, sub.id, { assigneeId: userId })
    }
    onUpdate()
    setOpen(false)
  }

  return (
    <>
      <button
        ref={btnRef}
        onClick={openDropdown}
        className="w-full inline-flex items-center gap-1 px-1 py-0.5 rounded-[4px] hover:bg-bg-elevated transition-colors"
        title={tr('taskDetail.fAssignee')}
      >
        {sub.assignee ? (
          <Avatar name={sub.assignee.fullName} avatarUrl={sub.assignee.avatarUrl} size="xs" className="shrink-0" />
        ) : (
          <img src={DEFAULT_AVATAR} alt="" className="w-5 h-5 rounded-full object-cover shrink-0" />
        )}
        <span className="text-[12px] text-fg-muted truncate">{sub.assignee?.fullName ?? tr('common.unassigned')}</span>
      </button>
      {open && createPortal(
        <>
          <div className="fixed inset-0 z-[9998]" onClick={() => setOpen(false)} />
          <div
            className="fixed z-[9999] w-52 max-h-64 overflow-y-auto scrollbar-thin rounded-lg border border-border bg-bg-surface shadow-app-md py-0.5"
            style={{ top: pos.top, left: pos.left - 208 }}
          >
            <button
              onClick={(e) => { e.stopPropagation(); pick(null) }}
              className={cn('w-full flex items-center gap-2 px-3 py-1.5 text-xs hover:bg-bg-subtle transition-colors', !sub.assigneeId && 'bg-bg-subtle')}
            >
              <img src={DEFAULT_AVATAR} alt="" className="w-5 h-5 rounded-full object-cover shrink-0" />
              <span className="flex-1 text-left text-fg-muted truncate">{tr('common.unassigned')}</span>
              {!sub.assigneeId && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
            </button>
            {members.map((m) => {
              const isCurrent = sub.assigneeId === m.userId
              return (
                <button
                  key={m.userId}
                  onClick={(e) => { e.stopPropagation(); pick(m.userId) }}
                  className={cn('w-full flex items-center gap-2 px-3 py-1.5 text-xs hover:bg-bg-subtle transition-colors', isCurrent && 'bg-bg-subtle')}
                >
                  <Avatar name={m.user.fullName} avatarUrl={m.user.avatarUrl} size="xs" />
                  <span className="flex-1 text-left text-fg truncate">{m.user.fullName}</span>
                  {isCurrent && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
                </button>
              )
            })}
          </div>
        </>,
        document.body,
      )}
    </>
  )
}

const SUBTASK_PRIORITY_KEYS = ['urgent', 'high', 'medium', 'low', 'lowest']

// Inline priority picker for a subtask row.
function SubtaskPriorityPicker({ sub, projectId, onUpdate }: {
  sub: Task; projectId: string; onUpdate: () => void
}) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const btnRef = useRef<HTMLButtonElement>(null)
  const [pos, setPos] = useState({ top: 0, left: 0 })

  const current = PRIORITY_CONFIG[sub.priority] ?? PRIORITY_CONFIG.medium

  const openDropdown = (e: React.MouseEvent) => {
    e.stopPropagation()
    if (btnRef.current) {
      const r = btnRef.current.getBoundingClientRect()
      setPos({ top: r.bottom + 4, left: r.right })
    }
    setOpen((v) => !v)
  }

  const pick = async (p: string) => {
    if (p !== sub.priority) await tasksApi.update(projectId, sub.id, { priority: p })
    onUpdate()
    setOpen(false)
  }

  return (
    <>
      <button
        ref={btnRef}
        onClick={openDropdown}
        className="w-full inline-flex items-center gap-1 px-1 py-0.5 rounded-[4px] hover:bg-bg-elevated transition-colors"
        title={tr('taskDetail.fPriority')}
      >
        <img src={current.svg} alt="" width={14} height={14} className="shrink-0" />
        <span className="text-[12px] truncate" style={{ color: current.hexColor }}>{tr('priority.' + sub.priority)}</span>
      </button>
      {open && createPortal(
        <>
          <div className="fixed inset-0 z-[9998]" onClick={() => setOpen(false)} />
          <div
            className="fixed z-[9999] w-40 rounded-lg border border-border bg-bg-surface shadow-app-md py-0.5"
            style={{ top: pos.top, left: pos.left - 160 }}
          >
            {SUBTASK_PRIORITY_KEYS.map((p) => {
              const cfg = PRIORITY_CONFIG[p]
              const isCurrent = p === sub.priority
              return (
                <button
                  key={p}
                  onClick={(e) => { e.stopPropagation(); pick(p) }}
                  className={cn('w-full flex items-center gap-2 px-3 py-1.5 text-xs hover:bg-bg-subtle transition-colors', isCurrent && 'bg-bg-subtle')}
                >
                  <img src={cfg.svg} alt="" width={14} height={14} className="shrink-0" />
                  <span className="flex-1 text-left text-fg truncate">{tr('priority.' + p)}</span>
                  {isCurrent && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
                </button>
              )
            })}
          </div>
        </>,
        document.body,
      )}
    </>
  )
}

// ─── Subtasks Section ─────────────────────────────────────────────────────────

function SubtasksSection({ task, projectId, projectKey = 'TASK', onSubtaskClick, openAddSignal = 0 }: {
  task: Task; projectId: string; projectKey?: string; onSubtaskClick?: (taskId: string) => void; openAddSignal?: number
}) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const [adding, setAdding] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const rootRef = useRef<HTMLDivElement>(null)

  // The header "Add child task" button bumps openAddSignal → open + scroll to the input.
  useEffect(() => {
    if (openAddSignal > 0) {
      setAdding(true)
      rootRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }, [openAddSignal])
  const { data: columns = [] } = useQuery({
    queryKey: ['columns', projectId],
    queryFn: () => columnsApi.list(projectId),
  })
  const subtasks = (task.subtasks ?? [])
  const done = subtasks.filter((s) => s.status === 'done').length
  const pct = subtasks.length ? Math.round((done / subtasks.length) * 100) : 0

  const { mutate: createSubtask, isPending } = useMutation({
    mutationFn: () => tasksApi.create(projectId, {
      columnId: task.columnId,
      title: newTitle.trim(),
      parentTaskId: task.id,
    }),
    onMutate: () => {
      // Optimistically bump subtask_count on parent card in the board list
      qc.setQueriesData(
        { queryKey: ['tasks', projectId] },
        (old: { data: Task[]; meta: unknown } | undefined) => {
          if (!old) return old
          return {
            ...old,
            data: old.data.map((t) =>
              t.id === task.id ? { ...t, subtaskCount: (t.subtaskCount ?? 0) + 1 } : t,
            ),
          }
        },
      )
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['task', projectId, task.id] })
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
      // Refresh the All/History timeline so the "created subtask" entry shows up.
      qc.invalidateQueries({ queryKey: ['activity', projectId, 'task', task.id] })
      setNewTitle('')
      setAdding(false)
    },
    onError: () => {
      toast.error(tr('taskDetail.createSubtaskFailed'))
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
    },
  })

  return (
    <div ref={rootRef}>
      <div className="flex items-center justify-between mb-2">
        <p className="text-sm font-semibold text-fg">{tr('taskDetail.subtasks')}</p>
        <button
          onClick={() => setAdding(true)}
          className="text-xs text-accent hover:underline flex items-center gap-1"
        >
          <Plus className="w-3 h-3" /> {tr('taskDetail.addSubtask')}
        </button>
      </div>

      {subtasks.length > 0 && (
        <div className="mb-2">
          <div className="flex items-center justify-between text-xs text-fg-muted mb-1">
            <span>{tr('taskDetail.subtasksCompleted', { done, total: subtasks.length })}</span>
            <span>{pct}%</span>
          </div>
          <div className="h-1.5 rounded-full bg-bg-subtle overflow-hidden">
            <div
              className="h-full rounded-full bg-success transition-all duration-300"
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>
      )}

      <div className="space-y-1">
        {subtasks.map((sub) => {
          const taskCode = sub.taskNumber != null ? `${projectKey}-${sub.taskNumber}` : null
          const refresh = () => {
            qc.invalidateQueries({ queryKey: ['task', projectId, task.id] })
            qc.invalidateQueries({ queryKey: ['tasks', projectId] })
          }
          return (
            <div
              key={sub.id}
              className="flex items-center gap-2 py-2 px-2.5 rounded-lg border border-border/50 bg-bg-surface hover:bg-bg-subtle transition-colors group"
            >
              {/* Subtask icon — 14px fixed */}
              <SubtaskIcon size={14} />

              {/* Task code + title — takes remaining space */}
              <div className="flex items-center gap-1.5 flex-1 min-w-0">
                {taskCode && (
                  <button
                    onClick={() => onSubtaskClick?.(sub.id)}
                    className="text-[11px] font-bold text-info shrink-0 hover:underline"
                  >
                    {taskCode}
                  </button>
                )}
                <span
                  className={cn(
                    'text-sm text-fg truncate',
                    sub.status === 'done' && 'line-through text-fg-subtle',
                    onSubtaskClick && 'cursor-pointer hover:text-accent transition-colors',
                  )}
                  onClick={() => onSubtaskClick?.(sub.id)}
                >
                  {sub.title}
                </span>
              </div>

              {/* Priority — 76px fixed (inline editable) */}
              <div className="w-[76px] shrink-0">
                <SubtaskPriorityPicker sub={sub} projectId={projectId} onUpdate={refresh} />
              </div>

              {/* Assignee — 108px fixed (inline editable) */}
              <div className="w-[108px] shrink-0">
                <SubtaskAssigneePicker sub={sub} projectId={projectId} onUpdate={refresh} />
              </div>

              {/* Status dropdown — 90px fixed */}
              <div className="w-[90px] shrink-0">
                <SubtaskStatusPicker sub={sub} projectId={projectId} columns={columns} onUpdate={refresh} />
              </div>
            </div>
          )
        })}
      </div>

      {adding && (
        <div className="mt-2 flex gap-2">
          <input
            autoFocus
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && newTitle.trim()) createSubtask()
              if (e.key === 'Escape') { setAdding(false); setNewTitle('') }
            }}
            placeholder={tr('taskDetail.subtaskPlaceholder')}
            className="flex-1 h-8 rounded-lg border border-border bg-bg-elevated px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-subtle"
          />
          <Button variant="primary" size="sm" onClick={() => newTitle.trim() && createSubtask()} loading={isPending}>{tr('common.add')}</Button>
          <Button variant="ghost" size="sm" onClick={() => { setAdding(false); setNewTitle('') }}>✕</Button>
        </div>
      )}
    </div>
  )
}

// ─── Linked Items Section ─────────────────────────────────────────────────────

function LinkedItemsSection({ task, projectId }: { task: Task; projectId: string }) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const [adding, setAdding] = useState(false)
  const [linkType, setLinkType] = useState<'blocks' | 'blocked_by' | 'relates_to'>('relates_to')
  const [search, setSearch] = useState('')
  const [selectedId, setSelectedId] = useState('')

  const { data: links = [] } = useQuery<TaskLink[]>({
    queryKey: ['task-links', projectId, task.id],
    queryFn: () => apiClient.get<{ success: true; data: TaskLink[] }>(`/projects/${projectId}/tasks/${task.id}/links`).then(r => r.data.data),
  })

  const { data: allTasks } = useQuery({
    queryKey: ['tasks-search', projectId],
    queryFn: () => tasksApi.list(projectId, { limit: 200 }),
    enabled: adding,
    select: (d) => d.data.filter((t) => t.id !== task.id),
  })

  const { mutate: addLink, isPending } = useMutation({
    mutationFn: () => apiClient.post(`/projects/${projectId}/tasks/${task.id}/links`, { targetTaskId: selectedId, linkType }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['task-links', projectId, task.id] })
      setAdding(false); setSearch(''); setSelectedId('')
      toast.success(tr('taskDetail.linked'))
    },
    onError: () => toast.error(tr('taskDetail.linkFailed')),
  })

  const { mutate: removeLink } = useMutation({
    mutationFn: (linkId: string) => apiClient.delete(`/projects/${projectId}/tasks/${task.id}/links/${linkId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['task-links', projectId, task.id] }),
    onError: () => toast.error(tr('taskDetail.unlinkFailed')),
  })

  const filtered = (allTasks ?? []).filter(t =>
    t.title.toLowerCase().includes(search.toLowerCase())
  ).slice(0, 8)

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <p className="text-sm font-semibold text-fg">{tr('taskDetail.linkedItems')}</p>
        <button onClick={() => setAdding(true)} className="text-xs text-accent hover:underline flex items-center gap-1">
          <Plus className="w-3 h-3" /> {tr('taskDetail.addLinkedWorkItem')}
        </button>
      </div>

      {links.map((link) => {
        const other = link.sourceTaskId === task.id ? link.targetTask : link.sourceTask
        const status = other?.status ?? 'todo'
        const sconf = STATUS_CONFIG[status]
        return (
          <div key={link.id} className="flex items-center gap-2 py-1.5 px-2 rounded-lg hover:bg-bg-subtle group">
            <span className="text-xs text-fg-subtle italic w-24 shrink-0">{tr('taskDetail.' + LINK_TYPE_LABEL_KEYS[link.linkType])}</span>
            <span className={cn('text-xs px-1.5 py-0.5 rounded font-medium', sconf.color, sconf.bg)}>
              {tr('status.' + status)}
            </span>
            <span className="text-sm text-fg flex-1 truncate">{other?.title ?? '—'}</span>
            <button
              onClick={() => removeLink(link.id)}
              className="opacity-0 group-hover:opacity-100 text-fg-subtle hover:text-danger transition-all"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )
      })}

      {adding && (
        <div className="mt-2 p-3 rounded-lg border border-border bg-bg-elevated space-y-2">
          <select
            value={linkType}
            onChange={(e) => setLinkType(e.target.value as typeof linkType)}
            className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
          >
            {Object.entries(LINK_TYPE_LABEL_KEYS).map(([v, k]) => <option key={v} value={v}>{tr('taskDetail.' + k)}</option>)}
          </select>
          <input
            autoFocus
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={tr('taskDetail.searchTask')}
            className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-subtle"
          />
          {filtered.length > 0 && (
            <div className="rounded-lg border border-border overflow-hidden max-h-40 overflow-y-auto">
              {filtered.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setSelectedId(t.id)}
                  className={cn(
                    'w-full text-left px-3 py-2 text-sm flex items-center gap-2 hover:bg-bg-subtle transition-colors',
                    selectedId === t.id && 'bg-bg-active text-accent'
                  )}
                >
                  {selectedId === t.id && <Check className="w-3.5 h-3.5 shrink-0" />}
                  <span className="truncate">{t.title}</span>
                </button>
              ))}
            </div>
          )}
          <div className="flex gap-2">
            <Button variant="primary" size="sm" onClick={() => selectedId && addLink()} disabled={!selectedId} loading={isPending}>{tr('taskDetail.link')}</Button>
            <Button variant="ghost" size="sm" onClick={() => { setAdding(false); setSearch(''); setSelectedId('') }}>{tr('common.cancel')}</Button>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Tab: All ─────────────────────────────────────────────────────────────────

function AllTab({ projectId, taskId }: { projectId: string; taskId: string }) {
  const { t: tr } = useTranslation()
  const { data: comments = [], isLoading: cLoading } = useQuery({
    queryKey: ['comments', projectId, taskId],
    queryFn: () => commentsApi.list(projectId, taskId),
  })
  const { data: activity = [], isLoading: aLoading } = useQuery({
    queryKey: ['activity', projectId, 'task', taskId],
    queryFn: () => apiClient.get<{ success: true; data: ActivityLog[] }>(`/projects/${projectId}/activity`, {
      params: { entityType: 'task', entityId: taskId, limit: 50 }
    }).then(r => r.data.data),
  })

  if (cLoading || aLoading) return <TimelineSkeleton />

  const items = [
    ...comments.map(c => ({ type: 'comment' as const, date: c.createdAt, data: c })),
    ...activity.map(a => ({ type: 'activity' as const, date: a.createdAt, data: a })),
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())

  if (!items.length) return <p className="text-sm text-fg-subtle text-center py-8">{tr('taskDetail.noActivity')}</p>

  return (
    <div className="space-y-3">
      {items.map((item) => item.type === 'comment'
        ? <CommentBubble key={`c-${item.data.id}`} comment={item.data as Comment} mini />
        : <HistoryItem key={`a-${item.data.id}`} log={item.data as ActivityLog} projectId={projectId} />
      )}
    </div>
  )
}

// ─── Tab: Comments ────────────────────────────────────────────────────────────

function CommentsTab({ projectId, taskId }: { projectId: string; taskId: string }) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const { user } = useAuthStore()
  const [content, setContent] = useState('')
  const [replyTo, setReplyTo] = useState<Comment | null>(null)
  const [editing, setEditing] = useState<{ id: string; content: string } | null>(null)
  // Users picked from the @-mention dropdown; on submit we send the ids of those
  // still present in the text so the backend can notify them.
  const [mentions, setMentions] = useState<TaskUser[]>([])
  const [mentionQuery, setMentionQuery] = useState<string | null>(null)
  const [mentionStart, setMentionStart] = useState(0)
  const [mentionIdx, setMentionIdx] = useState(0)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const { data: comments = [], isLoading } = useQuery({
    queryKey: ['comments', projectId, taskId],
    queryFn: () => commentsApi.list(projectId, taskId),
  })

  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
  })

  const { mutate: addComment, isPending } = useMutation({
    mutationFn: (dto: { content: string; parentId?: string; mentionedUserIds?: string[] }) =>
      commentsApi.create(projectId, taskId, dto),
    onMutate: async ({ content: c, parentId }) => {
      const optimistic: Comment = {
        id: 'tmp-' + Date.now(),
        taskId, authorId: user!.id,
        author: { id: user!.id, fullName: user!.fullName, email: '', avatarUrl: user!.avatarUrl ?? null },
        content: c, parentId: parentId ?? null,
        editedAt: null, createdAt: new Date().toISOString(), replies: [],
      }
      // Match the API shape: a reply nests under its top-level parent's `replies`,
      // a top-level comment appends to the list.
      qc.setQueryData(['comments', projectId, taskId], (old: Comment[] = []) =>
        parentId
          ? old.map(top => top.id === parentId ? { ...top, replies: [...(top.replies ?? []), optimistic] } : top)
          : [...old, optimistic],
      )
      setContent(''); setReplyTo(null); setMentions([]); setMentionQuery(null)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['comments', projectId, taskId] }),
    onError: () => { toast.error(tr('taskDetail.sendFailed')); qc.invalidateQueries({ queryKey: ['comments', projectId, taskId] }) },
  })

  const { mutate: updateComment } = useMutation({
    mutationFn: ({ id, content }: { id: string; content: string }) => commentsApi.update(projectId, taskId, id, content),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['comments', projectId, taskId] }); setEditing(null) },
  })

  const { mutate: deleteComment } = useMutation({
    mutationFn: (id: string) => commentsApi.delete(projectId, taskId, id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['comments', projectId, taskId] }),
  })

  // The API returns only top-level comments with their replies nested under
  // `replies` (see CommentResource). Consume that shape directly — do NOT rebuild
  // it by filtering a flat list (replies aren't top-level entries).
  const topLevel = comments.filter(c => !c.parentId)
  // Keep threads one level deep: a reply to a reply attaches to the same
  // top-level comment, so the API always returns it nested (index only eager-loads
  // one level of `replies`).
  const effectiveParentId = replyTo ? (replyTo.parentId ?? replyTo.id) : undefined
  const memberUsers = members.map(m => m.user)

  const submit = () => {
    if (!content.trim()) return
    // Only notify mentions whose `@FullName` is still in the text.
    const mentionedUserIds = [...new Set(
      mentions.filter(u => content.includes('@' + u.fullName)).map(u => u.id),
    )]
    addComment({ content: content.trim(), parentId: effectiveParentId, mentionedUserIds })
  }

  // Candidates for the @-mention dropdown: project members matching the typed query.
  const mentionCandidates = mentionQuery === null ? [] : memberUsers
    .filter(u => u.fullName.toLowerCase().includes(mentionQuery.toLowerCase()))
    .slice(0, 6)

  // Detect a `@token` being typed at the caret (token = run of non-space chars).
  const onContentChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value
    setContent(val)
    const before = val.slice(0, e.target.selectionStart)
    const m = /(?:^|\s)@(\S*)$/.exec(before)
    if (m) {
      setMentionQuery(m[1])
      setMentionStart(before.length - m[1].length - 1) // index of the '@'
      setMentionIdx(0)
    } else {
      setMentionQuery(null)
    }
  }

  const pickMention = (u: TaskUser) => {
    const tail = content.slice(mentionStart + 1 + (mentionQuery?.length ?? 0))
    const next = content.slice(0, mentionStart) + '@' + u.fullName + ' ' + tail
    setContent(next)
    setMentions(prev => prev.some(p => p.id === u.id) ? prev : [...prev, u])
    setMentionQuery(null)
    const caret = mentionStart + u.fullName.length + 2
    requestAnimationFrame(() => {
      textareaRef.current?.focus()
      textareaRef.current?.setSelectionRange(caret, caret)
    })
  }

  if (isLoading) return <TimelineSkeleton />

  const quickReplies = [tr('taskDetail.quick1'), tr('taskDetail.quick2'), tr('taskDetail.quick3')]

  return (
    <div className="space-y-4">
      {topLevel.length === 0 && (
        <p className="text-sm text-fg-subtle text-center py-4">{tr('taskDetail.noComments')}</p>
      )}
      {topLevel.map((c) => (
        <CommentBubble
          key={c.id}
          comment={c}
          replies={c.replies ?? []}
          currentUserId={user?.id}
          editing={editing}
          onReply={setReplyTo}
          onEdit={setEditing}
          onUpdate={(id, content) => updateComment({ id, content })}
          onDelete={deleteComment}
          memberNames={memberUsers.map(u => u.fullName)}
        />
      ))}

      {/* Input area */}
      <div className="pt-2 border-t border-border">
        {replyTo && (
          <div className="flex items-center gap-2 text-xs text-fg-muted bg-bg-subtle rounded-lg px-2.5 py-1.5 mb-2">
            {tr('taskDetail.replyingTo', { name: replyTo.author.fullName })}
            <button onClick={() => setReplyTo(null)} className="ml-auto hover:text-fg">✕</button>
          </div>
        )}

        {/* Quick replies */}
        <div className="flex flex-wrap gap-1.5 mb-2">
          {quickReplies.map(q => (
            <button
              key={q}
              onClick={() => setContent(q)}
              className="text-xs px-2 py-1 rounded-full border border-border text-fg-muted hover:border-accent hover:text-accent transition-colors"
            >
              {q}
            </button>
          ))}
        </div>

        <div className="flex gap-2">
          {user && <Avatar name={user.fullName} avatarUrl={user.avatarUrl} size="sm" className="shrink-0 mt-1" />}
          <div className="flex-1 space-y-1.5">
            <div className="relative">
              <textarea
                ref={textareaRef}
                value={content}
                onChange={onContentChange}
                onKeyDown={(e) => {
                  // While the @-mention dropdown is open, arrows/enter/tab/esc drive it.
                  if (mentionQuery !== null && mentionCandidates.length > 0) {
                    if (e.key === 'ArrowDown') { e.preventDefault(); setMentionIdx(i => (i + 1) % mentionCandidates.length); return }
                    if (e.key === 'ArrowUp') { e.preventDefault(); setMentionIdx(i => (i - 1 + mentionCandidates.length) % mentionCandidates.length); return }
                    if (e.key === 'Enter' || e.key === 'Tab') { e.preventDefault(); pickMention(mentionCandidates[mentionIdx]); return }
                    if (e.key === 'Escape') { e.preventDefault(); setMentionQuery(null); return }
                  }
                  if ((e.shiftKey || e.ctrlKey || e.metaKey) && e.key === 'Enter' && content.trim()) {
                    e.preventDefault()
                    submit()
                  }
                }}
                placeholder={tr('taskDetail.commentPlaceholder')}
                rows={4}
                className="w-full bg-bg-elevated border border-border rounded-lg px-3 py-2 text-sm text-fg resize-none focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-subtle"
              />
              {mentionQuery !== null && mentionCandidates.length > 0 && (
                <div className="absolute left-0 bottom-full mb-1 z-10 w-64 max-h-56 overflow-y-auto scrollbar-thin bg-bg-elevated border border-border rounded-lg shadow-lg py-1">
                  {mentionCandidates.map((u, i) => (
                    <button
                      key={u.id}
                      type="button"
                      onMouseDown={(e) => { e.preventDefault(); pickMention(u) }}
                      onMouseEnter={() => setMentionIdx(i)}
                      className={cn(
                        'w-full flex items-center gap-2 px-2.5 py-1.5 text-left text-sm',
                        i === mentionIdx ? 'bg-bg-subtle text-fg' : 'text-fg-muted',
                      )}
                    >
                      <Avatar name={u.fullName} avatarUrl={u.avatarUrl} size="sm" className="shrink-0" />
                      <span className="truncate">{u.fullName}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs text-fg-subtle">{tr('taskDetail.pressMToComment')}</span>
              <Button variant="primary" size="sm" disabled={!content.trim()} loading={isPending} onClick={submit}>
                {tr('common.save')}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── Comment Bubble ───────────────────────────────────────────────────────────

// Highlights `@FullName` runs that match a known project member. Longest names
// first so "@Bui Manh Dung" wins over a member also named "@Bui".
function MentionText({ text, names }: { text: string; names?: string[] }) {
  if (!names || names.length === 0) return <>{text}</>
  const escaped = [...names]
    .sort((a, b) => b.length - a.length)
    .map(n => n.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
  const re = new RegExp('@(' + escaped.join('|') + ')', 'g')
  const parts: React.ReactNode[] = []
  let last = 0
  let m: RegExpExecArray | null
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) parts.push(text.slice(last, m.index))
    parts.push(<span key={m.index} className="text-accent font-medium">{m[0]}</span>)
    last = m.index + m[0].length
  }
  if (last < text.length) parts.push(text.slice(last))
  return <>{parts}</>
}

function CommentBubble({
  comment, replies, currentUserId, editing, onReply, onEdit, onUpdate, onDelete, mini, memberNames
}: {
  comment: Comment; replies?: Comment[]; currentUserId?: string
  editing?: { id: string; content: string } | null
  onReply?: (c: Comment) => void; onEdit?: (e: { id: string; content: string } | null) => void
  onUpdate?: (id: string, content: string) => void; onDelete?: (id: string) => void
  mini?: boolean; memberNames?: string[]
}) {
  const { t: tr } = useTranslation()
  const isOwn = comment.authorId === currentUserId
  const isEditing = editing?.id === comment.id

  return (
    <div className="flex gap-2.5 group">
      <Avatar name={comment.author.fullName} avatarUrl={comment.author.avatarUrl} size="sm" className="shrink-0 mt-0.5" />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          <span className="text-sm font-medium text-fg">{comment.author.fullName}</span>
          <span className="text-xs text-fg-subtle">{formatRelative(comment.createdAt)}</span>
          {comment.editedAt && <span className="text-xs text-fg-subtle italic">{tr('board.edited')}</span>}
        </div>

        {isEditing && onEdit && onUpdate ? (
          <div className="space-y-1.5">
            <textarea
              value={editing!.content}
              onChange={(e) => onEdit({ ...editing!, content: e.target.value })}
              autoFocus rows={2}
              className="w-full bg-bg-elevated border border-accent rounded-lg px-3 py-2 text-sm text-fg resize-none focus:outline-none"
            />
            <div className="flex gap-2">
              <Button variant="primary" size="sm" onClick={() => onUpdate(comment.id, editing!.content)}>{tr('common.save')}</Button>
              <Button variant="ghost" size="sm" onClick={() => onEdit(null)}>{tr('common.cancel')}</Button>
            </div>
          </div>
        ) : (
          <p className="text-sm text-fg whitespace-pre-wrap break-words">
            <MentionText text={comment.content} names={memberNames} />
          </p>
        )}

        {!mini && (
          <div className="flex items-center gap-3 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
            {onReply && (
              <button onClick={() => onReply(comment)} className="text-xs text-fg-subtle hover:text-accent transition-colors">
                {tr('board.reply')}
              </button>
            )}
            {isOwn && !isEditing && onEdit && onDelete && (
              <>
                <button onClick={() => onEdit({ id: comment.id, content: comment.content })} className="text-xs text-fg-subtle hover:text-fg">
                  <Pencil className="w-3 h-3" />
                </button>
                <button onClick={() => onDelete(comment.id)} className="text-xs text-fg-subtle hover:text-danger">
                  <Trash2 className="w-3 h-3" />
                </button>
              </>
            )}
          </div>
        )}

        {replies && replies.length > 0 && (
          <div className="mt-2 pl-3 border-l-2 border-border space-y-2">
            {replies.map(r => (
              <CommentBubble
                key={r.id} comment={r} currentUserId={currentUserId}
                editing={editing} onReply={onReply} onEdit={onEdit} onUpdate={onUpdate} onDelete={onDelete}
                memberNames={memberNames}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Tab: History ─────────────────────────────────────────────────────────────

interface ActivityLog {
  id: string; action: string; entityType: string
  oldValues: Record<string, unknown> | null
  newValues: Record<string, unknown> | null
  createdAt: string; userId: string
  user?: { fullName: string; avatarUrl: string | null }
}

function HistoryTab({ projectId, taskId }: { projectId: string; taskId: string }) {
  const { t: tr } = useTranslation()
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ['activity', projectId, 'task', taskId],
    queryFn: () => apiClient.get<{ success: true; data: ActivityLog[] }>(`/projects/${projectId}/activity`, {
      params: { entityType: 'task', entityId: taskId, limit: 50 }
    }).then(r => r.data.data),
  })

  if (isLoading) return <TimelineSkeleton />
  if (!logs.length) return <p className="text-sm text-fg-subtle text-center py-8">{tr('taskDetail.noHistory')}</p>

  return (
    <div className="space-y-2">
      {logs.map(log => <HistoryItem key={log.id} log={log} projectId={projectId} />)}
    </div>
  )
}

// Readable labels for the snapshot keys the backend records (see TaskController::snapshot).
// `status` (enum) is omitted on purpose — the board column is the source of truth, so
// we surface `columnId` as "Status" with the column's own name.
// Maps each snapshot key the backend records to its i18n key under `taskDetail`.
// `status` (enum) is omitted on purpose — the board column is the source of truth,
// so we surface `columnId` as "Status" with the column's own name.
const HISTORY_FIELDS: Record<string, string> = {
  title: 'fTitle',
  columnId: 'fStatus',
  assigneeId: 'fAssignee',
  priority: 'fPriority',
  dueDate: 'fDueDate',
}

function HistoryItem({ log, projectId }: { log: ActivityLog; projectId: string }) {
  const { t: tr } = useTranslation()
  const timezone = useSiteTimezone()
  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
  })
  const { data: columns = [] } = useQuery({
    queryKey: ['columns', projectId],
    queryFn: () => columnsApi.list(projectId),
  })

  const actionLabel: Record<string, string> = {
    created: tr('taskDetail.histCreated'),
    updated: tr('taskDetail.histUpdated'),
    status_changed: tr('taskDetail.histStatusChanged'),
    moved: tr('taskDetail.histMoved'),
    assigned: tr('taskDetail.histAssigned'),
    commented: tr('taskDetail.histCommented'),
    deleted: tr('taskDetail.histDeleted'),
  }

  // Resolve recorded IDs to human-readable text.
  const formatValue = (key: string, value: unknown): string => {
    if (value === null || value === undefined || value === '') {
      return key === 'assigneeId' ? tr('common.unassigned') : tr('common.none')
    }
    if (key === 'assigneeId') return members.find(m => m.userId === value)?.user.fullName ?? tr('taskDetail.unknownUser')
    if (key === 'columnId') return columns.find(c => c.id === value)?.name ?? String(value)
    return String(value)
  }

  // The backend stores a full snapshot on every change, so diff old vs new and
  // surface only the fields that actually changed — one line each, "from → to".
  const old = log.oldValues
  const changes = old
    ? Object.keys(HISTORY_FIELDS)
        .filter(k => (old[k] ?? null) !== (log.newValues?.[k] ?? null))
        .map(k => ({ label: tr('taskDetail.' + HISTORY_FIELDS[k]), from: formatValue(k, old[k]), to: formatValue(k, log.newValues?.[k]) }))
    : []

  // Log-time entries are stored as action 'updated' (the action column is a fixed
  // enum) and recognised by their newValues keys. Show "logged 2h" (+ "(QA)") instead
  // of a bare "updated". New records carry the increment in `hours` + an `isQa` flag;
  // older ones only the running (qa)loggedHours total.
  const nv = log.newValues ?? {}
  const isLogTime = !old && ('hours' in nv || 'loggedHours' in nv || 'qaLoggedHours' in nv)
  let actionText = actionLabel[log.action] ?? log.action
  if (isLogTime) {
    const isQaLog = 'isQa' in nv ? nv.isQa === true : 'qaLoggedHours' in nv
    const amount = 'hours' in nv ? Number(nv.hours) : Number(nv.qaLoggedHours ?? nv.loggedHours)
    const isTotal = !('hours' in nv)
    const key = isTotal ? (isQaLog ? 'histLoggedTotalQa' : 'histLoggedTotal') : (isQaLog ? 'histLoggedQa' : 'histLogged')
    actionText = tr('taskDetail.' + key, { time: formatTimeHours(amount || 0) })
  } else if (!old && typeof nv.subtaskCreated === 'string') {
    // Subtask creation is logged on the parent as action 'updated' + a subtaskCreated marker.
    actionText = tr('taskDetail.histSubtaskCreated', { title: nv.subtaskCreated })
  }
  const note = typeof nv.note === 'string' && nv.note.trim() ? nv.note.trim() : null

  return (
    <div className="flex items-center gap-2.5 text-xs">
      <Avatar
        name={log.user?.fullName ?? tr('common.system')}
        avatarUrl={log.user?.avatarUrl ?? null}
        size="sm"
        className="shrink-0 mt-0.5"
      />
      <div className="flex-1 min-w-0">
        <div className="text-fg-muted">
          <span className="font-medium text-fg">{log.user?.fullName ?? tr('common.system')}</span>
          {' '}{actionText}
          <span className="ml-2 text-fg-subtle" title={formatRelative(log.createdAt, timezone)}>
            {formatZonedDateTime(log.createdAt, timezone)}
          </span>
        </div>
        {note && <p className="mt-0.5 text-fg-subtle italic whitespace-pre-wrap break-words">“{note}”</p>}
        {changes.length > 0 && (
          <ul className="mt-1 space-y-0.5">
            {changes.map(c => (
              <li key={c.label} className="text-fg-subtle">
                <span className="text-fg-muted">{c.label}:</span>{' '}
                <span className="line-through opacity-60">{c.from}</span>
                <span className="mx-1 text-fg-subtle">→</span>
                <span className="text-fg">{c.to}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}

// ─── Tab: Work Log ────────────────────────────────────────────────────────────

function WorkLogTab({ task, onUpdate }: { task: Task; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const [timeInput, setTimeInput] = useState('')
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [inputError, setInputError] = useState('')

  const logTime = () => {
    const h = parseTimeInput(timeInput)
    if (!h) { setInputError(tr('taskDetail.timeFormatError')); return }
    setInputError('')
    const current = Number(task.loggedHours) || 0
    onUpdate({ loggedHours: current + h })
    setTimeInput('')
  }

  const logged = Number(task.loggedHours) || 0
  const estimated = Number(task.estimatedHours) || 0
  const remaining = Math.max(0, estimated - logged)

  return (
    <div className="space-y-4">
      <div className="p-4 rounded-xl border border-border bg-bg-elevated space-y-3">
        <p className="text-sm font-semibold text-fg">{tr('taskDetail.logTime')}</p>
        <div className="grid grid-cols-2 gap-2">
          <div>
            <label className="text-xs text-fg-subtle mb-1 block">{tr('taskDetail.timeSpent')}</label>
            <input
              type="text" value={timeInput}
              onChange={(e) => { setTimeInput(e.target.value); setInputError('') }}
              onKeyDown={(e) => e.key === 'Enter' && logTime()}
              placeholder={tr('taskDetail.timePlaceholder')}
              className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-muted"
            />
            {inputError && <p className="text-xs text-danger mt-0.5">{inputError}</p>}
          </div>
          <div>
            <label className="text-xs text-fg-subtle mb-1 block">{tr('taskDetail.date')}</label>
            <input
              type="date" value={date} onChange={(e) => setDate(e.target.value)}
              className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            />
          </div>
        </div>
        <p className="text-xs text-fg-subtle">{tr('taskDetail.timeFormatHint')}</p>
        <Button variant="primary" size="sm" onClick={logTime} disabled={!timeInput.trim()}>{tr('taskDetail.logTime')}</Button>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {[
          { label: tr('taskDetail.estimated'), value: formatTimeHours(estimated) },
          { label: tr('taskDetail.logged'),    value: formatTimeHours(logged) },
          { label: tr('taskDetail.remaining'), value: formatTimeHours(remaining) },
        ].map(({ label, value }) => (
          <div key={label} className="p-3 rounded-xl border border-border bg-bg-elevated text-center">
            <p className="text-sm font-bold text-fg">{value}</p>
            <p className="text-xs text-fg-muted">{label}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Note (free-form, exported as the "Note" column) ──────────────────────────

function NoteSection({ task, onUpdate }: { task: Task; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const [editing, setEditing] = useState(false)
  const [value, setValue] = useState(task.note ?? '')

  // Re-sync when switching tasks or when the note changes elsewhere (realtime).
  useEffect(() => { setValue(task.note ?? '') }, [task.id, task.note])

  const commit = () => {
    setEditing(false)
    const next = value.trim()
    if (next !== (task.note ?? '')) onUpdate({ note: next || null })
  }

  if (editing) {
    return (
      <textarea
        autoFocus
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === 'Escape') { setValue(task.note ?? ''); setEditing(false) }
          if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) { e.preventDefault(); commit() }
        }}
        rows={4}
        placeholder={tr('taskDetail.notePlaceholder')}
        className="w-full rounded-lg border border-border bg-bg-subtle px-2.5 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-muted resize-y"
      />
    )
  }

  return (
    <button
      onClick={() => setEditing(true)}
      className="w-full text-left text-sm rounded-lg border border-transparent hover:border-border hover:bg-bg-subtle px-2.5 py-2 transition-colors min-h-[2.25rem]"
    >
      {task.note
        ? <span className="text-fg whitespace-pre-wrap break-words">{task.note}</span>
        : <span className="text-fg-muted">{tr('taskDetail.notePlaceholder')}</span>}
    </button>
  )
}

// ─── Right Column ─────────────────────────────────────────────────────────────

function RightColumn({ task, projectId, projectKey = 'TASK', onUpdate }: {
  task: Task; projectId: string; projectKey?: string; onUpdate: (dto: UpdateTaskDto) => void
}) {
  const { t: tr } = useTranslation()
  const [detailsOpen, setDetailsOpen] = useState(true)
  const [devOpen, setDevOpen] = useState(false)
  const [noteOpen, setNoteOpen] = useState(true)

  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
  })
  const { data: labels = [] } = useQuery({
    queryKey: ['labels', projectId],
    queryFn: () => labelsApi.list(projectId),
  })
  const { data: requesters = [] } = useQuery({
    queryKey: ['requesters', projectId],
    queryFn: () => requestersApi.list(projectId),
  })
  const { data: columns = [] } = useQuery({
    queryKey: ['columns', projectId],
    queryFn: () => columnsApi.list(projectId),
  })

  return (
    <div className="w-[430px] min-w-[430px] shrink-0 border-l border-border scrollbar-overlay flex flex-col">

      {/* Status + quick actions */}
      <div className="px-5 py-4 border-b border-border space-y-2">
        <StatusDropdown task={task} columns={columns} onUpdate={onUpdate} />
      </div>

      {/* Details */}
      <CollapsibleSection
        title={tr('taskDetail.details')}
        open={detailsOpen}
        onToggle={() => setDetailsOpen(v => !v)}
      >
        <div className="space-y-0">
          {/* Assignee */}
          <FieldRow label={tr('taskDetail.fAssignee')} icon={<User className="w-3.5 h-3.5" />}>
            <AssigneeField task={task} members={members} onUpdate={onUpdate} />
          </FieldRow>

          {/* QA Assignee */}
          <FieldRow label={tr('taskDetail.qaAssignee')} icon={<User className="w-3.5 h-3.5" />}>
            <AssigneeField task={task} members={members} onUpdate={onUpdate} variant="qa" />
          </FieldRow>

          {/* Priority */}
          <FieldRow label={tr('taskDetail.fPriority')} icon={<Flag className="w-3.5 h-3.5" />}>
            <PriorityField task={task} onUpdate={onUpdate} />
          </FieldRow>

          {/* Due date */}
          <FieldRow label={tr('taskDetail.fDueDate')} icon={<Calendar className="w-3.5 h-3.5" />} align="center">
            <DueDateField task={task} onUpdate={onUpdate} />
          </FieldRow>

          {/* Company (formerly Labels) */}
          <FieldRow label={tr('taskDetail.company')} icon={<Tag className="w-3.5 h-3.5" />}>
            <LabelsField task={task} labels={labels} projectId={projectId} onUpdate={onUpdate} />
          </FieldRow>

          {/* Requester (label-like; who requested the task) */}
          <FieldRow label={tr('taskDetail.requester')} icon={<User className="w-3.5 h-3.5" />}>
            <LabelsField task={task} labels={requesters} projectId={projectId} onUpdate={onUpdate} variant="requester" />
          </FieldRow>

          {/* Reporter */}
          <FieldRow label={tr('taskDetail.reporter')} icon={<User className="w-3.5 h-3.5" />}>
            {task.reporter ? (
              <div className="flex items-center gap-1.5">
                <Avatar name={task.reporter.fullName} avatarUrl={task.reporter.avatarUrl} size="xs" />
                <span className="text-sm text-fg">{task.reporter.fullName}</span>
              </div>
            ) : <span className="text-sm text-fg-muted">—</span>}
          </FieldRow>

          {/* Time tracking */}
          <FieldRow label={tr('taskDetail.timeTracking')} icon={<CheckSquare className="w-3.5 h-3.5" />}>
            <TimeTrackingField task={task} projectId={projectId} />
          </FieldRow>

          {/* QA time tracking */}
          <FieldRow label={tr('taskDetail.qaTimeTracking')} icon={<CheckSquare className="w-3.5 h-3.5" />}>
            <TimeTrackingField task={task} projectId={projectId} variant="qa" />
          </FieldRow>

          {/* Parent task */}
          <FieldRow label={tr('taskDetail.parent')} icon={<AlignLeft className="w-3.5 h-3.5" />}>
            {task.parentTask?.taskNumber != null ? (
              <span className="flex items-center gap-1 text-sm text-fg-muted">
                <TaskIcon size={12} />
                {projectKey}-{task.parentTask.taskNumber}
              </span>
            ) : task.parentTaskId ? (
              <span className="text-sm text-fg-muted">{projectKey}-?</span>
            ) : (
              <span className="text-sm text-fg-muted">{tr('common.none')}</span>
            )}
          </FieldRow>

          {/* Team (stub) */}
          <FieldRow label={tr('taskDetail.team')} icon={<User className="w-3.5 h-3.5" />}>
            <span className="text-sm text-fg-muted">{tr('common.none')}</span>
          </FieldRow>

          {/* Start date */}
          <FieldRow label={tr('taskDetail.startDate')} icon={<Calendar className="w-3.5 h-3.5" />}>
            <StartDateField task={task} onUpdate={onUpdate} />
          </FieldRow>
        </div>
      </CollapsibleSection>

      {/* Development */}
      <CollapsibleSection
        title={tr('taskDetail.development')}
        open={devOpen}
        onToggle={() => setDevOpen(v => !v)}
      >
        <CreateBranchPanel task={task} projectKey={projectKey} />
      </CollapsibleSection>

      {/* Note — exported as the "Note" column in the tasks report */}
      <CollapsibleSection
        title={tr('taskDetail.note')}
        open={noteOpen}
        onToggle={() => setNoteOpen(v => !v)}
      >
        <NoteSection task={task} onUpdate={onUpdate} />
      </CollapsibleSection>

      {/* Footer */}
      <div className="mt-auto px-5 py-4 border-t border-border">
        <div className="text-xs text-fg-subtle space-y-1 mb-3">
          <p>{tr('taskDetail.createdAt', { time: formatRelative(task.createdAt) })}</p>
          <p>{tr('taskDetail.updatedAt', { time: formatRelative(task.updatedAt) })}</p>
        </div>
        <button className="flex items-center gap-1.5 text-xs text-fg-muted hover:text-fg transition-colors">
          <Zap className="w-3.5 h-3.5" />
          {tr('taskDetail.configure')}
        </button>
      </div>
    </div>
  )
}

// ─── Status Dropdown ──────────────────────────────────────────────────────────

// Map a column name to one of the built-in status palette keys (display only;
// the backend re-derives the stored status enum independently).
function columnStatusKey(name?: string | null): string {
  const n = (name ?? '').toLowerCase()
  if (/(done|complete|closed|hoàn thành|xong)/.test(n)) return 'done'
  if (/(review|testing|qa|duyệt|kiểm thử)/.test(n)) return 'in_review'
  if (/(progress|doing|active|wip|đang|thực hiện)/.test(n)) return 'in_progress'
  return 'todo'
}

// Visual for a column: prefer its own color, else fall back to the status palette.
function columnVisual(col?: BoardColumn | null): { bg: string; fg: string } {
  if (col?.color) return { bg: col.color, fg: '#FFFFFF' }
  const sc = STATUS_CONFIG[columnStatusKey(col?.name)] ?? STATUS_CONFIG.todo
  return { bg: sc.hexBg, fg: sc.hexColor }
}

// Status = the task's board column. Columns are the source of truth, so the
// dropdown lists the project's actual columns; picking one moves the task there.
function StatusDropdown({ task, columns, onUpdate }: { task: Task; columns: BoardColumn[]; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  const currentCol = columns.find((c) => c.id === task.columnId) ?? null
  const current = columnVisual(currentCol)
  const fallbackLabel = tr('status.' + task.status)
  const currentLabel = currentCol?.name ?? fallbackLabel

  useEffect(() => {
    if (!open) return
    const h = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', h)
    return () => document.removeEventListener('mousedown', h)
  }, [open])

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(v => !v)}
        style={{ backgroundColor: current.bg, color: current.fg }}
        className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm font-semibold transition-opacity hover:opacity-90"
      >
        {currentLabel}
        <ChevronDown className="w-3.5 h-3.5" />
      </button>
      {open && (
        <div className="absolute top-full left-0 right-0 mt-1 z-50 rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden">
          {columns.map((col) => {
            const isCurrent = col.id === task.columnId
            return (
              <button
                key={col.id}
                onClick={() => { if (!isCurrent) onUpdate({ columnId: col.id }); setOpen(false) }}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-bg-subtle transition-colors"
              >
                <span
                  className="w-2.5 h-2.5 rounded-full shrink-0"
                  style={{ backgroundColor: columnVisual(col).bg }}
                />
                <span className={cn('flex-1 text-left text-fg', isCurrent && 'font-medium')}>
                  {col.name}
                </span>
                {isCurrent && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ─── Assignee Field ───────────────────────────────────────────────────────────

function AssigneeField({ task, members, onUpdate, variant = 'dev' }: {
  task: Task; members: Array<{ userId: string; user: { fullName: string; avatarUrl: string | null } }>
  onUpdate: (dto: UpdateTaskDto) => void
  variant?: 'dev' | 'qa'
}) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const { user: me } = useAuthStore()
  const canAssign = usePermissions().includes('assign_tasks')

  const isQa = variant === 'qa'
  const currentId = isQa ? task.qaAssigneeId : task.assigneeId
  const setAssignee = (userId: string | null | undefined) =>
    onUpdate(isQa ? { qaAssigneeId: userId ?? null } : { assigneeId: userId ?? null })

  useEffect(() => {
    if (!open) return
    const h = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', h)
    return () => document.removeEventListener('mousedown', h)
  }, [open])

  // Use the task's user object directly (from store/server); fallback to members list lookup
  const assigneeUser = (isQa ? task.qaAssignee : task.assignee) ?? members.find(m => m.userId === currentId)?.user ?? null

  // Without assign_tasks the backend rejects any assignee change — show read-only.
  if (!canAssign) {
    return (
      <div className="flex items-center gap-1.5">
        {assigneeUser
          ? <><Avatar name={assigneeUser.fullName} avatarUrl={assigneeUser.avatarUrl} size="xs" /><span className="text-sm text-fg">{assigneeUser.fullName}</span></>
          : <span className="text-sm text-fg-muted">{tr('common.unassigned')}</span>
        }
      </div>
    )
  }

  return (
    <div ref={ref} className="relative">
      <button onClick={() => setOpen(v => !v)} className="flex items-center gap-1.5 hover:text-fg transition-colors">
        {assigneeUser
          ? <><Avatar name={assigneeUser.fullName} avatarUrl={assigneeUser.avatarUrl} size="xs" /><span className="text-sm text-fg">{assigneeUser.fullName}</span></>
          : <span className="text-sm text-fg-muted">{tr('common.unassigned')}</span>
        }
      </button>
      {!currentId && (
        <button
          onClick={() => { setAssignee(me?.id); setOpen(false) }}
          className="ml-2 text-xs text-accent hover:underline"
        >
          {tr('taskDetail.assignToMe')}
        </button>
      )}
      {open && (
        <div className="absolute top-full left-0 mt-1 z-50 w-56 rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden">
          <button
            onClick={() => { setAssignee(null); setOpen(false) }}
            className="w-full text-left px-3 py-2 text-sm text-fg-muted hover:bg-bg-subtle"
          >
            {tr('common.unassigned')}
          </button>
          {members.map(m => (
            <button
              key={m.userId}
              onClick={() => { setAssignee(m.userId); setOpen(false) }}
              className={cn('w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-bg-subtle', m.userId === currentId && 'bg-bg-active')}
            >
              <Avatar name={m.user.fullName} avatarUrl={m.user.avatarUrl} size="xs" />
              {m.user.fullName}
              {m.userId === currentId && <Check className="w-3.5 h-3.5 ml-auto text-accent" />}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Labels Field ─────────────────────────────────────────────────────────────

const LABEL_COLORS = [
  '#FF5630','#FF7A00','#FFA500','#FFAB00',
  '#36B37E','#00B8D9','#0052CC','#6554C0',
  '#97A0AF','#42526E',
]

function LabelsField({ task, labels, projectId, onUpdate, variant = 'label' }: {
  task: Task
  labels: Array<{ id: string; name: string; color: string }>
  projectId: string
  onUpdate: (dto: UpdateTaskDto) => void
  variant?: 'label' | 'requester'
}) {
  const { t: tr } = useTranslation()
  const qc = useQueryClient()
  const toast = useToast()
  const [open, setOpen] = useState(false)
  const [newName, setNewName] = useState('')
  const [newColor, setNewColor] = useState(LABEL_COLORS[5])
  const [creating, setCreating] = useState(false)
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [pendingDelete, setPendingDelete] = useState<{ id: string; name: string } | null>(null)
  const ref = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const isReq = variant === 'requester'
  const selected = (isReq ? task.requesters : task.labels) ?? []
  const labelIds = selected.map(l => l.id)
  const emitIds = (ids: string[]) => onUpdate(isReq ? { requesterIds: ids } : { labelIds: ids })
  const createEntry = isReq ? requestersApi.create : labelsApi.create
  const deleteEntry = isReq ? requestersApi.delete : labelsApi.delete
  const listQueryKey = isReq ? ['requesters', projectId] : ['labels', projectId]

  useEffect(() => {
    if (!open) return
    const h = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) { setOpen(false); setCreating(false) } }
    document.addEventListener('mousedown', h)
    return () => document.removeEventListener('mousedown', h)
  }, [open])

  useEffect(() => {
    if (creating) inputRef.current?.focus()
  }, [creating])

  const toggle = (labelId: string) => {
    const next = labelIds.includes(labelId)
      ? labelIds.filter(id => id !== labelId)
      : [...labelIds, labelId]
    emitIds(next)
  }

  const remove = (e: React.MouseEvent, labelId: string) => {
    e.stopPropagation()
    emitIds(labelIds.filter(id => id !== labelId))
  }

  const createLabel = async () => {
    const name = newName.trim()
    if (!name) return
    const created = await createEntry(projectId, { name, color: newColor })
    qc.invalidateQueries({ queryKey: listQueryKey })
    emitIds([...labelIds, created.id])
    setNewName('')
    setCreating(false)
  }

  const confirmDelete = async () => {
    const entry = pendingDelete
    if (!entry) return
    setDeletingId(entry.id)
    try {
      await deleteEntry(projectId, entry.id)
      // Drop it from this task's selection too, if it was assigned.
      if (labelIds.includes(entry.id)) emitIds(labelIds.filter(id => id !== entry.id))
      qc.invalidateQueries({ queryKey: listQueryKey })
      toast.success(tr('taskDetail.deleteEntrySuccess', { name: entry.name }))
      setPendingDelete(null)
    } catch {
      toast.error(tr('taskDetail.deleteEntryError', { name: entry.name }))
    } finally {
      setDeletingId(null)
    }
  }

  return (
    <div ref={ref} className="relative">
      {/* Chips */}
      <div className="flex flex-wrap gap-1">
        {selected.length === 0 && !open && (
          <span className="text-sm text-fg-muted">{tr('common.none')}</span>
        )}
        {selected.map(l => (
          <span
            key={l.id}
            className="flex items-center gap-1 px-2 py-0.5 rounded-[4px] text-xs font-medium text-white group"
            style={{ backgroundColor: l.color }}
          >
            {l.name}
            <button
              onClick={(e) => remove(e, l.id)}
              className="opacity-0 group-hover:opacity-100 transition-opacity ml-0.5 hover:bg-black/20 rounded-full"
            >
              <X className="w-2.5 h-2.5" />
            </button>
          </span>
        ))}
        <button
          onClick={() => setOpen(v => !v)}
          className="flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-xs border border-dashed border-border text-fg-muted hover:border-accent hover:text-accent transition-colors"
        >
          <Plus className="w-3 h-3" />
        </button>
      </div>

      {/* Dropdown */}
      {open && (
        <div className="absolute top-full left-0 mt-1 z-50 w-56 rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden">
          {/* Existing labels */}
          <div className="max-h-40 overflow-y-auto">
            {labels.length === 0 && !creating && (
              <p className="px-3 py-2 text-xs text-fg-muted">{tr('taskDetail.noLabels')}</p>
            )}
            {labels.map(l => {
              const active = labelIds.includes(l.id)
              return (
                <div key={l.id} className="group/row flex items-center hover:bg-bg-subtle">
                  <button
                    onClick={() => toggle(l.id)}
                    className="flex-1 min-w-0 flex items-center gap-2 px-3 py-1.5 text-sm"
                  >
                    <span className="w-3 h-3 rounded-full shrink-0" style={{ backgroundColor: l.color }} />
                    <span className="flex-1 text-left text-fg truncate">{l.name}</span>
                    {active && <Check className="w-3.5 h-3.5 text-accent shrink-0" />}
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); setPendingDelete({ id: l.id, name: l.name }) }}
                    disabled={deletingId === l.id}
                    title={tr('common.delete')}
                    className="shrink-0 p-1.5 mr-1 rounded text-fg-muted opacity-0 group-hover/row:opacity-100 hover:text-danger hover:bg-danger/10 transition-opacity disabled:opacity-40"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              )
            })}
          </div>

          {/* Create inline */}
          {creating ? (
            <div className="border-t border-border p-2 space-y-2">
              <input
                ref={inputRef}
                value={newName}
                onChange={e => setNewName(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') createLabel(); if (e.key === 'Escape') setCreating(false) }}
                placeholder={tr('taskDetail.labelPlaceholder')}
                className="w-full text-sm bg-bg-elevated border border-border rounded-md px-2 py-1 focus:outline-none focus:ring-1 focus:ring-accent text-fg placeholder:text-fg-muted"
              />
              <div className="flex gap-1 flex-wrap">
                {LABEL_COLORS.map(c => (
                  <button
                    key={c}
                    onClick={() => setNewColor(c)}
                    className="w-5 h-5 rounded-full transition-transform hover:scale-110"
                    style={{ backgroundColor: c, outline: c === newColor ? '2px solid white' : 'none', outlineOffset: '-3px' }}
                  />
                ))}
              </div>
              <div className="flex gap-1.5">
                <button
                  onClick={createLabel}
                  disabled={!newName.trim()}
                  className="flex-1 text-xs py-1 rounded-md bg-accent text-white disabled:opacity-40"
                >
                  {tr('common.create')}
                </button>
                <button onClick={() => setCreating(false)} className="text-xs py-1 px-2 rounded-md border border-border text-fg-muted hover:text-fg">
                  {tr('common.cancel')}
                </button>
              </div>
            </div>
          ) : (
            <button
              onClick={() => setCreating(true)}
              className="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-fg-muted border-t border-border hover:bg-bg-subtle"
            >
              <Plus className="w-3 h-3" /> {tr('taskDetail.createLabel')}
            </button>
          )}
        </div>
      )}

      <ConfirmDialog
        open={!!pendingDelete}
        onClose={() => setPendingDelete(null)}
        onConfirm={confirmDelete}
        loading={!!deletingId}
        title={tr('common.delete')}
        message={pendingDelete ? tr('taskDetail.deleteEntryConfirm', { name: pendingDelete.name }) : ''}
        confirmLabel={tr('common.delete')}
        cancelLabel={tr('common.cancel')}
      />
    </div>
  )
}

// ─── Priority Field ───────────────────────────────────────────────────────────

function PriorityField({ task, onUpdate }: { task: Task; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const pc = PRIORITY_CONFIG[task.priority]
  const currentLabel = tr('priority.' + task.priority)

  useEffect(() => {
    if (!open) return
    const h = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', h)
    return () => document.removeEventListener('mousedown', h)
  }, [open])

  return (
    <div ref={ref} className="relative">
      <button onClick={() => setOpen(v => !v)} className="flex items-center gap-1.5 hover:opacity-80 transition-opacity">
        {pc
          ? <><img src={pc.svg} alt={currentLabel} width={16} height={16} className="shrink-0" />
              <span className="text-sm" style={{ color: pc.hexColor }}>{currentLabel}</span></>
          : <span className="text-sm text-fg-muted">{tr('common.none')}</span>
        }
      </button>
      {open && (
        <div className="absolute top-full left-0 mt-1 z-50 w-40 rounded-lg border border-border bg-bg-surface shadow-app-md overflow-hidden">
          {Object.entries(PRIORITY_CONFIG).map(([v, c]) => {
            const label = tr('priority.' + v)
            return (
              <button
                key={v}
                onClick={() => { onUpdate({ priority: v }); setOpen(false) }}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-bg-subtle"
              >
                <img src={c.svg} alt={label} width={16} height={16} className="shrink-0" />
                <span style={{ color: c.hexColor }}>{label}</span>
                {v === task.priority && <Check className="w-3.5 h-3.5 text-accent ml-auto" />}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ─── Due Date Field ───────────────────────────────────────────────────────────

function DueDateField({ task, onUpdate }: { task: Task; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const timezone = useSiteTimezone()
  const [editing, setEditing] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  const isOverdue =
    task.dueDate && task.status !== 'done' && new Date(task.dueDate) < new Date()

  useEffect(() => {
    if (editing) inputRef.current?.showPicker?.()
  }, [editing])

  const fmt = (date: string) => formatZonedDate(date, timezone, 'en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
  })

  const handleQuick = (days: number) => {
    const d = new Date()
    d.setDate(d.getDate() + days)
    const iso = d.toISOString().slice(0, 10)
    onUpdate({ dueDate: iso })
    setEditing(false)
  }

  if (editing) {
    return (
      <div className="relative">
        <input
          ref={inputRef}
          type="date"
          defaultValue={task.dueDate?.slice(0, 10) ?? ''}
          onBlur={(e) => { onUpdate({ dueDate: e.target.value || undefined }); setEditing(false) }}
          onChange={(e) => { if (e.target.value) { onUpdate({ dueDate: e.target.value }); setEditing(false) } }}
          className="w-full text-sm text-fg bg-bg-elevated border border-accent rounded-md px-2 py-1 focus:outline-none"
          autoFocus
        />
        <div className="absolute top-full left-0 mt-1 z-50 flex gap-1 bg-bg-surface border border-border rounded-lg p-1.5 shadow-app-md">
          {[
            [tr('filter.today'), 0],
            [tr('taskDetail.tomorrow'), 1],
            [tr('taskDetail.nextWeek'), 7],
          ].map(([label, days]) => (
            <button
              key={label as string}
              onClick={() => handleQuick(days as number)}
              className="px-2 py-1 text-xs rounded-md bg-bg-elevated hover:bg-accent hover:text-white transition-colors whitespace-nowrap"
            >
              {label}
            </button>
          ))}
          <button
            onClick={() => { onUpdate({ dueDate: null }); setEditing(false) }}
            className="px-2 py-1 text-xs rounded-md text-danger hover:bg-danger/10 transition-colors"
          >
            {tr('filter.clear')}
          </button>
        </div>
      </div>
    )
  }

  return (
    <button
      onClick={() => setEditing(true)}
      className={cn('w-fit flex items-center gap-1 text-sm rounded-[4px] px-1.5 py-0.5 border transition-colors', isOverdue ? 'bg-[#FFEBE6] text-[#ae2e24] hover:bg-[#FFEBE6]/80' : 'bg-white text-[#292a2e] hover:bg-bg-subtle')}
      style={{ borderColor: isOverdue ? '#ae2e24' : '#0B120E24' }}
    >
      {isOverdue && (
        <svg width="14" height="14" fill="none" viewBox="0 0 16 16" className="shrink-0">
          <path fill="currentColor" fillRule="evenodd" d="M5.7 1.383c.996-1.816 3.605-1.817 4.602-.002l5.35 9.73C16.612 12.86 15.346 15 13.35 15H2.667C.67 15-.594 12.862.365 11.113zm3.288.72a1.125 1.125 0 0 0-1.972.002L1.68 11.834c-.41.75.132 1.666.987 1.666H13.35c.855 0 1.398-.917.986-1.667z" clipRule="evenodd"/>
          <path fill="currentColor" fillRule="evenodd" d="M7.25 9V4h1.5v5z" clipRule="evenodd"/>
          <path fill="currentColor" d="M9 11.25a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/>
        </svg>
      )}
      <Calendar className="w-3.5 h-3.5" />
      {task.dueDate ? fmt(task.dueDate) : <span className="text-fg-muted">{tr('common.none')}</span>}
    </button>
  )
}

// ─── Time Tracking Field ──────────────────────────────────────────────────────

function TimeTrackingField({ task, projectId, variant = 'dev' }: { task: Task; projectId: string; variant?: 'dev' | 'qa' }) {
  const { t: tr } = useTranslation()
  const isQa = variant === 'qa'
  const [showModal, setShowModal] = useState(false)
  const [timeInput, setTimeInput] = useState('')
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [inputError, setInputError] = useState('')
  const [remainingMode, setRemainingMode] = useState<'auto' | 'manual' | 'keep'>('auto')
  const [manualRemaining, setManualRemaining] = useState('')
  const [description, setDescription] = useState('')
  const toast = useToast()
  const qc = useQueryClient()

  const logged    = Number(isQa ? task.qaLoggedHours : task.loggedHours)   || 0
  const estimated = Number(isQa ? task.qaEstimatedHours : task.estimatedHours) || 0
  const hasLogged = logged > 0
  const overBudget = estimated > 0 && logged > estimated
  const pct = estimated > 0
    ? Math.min((logged / estimated) * 100, 100)
    : hasLogged ? 100 : 0
  const fillColor = overBudget ? '#FF5630' : '#0052CC'
  const tooltipText = estimated > 0
    ? tr('taskDetail.loggedTooltipEstimated', { logged: formatTimeHours(logged), est: formatTimeHours(estimated), pct: Math.round(pct) })
    : tr('taskDetail.loggedTooltip', { logged: formatTimeHours(logged) })

  const { mutate: doLogTime, isPending } = useMutation({
    // The ONLY request whose failure means "could not log time" is this one.
    mutationFn: (h: number) =>
      tasksApi.logTime(projectId, task.id, {
        hours: h,
        loggedDate: date,
        description: description.trim() || undefined,
        isQa,
      }),
    onSuccess: async (loggedTask, h) => {
      // Reflect the logged time immediately. This runs BEFORE the remaining-estimate
      // adjustment so success never depends on a second request — under the realtime
      // `task:updated` invalidation burst that second request can be slow or fail and
      // previously surfaced as a false "could not log time" with a stale UI.
      qc.setQueryData(['task', projectId, task.id], loggedTask)
      qc.invalidateQueries({ queryKey: ['tasks', projectId] })
      toast.success(tr('taskDetail.logTimeSuccess'))
      setTimeInput(''); setDescription(''); setManualRemaining('')
      setShowModal(false)

      // Best-effort: adjust the remaining estimate. A failure here is non-fatal — the
      // time is already logged — so it must not toast an error or block the UI.
      try {
        const setEstimate = (val: number) =>
          tasksApi.update(projectId, task.id, isQa ? { qaEstimatedHours: val } : { estimatedHours: val })
        let updated: Task | undefined
        if (remainingMode === 'auto' && estimated > 0) {
          const newEstimated = Math.max(logged + h, estimated - h)
          if (newEstimated !== estimated) updated = await setEstimate(newEstimated)
        } else if (remainingMode === 'manual') {
          updated = await setEstimate(logged + h + (parseTimeInput(manualRemaining) || 0))
        }
        if (updated) qc.setQueryData(['task', projectId, task.id], updated)
      } catch { /* remaining estimate unchanged; the time was logged */ }
    },
    onError: () => toast.error(tr('taskDetail.logTimeFailed')),
  })

  const logTime = () => {
    const h = parseTimeInput(timeInput)
    if (!h) { setInputError(tr('taskDetail.timeFormatError')); return }
    setInputError('')
    doLogTime(h)
  }

  const closeModal = () => {
    setShowModal(false)
    setTimeInput(''); setInputError(''); setDescription(''); setManualRemaining('')
    setRemainingMode('auto')
  }

  return (
    <div className="w-full">
      {/* ── Display ── */}
      {!hasLogged ? (
        <button
          onClick={() => setShowModal(true)}
          className="text-sm hover:text-accent transition-colors"
          style={{ color: '#42526E' }}
        >
          {tr('taskDetail.noTimeLogged')}
        </button>
      ) : (
        <button onClick={() => setShowModal(true)} title={tooltipText} className="w-full text-left group space-y-1">
          {/* Bar */}
          <div className="w-full rounded-sm overflow-hidden" style={{ height: 4, backgroundColor: '#DFE1E6' }}>
            <div
              className="h-full rounded-sm transition-all duration-300"
              style={{ width: `${pct}%`, backgroundColor: fillColor }}
            />
          </div>
          {/* Label */}
          <p
            className="text-xs leading-none group-hover:opacity-75 transition-opacity"
            style={{ color: overBudget ? '#FF5630' : '#42526E', fontSize: 13 }}
          >
            {estimated > 0
              ? tr('taskDetail.loggedEstimated', { logged: formatTimeHours(logged), est: formatTimeHours(estimated) })
              : tr('taskDetail.loggedOnly', { logged: formatTimeHours(logged) })}
          </p>
        </button>
      )}

      {/* ── Modal ── */}
      {showModal && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={closeModal} />
          <div className="relative bg-bg-surface border border-border rounded-xl shadow-app-lg w-[500px] overflow-hidden">
            {/* Header */}
            <div className="flex items-center justify-between px-5 py-3.5 border-b border-border">
              <h3 className="text-sm font-semibold text-fg">{tr('taskDetail.logTime')}</h3>
              <button onClick={closeModal} className="text-fg-muted hover:text-fg transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="px-5 py-4 space-y-4">
              {/* Time spent */}
              <div>
                <label className="text-xs font-medium text-fg-muted mb-1.5 block">{tr('taskDetail.timeSpent')}</label>
                <input
                  autoFocus
                  type="text" value={timeInput}
                  onChange={(e) => { setTimeInput(e.target.value); setInputError('') }}
                  onKeyDown={(e) => e.key === 'Enter' && logTime()}
                  placeholder={tr('taskDetail.timePlaceholder')}
                  className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-muted"
                />
                {inputError
                  ? <p className="text-xs text-danger mt-1">{inputError}</p>
                  : <p className="text-xs text-fg-subtle mt-1">{tr('taskDetail.timeAccepts')}</p>
                }
              </div>

              {/* Date logged */}
              <div>
                <label className="text-xs font-medium text-fg-muted mb-1.5 block">{tr('taskDetail.dateLogged')}</label>
                <input
                  type="date" value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full h-8 rounded-lg border border-border bg-bg-subtle px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                />
              </div>

              {/* Remaining estimate */}
              <div>
                <label className="text-xs font-medium text-fg-muted mb-1.5 block">{tr('taskDetail.remainingEstimate')}</label>
                <div className="space-y-1.5">
                  {([
                    { value: 'auto', label: tr('taskDetail.remainingAuto') },
                    { value: 'manual', label: tr('taskDetail.remainingManual') },
                    { value: 'keep', label: tr('taskDetail.remainingKeep') },
                  ] as const).map(opt => (
                    <label key={opt.value} className="flex items-center gap-2 cursor-pointer select-none">
                      <input
                        type="radio" name="rem" value={opt.value}
                        checked={remainingMode === opt.value}
                        onChange={() => setRemainingMode(opt.value)}
                        className="accent-accent w-3.5 h-3.5"
                      />
                      <span className="text-sm text-fg">{opt.label}</span>
                    </label>
                  ))}
                </div>
                {remainingMode === 'manual' && (
                  <input
                    type="text" value={manualRemaining}
                    onChange={(e) => setManualRemaining(e.target.value)}
                    placeholder={tr('taskDetail.timeExample')}
                    autoFocus
                    className="mt-2 w-full h-8 rounded-lg border border-border bg-bg-subtle px-2.5 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-muted"
                  />
                )}
              </div>

              {/* Work description */}
              <div>
                <label className="text-xs font-medium text-fg-muted mb-1.5 block">{tr('taskDetail.workDescription')}</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder={tr('taskDetail.workDescPlaceholder')}
                  rows={2}
                  className="w-full rounded-lg border border-border bg-bg-subtle px-2.5 py-2 text-sm text-fg resize-none focus:outline-none focus:ring-2 focus:ring-accent placeholder:text-fg-muted"
                />
              </div>
            </div>

            {/* Footer */}
            <div className="flex gap-2 justify-end px-5 py-3.5 border-t border-border">
              <Button variant="ghost" size="sm" onClick={closeModal}>{tr('common.cancel')}</Button>
              <Button variant="primary" size="sm" disabled={!timeInput.trim()} loading={isPending} onClick={logTime}>
                {tr('common.save')}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Start Date Field ─────────────────────────────────────────────────────────

function StartDateField({ task, onUpdate }: { task: Task; onUpdate: (dto: UpdateTaskDto) => void }) {
  const { t: tr } = useTranslation()
  const toast = useToast()

  return (
    <input
      type="date"
      defaultValue={(task as Task & { startDate?: string }).startDate?.slice(0, 10) ?? ''}
      max={task.dueDate?.slice(0, 10) ?? ''}
      onChange={(e) => {
        const val = e.target.value
        if (task.dueDate && val > task.dueDate.slice(0, 10)) {
          toast.error(tr('taskDetail.startAfterDue'))
          e.target.value = (task as Task & { startDate?: string }).startDate?.slice(0, 10) ?? ''
          return
        }
        onUpdate({ dueDate: task.dueDate } as UpdateTaskDto) // trigger save via parent
      }}
      className="text-sm text-fg bg-transparent focus:outline-none cursor-pointer hover:text-accent"
    />
  )
}

// ─── Create Branch Panel ──────────────────────────────────────────────────────

function CreateBranchPanel({ task, projectKey = 'TASK' }: { task: Task; projectKey?: string }) {
  const { t: tr } = useTranslation()
  const [expanded, setExpanded] = useState(false)
  const [copied, setCopied] = useState(false)
  const toast = useToast()

  const slug = task.title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .slice(0, 40)
  const taskId = task.taskNumber != null
    ? `${projectKey}-${task.taskNumber}`
    : `${projectKey}-${(task.position ?? 0) + 1}`
  const [branchName, setBranchName] = useState(`${taskId.toLowerCase()}-${slug}`)
  const command = `git checkout -b ${branchName}`

  const copyCommand = () => {
    navigator.clipboard.writeText(command)
    setCopied(true)
    toast.success(tr('taskDetail.commandCopied'))
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="space-y-2">
      <div className="flex gap-1">
        <button
          onClick={() => setExpanded(v => !v)}
          className="flex-1 flex items-center justify-between gap-1.5 px-3 py-2 text-sm border border-border rounded-lg text-fg-muted hover:text-fg hover:border-accent/50 transition-colors"
        >
          <span className="flex items-center gap-1.5">
            <GitBranch className="w-3.5 h-3.5" /> {tr('taskDetail.createBranch')}
          </span>
          <ChevronDown className={cn('w-3.5 h-3.5 transition-transform', expanded && 'rotate-180')} />
        </button>
      </div>

      {expanded && (
        <div className="rounded-lg border border-border bg-bg-elevated p-3 space-y-2">
          <p className="text-xs font-semibold text-fg-muted uppercase tracking-wide">
            {tr('taskDetail.gitCreateBranch')}
          </p>
          <div className="flex items-center gap-2">
            <input
              value={branchName}
              onChange={(e) => setBranchName(e.target.value)}
              className="flex-1 bg-bg-subtle border border-border rounded-md px-2 py-1.5 text-xs font-mono text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            />
            <button
              onClick={copyCommand}
              title={copied ? tr('taskDetail.copied') : tr('taskDetail.copyCommand')}
              className={cn(
                'shrink-0 flex items-center justify-center w-8 h-8 rounded-md border border-border transition-colors',
                copied ? 'bg-success/10 border-success text-success' : 'hover:bg-bg-subtle text-fg-muted hover:text-fg',
              )}
            >
              {copied ? <Check className="w-3.5 h-3.5" /> : <AlignLeft className="w-3.5 h-3.5" />}
            </button>
          </div>
          <p className="text-xs font-mono text-fg-muted bg-bg-subtle rounded px-2 py-1 select-all">
            {command}
          </p>
        </div>
      )}

      <div className="flex gap-1.5 text-xs text-fg-muted">
        <button className="flex items-center gap-1 hover:text-accent transition-colors">
          <Link2 className="w-3 h-3" /> {tr('taskDetail.linkPr')}
        </button>
        <span>·</span>
        <button className="flex items-center gap-1 hover:text-accent transition-colors">
          <Link2 className="w-3 h-3" /> {tr('taskDetail.linkCommit')}
        </button>
      </div>
    </div>
  )
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function CollapsibleSection({ title, open, onToggle, children, badge }: {
  title: string; open: boolean; onToggle: () => void
  children: React.ReactNode; badge?: React.ReactNode
}) {
  return (
    <div className="border-b border-border">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between px-4 py-2.5 text-xs font-semibold text-fg-subtle uppercase tracking-wide hover:text-fg transition-colors"
      >
        <span className="flex items-center gap-1.5">{badge}{title}</span>
        {open ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronRight className="w-3.5 h-3.5" />}
      </button>
      {open && <div className="px-4 pb-3">{children}</div>}
    </div>
  )
}

function FieldRow({ label, icon, children, align = 'start' }: {
  label: string; icon: React.ReactNode; children: React.ReactNode; align?: 'start' | 'center'
}) {
  return (
    <div className={cn('flex gap-2 py-2 border-b border-border/50 last:border-0', align === 'center' ? 'items-center' : 'items-start')}>
      <div className={cn('flex items-center gap-1.5 w-35 shrink-0 text-xs text-fg-muted', align === 'start' && 'pt-0.5')}>
        {icon}{label}
      </div>
      <div className="flex-1 min-w-0">{children}</div>
    </div>
  )
}

function TimelineSkeleton() {
  return (
    <div className="space-y-3">
      {[...Array(3)].map((_, i) => (
        <div key={i} className="flex gap-2">
          <Skeleton className="w-7 h-7 rounded-full shrink-0" />
          <Skeleton className="flex-1 h-12 rounded-lg" />
        </div>
      ))}
    </div>
  )
}
