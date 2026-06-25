import { useSiteTimezone } from '@/hooks/useSiteTimezone'
import { useToast } from '@/hooks/useToast'
import { useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import { format, subDays } from 'date-fns'
import { CheckCircle2, ListTodo, Percent, Clock, AlertTriangle, Timer, Gauge, Download } from 'lucide-react'
import { reportsApi, type DeveloperGrade, type DevReportParams } from '@/api/reports'
import { membersApi } from '@/api/members'
import { projectsApi } from '@/api/projects'
import { Avatar, Button, Skeleton, EmptyState, PriorityBadge, StatusBadge } from '@/components/ui'
import { TaskDetailModal } from '@/pages/board/components/TaskDetailModal'
import { formatZonedDate } from '@/lib/timezones'

const TASK_PAGE_SIZE = 20

function getProjectKey(name?: string | null): string {
  const words = (name ?? '').trim().split(/\s+/).filter(Boolean)
  return words.length > 1
    ? words.map((w) => w[0]).join('').toUpperCase()
    : (words[0] ?? 'TASK').slice(0, 5).toUpperCase()
}

type Period = 'week' | 'month' | 'quarter' | 'year' | 'custom'
const PERIOD_DAYS: Record<Exclude<Period, 'custom'>, number> = { week: 7, month: 30, quarter: 90, year: 365 }

const PRIORITY_OPTS = [
  { value: 'urgent' }, { value: 'high' },
  { value: 'medium' }, { value: 'low' }, { value: 'lowest' },
]

const GRADE_STYLE: Record<DeveloperGrade, { cls: string }> = {
  excellent: { cls: 'bg-success/15 text-success' },
  good: { cls: 'bg-info/15 text-info' },
  average: { cls: 'bg-warning/15 text-warning' },
  poor: { cls: 'bg-danger/15 text-danger' },
}

const PIE_COLORS = ['#10b981', '#eab308', '#f97316', '#ef4444']
const CHART_TOOLTIP = { backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8, fontSize: 12 }

export function DeveloperReportPage() {
  const { t } = useTranslation()
  const timezone = useSiteTimezone()
  const toast = useToast()
  const { projectId = '' } = useParams<{ projectId: string }>()

  const [period, setPeriod] = useState<Period>('week')
  const [from, setFrom] = useState(format(subDays(new Date(), 7), 'yyyy-MM-dd'))
  const [to, setTo] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [userId, setUserId] = useState('')
  const [priority, setPriority] = useState('')
  // Filters apply instantly — the query depends directly on the inputs.
  const params: DevReportParams = { from, to, userId: userId || undefined, priority: priority || undefined }

  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
    enabled: !!projectId,
  })

  const { data: project } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectsApi.get(projectId),
    enabled: !!projectId,
    staleTime: 10 * 60_000,
  })
  const projectKey = project ? getProjectKey(project.name) : 'TASK'

  const { data, isLoading } = useQuery({
    queryKey: ['developer-report', projectId, from, to, userId, priority],
    queryFn: () => reportsApi.developerReport(projectId, params),
    enabled: !!projectId,
  })

  // Task Details: open the detail modal on row click + paginate (20 / page).
  const [openTaskId, setOpenTaskId] = useState<string | null>(null)
  const [taskPage, setTaskPage] = useState(1)

  // Reset to the first page whenever the filters (and thus the dataset) change.
  const taskFilterKey = `${from}|${to}|${userId}|${priority}`
  const [taskFilterSeen, setTaskFilterSeen] = useState(taskFilterKey)
  if (taskFilterSeen !== taskFilterKey) {
    setTaskFilterSeen(taskFilterKey)
    setTaskPage(1)
  }

  const taskDetails = data?.taskDetails ?? []
  const taskTotalPages = Math.max(1, Math.ceil(taskDetails.length / TASK_PAGE_SIZE))
  const pagedTasks = taskDetails.slice((taskPage - 1) * TASK_PAGE_SIZE, taskPage * TASK_PAGE_SIZE)

  const applyPeriod = (p: Exclude<Period, 'custom'>) => {
    const newTo = format(new Date(), 'yyyy-MM-dd')
    const newFrom = format(subDays(new Date(), PERIOD_DAYS[p]), 'yyyy-MM-dd')
    setPeriod(p); setFrom(newFrom); setTo(newTo)
  }

  const reset = () => {
    const newTo = format(new Date(), 'yyyy-MM-dd')
    const newFrom = format(subDays(new Date(), 7), 'yyyy-MM-dd')
    setPeriod('week'); setFrom(newFrom); setTo(newTo); setUserId(''); setPriority('')
  }

  const [exporting, setExporting] = useState(false)
  const exportXlsx = async () => {
    setExporting(true)
    try {
      const blob = await reportsApi.exportDeveloperReportXlsx(projectId, {
        from, to, userId: userId || undefined, priority: priority || undefined, baseUrl: window.location.origin,
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = `developer-report-${from}_${to}-${format(new Date(), 'yyyyMMdd-HHmmss')}.xlsx`; a.click()
      URL.revokeObjectURL(url)
    } catch {
      toast.error(t('pages.exportFailed'))
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="flex items-start justify-between gap-4 px-6 py-4 border-b border-border shrink-0">
        <div>
          <h1 className="text-base font-semibold text-fg">{t('nav.developerReport')}</h1>
          <p className="text-xs text-fg-muted mt-0.5">{t('pages.developerReportSubtitle')}</p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <Button variant="primary" size="sm" className="gap-1.5 shrink-0" onClick={exportXlsx} loading={exporting}><Download className="w-4 h-4" /> {t('reports.exportCsv')}</Button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-3 px-6 py-3 border-b border-border shrink-0">
        <div className="flex rounded-lg border border-border overflow-hidden">
          {(['week', 'month', 'quarter', 'year'] as const).map((p) => (
            <button key={p} onClick={() => applyPeriod(p)}
              className={`px-3 py-1.5 text-xs font-medium capitalize transition-colors ${period === p ? 'bg-accent text-white' : 'text-fg-muted hover:bg-bg-subtle'}`}>
              {t('activity.period.' + p)}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-1">
          <input type="date" value={from} onChange={(e) => { setFrom(e.target.value); setPeriod('custom') }}
            className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent" />
          <span className="text-fg-subtle text-xs">→</span>
          <input type="date" value={to} onChange={(e) => { setTo(e.target.value); setPeriod('custom') }}
            className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent" />
        </div>
        <select value={userId} onChange={(e) => setUserId(e.target.value)}
          className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent">
          <option value="">{t('developerReport.allDevelopers')}</option>
          {members.map((m) => <option key={m.userId} value={m.userId}>{m.user.fullName}</option>)}
        </select>
        <select value={priority} onChange={(e) => setPriority(e.target.value)}
          className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent">
          <option value="">{t('myTasks.allPriorities')}</option>
          {PRIORITY_OPTS.map((p) => <option key={p.value} value={p.value}>{t('priority.' + p.value)}</option>)}
        </select>
        <Button variant="ghost" size="sm" onClick={reset}>{t('filter.reset')}</Button>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto scrollbar-thin p-6 space-y-6">
        {/* KPI cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-7 gap-3">
          {isLoading ? (
            [...Array(7)].map((_, i) => <Skeleton key={i} className="h-20 rounded-card" />)
          ) : (
            <>
              <Kpi icon={<ListTodo />} color="text-fg" value={data?.kpis.totalTasks ?? 0} label={t('developerReport.totalTasks')} />
              <Kpi icon={<CheckCircle2 />} color="text-success" value={data?.kpis.completedTasks ?? 0} label={t('summary.completed')} />
              <Kpi icon={<Percent />} color="text-accent" value={`${data?.kpis.completionRate ?? 0}%`} label={t('reports.completionRate')} />
              <Kpi icon={<Clock />} color="text-info" value={`${data?.kpis.loggedHours ?? 0}h`} label={t('developerReport.loggedHours')} />
              <Kpi icon={<AlertTriangle />} color="text-danger" value={data?.kpis.overdueTasks ?? 0} label={t('summary.overdue')} />
              <Kpi icon={<Timer />} color="text-warning" value={`${data?.kpis.avgCompletionTime ?? 0}d`} label={t('developerReport.avgCompletion')} />
              <Kpi icon={<Gauge />} color="text-violet-400" value={`${data?.kpis.productivityScore ?? 0}%`} label={t('developerReport.productivity')} />
            </>
          )}
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          <ChartCard title={t('developerReport.taskDistribution')} loading={isLoading}>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={data?.taskDistribution ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#8888a0' }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#8888a0' }} />
                <Tooltip cursor={{ fill: 'rgba(255,255,255,0.04)' }} contentStyle={CHART_TOOLTIP} itemStyle={{ color: '#fff' }} labelStyle={{ color: '#fff' }} />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {(data?.taskDistribution ?? []).map((entry, i) => (
                    <Cell key={i} fill={entry.color ?? PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title={t('developerReport.loggedHoursTrend')} loading={isLoading}>
            <ResponsiveContainer width="100%" height={260}>
              <LineChart data={data?.loggedHoursTrend ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="week" tick={{ fontSize: 11, fill: '#8888a0' }} />
                <YAxis tick={{ fontSize: 11, fill: '#8888a0' }} />
                <Tooltip contentStyle={CHART_TOOLTIP} />
                <Line type="monotone" dataKey="hours" stroke="#34c77b" strokeWidth={2} dot={{ r: 3 }} />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title={t('developerReport.completionTrend')} loading={isLoading}>
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={data?.completionTrend ?? []}>
                <defs>
                  <linearGradient id="compGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8166ff" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#8166ff" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#8888a0' }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#8888a0' }} />
                <Tooltip contentStyle={CHART_TOOLTIP} />
                <Area type="monotone" dataKey="completed" stroke="#8166ff" strokeWidth={2} fill="url(#compGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title={t('developerReport.overdueAnalysis')} loading={isLoading}>
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie data={data?.overdueAnalysis ?? []} dataKey="value" nameKey="name"
                  innerRadius={50} outerRadius={85} paddingAngle={2}
                  label={({ name, value }) => (value ? `${name}: ${value}` : '')}>
                  {(data?.overdueAnalysis ?? []).map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
                </Pie>
                <Tooltip contentStyle={CHART_TOOLTIP} />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* Developer summary table */}
        <div className="rounded-card border border-border bg-bg-elevated overflow-hidden">
          <p className="text-sm font-semibold text-fg px-5 py-3 border-b border-border">{t('developerReport.developerSummary')}</p>
          {isLoading ? (
            <div className="p-5 space-y-2">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-10" />)}</div>
          ) : (data?.developers.length ?? 0) === 0 ? (
            <div className="py-10"><EmptyState title={t('developerReport.noDeveloperData')} /></div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead className="sticky top-0 bg-bg-surface text-fg-subtle">
                  <tr className="text-left">
                    {[t('developerReport.developer'), t('developerReport.assigned'), t('summary.completed'), t('developerReport.rate'), t('taskDetail.logged'), t('developerReport.avgDuration'), t('summary.overdue'), t('developerReport.score'), t('taskDetail.fStatus')].map((h) => (
                      <th key={h} className="px-4 py-2 font-medium whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data!.developers.map((d) => (
                    <tr key={d.userId} className="border-t border-border hover:bg-bg-subtle/50">
                      <td className="px-4 py-2">
                        <div className="flex items-center gap-2">
                          <Avatar name={d.fullName} avatarUrl={d.avatarUrl} size="sm" />
                          <span className="text-fg font-medium whitespace-nowrap">{d.fullName}</span>
                        </div>
                      </td>
                      <td className="px-4 py-2 text-fg-muted">{d.assigned}</td>
                      <td className="px-4 py-2 text-fg-muted">{d.completed}</td>
                      <td className="px-4 py-2 text-fg-muted">{d.completionRate}%</td>
                      <td className="px-4 py-2 text-fg-muted">{d.loggedHours}h</td>
                      <td className="px-4 py-2 text-fg-muted">{d.avgDuration}d</td>
                      <td className="px-4 py-2">
                        <span className={d.overdue > 0 ? 'text-danger font-medium' : 'text-fg-muted'}>{d.overdue}</span>
                      </td>
                      <td className="px-4 py-2 font-semibold text-fg">{d.productivityScore}%</td>
                      <td className="px-4 py-2">
                        <span className={`px-2 py-0.5 rounded-full text-[11px] font-medium ${GRADE_STYLE[d.grade].cls}`}>
                          {t('developerReport.grade.' + d.grade)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Task details table */}
        <div className="rounded-card border border-border bg-bg-elevated overflow-hidden">
          <p className="text-sm font-semibold text-fg px-5 py-3 border-b border-border">{t('developerReport.taskDetails')}</p>
          {isLoading ? (
            <div className="p-5 space-y-2">{[...Array(5)].map((_, i) => <Skeleton key={i} className="h-9" />)}</div>
          ) : (data?.taskDetails.length ?? 0) === 0 ? (
            <div className="py-10"><EmptyState title={t('developerReport.noTasksInPeriod')} /></div>
          ) : (
            <div className="overflow-x-auto max-h-[480px] overflow-y-auto scrollbar-thin">
              <table className="w-full text-xs">
                <thead className="sticky top-0 bg-bg-surface text-fg-subtle z-10">
                  <tr className="text-left">
                    {[t('pages.summary'), t('taskDetail.fPriority'), t('taskDetail.fStatus'), t('taskDetail.estimated'), t('taskDetail.logged'), t('taskDetail.fDueDate'), t('summary.completed'), t('summary.overdue')].map((h) => (
                      <th key={h} className="px-4 py-2 font-medium whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {pagedTasks.map((task) => (
                    <tr
                      key={task.id}
                      onClick={() => setOpenTaskId(task.id)}
                      className="border-t border-border hover:bg-bg-subtle/50 cursor-pointer"
                    >
                      <td className="px-4 py-2 max-w-xs"><span className="text-accent hover:underline truncate block">{task.title}</span></td>
                      <td className="px-4 py-2"><PriorityBadge priority={task.priority} /></td>
                      <td className="px-4 py-2">
                        {task.columnName ? (
                          <span
                            className="inline-flex rounded-md border px-2 py-0.5 text-xs font-medium"
                            style={task.columnColor
                              ? { backgroundColor: `${task.columnColor}1A`, color: task.columnColor, borderColor: `${task.columnColor}55` }
                              : undefined}
                          >
                            {task.columnName}
                          </span>
                        ) : (
                          <StatusBadge status={task.status} />
                        )}
                      </td>
                      <td className="px-4 py-2 text-fg-muted">{task.estimatedHours ?? '—'}</td>
                      <td className="px-4 py-2 text-fg-muted">{task.loggedHours != null ? `${task.loggedHours}h` : '—'}</td>
                      <td className="px-4 py-2 text-fg-muted whitespace-nowrap">{task.dueDate ? formatZonedDate(task.dueDate, timezone, 'en-US') : '—'}</td>
                      <td className="px-4 py-2 text-fg-muted whitespace-nowrap">{task.completedDate ? formatZonedDate(task.completedDate, timezone, 'en-US') : '—'}</td>
                      <td className="px-4 py-2">
                        {task.overdue || task.lateDays > 0 ? (
                          <span className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-danger/15 text-danger whitespace-nowrap">
                            {t('developerReport.lateByDays', { days: task.lateDays })}
                          </span>
                        ) : (
                          <span className="text-success">{t('developerReport.onTime')}</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          {taskDetails.length > 0 && (
            <div className="flex items-center justify-between gap-3 px-5 py-3 border-t border-border text-xs text-fg-muted">
              <span>{t('board.tasksCount', { count: taskDetails.length })}</span>
              {taskTotalPages > 1 && (
                <div className="flex items-center gap-2">
                  <Button variant="outline" size="sm" disabled={taskPage <= 1} onClick={() => setTaskPage((p) => Math.max(1, p - 1))}>{t('activity.prev')}</Button>
                  <span>{t('activity.page', { page: taskPage })} / {taskTotalPages}</span>
                  <Button variant="outline" size="sm" disabled={taskPage >= taskTotalPages} onClick={() => setTaskPage((p) => Math.min(taskTotalPages, p + 1))}>{t('activity.next')}</Button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      <TaskDetailModal
        task={null}
        taskId={openTaskId}
        projectId={projectId}
        projectKey={projectKey}
        open={!!openTaskId}
        onClose={() => setOpenTaskId(null)}
        onOpenTask={(id) => setOpenTaskId(id)}
      />
    </div>
  )
}

function Kpi({ icon, color, value, label }: { icon: ReactNode; color: string; value: ReactNode; label: string }) {
  return (
    <div className="rounded-card border border-border bg-bg-elevated p-3">
      <span className={`[&>svg]:w-4 [&>svg]:h-4 ${color}`}>{icon}</span>
      <p className="text-xl font-bold text-fg mt-1.5">{value}</p>
      <p className="text-[11px] text-fg-muted mt-0.5">{label}</p>
    </div>
  )
}

function ChartCard({ title, children, loading }: { title: string; children: ReactNode; loading?: boolean }) {
  return (
    <div className="rounded-card border border-border bg-bg-elevated p-5">
      <p className="text-sm font-semibold text-fg mb-4">{title}</p>
      {loading ? <Skeleton className="h-52" /> : children}
    </div>
  )
}
