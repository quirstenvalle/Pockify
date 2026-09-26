import { useState, type ReactNode } from "react";
import { Link, useRouterState } from "@tanstack/react-router";
import { LayoutGrid, Receipt, Wallet, PieChart, User, Plus, Bell } from "lucide-react";
import { QuickAdd } from "./QuickAdd";
import { usePockify } from "@/lib/pockify-store";
import { budgetAlerts, unreadAlertCount, type Alert } from "@/lib/pockify";
import { useBreakpoint } from "@/hooks/use-breakpoint";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

const NAV = [
  { to: "/", label: "Home", icon: LayoutGrid },
  { to: "/transactions", label: "Activity", icon: Receipt },
  { to: "/budgets", label: "Budgets", icon: Wallet },
  { to: "/analytics", label: "Insights", icon: PieChart },
] as const;

function NotificationPanel({
  alertList,
  readAlertIds,
  onMarkRead,
  onMarkAllRead,
}: {
  alertList: Alert[];
  readAlertIds: string[];
  onMarkRead: (id: string) => void;
  onMarkAllRead: () => void;
}) {
  const readSet = new Set(readAlertIds);
  const hasUnread = alertList.some((alert) => !readSet.has(alert.id));

  return (
    <div className="p-4">
      <div className="flex items-center justify-between gap-2">
        <h2 className="text-sm font-extrabold">Notifications</h2>
        {hasUnread && (
          <button
            type="button"
            onClick={onMarkAllRead}
            className="text-accent text-[11px] font-bold"
          >
            Mark all read
          </button>
        )}
      </div>
      <div className="mt-3 max-h-72 space-y-2 overflow-y-auto">
        {alertList.length === 0 ? (
          <p className="text-muted-foreground text-sm">
            No budget alerts right now. You&apos;re all clear.
          </p>
        ) : (
          alertList.map((alert) => {
            const isRead = readSet.has(alert.id);
            return (
              <div
                key={alert.id}
                className={`rounded-2xl p-3 ${isRead ? "bg-surface-sunken/70 opacity-80" : "card-soft"}`}
              >
                <p className={`text-sm font-bold ${isRead ? "text-muted-foreground" : ""}`}>
                  {alert.title}
                </p>
                <p className="text-muted-foreground mt-1 text-xs">{alert.body}</p>
                {!isRead && (
                  <button
                    type="button"
                    onClick={() => onMarkRead(alert.id)}
                    className="text-accent mt-2 text-[11px] font-bold"
                  >
                    Mark as read
                  </button>
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

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
  const { user, transactions, budgets, readAlertIds, markAlertRead, markAllAlertsRead } =
    usePockify();
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const alertList = budgetAlerts(transactions, budgets);
  const unreadCount = unreadAlertCount(alertList, new Set(readAlertIds));
  const { isDesktop } = useBreakpoint();

  const header = (
    <header className="mb-6 flex items-center justify-between gap-4">
      <div className="flex min-w-0 items-center gap-3">
        <div className="bg-accent text-accent-foreground flex size-11 shrink-0 items-center justify-center rounded-full text-lg font-bold">
          {user.name.charAt(0)}
        </div>
        <div className="min-w-0">
          <p className="text-muted-foreground text-xs font-medium">Hi, {user.name}</p>
          <h1 className="truncate text-lg leading-tight font-extrabold tracking-tight">{title}</h1>
          {subtitle && <p className="text-muted-foreground truncate text-xs">{subtitle}</p>}
        </div>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <Popover open={notifOpen} onOpenChange={setNotifOpen}>
          <PopoverTrigger asChild>
            <button
              type="button"
              className="card-soft text-muted-foreground relative flex size-10 shrink-0 items-center justify-center"
              aria-label="Notifications"
            >
              <Bell className="size-4" />
              {unreadCount > 0 && (
                <span className="bg-accent text-accent-foreground absolute -top-1 -right-1 flex size-4 items-center justify-center rounded-full text-[10px] font-bold">
                  {unreadCount}
                </span>
              )}
            </button>
          </PopoverTrigger>
          <PopoverContent
            align="end"
            side="bottom"
            sideOffset={8}
            className="card-raised w-80 max-w-[calc(100vw-1.5rem)] border-0 p-0 shadow-[var(--shadow-raised)]"
          >
            <NotificationPanel
              alertList={alertList}
              readAlertIds={readAlertIds}
              onMarkRead={markAlertRead}
              onMarkAllRead={() => markAllAlertsRead(alertList.map((alert) => alert.id))}
            />
          </PopoverContent>
        </Popover>
        <Link
          to="/profile"
          aria-label="Profile"
          title="Profile"
          className={`card-soft flex size-10 shrink-0 items-center justify-center ${
            pathname === "/profile" ? "text-accent" : "text-muted-foreground"
          }`}
        >
          <User className="size-4" />
        </Link>
      </div>
    </header>
  );

  if (isDesktop) {
    return (
      <div className="app-bg min-h-screen">
        <div className="mx-auto flex min-h-screen w-full max-w-7xl">
          <aside className="sticky top-0 flex h-screen w-64 shrink-0 flex-col border-r border-border/60 px-4 py-6">
            <div className="mb-8 px-2">
              <p className="text-accent text-xl font-extrabold">Pockify</p>
              <p className="text-muted-foreground mt-1 text-xs">Smart expense tracker</p>
            </div>
            <nav className="flex flex-1 flex-col gap-1">
              {NAV.map((n) => (
                <DesktopNavItem key={n.to} {...n} active={pathname === n.to} />
              ))}
            </nav>
            <button
              onClick={() => setOpen(true)}
              className="bg-accent text-accent-foreground mt-4 flex items-center justify-center gap-2 rounded-full py-3 text-sm font-bold"
            >
              <Plus className="size-4" />
              Quick add
            </button>
          </aside>

          <main className="min-w-0 flex-1 px-6 py-6 lg:px-8 xl:px-10">
            {header}
            <div className="mx-auto w-full max-w-5xl">{children}</div>
          </main>
        </div>

        <QuickAdd open={open} onOpenChange={setOpen} />
      </div>
    );
  }

  return (
    <div className="app-bg min-h-screen">
      <div className="app-container pb-32 pt-6">
        {header}
        {children}
      </div>

      <nav className="fixed inset-x-0 bottom-4 z-40 mx-auto w-full max-w-md px-4 sm:max-w-xl sm:px-6">
        <div className="card-raised flex items-center justify-between px-3 py-3 sm:px-4">
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
          {NAV.slice(2).map((n) => (
            <NavItem key={n.to} {...n} active={pathname === n.to} />
          ))}
        </div>
      </nav>

      <QuickAdd open={open} onOpenChange={setOpen} />
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

function DesktopNavItem({
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
      className={`flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-semibold transition ${
        active
          ? "bg-accent/15 text-foreground"
          : "text-muted-foreground hover:bg-surface-sunken hover:text-foreground"
      }`}
    >
      <Icon className={`size-5 ${active ? "text-accent" : ""}`} />
      {label}
    </Link>
  );
}
