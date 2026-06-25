import { useSiteTimezone } from '@/hooks/useSiteTimezone'
import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import {
  RefreshCw, Download, CheckCircle2, RefreshCcw, PlusCircle,
  Clock, AlertTriangle, Ban,
} from 'lucide-react'
import { reportsApi, type ProjectSummary } from '@/api/reports'
import { projectsApi } from '@/api/projects'
import { Avatar, Button, EmptyState, Skeleton } from '@/components/ui'
import { formatRelative } from '@/lib/utils'
import { formatZonedDateTime } from '@/lib/timezones'

// ─── Config ─────────────────────────────────────────────────────────────────

function getProjectKey(name: string): string {
  const words = name.trim().split(/\s+/)
  return words.length > 1
    ? words.map((w) => w[0]).join('').toUpperCase()
    : name.slice(0, 5).toUpperCase()
}

const PRIORITY_CONFIG: Record<string, { color: string }> = {
  urgent: { color: '#ef4444' },
  high: { color: '#f97316' },
  medium: { color: '#eab308' },
  low: { color: '#3b82f6' },
  lowest: { color: '#6b7280' },
}
const PRIORITY_ORDER = ['urgent', 'high', 'medium', 'low', 'lowest']

const TYPE_CONFIG: Record<string, { color: string }> = {
  task: { color: '#3b82f6' },
  subtask: { color: '#8b5cf6' },
}
const TYPE_ORDER = ['task', 'subtask']

// ─── Page ───────────────────────────────────────────────────────────────────

export function SummaryPage() {
  const { t } = useTranslation()
  const { projectId = '' } = useParams<{ projectId: string }>()

  const { data: project } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectsApi.get(projectId),
    enabled: !!projectId,
    staleTime: 10 * 60_000,
  })
  const projectKey = project ? getProjectKey(project.name) : 'TASK'

  const { data, isLoading, isFetching, refetch } = useQuery({
    queryKey: ['summary', projectId],
    queryFn: () => reportsApi.summary(projectId),
    enabled: !!projectId,
    // Always pull fresh stats when opening the page so board changes (new columns,
    // moved tasks, etc.) are reflected immediately instead of a 30s-stale cache.
    staleTime: 0,
    refetchOnMount: 'always',
  })

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="flex items-start justify-between gap-4 px-6 py-4 border-b border-border shrink-0">
        <div>
          <h1 className="text-base font-semibold text-fg">{t('pages.summary')}</h1>
          <p className="text-xs text-fg-muted mt-0.5">
            {t('pages.summarySubtitle')}
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching}>
            <RefreshCw className={`w-4 h-4 ${isFetching ? 'animate-spin' : ''}`} /> {t('summary.refresh')}
          </Button>
          <Button variant="outline" size="sm" onClick={() => window.print()}>
            <Download className="w-4 h-4" /> {t('summary.exportReport')}
          </Button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin p-6 space-y-6">
        {/* KPI cards */}
        <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-4">
          {isLoading ? (
            [...Array(6)].map((_, i) => <Skeleton key={i} className="h-24 rounded-card" />)
          ) : (
            <>
              <KpiCard icon={<CheckCircle2 />} color="text-success" value={data?.kpis.completed ?? 0}
                label={t('summary.completed')} hint={t('summary.completedHint')} />
              <KpiCard icon={<RefreshCcw />} color="text-info" value={data?.kpis.updated ?? 0}
                label={t('summary.updated')} hint={t('summary.updatedHint')} />
              <KpiCard icon={<PlusCircle />} color="text-accent" value={data?.kpis.created ?? 0}
                label={t('summary.created')} hint={t('summary.createdHint')} />
              <KpiCard icon={<Clock />} color="text-warning" value={data?.kpis.dueSoon ?? 0}
                label={t('summary.dueSoon')} hint={t('summary.dueSoonHint')} />
              <KpiCard icon={<AlertTriangle />} color="text-danger" value={data?.kpis.overdue ?? 0}
                label={t('summary.overdue')} hint={t('summary.overdueHint')} />
              <KpiCard icon={<Ban />} color="text-fg-muted" value={data?.kpis.blocked ?? 0}
                label={t('summary.blocked')} hint={t('summary.blockedHint')} />
            </>
          )}
        </div>

        {/* Two-column grid */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          <StatusOverview data={data} loading={isLoading} />
          <RecentActivities data={data} loading={isLoading} projectKey={projectKey} />
          <PriorityDistribution data={data} loading={isLoading} />
          <TaskTypes data={data} loading={isLoading} />
        </div>

        {/* Team workload — full width */}
        <TeamWorkload data={data} loading={isLoading} />
      </div>
    </div>
  )
}

