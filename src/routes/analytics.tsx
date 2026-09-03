import { createFileRoute } from "@tanstack/react-router";
import {
  Bar,
  BarChart,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  XAxis,
} from "recharts";
import { AppShell } from "@/components/pockify/AppShell";
import { usePockify } from "@/lib/pockify-store";
import {
  categoryOf,
  daysAgo,
  isThisMonth,
  monthlyTotals,
  monthlyTrend,
  peso,
  spentByCategory,
  sum,
  weeklyBars,
} from "@/lib/pockify";

export const Route = createFileRoute("/analytics")({
  head: () => ({
    meta: [
      { title: "Insights & Reports — Pockify" },
      {
        name: "description",
        content:
          "Pie charts, weekly bars and monthly trends that show exactly where your money goes.",
      },
      { property: "og:title", content: "Insights & Reports — Pockify" },
      {
        property: "og:description",
        content:
          "Pie charts, weekly bars and monthly trends that show exactly where your money goes.",
      },
    ],
  }),
  component: AnalyticsPage,
});

function AnalyticsPage() {
  const { transactions } = usePockify();
  const totals = monthlyTotals(transactions);
  const spent = spentByCategory(transactions);
  const pie = [...spent.entries()]
    .map(([name, value]) => ({ name, value, color: categoryOf(name).color }))
    .sort((a, b) => b.value - a.value);
  const totalSpent = pie.reduce((a, b) => a + b.value, 0) || 1;
  const bars = weeklyBars(transactions);
  const trend = monthlyTrend(transactions);

  const week = transactions.filter((t) => t.kind === "expense" && daysAgo(t.date) <= 7);
  const biggest = [...week].sort((a, b) => b.amount - a.amount)[0];
  const monthExpenses = transactions.filter((t) => t.kind === "expense" && isThisMonth(t.date));
  const avgDaily = Math.round(sum(monthExpenses) / Math.max(1, new Date().getDate()));

  return (
    <AppShell title="Insights" subtitle="Where your money goes">
      <section className="card-raised p-5">
        <h2 className="text-sm font-extrabold">Spending by category</h2>
        <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-center">
          <div className="h-40 w-full max-w-[9rem] shrink-0 sm:w-36">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pie}
                  dataKey="value"
                  innerRadius={38}
                  outerRadius={62}
                  paddingAngle={3}
                  stroke="none"
                >
                  {pie.map((p) => (
                    <Cell key={p.name} fill={p.color} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <ul className="w-full flex-1 space-y-1.5 sm:w-auto">
            {pie.slice(0, 6).map((p) => (
              <li key={p.name} className="flex items-center gap-2 text-xs">
                <span
                  className="size-2.5 shrink-0 rounded-full"
                  style={{ background: p.color }}
                />
                <span className="flex-1 truncate font-semibold">{p.name}</span>
                <span className="num text-muted-foreground font-bold">
                  {Math.round((p.value / totalSpent) * 100)}%
                </span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="text-sm font-extrabold">Spending this month</h2>
        <p className="num text-muted-foreground mb-2 text-xs">
          {peso(totals.expenses)} across {monthExpenses.length} entries
        </p>
        <div className="h-36">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={bars}>
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 10, fill: "var(--muted-foreground)" }}
              />
              <Bar dataKey="amount" radius={8} fill="var(--chart-1)" barSize={26} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="text-sm font-extrabold">6-month trend</h2>
        <div className="mt-2 h-36">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={trend}>
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 10, fill: "var(--muted-foreground)" }}
              />
              <Line
                type="monotone"
                dataKey="amount"
                stroke="var(--accent)"
                strokeWidth={3}
                dot={{ r: 3, fill: "var(--accent)" }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </section>

      <section className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Stat label="Avg. daily spend" value={peso(avgDaily)} />
        <Stat label="Biggest this week" value={biggest ? peso(biggest.amount) : "₱0"} />
        <Stat label="Top category" value={pie[0]?.name ?? "—"} />
        <Stat label="Saved this month" value={peso(Math.max(0, totals.balance))} />
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="text-sm font-extrabold">Monthly report</h2>
        <dl className="mt-3 space-y-2 text-xs">
          <Row label="Total income" value={peso(totals.income)} />
          <Row label="Total expenses" value={peso(totals.expenses)} />
          <Row label="Net savings" value={peso(totals.balance)} />
          <Row label="Top spending category" value={pie[0]?.name ?? "—"} />
        </dl>
        <button className="bg-surface-sunken text-muted-foreground mt-4 w-full rounded-full py-2.5 text-xs font-bold">
          Export as PDF (coming soon)
        </button>
      </section>
    </AppShell>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="card-soft p-4">
      <p className="text-muted-foreground text-[11px] font-medium">{label}</p>
      <p className="num mt-1 text-base font-extrabold">{value}</p>
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="num font-bold">{value}</dd>
    </div>
  );
}