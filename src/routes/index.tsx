import { createFileRoute, Link } from "@tanstack/react-router";
import { Area, AreaChart, ResponsiveContainer } from "recharts";
import { ArrowUpRight, Flame, Lightbulb, TrendingUp } from "lucide-react";
import { AppShell } from "@/components/pockify/AppShell";
import { usePockify } from "@/lib/pockify-store";
import {
  budgetAlerts,
  categoryOf,
  essentialStreak,
  healthLevel,
  healthScore,
  monthlyTotals,
  peso,
  smartSuggestions,
  sparkline,
  spentByCategory,
  TIPS,
} from "@/lib/pockify";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Pockify Dashboard — Smart Expense Tracker" },
      {
        name: "description",
        content:
          "Balance, budgets, wallet health score and essential spending streak in one clean dashboard.",
      },
      { property: "og:title", content: "Pockify Dashboard — Smart Expense Tracker" },
      {
        property: "og:description",
        content:
          "Balance, budgets, wallet health score and essential spending streak in one clean dashboard.",
      },
    ],
  }),
  component: Dashboard,
});

function Dashboard() {
  const { transactions, budgets } = usePockify();
  const totals = monthlyTotals(transactions);
  const score = healthScore(transactions, budgets);
  const level = healthLevel(score);
  const streak = essentialStreak(transactions);
  const alerts = budgetAlerts(transactions, budgets);
  const tips = smartSuggestions(transactions);
  const spent = spentByCategory(transactions);
  const budgetTotal = budgets.reduce((a, b) => a + b.limit, 0);
  const budgetUsed = budgets.reduce((a, b) => a + Math.min(b.limit, spent.get(b.category) ?? 0), 0);
  const recent = [...transactions].sort((a, b) => b.date.localeCompare(a.date)).slice(0, 4);
  const tip = TIPS[new Date().getDate() % TIPS.length];

  return (
    <AppShell title="Dashboard" subtitle={new Date().toLocaleDateString("en-PH", { dateStyle: "medium" })}>
      <section className="card-raised overflow-hidden p-5">
        <p className="text-muted-foreground text-xs font-semibold">Current balance</p>
        <div className="flex items-end justify-between">
          <p className="num text-4xl font-extrabold">{peso(totals.balance)}</p>
          <span className="bg-success-soft text-success flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-bold">
            <ArrowUpRight className="size-3" />
            {totals.income ? Math.round((totals.balance / totals.income) * 100) : 0}%
          </span>
        </div>
        <div className="-mx-2 mt-2 h-16">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={sparkline(2)}>
              <defs>
                <linearGradient id="spark" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="var(--success)" stopOpacity={0.35} />
                  <stop offset="100%" stopColor="var(--success)" stopOpacity={0} />
                </linearGradient>
              </defs>
              <Area
                type="monotone"
                dataKey="y"
                stroke="var(--success)"
                strokeWidth={2.5}
                fill="url(#spark)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        <div className="border-border mt-2 grid grid-cols-3 gap-2 border-t pt-4">
          <Mini label="Income" value={peso(totals.income)} tone="text-success" />
          <Mini label="Expenses" value={peso(totals.expenses)} />
          <Mini label="Budget left" value={peso(Math.max(0, budgetTotal - budgetUsed))} />
        </div>
      </section>

      <section className="mt-4 grid grid-cols-2 gap-3">
        <div className="card-soft p-4">
          <p className="text-muted-foreground text-[11px] font-semibold">Wallet Health</p>
          <div className="mt-2 flex items-end gap-1">
            <span className="num text-3xl font-extrabold">{score}</span>
            <span className="text-muted-foreground mb-1 text-xs font-bold">/100</span>
          </div>
          <div className="bg-surface-sunken mt-2 h-2 overflow-hidden rounded-full">
            <div
              className="h-full rounded-full"
              style={{
                width: `${score}%`,
                background:
                  level.tone === "success"
                    ? "var(--success)"
                    : level.tone === "warning"
                      ? "var(--warning)"
                      : "var(--destructive)",
              }}
            />
          </div>
          <p className="mt-2 text-xs font-bold">{level.label}</p>
        </div>

        <div className="card-soft p-4">
          <p className="text-muted-foreground text-[11px] font-semibold">Essential Streak</p>
          <div className="mt-2 flex items-center gap-2">
            <Flame className="text-accent size-7" />
            <span className="num text-3xl font-extrabold">{streak}</span>
          </div>
          <p className="text-muted-foreground mt-2 text-xs">
            {streak > 0
              ? "Only essentials logged — keep it going."
              : "Log only essentials today to start a streak."}
          </p>
        </div>
      </section>

      {alerts.length > 0 && (
        <section className="mt-4 space-y-2">
          {alerts.slice(0, 2).map((a) => (
            <div
              key={a.title}
              className={`card-soft p-4 ${a.level === "over" ? "bg-danger-soft" : "bg-warning-soft"}`}
            >
              <p className="text-xs font-extrabold">{a.title}</p>
              <p className="text-muted-foreground mt-0.5 text-[11px]">{a.body}</p>
            </div>
          ))}
        </section>
      )}

      <section className="card-raised mt-4 p-5">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="flex items-center gap-2 text-sm font-extrabold">
            <TrendingUp className="text-accent size-4" /> Smart recommendations
          </h2>
        </div>
        <ul className="space-y-2">
          {tips.map((s) => (
            <li key={s} className="bg-surface-sunken rounded-2xl p-3 text-xs leading-relaxed">
              {s}
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-4">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-sm font-extrabold">Budget progress</h2>
          <Link to="/budgets" className="text-muted-foreground text-xs font-semibold">
            Manage
          </Link>
        </div>
        <div className="space-y-2">
          {budgets.slice(0, 3).map((b) => {
            const used = spent.get(b.category) ?? 0;
            const pct = Math.min(100, Math.round((used / b.limit) * 100));
            const cat = categoryOf(b.category);
            return (
              <div key={b.id} className="card-soft p-4">
                <div className="flex items-center justify-between text-xs font-bold">
                  <span>
                    {cat.icon} {b.category}
                  </span>
                  <span className="num text-muted-foreground">
                    {peso(used)} / {peso(b.limit)}
                  </span>
                </div>
                <div className="bg-surface-sunken mt-2.5 h-2 overflow-hidden rounded-full">
                  <div
                    className="h-full rounded-full"
                    style={{ width: `${pct}%`, background: cat.color }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </section>

      <section className="mt-5">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-sm font-extrabold">Recent transactions</h2>
          <Link to="/transactions" className="text-muted-foreground text-xs font-semibold">
            See all
          </Link>
        </div>
        <div className="card-raised divide-border divide-y px-4">
          {recent.map((t) => {
            const cat = categoryOf(t.category);
            return (
              <div key={t.id} className="flex items-center gap-3 py-3">
                <div
                  className="flex size-9 items-center justify-center rounded-full text-base"
                  style={{ background: `color-mix(in oklab, ${cat.color} 18%, transparent)` }}
                >
                  {t.kind === "income" ? "💰" : cat.icon}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-bold">{t.category}</p>
                  <p className="text-muted-foreground truncate text-[11px]">{t.note ?? t.date}</p>
                </div>
                <p
                  className={`num text-xs font-extrabold ${t.kind === "income" ? "text-success" : ""}`}
                >
                  {t.kind === "income" ? "+" : "−"}
                  {peso(t.amount)}
                </p>
              </div>
            );
          })}
        </div>
      </section>

      <section className="card-soft mt-4 flex gap-3 p-4">
        <Lightbulb className="text-warning mt-0.5 size-4 shrink-0" />
        <div>
          <p className="text-xs font-extrabold">Tip of the day</p>
          <p className="text-muted-foreground mt-0.5 text-[11px] leading-relaxed">{tip}</p>
        </div>
      </section>
    </AppShell>
  );
}

function Mini({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div>
      <p className="text-muted-foreground text-[11px] font-medium">{label}</p>
      <p className={`num text-sm font-extrabold ${tone ?? ""}`}>{value}</p>
    </div>
  );
}
