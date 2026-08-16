import { createFileRoute } from "@tanstack/react-router";
import { Bell, LogOut, Shield, Star, Trophy, Wallet } from "lucide-react";
import { toast } from "sonner";
import { AppShell } from "@/components/pockify/AppShell";
import { usePockify } from "@/lib/pockify-store";
import {
  BADGES,
  budgetAlerts,
  essentialStreak,
  healthLevel,
  healthScore,
  peso,
} from "@/lib/pockify";
import { Switch } from "@/components/ui/switch";

export const Route = createFileRoute("/profile")({
  head: () => ({
    meta: [
      { title: "Profile & Alerts — Pockify" },
      {
        name: "description",
        content: "Badges, Budget Buddy alerts, favorite transactions and Pockify settings.",
      },
      { property: "og:title", content: "Profile & Alerts — Pockify" },
      {
        property: "og:description",
        content: "Badges, Budget Buddy alerts, favorite transactions and Pockify settings.",
      },
    ],
  }),
  component: ProfilePage,
});

function ProfilePage() {
  const { user, transactions, budgets } = usePockify();
  const streak = essentialStreak(transactions);
  const score = healthScore(transactions, budgets);
  const level = healthLevel(score);
  const alerts = budgetAlerts(transactions, budgets);
  const favorites = transactions.filter((t) => t.favorite);

  return (
    <AppShell title="Profile" subtitle={user.email}>
      <section className="card-raised flex items-center gap-4 p-5">
        <div className="bg-accent text-accent-foreground flex size-14 items-center justify-center rounded-full text-2xl font-extrabold">
          {user.name.charAt(0)}
        </div>
        <div className="flex-1">
          <p className="text-base font-extrabold">{user.name}</p>
          <p className="text-muted-foreground text-xs">
            Wallet health {score} · {level.label}
          </p>
        </div>
        <button
          onClick={() => toast("Auth connects to Lovable Cloud later")}
          className="text-muted-foreground"
          aria-label="Log out"
        >
          <LogOut className="size-4" />
        </button>
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="flex items-center gap-2 text-sm font-extrabold">
          <Trophy className="text-warning size-4" /> Achievements
        </h2>
        <p className="text-muted-foreground mt-1 text-xs">
          Essential Spending Streak: {streak} day{streak === 1 ? "" : "s"}
        </p>
        <div className="mt-3 grid grid-cols-2 gap-3">
          {BADGES.map((b) => {
            const unlocked = streak >= b.days;
            return (
              <div
                key={b.name}
                className={`rounded-2xl p-3 text-center ${
                  unlocked ? "bg-success-soft" : "bg-surface-sunken opacity-60"
                }`}
              >
                <div className="text-xl">{b.icon}</div>
                <p className="mt-1 text-xs font-bold">{b.name}</p>
                <p className="text-muted-foreground text-[11px]">{b.days}-day streak</p>
              </div>
            );
          })}
        </div>
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="flex items-center gap-2 text-sm font-extrabold">
          <Bell className="text-accent size-4" /> Budget Buddy alerts
        </h2>
        <div className="mt-3 space-y-2">
          {alerts.length === 0 && (
            <p className="text-muted-foreground text-xs">
              All budgets are comfortably within range.
            </p>
          )}
          {alerts.map((a) => (
            <div
              key={a.title}
              className={`rounded-2xl p-3 ${a.level === "over" ? "bg-danger-soft" : "bg-warning-soft"}`}
            >
              <p className="text-xs font-bold">{a.title}</p>
              <p className="text-muted-foreground mt-0.5 text-[11px]">{a.body}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="card-raised mt-4 p-5">
        <h2 className="flex items-center gap-2 text-sm font-extrabold">
          <Star className="text-warning size-4" /> Favorite transactions
        </h2>
        <div className="mt-3 space-y-2">
          {favorites.length === 0 && (
            <p className="text-muted-foreground text-xs">
              Star a transaction to reuse it in Quick Add.
            </p>
          )}
          {favorites.map((f) => (
            <div key={f.id} className="bg-surface-sunken flex justify-between rounded-2xl p-3">
              <p className="text-xs font-bold">{f.note ?? f.category}</p>
              <p className="num text-xs font-bold">{peso(f.amount)}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="card-raised mt-4 divide-y divide-border p-5">
        <SettingRow icon={Bell} label="Daily expense reminder" />
        <SettingRow icon={Wallet} label="Budget threshold alerts" />
        <SettingRow icon={Trophy} label="Streak celebrations" />
        <SettingRow icon={Shield} label="Biometric lock" defaultOn={false} />
      </section>

      <p className="text-muted-foreground mt-4 text-center text-[11px]">
        Accounts, sync and notifications will be wired to Lovable Cloud later.
      </p>
    </AppShell>
  );
}

function SettingRow({
  icon: Icon,
  label,
  defaultOn = true,
}: {
  icon: typeof Bell;
  label: string;
  defaultOn?: boolean;
}) {
  return (
    <div className="flex items-center gap-3 py-3">
      <Icon className="text-muted-foreground size-4" />
      <p className="flex-1 text-xs font-semibold">{label}</p>
      <Switch defaultChecked={defaultOn} />
    </div>
  );
}