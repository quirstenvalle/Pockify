import { useMemo, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Search, Star, Trash2 } from "lucide-react";
import { AppShell } from "@/components/pockify/AppShell";
import { usePockify } from "@/lib/pockify-store";
import { categoryOf, daysAgo, peso, sum } from "@/lib/pockify";
import { Input } from "@/components/ui/input";

export const Route = createFileRoute("/transactions")({
  head: () => ({
    meta: [
      { title: "Transactions — Pockify" },
      {
        name: "description",
        content: "Search, filter and manage every Pockify expense and income entry.",
      },
      { property: "og:title", content: "Transactions — Pockify" },
      {
        property: "og:description",
        content: "Search, filter and manage every Pockify expense and income entry.",
      },
    ],
  }),
  component: TransactionsPage,
});

const FILTERS = ["Today", "This Week", "This Month", "All"] as const;

function TransactionsPage() {
  const { transactions, removeTransaction, toggleFavorite } = usePockify();
  const [q, setQ] = useState("");
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("This Month");

  const list = useMemo(() => {
    return transactions
      .filter((t) => {
        const age = daysAgo(t.date);
        if (filter === "Today") return age === 0;
        if (filter === "This Week") return age <= 7;
        if (filter === "This Month") return age <= 31;
        return true;
      })
      .filter((t) =>
        q
          ? `${t.category} ${t.note ?? ""}`.toLowerCase().includes(q.toLowerCase())
          : true,
      )
      .sort((a, b) => b.date.localeCompare(a.date));
  }, [transactions, filter, q]);

  const spent = sum(list.filter((t) => t.kind === "expense"));
  const earned = sum(list.filter((t) => t.kind === "income"));

  return (
    <AppShell title="Transactions" subtitle={`${list.length} entries`}>
      <div className="card-raised mb-4 grid grid-cols-2 divide-x divide-border p-4">
        <div>
          <p className="text-muted-foreground text-xs font-medium">Money in</p>
          <p className="num text-success text-xl font-extrabold">{peso(earned)}</p>
        </div>
        <div className="pl-4">
          <p className="text-muted-foreground text-xs font-medium">Money out</p>
          <p className="num text-xl font-extrabold">{peso(spent)}</p>
        </div>
      </div>

      <div className="relative mb-3">
        <Search className="text-muted-foreground absolute top-1/2 left-4 size-4 -translate-y-1/2" />
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search expenses…"
          className="card-soft h-12 border-0 pl-11"
        />
      </div>

      <div className="mb-4 flex gap-2 overflow-x-auto pb-1">
        {FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`shrink-0 rounded-full px-4 py-2 text-xs font-semibold transition ${
              filter === f ? "bg-primary text-primary-foreground" : "card-soft text-muted-foreground"
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {list.map((t) => {
          const cat = categoryOf(t.category);
          return (
            <div key={t.id} className="card-soft flex items-center gap-3 p-4">
              <div
                className="flex size-10 items-center justify-center rounded-full text-lg"
                style={{ background: `color-mix(in oklab, ${cat.color} 18%, transparent)` }}
              >
                {t.kind === "income" ? "💰" : cat.icon}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold">{t.category}</p>
                <p className="text-muted-foreground truncate text-xs">
                  {t.note ?? t.method} · {t.date}
                </p>
              </div>
              <div className="text-right">
                <p
                  className={`num text-sm font-extrabold ${t.kind === "income" ? "text-success" : ""}`}
                >
                  {t.kind === "income" ? "+" : "−"}
                  {peso(t.amount)}
                </p>
                <div className="mt-1 flex justify-end gap-2">
                  <button onClick={() => toggleFavorite(t.id)} aria-label="Favorite">
                    <Star
                      className={`size-3.5 ${t.favorite ? "fill-warning text-warning" : "text-muted-foreground"}`}
                    />
                  </button>
                  <button onClick={() => removeTransaction(t.id)} aria-label="Delete">
                    <Trash2 className="text-muted-foreground size-3.5" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
        {list.length === 0 && (
          <p className="text-muted-foreground py-10 text-center text-sm">
            Nothing here yet — tap + to log something.
          </p>
        )}
      </div>
    </AppShell>
  );
}