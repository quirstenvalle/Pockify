import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { AppShell } from "@/components/pockify/AppShell";
import { usePockify } from "@/lib/pockify-store";
import { CATEGORIES, categoryOf, peso, spentByCategory } from "@/lib/pockify";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/budgets")({
  head: () => ({
    meta: [
      { title: "Budgets & Goals — Pockify" },
      {
        name: "description",
        content: "Set category budgets, watch progress bars and track savings goals in Pockify.",
      },
      { property: "og:title", content: "Budgets & Goals — Pockify" },
      {
        property: "og:description",
        content: "Set category budgets, watch progress bars and track savings goals in Pockify.",
      },
    ],
  }),
  component: BudgetsPage,
});

function BudgetsPage() {
  const { budgets, transactions, addBudget, removeBudget, goals, contributeGoal, addGoal } =
    usePockify();
  const spent = spentByCategory(transactions);
  const [category, setCategory] = useState("Gaming");
  const [limit, setLimit] = useState("");
  const [goalTitle, setGoalTitle] = useState("");
  const [goalTarget, setGoalTarget] = useState("");

  return (
    <AppShell title="Budgets" subtitle="Monthly limits & savings goals">
      <div className="space-y-3">
        {budgets.map((b) => {
          const used = spent.get(b.category) ?? 0;
          const pct = Math.min(100, Math.round((used / b.limit) * 100));
          const cat = categoryOf(b.category);
          const over = used > b.limit;
          return (
            <div key={b.id} className="card-soft p-4">
              <div className="flex items-center gap-3">
                <span className="text-lg">{cat.icon}</span>
                <p className="flex-1 text-sm font-bold">{b.category}</p>
                <span
                  className={`rounded-full px-2.5 py-1 text-[11px] font-bold ${
                    over
                      ? "bg-danger-soft text-destructive"
                      : pct >= 80
                        ? "bg-warning-soft text-warning-foreground"
                        : "bg-success-soft text-success"
                  }`}
                >
                  {pct}%
                </span>
                <button onClick={() => removeBudget(b.id)} aria-label="Delete budget">
                  <Trash2 className="text-muted-foreground size-4" />
                </button>
              </div>
              <div className="bg-surface-sunken mt-3 h-2.5 overflow-hidden rounded-full">
                <div
                  className="h-full rounded-full transition-all"
                  style={{
                    width: `${pct}%`,
                    background: over ? "var(--destructive)" : cat.color,
                  }}
                />
              </div>
              <p className="num text-muted-foreground mt-2 text-xs font-semibold">
                {peso(used)} / {peso(b.limit)} · {peso(Math.max(0, b.limit - used))} left
              </p>
            </div>
          );
        })}
      </div>

      <section className="card-raised mt-5 p-5">
        <h2 className="text-sm font-extrabold">Add budget</h2>
        <p className="text-muted-foreground mb-3 text-xs">
          Pick a default category or type a custom one.
        </p>
        <div className="mb-3 flex flex-wrap gap-2">
          {CATEGORIES.slice(0, 8).map((c) => (
            <button
              key={c.name}
              onClick={() => setCategory(c.name)}
              className={`rounded-full px-3 py-1.5 text-xs font-semibold ${
                category === c.name
                  ? "bg-accent text-accent-foreground"
                  : "bg-surface-sunken text-muted-foreground"
              }`}
            >
              {c.icon} {c.name}
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <Input
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            placeholder="Category"
            className="bg-surface-sunken h-11 rounded-xl border-0"
          />
          <Input
            value={limit}
            onChange={(e) => setLimit(e.target.value)}
            inputMode="numeric"
            placeholder="Limit"
            className="bg-surface-sunken num h-11 w-28 rounded-xl border-0"
          />
          <Button
            size="icon"
            className="size-11 shrink-0 rounded-xl"
            onClick={() => {
              const n = Number(limit);
              if (!category || !n) return toast.error("Add a category and limit");
              addBudget({ category, limit: n });
              setLimit("");
              toast.success(`${category} budget set to ${peso(n)}`);
            }}
            aria-label="Add budget"
          >
            <Plus className="size-4" />
          </Button>
        </div>
      </section>

      <h2 className="mt-6 mb-3 text-sm font-extrabold">Savings goals</h2>
      <div className="space-y-3">
        {goals.map((g) => {
          const pct = Math.round((g.current / g.target) * 100);
          return (
            <div key={g.id} className="card-soft p-4">
              <div className="flex items-baseline justify-between">
                <p className="text-sm font-bold">{g.title}</p>
                <p className="num text-muted-foreground text-xs font-semibold">{pct}% complete</p>
              </div>
              <div className="bg-surface-sunken mt-3 h-2.5 overflow-hidden rounded-full">
                <div
                  className="bg-success h-full rounded-full"
                  style={{ width: `${Math.min(100, pct)}%` }}
                />
              </div>
              <div className="mt-3 flex items-center justify-between">
                <p className="num text-xs font-semibold">
                  {peso(g.current)} / {peso(g.target)}
                </p>
                <button
                  onClick={() => {
                    contributeGoal(g.id, 500);
                    toast.success(`₱500 added to ${g.title}`);
                  }}
                  className="bg-surface-sunken rounded-full px-3 py-1.5 text-xs font-bold"
                >
                  + ₱500
                </button>
              </div>
            </div>
          );
        })}

        <div className="card-soft flex gap-2 p-4">
          <Input
            value={goalTitle}
            onChange={(e) => setGoalTitle(e.target.value)}
            placeholder="New goal"
            className="bg-surface-sunken h-11 rounded-xl border-0"
          />
          <Input
            value={goalTarget}
            onChange={(e) => setGoalTarget(e.target.value)}
            inputMode="numeric"
            placeholder="Target"
            className="bg-surface-sunken num h-11 w-28 rounded-xl border-0"
          />
          <Button
            size="icon"
            className="size-11 shrink-0 rounded-xl"
            aria-label="Add goal"
            onClick={() => {
              const n = Number(goalTarget);
              if (!goalTitle || !n) return toast.error("Add a goal name and target");
              addGoal({ title: goalTitle, target: n, current: 0 });
              setGoalTitle("");
              setGoalTarget("");
            }}
          >
            <Plus className="size-4" />
          </Button>
        </div>
      </div>
    </AppShell>
  );
}