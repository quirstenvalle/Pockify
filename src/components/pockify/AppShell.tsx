import { useState, type ReactNode } from "react";
import { Link, useRouterState } from "@tanstack/react-router";
import { LayoutGrid, Receipt, Wallet, PieChart, User, Plus, Bell } from "lucide-react";
import { QuickAdd } from "./QuickAdd";
import { usePockify } from "@/lib/pockify-store";
import { budgetAlerts } from "@/lib/pockify";

const NAV = [
  { to: "/", label: "Home", icon: LayoutGrid },
  { to: "/transactions", label: "Activity", icon: Receipt },
  { to: "/budgets", label: "Budgets", icon: Wallet },
  { to: "/analytics", label: "Insights", icon: PieChart },
  { to: "/profile", label: "Profile", icon: User },
] as const;

export function AppShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const { user, transactions, budgets } = usePockify();
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const alertList = budgetAlerts(transactions, budgets);
  const alerts = alertList.length;

  return (
    <div className="app-bg min-h-screen">
      <div className="mx-auto w-full max-w-md px-5 pt-6 pb-32">
        <header className="mb-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-accent text-accent-foreground flex size-11 items-center justify-center rounded-full text-lg font-bold">
              {user.name.charAt(0)}
            </div>
            <div>
              <p className="text-muted-foreground text-xs font-medium">Hi, {user.name}</p>
              <h1 className="text-lg leading-tight font-extrabold tracking-tight">{title}</h1>
              {subtitle && <p className="text-muted-foreground text-xs">{subtitle}</p>}
            </div>
          </div>
          <button
            type="button"
            onClick={() => setNotifOpen(true)}
            className="card-soft text-muted-foreground relative flex size-10 items-center justify-center"
            aria-label="Notifications"
          >
            <Bell className="size-4" />
            {alerts > 0 && (
              <span className="bg-accent text-accent-foreground absolute -top-1 -right-1 flex size-4 items-center justify-center rounded-full text-[10px] font-bold">
                {alerts}
              </span>
            )}
          </button>
        </header>

        {children}
      </div>

      <nav className="fixed inset-x-0 bottom-4 z-40 mx-auto w-full max-w-md px-5">
        <div className="card-raised flex items-center justify-between px-4 py-3">
          {NAV.slice(0, 2).map((n) => (
            <NavItem key={n.to} {...n} active={pathname === n.to} />
          ))}
          <button
            onClick={() => setOpen(true)}
            aria-label="Quick add"
            className="border-accent text-accent -mt-8 flex size-14 items-center justify-center rounded-full border-4 bg-surface shadow-[var(--shadow-raised)]"
          >
            <Plus className="size-6" />
          </button>
          {NAV.slice(2, 5).map((n) => (
            <NavItem key={n.to} {...n} active={pathname === n.to} />
          ))}
        </div>
      </nav>

      <QuickAdd open={open} onOpenChange={setOpen} />

      {notifOpen && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/35 px-5 pb-8">
          <button
            type="button"
            className="absolute inset-0"
            aria-label="Close notifications"
            onClick={() => setNotifOpen(false)}
          />
          <div className="card-raised relative z-10 w-full max-w-md p-5">
            <h2 className="text-lg font-extrabold">Notifications</h2>
            <div className="mt-3 space-y-3">
              {alertList.length === 0 ? (
                <p className="text-muted-foreground text-sm">
                  No budget alerts right now. You&apos;re all clear.
                </p>
              ) : (
                alertList.map((alert) => (
                  <div key={alert.title} className="card-soft p-3">
                    <p className="text-sm font-bold">{alert.title}</p>
                    <p className="text-muted-foreground mt-1 text-xs">{alert.body}</p>
                  </div>
                ))
              )}
            </div>
            <button
              type="button"
              onClick={() => setNotifOpen(false)}
              className="bg-surface-sunken mt-4 w-full rounded-full py-2.5 text-xs font-bold"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function NavItem({
  to,
  label,
  icon: Icon,
  active,
}: {
  to: string;
  label: string;
  icon: typeof LayoutGrid;
  active: boolean;
}) {
  return (
    <Link
      to={to}
      className={`flex w-12 flex-col items-center gap-1 text-[10px] font-semibold transition ${
        active ? "text-foreground" : "text-muted-foreground"
      }`}
    >
      <Icon className={`size-5 ${active ? "text-accent" : ""}`} />
      {label}
    </Link>
  );
}
