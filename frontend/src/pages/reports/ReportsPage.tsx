import { useEffect, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Download, X, ListTodo, CheckCircle2, Percent, Clock, AlertTriangle, Timer, Gauge } from 'lucide-react'
import {
  BarChart, Bar, LineChart, Line, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts'
import { reportsApi } from '@/api/reports'
import { membersApi } from '@/api/members'
import { sprintsApi } from '@/api/sprints'
import { useFilterStore } from '@/stores/useFilterStore'
import { useToast } from '@/hooks/useToast'
import { Button, Skeleton } from '@/components/ui'
import { format, subDays, startOfWeek, startOfMonth, startOfQuarter, startOfYear } from 'date-fns'

// Fallback slice colours for board columns that have no colour set.
const FALLBACK_COLORS = ['#6b7280', '#3b82f6', '#f59e0b', '#10b981', '#8166ff', '#ef4444', '#06b6d4', '#ec4899']

type Period = 'week' | 'month' | 'quarter' | 'year' | 'custom'
const PERIOD_DAYS: Record<Exclude<Period, 'custom'>, number> = { week: 7, month: 30, quarter: 90, year: 365 }

export function ReportsPage() {
  const { t } = useTranslation()
  const { projectId = '' } = useParams<{ projectId: string }>()
  const { reports, setReportFilter } = useFilterStore()
  const [exportOpen, setExportOpen] = useState(false)
  const [period, setPeriod] = useState<Period>('week')

  const { data: members = [] } = useQuery({
    queryKey: ['members', projectId],
    queryFn: () => membersApi.list(projectId),
    enabled: !!projectId,
  })
  const { data: sprints = [] } = useQuery({
    queryKey: ['sprints', projectId],
    queryFn: () => sprintsApi.list(projectId),
    enabled: !!projectId,
  })

  const { data: weekly, isLoading: weeklyLoading } = useQuery({
    queryKey: ['reports', 'weekly', projectId, reports],
    queryFn: () => reportsApi.weekly(projectId, reports),
    enabled: !!projectId,
  })
  const { data: devReport } = useQuery({
    queryKey: ['reports', 'kpis', projectId, reports],
    queryFn: () => reportsApi.developerReport(projectId, { from: reports.from, to: reports.to, userId: reports.userId, sprintId: reports.sprintId }),
    enabled: !!projectId,
  })
  const kpis = devReport?.kpis
  const { data: productivity } = useQuery({
    queryKey: ['reports', 'productivity', projectId, reports],
    queryFn: () => reportsApi.productivity(projectId, reports),
    enabled: !!projectId,
  })
  const { data: completion } = useQuery({
    queryKey: ['reports', 'completion', projectId, reports],
    queryFn: () => reportsApi.completionRate(projectId, reports),
    enabled: !!projectId,
  })
  const { data: hours } = useQuery({
    queryKey: ['reports', 'hours', projectId, reports],
    queryFn: () => reportsApi.workingHours(projectId, reports),
    enabled: !!projectId,
  })

  const applyPeriod = (p: Exclude<Period, 'custom'>) => {
    setPeriod(p)
    setReportFilter({
      from: format(subDays(new Date(), PERIOD_DAYS[p]), 'yyyy-MM-dd'),
      to: format(new Date(), 'yyyy-MM-dd'),
    })
  }

  const reset = () => {
    setPeriod('week')
    setReportFilter({
      from: format(subDays(new Date(), 7), 'yyyy-MM-dd'),
      to: format(new Date(), 'yyyy-MM-dd'),
      userId: undefined,
      sprintId: undefined,
    })
  }

  // On mount: default to the last week, or derive the active chip from a saved range.
  const todayStr = format(new Date(), 'yyyy-MM-dd')
  useEffect(() => {
    // Member filter was removed — clear any stale per-user filter.
    if (reports.userId) setReportFilter({ userId: undefined })
    if (!reports.from && !reports.to) { applyPeriod('week'); return }
    const match = reports.to === todayStr && reports.from
      ? (['week', 'month', 'quarter', 'year'] as const).find(
          (p) => reports.from === format(subDays(new Date(), PERIOD_DAYS[p]), 'yyyy-MM-dd'))
      : undefined
    setPeriod(match ?? 'custom')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Working-hours chart: label each bar with the member's name (the API returns
  // only userIds), falling back to a short id for users no longer in the project.
  const hoursData = (hours ?? []).map((h) => ({
    ...h,
    name: members.find((m) => m.userId === h.userId)?.user.fullName ?? h.userId.slice(0, 6),
  }))

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="flex items-start justify-between gap-4 px-6 py-4 border-b border-border shrink-0">
        <h1 className="text-base font-semibold text-fg">{t('pages.reports')}</h1>
        <Button variant="primary" size="sm" className="gap-1.5 shrink-0" onClick={() => setExportOpen(true)}>
          <Download className="w-3.5 h-3.5" /> {t('reports.exportCsv')}
        </Button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-3 px-6 py-3 border-b border-border shrink-0">
        <div className="flex rounded-lg border border-border overflow-hidden">
          {(['week', 'month', 'quarter', 'year'] as const).map((p) => (
            <button
              key={p}
              onClick={() => applyPeriod(p)}
              className={`px-3 py-1.5 text-xs font-medium capitalize transition-colors ${period === p ? 'bg-accent text-white' : 'text-fg-muted hover:bg-bg-subtle'}`}
            >
              {p}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-1">
          <input
            type="date"
            value={reports.from ?? ''}
            onChange={(e) => { setReportFilter({ from: e.target.value || undefined }); setPeriod('custom') }}
            className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
          />
          <span className="text-fg-subtle text-xs">→</span>
          <input
            type="date"
            value={reports.to ?? ''}
            onChange={(e) => { setReportFilter({ to: e.target.value || undefined }); setPeriod('custom') }}
            className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
          />
        </div>

        {sprints.length > 0 && (
          <select
            value={reports.sprintId ?? ''}
            onChange={(e) => setReportFilter({ sprintId: e.target.value || undefined })}
            className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
          >
            <option value="">{t('filter.allSprints')}</option>
            {sprints.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        )}

        <Button variant="ghost" size="sm" onClick={reset}>Reset</Button>
      </div>

      {/* Charts */}
      <div className="flex-1 overflow-y-auto scrollbar-thin p-6 grid grid-cols-1 xl:grid-cols-2 gap-6">

        {/* KPI cards */}
        <div className="xl:col-span-2 grid grid-cols-2 md:grid-cols-4 xl:grid-cols-7 gap-3">
          <Kpi icon={<ListTodo />} color="text-fg" value={kpis?.totalTasks ?? 0} label="Total Tasks" />
          <Kpi icon={<CheckCircle2 />} color="text-success" value={kpis?.completedTasks ?? 0} label="Completed" />
          <Kpi icon={<Percent />} color="text-accent" value={`${kpis?.completionRate ?? 0}%`} label="Completion Rate" />
          <Kpi icon={<Clock />} color="text-info" value={`${kpis?.loggedHours ?? 0}h`} label="Logged Hours" />
          <Kpi icon={<AlertTriangle />} color="text-danger" value={kpis?.overdueTasks ?? 0} label="Overdue" />
          <Kpi icon={<Timer />} color="text-warning" value={`${kpis?.avgCompletionTime ?? 0}d`} label="Avg Completion" />
          <Kpi icon={<Gauge />} color="text-violet-400" value={`${kpis?.productivityScore ?? 0}%`} label="Productivity" />
        </div>

        {/* Weekly Bar Chart */}
        <ChartCard title={t('reports.weeklyCompleted')} loading={weeklyLoading}>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={weekly ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#8888a0' }} />
              <YAxis tick={{ fontSize: 11, fill: '#8888a0' }} />
              <Tooltip contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8 }} />
              <Bar dataKey="completed" fill="#8166ff" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Productivity Line Chart */}
        <ChartCard title={t('reports.productivity30')}>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={productivity ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#8888a0' }} />
              <YAxis tick={{ fontSize: 11, fill: '#8888a0' }} />
              <Tooltip contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8 }} />
              <Line type="monotone" dataKey="completed" stroke="#8166ff" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Completion Rate Donut */}
        <ChartCard title={t('reports.completionByStatus')}>
          <ResponsiveContainer width="100%" height={260}>
            <PieChart>
              <Pie
                data={completion ?? []}
                dataKey="count"
                nameKey="name"
                innerRadius={50}
                outerRadius={80}
                paddingAngle={3}
                label={({ name, value }) => `${name}: ${value}`}
              >
                {(completion ?? []).map((entry, i) => (
                  <Cell key={entry.columnId} fill={entry.color ?? FALLBACK_COLORS[i % FALLBACK_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8 }} />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* Working Hours Stacked Bar */}
        <ChartCard title={t('reports.hoursEstVsLogged')}>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={hoursData}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="name" tick={<HoursTick />} interval={0} height={34} />
              <YAxis tick={{ fontSize: 11, fill: '#8888a0' }} />
              <Tooltip contentStyle={{ backgroundColor: '#1b1b23', border: '1px solid #2d2d38', borderRadius: 8 }} />
              <Legend />
              <Bar dataKey="estimatedHours" name="Estimated" fill="#8166ff" radius={[4, 4, 0, 0]} />
              <Bar dataKey="loggedHours" name="Logged" fill="#34c77b" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {exportOpen && <ExportDialog projectId={projectId} onClose={() => setExportOpen(false)} />}
    </div>
  )
}

// ─── Export CSV dialog ─────────────────────────────────────────────────────────

type ExportMode = 'week' | 'month' | 'quarter' | 'year' | 'custom'

const EXPORT_MODES: { value: ExportMode; labelKey: string }[] = [
  { value: 'week', labelKey: 'reports.exportWeek' },
  { value: 'month', labelKey: 'reports.exportMonth' },
  { value: 'quarter', labelKey: 'reports.exportQuarter' },
  { value: 'year', labelKey: 'reports.exportYear' },
  { value: 'custom', labelKey: 'reports.exportCustom' },
]

function ExportDialog({ projectId, onClose }: { projectId: string; onClose: () => void }) {
  const { t } = useTranslation()
  const toast = useToast()
  const [mode, setMode] = useState<ExportMode>('week')
  const [customFrom, setCustomFrom] = useState(format(subDays(new Date(), 7), 'yyyy-MM-dd'))
  const [loading, setLoading] = useState(false)

  const rangeFor = (m: ExportMode): { from: string; to: string } => {
    const now = new Date()
    const to = format(now, 'yyyy-MM-dd')
    if (m === 'custom') return { from: customFrom, to }
    const start =
      m === 'week' ? startOfWeek(now, { weekStartsOn: 1 })
      : m === 'month' ? startOfMonth(now)
      : m === 'quarter' ? startOfQuarter(now)
      : startOfYear(now)
    return { from: format(start, 'yyyy-MM-dd'), to }
  }

  const doExport = async () => {
    const { from, to } = rangeFor(mode)
    if (mode === 'custom' && !from) { toast.error(t('reports.exportPickStart')); return }
    setLoading(true)
    try {
      const blob = await reportsApi.exportTasksXlsx(projectId, { from, to, baseUrl: window.location.origin })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `tasks-export-${from}_${to}-${format(new Date(), 'yyyyMMdd-HHmmss')}.xlsx`
      a.click()
      URL.revokeObjectURL(url)
      toast.success(t('reports.exportSuccess'))
      onClose()
    } catch {
      toast.error(t('reports.exportFailed'))
    } finally {
      setLoading(false)
    }
  }

  return createPortal(
    <div className="fixed inset-0 z-[60] flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative w-[440px] max-w-[92vw] rounded-xl border border-border bg-bg-surface shadow-app-lg overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3.5 border-b border-border">
          <h3 className="text-sm font-semibold text-fg">{t('reports.exportCsv')}</h3>
          <button onClick={onClose} className="text-fg-muted hover:text-fg transition-colors">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="px-5 py-4 space-y-1">
          <p className="text-xs text-fg-muted mb-1.5">{t('reports.exportChoose')}</p>
          {EXPORT_MODES.map((opt) => (
            <label key={opt.value} className="flex items-center gap-2 cursor-pointer select-none py-1">
              <input
                type="radio"
                name="exportMode"
                value={opt.value}
                checked={mode === opt.value}
                onChange={() => setMode(opt.value)}
                className="accent-accent w-4 h-4"
              />
              <span className="text-sm text-fg">{t(opt.labelKey)}</span>
            </label>
          ))}
          {mode === 'custom' && (
            <div className="pl-6 pt-1">
              <label className="text-xs text-fg-muted block mb-1">{t('reports.exportStartDate')}</label>
              <input
                type="date"
                value={customFrom}
                max={format(new Date(), 'yyyy-MM-dd')}
                onChange={(e) => setCustomFrom(e.target.value)}
                className="h-8 rounded-lg border border-border bg-bg-elevated px-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
              />
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-5 py-3.5 border-t border-border">
          <Button variant="ghost" size="sm" onClick={onClose}>{t('common.cancel')}</Button>
          <Button variant="primary" size="sm" loading={loading} onClick={doExport}>{t('reports.exportAction')}</Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}

// KPI card matching the Developer Report page (coloured icon + value + label).
function Kpi({ icon, color, value, label }: { icon: ReactNode; color: string; value: ReactNode; label: string }) {
  return (
    <div className="rounded-card border border-border bg-bg-elevated p-3">
      <span className={`[&>svg]:w-4 [&>svg]:h-4 ${color}`}>{icon}</span>
      <p className="text-xl font-bold text-fg mt-1.5">{value}</p>
      <p className="text-[11px] text-fg-muted mt-0.5">{label}</p>
    </div>
  )
}

// Centered X-axis tick for the Working Hours chart: places the user name in the
// middle of each bar group, truncating long names (full name shown on hover).
function HoursTick({ x = 0, y = 0, payload }: { x?: number; y?: number; payload?: { value?: string } }) {
  const name = payload?.value ?? ''
  const short = name.length > 12 ? `${name.slice(0, 11)}…` : name
  return (
    <text x={x} y={y + 12} textAnchor="middle" fontSize={11} fill="#8888a0">
      <title>{name}</title>
      {short}
    </text>
  )
}

function ChartCard({ title, children, loading }: { title: string; children: ReactNode; loading?: boolean }) {
  return (
    <div className="rounded-card border border-border bg-bg-elevated p-4">
      <p className="text-sm font-medium text-fg mb-4">{title}</p>
      {loading ? <Skeleton className="h-48" /> : children}
    </div>
  )
}