// ─── KPI Card ───────────────────────────────────────────────────────────────

function KpiCard({ icon, color, value, label, hint }: {
  icon: ReactNode; color: string; value: number; label: string; hint: string
}) {
  return (
    <div className="rounded-card border border-border bg-bg-elevated p-4 transition-colors hover:border-accent/50">
      <div className={`mb-2 ${color}`}>
        <span className="[&>svg]:w-5 [&>svg]:h-5">{icon}</span>
      </div>
      <p className="text-2xl font-bold text-fg">{value}</p>
      <p className="text-xs font-medium text-fg mt-0.5">{label}</p>
      <p className="text-[11px] text-fg-subtle mt-1 leading-tight">{hint}</p>
    </div>
  )
}

// ─── Card shell ─────────────────────────────────────────────────────────────

function Card({ title, description, children, className }: {
  title: string; description?: string; children: ReactNode; className?: string
}) {
  return (
    <div className={`rounded-card border border-border bg-bg-elevated p-5 ${className ?? ''}`}>
      <p className="text-sm font-semibold text-fg">{title}</p>
      {description && <p className="text-xs text-fg-muted mt-0.5 mb-4">{description}</p>}
      {!description && <div className="mb-4" />}
      {children}
    </div>
  )
}

// ─── Status Overview (donut) ────────────────────────────────────────────────

function StatusOverview({ data, loading }: { data?: ProjectSummary; loading: boolean }) {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { projectId = '' } = useParams<{ projectId: string }>()
  const slices = (data?.statusOverview ?? []).map((s) => ({
    columnId: s.columnId,
    name: s.name,
    value: s.count,
    color: s.color ?? '#6b7280',
  }))
  const total = data?.total ?? 0

  // Click a column (donut slice or legend) → open the List page filtered to it.
  const goToColumn = (columnId?: string) => {
    if (columnId) navigate(`/projects/${projectId}/list?column=${columnId}`)
  }

  return (
    <Card title={t('summary.statusOverview')} description={t('summary.statusOverviewDesc')}>
      {loading ? (
        <Skeleton className="h-64" />
      ) : slices.length === 0 ? (
        <EmptyState title={t('myTasks.emptyTitle')} />
      ) : (
        <div className="flex items-center gap-4">
          <div className="relative shrink-0" style={{ width: 300, height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={slices} dataKey="value" nameKey="name"
                  innerRadius={90} outerRadius={130} paddingAngle={2} strokeWidth={0}
                  className="cursor-pointer" onClick={(d) => {
                    const slice = d as unknown as { columnId?: string; payload?: { columnId?: string } }
                    goToColumn(slice.columnId ?? slice.payload?.columnId)
                  }}>
                  {slices.map((s) => <Cell key={s.name} fill={s.color} />)}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8, fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-2xl font-bold text-fg">{total}</span>
              <span className="text-[14px] text-fg-subtle">{t('summary.totalWorkItems')}</span>
            </div>
          </div>
          <div className="flex-1 min-w-0 max-h-52 overflow-y-auto scrollbar-thin space-y-2.5 pr-1">
            {slices.map((s) => (
              <button key={s.name} onClick={() => goToColumn(s.columnId)}
                className="flex w-full items-center gap-2.5 text-xs rounded-md px-1.5 py-1 -mx-1.5 hover:bg-bg-subtle transition-colors text-left">
                <span className="w-3 h-3 shrink-0" style={{ backgroundColor: s.color }} />
                <span className="flex-1 truncate text-fg-muted text-[16px] hover:text-accent transition-colors">{s.name}:</span>
                <span className="font-medium text-fg text-[16px]">{s.value}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </Card>
  )
}

// ─── Recent Activities ──────────────────────────────────────────────────────

function RecentActivities({ data, loading, projectKey }: {
  data?: ProjectSummary; loading: boolean; projectKey: string
}) {
  const { t } = useTranslation()
  const timezone = useSiteTimezone()
  const items = data?.recentActivities ?? []
  return (
    <Card title={t('summary.recentActivities')} description={t('summary.recentActivitiesDesc')}>
      {loading ? (
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-10 rounded-lg" />)}
        </div>
      ) : items.length === 0 ? (
        <EmptyState title={t('summary.noRecentActivity')} />
      ) : (
        <div className="max-h-[500px] overflow-y-auto scrollbar-thin space-y-3 pr-1">
          {items.map((a) => {
            const taskRef = a.taskNumber != null ? `${projectKey}-${a.taskNumber}` : null
            return (
              <div key={a.id} className="flex items-start gap-3">
                <Avatar name={a.userName ?? '?'} avatarUrl={a.userAvatar} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="text-xs text-fg leading-snug">
                    <span className="font-medium">{a.userName ?? t('summary.someone')}</span>{' '}
                    <span className="text-fg-muted">{t('activity.actions.' + a.action, { defaultValue: a.action })}</span>{' '}
                    {taskRef && <span className="font-medium text-accent">{taskRef}</span>}
                    {a.taskTitle && <span className="text-fg-muted"> · {a.taskTitle}</span>}
                  </p>
                  <p className="text-[11px] text-fg-subtle mt-0.5" title={formatRelative(a.createdAt, timezone)}>
                    {formatZonedDateTime(a.createdAt, timezone)}
                  </p>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </Card>
  )
}

// ─── Priority Distribution ──────────────────────────────────────────────────

function PriorityDistribution({ data, loading }: { data?: ProjectSummary; loading: boolean }) {
  const { t } = useTranslation()
  const map = new Map((data?.priorityDistribution ?? []).map((p) => [p.priority, p.count]))
  const bars = PRIORITY_ORDER.map((key) => ({
    name: t('priority.' + key),
    count: map.get(key) ?? 0,
    color: PRIORITY_CONFIG[key].color,
  }))

  return (
    <Card title={t('summary.priorityDistribution')} description={t('summary.priorityDistributionDesc')}>
      {loading ? (
        <Skeleton className="h-56" />
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={bars}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
            <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#8888a0' }} />
            <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#8888a0' }} />
            <Tooltip cursor={{ fill: 'rgba(255,255,255,0.04)' }}
              contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8, fontSize: 12 }} />
            <Bar dataKey="count" radius={[4, 4, 0, 0]}>
              {bars.map((b) => <Cell key={b.name} fill={b.color} />)}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      )}
    </Card>
  )
}

// ─── Task Types ─────────────────────────────────────────────────────────────

function TaskTypes({ data, loading }: { data?: ProjectSummary; loading: boolean }) {
  const { t } = useTranslation()
  const map = new Map((data?.taskTypes ?? []).map((t) => [t.type, t.count]))
  const total = data?.total ?? 0
  const rows = TYPE_ORDER
    .map((key) => ({ key, label: t('summary.type.' + key), color: TYPE_CONFIG[key].color, count: map.get(key) ?? 0 }))

  return (
    <Card title={t('summary.taskTypes')} description={t('summary.taskTypesDesc')}>
      {loading ? (
        <Skeleton className="h-56" />
      ) : (
        <div className="space-y-4">
          {rows.map((r) => {
            const pct = total > 0 ? Math.round((r.count / total) * 100) : 0
            return (
              <div key={r.key}>
                <div className="flex items-center justify-between text-xs mb-1">
                  <span className="font-medium text-fg">{r.label}</span>
                  <span className="text-fg-muted">{r.count} · {pct}%</span>
                </div>
                <div className="h-2 rounded-full bg-bg overflow-hidden">
                  <div className="h-full rounded-full transition-all duration-500"
                    style={{ width: `${pct}%`, backgroundColor: r.color }} />
                </div>
              </div>
            )
          })}
        </div>
      )}
    </Card>
  )
}

// ─── Team Workload ──────────────────────────────────────────────────────────

function TeamWorkload({ data, loading }: { data?: ProjectSummary; loading: boolean }) {
  const { t } = useTranslation()
  const members = data?.teamWorkload ?? []
  return (
    <Card title={t('summary.teamWorkload')} description={t('summary.teamWorkloadDesc')}>
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => <Skeleton key={i} className="h-20 rounded-lg" />)}
        </div>
      ) : members.length === 0 ? (
        <EmptyState title={t('summary.noAssignedTasks')} />
      ) : (
        <div className="max-h-96 overflow-y-auto scrollbar-thin grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 pr-1">
          {members.map((m) => {
            const pct = m.assigned > 0 ? Math.round((m.completed / m.assigned) * 100) : 0
            return (
              <div key={m.userId} className="rounded-lg border border-border bg-bg p-3">
                <div className="flex items-center gap-2.5">
                  <Avatar name={m.fullName} avatarUrl={m.avatarUrl} size="md" />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-fg truncate">{m.fullName}</p>
                    <p className="text-[11px] text-fg-subtle">
                      {t('summary.completedCount', { completed: m.completed, assigned: m.assigned })}
                    </p>
                  </div>
                  <span className="text-sm font-semibold text-accent">{pct}%</span>
                </div>
                <div className="mt-2.5 h-2 rounded-full bg-bg-subtle overflow-hidden">
                  <div className="h-full rounded-full bg-accent transition-all duration-500"
                    style={{ width: `${pct}%` }} />
                </div>
              </div>
            )
          })}
        </div>
      )}
    </Card>
  )
}
