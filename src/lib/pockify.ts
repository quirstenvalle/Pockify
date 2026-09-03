export type TxKind = "expense" | "income";

export type Transaction = {
  id: string;
  kind: TxKind;
  amount: number;
  category: string;
  note?: string | undefined;
  date: string; // ISO yyyy-mm-dd
  method?: string | undefined;
  favorite?: boolean | undefined;
};

export type Category = {
  name: string;
  icon: string;
  color: string; // css var reference
  essential: boolean;
  isDefault: boolean;
};

export type Budget = {
  id: string;
  category: string;
  limit: number;
};

export type Goal = {
  id: string;
  title: string;
  target: number;
  current: number;
};

export const peso = (n: number) =>
  "₱" + n.toLocaleString("en-PH", { maximumFractionDigits: n % 1 === 0 ? 0 : 2 });

export const CATEGORIES: Category[] = [
  { name: "Food", icon: "🍜", color: "var(--chart-3)", essential: false, isDefault: true },
  {
    name: "Transportation",
    icon: "🚌",
    color: "var(--chart-1)",
    essential: true,
    isDefault: true,
  },
  { name: "Grocery", icon: "🛒", color: "var(--chart-2)", essential: true, isDefault: true },
  { name: "Shopping", icon: "🛍️", color: "var(--chart-5)", essential: false, isDefault: true },
  {
    name: "Entertainment",
    icon: "🎬",
    color: "var(--chart-4)",
    essential: false,
    isDefault: true,
  },
  { name: "Bills", icon: "🧾", color: "var(--chart-1)", essential: true, isDefault: true },
  { name: "Healthcare", icon: "💊", color: "var(--chart-2)", essential: true, isDefault: true },
  { name: "Education", icon: "📚", color: "var(--chart-4)", essential: true, isDefault: true },
  { name: "Savings", icon: "🏦", color: "var(--chart-2)", essential: true, isDefault: true },
  { name: "Coffee", icon: "☕", color: "var(--chart-3)", essential: false, isDefault: false },
  { name: "Pet Expenses", icon: "🐶", color: "var(--chart-5)", essential: false, isDefault: false },
  { name: "Others", icon: "✨", color: "var(--chart-4)", essential: false, isDefault: true },
];

export const INCOME_SOURCES = ["Salary", "Allowance", "Freelance", "Business", "Gifts"];

export const categoryOf = (name: string) =>
  CATEGORIES.find((c) => c.name === name) ?? {
    name,
    icon: "✨",
    color: "var(--chart-4)",
    essential: false,
    isDefault: false,
  };

const d = (offset: number) => {
  const dt = new Date();
  dt.setDate(dt.getDate() - offset);
  return dt.toISOString().slice(0, 10);
};

let seq = 0;
const t = (
  kind: TxKind,
  amount: number,
  category: string,
  offset: number,
  note?: string,
  favorite?: boolean,
): Transaction => ({
  id: `seed-${seq++}`,
  kind,
  amount,
  category,
  date: d(offset),
  note,
  method: kind === "income" ? "Bank" : "Cash",
  favorite,
});

export const SEED_TRANSACTIONS: Transaction[] = [
  t("income", 20000, "Salary", 12, "December salary"),
  t("income", 3500, "Freelance", 8, "Logo design"),
  t("expense", 80, "Transportation", 0, "Bus fare", true),
  t("expense", 900, "Grocery", 0, "Weekly groceries"),
  t("expense", 1500, "Bills", 1, "Electricity"),
  t("expense", 340, "Healthcare", 2, "Vitamins"),
  t("expense", 220, "Education", 3, "Notebook + pens"),
  t("expense", 130, "Transportation", 4, "Grab ride"),
  t("expense", 720, "Grocery", 5, "Pantry restock"),
  t("expense", 250, "Food", 6, "Lunch with team"),
  t("expense", 95, "Coffee", 6, "Cold brew"),
  t("expense", 480, "Entertainment", 7, "Movie night"),
  t("expense", 120, "Food", 8, "Rice bowl", true),
  t("expense", 65, "Coffee", 8, "Latte"),
  t("expense", 1800, "Shopping", 9, "New sneakers"),
  t("expense", 260, "Food", 11, "Dinner out"),
  t("expense", 60, "Coffee", 12, "Americano"),
  t("expense", 2000, "Savings", 12, "Monthly set-aside"),
  t("expense", 450, "Bills", 15, "Internet top-up"),
  t("expense", 310, "Pet Expenses", 18, "Dog food"),
];

export const SEED_BUDGETS: Budget[] = [
  { id: "b1", category: "Food", limit: 5000 },
  { id: "b2", category: "Transportation", limit: 4000 },
  { id: "b3", category: "Grocery", limit: 3500 },
  { id: "b4", category: "Shopping", limit: 2000 },
  { id: "b5", category: "Coffee", limit: 600 },
  { id: "b6", category: "Entertainment", limit: 1200 },
];

export const SEED_GOALS: Goal[] = [
  { id: "g1", title: "New Laptop", target: 50000, current: 18500 },
  { id: "g2", title: "Emergency Fund", target: 30000, current: 12400 },
];

export const TIPS = [
  "Cooking one extra meal at home this week can noticeably reduce food expenses.",
  "Review subscriptions monthly to avoid paying for services you no longer use.",
  "Setting aside a small amount after every payday builds an emergency fund over time.",
  "Log expenses the moment they happen — memory is the biggest budgeting leak.",
];

/* ---------- derived helpers ---------- */

export const sum = (list: Transaction[]) => list.reduce((a, b) => a + b.amount, 0);

export const isThisMonth = (iso: string) => iso.slice(0, 7) === new Date().toISOString().slice(0, 7);

export const daysAgo = (iso: string) =>
  Math.round((Date.now() - new Date(iso + "T00:00:00").getTime()) / 86400000);

export function monthlyTotals(txs: Transaction[]) {
  const month = txs.filter((x) => isThisMonth(x.date));
  const income = sum(month.filter((x) => x.kind === "income"));
  const expenses = sum(month.filter((x) => x.kind === "expense"));
  return { income, expenses, balance: income - expenses };
}

export function spentByCategory(txs: Transaction[]) {
  const map = new Map<string, number>();
  txs
    .filter((x) => x.kind === "expense" && isThisMonth(x.date))
    .forEach((x) => map.set(x.category, (map.get(x.category) ?? 0) + x.amount));
  return map;
}

export function essentialStreak(txs: Transaction[]) {
  let streak = 0;
  for (let i = 0; i < 60; i++) {
    const day = d(i);
    const dayTx = txs.filter((x) => x.kind === "expense" && x.date === day);
    if (dayTx.length === 0) {
      if (i === 0) continue;
      break;
    }
    if (dayTx.every((x) => categoryOf(x.category).essential)) streak++;
    else break;
  }
  return streak;
}

export const BADGES = [
  { name: "Smart Starter", days: 3, icon: "🌱" },
  { name: "Budget Keeper", days: 7, icon: "🛡️" },
  { name: "Wise Spender", days: 14, icon: "🧠" },
  { name: "Financial Master", days: 30, icon: "👑" },
];

export function healthScore(txs: Transaction[], budgets: Budget[]) {
  const { income, expenses } = monthlyTotals(txs);
  const spent = spentByCategory(txs);
  let score = 50;

  // income vs expenses
  if (income > 0) {
    const ratio = expenses / income;
    score += ratio < 0.5 ? 25 : ratio < 0.7 ? 18 : ratio < 0.9 ? 10 : ratio < 1 ? 4 : -10;
  }
  // budget adherence
  const over = budgets.filter((b) => (spent.get(b.category) ?? 0) > b.limit).length;
  score += Math.max(-15, 15 - over * 8);
  // savings progress
  const saved = spent.get("Savings") ?? 0;
  score += saved > 0 ? Math.min(10, Math.round((saved / Math.max(income, 1)) * 100)) : 0;
  // essential ratio
  const monthExp = txs.filter((x) => x.kind === "expense" && isThisMonth(x.date));
  const essential = sum(monthExp.filter((x) => categoryOf(x.category).essential));
  score += monthExp.length ? Math.round((essential / Math.max(sum(monthExp), 1)) * 12) : 0;

  return Math.max(0, Math.min(100, Math.round(score)));
}

export function healthLevel(score: number) {
  if (score >= 90) return { label: "Excellent", tone: "success" as const };
  if (score >= 75) return { label: "Healthy", tone: "success" as const };
  if (score >= 60) return { label: "Fair", tone: "warning" as const };
  if (score >= 40) return { label: "Needs Improvement", tone: "warning" as const };
  return { label: "Critical", tone: "danger" as const };
}

export type Alert = {
  id: string;
  level: "info" | "warn" | "over";
  title: string;
  body: string;
};

export function budgetAlerts(txs: Transaction[], budgets: Budget[]): Alert[] {
  const spent = spentByCategory(txs);
  const out: Alert[] = [];
  budgets.forEach((b) => {
    const used = spent.get(b.category) ?? 0;
    const pct = used / b.limit;
    if (pct >= 1)
      out.push({
        id: `budget-${b.category}-over`,
        level: "over",
        title: `You exceeded your ${b.category} budget`,
        body: `${peso(used)} of ${peso(b.limit)} used — ${peso(used - b.limit)} over the limit.`,
      });
    else if (pct >= 0.8)
      out.push({
        id: `budget-${b.category}-warn`,
        level: "warn",
        title: `${b.category} budget at ${Math.round(pct * 100)}%`,
        body: `${peso(used)} of ${peso(b.limit)} used. Only ${peso(b.limit - used)} remaining.`,
      });
  });
  return out;
}

export const unreadAlertCount = (alerts: Alert[], readIds: ReadonlySet<string>) =>
  alerts.filter((alert) => !readIds.has(alert.id)).length;

export function smartSuggestions(txs: Transaction[]): string[] {
  const week = txs.filter((x) => x.kind === "expense" && daysAgo(x.date) <= 7);
  const out: string[] = [];
  const coffee = week.filter((x) => x.category === "Coffee");
  if (coffee.length >= 2)
    out.push(
      `You've bought coffee ${coffee.length} times this week. Making coffee at home twice next week could save around ${peso(Math.round(sum(coffee) / coffee.length) * 2)}.`,
    );
  const transport = sum(week.filter((x) => x.category === "Transportation"));
  if (transport > 150)
    out.push(
      `Transportation reached ${peso(transport)} this week. Walking short distances could trim it noticeably.`,
    );
  const food = sum(week.filter((x) => x.category === "Food"));
  if (food > 0)
    out.push(`Food spending this week is ${peso(food)} — packing lunch twice keeps it in range.`);
  out.push("Consider transferring ₱500 into savings while your balance is still positive.");
  return out.slice(0, 4);
}

export function weeklyBars(txs: Transaction[]) {
  const weeks = [0, 1, 2, 3].map((w) => ({ name: `Week ${w + 1}`, amount: 0 }));
  txs
    .filter((x) => x.kind === "expense" && isThisMonth(x.date))
    .forEach((x) => {
      const day = Number(x.date.slice(8, 10));
      const idx = Math.min(3, Math.floor((day - 1) / 7));
      const w = weeks[idx];
      if (w) w.amount += x.amount;
    });
  return weeks;
}

export function monthlyTrend(txs: Transaction[]) {
  const out: { name: string; amount: number }[] = [];
  for (let i = 5; i >= 0; i--) {
    const dt = new Date();
    dt.setMonth(dt.getMonth() - i);
    const key = dt.toISOString().slice(0, 7);
    out.push({
      name: dt.toLocaleString("en-US", { month: "short" }),
      amount: sum(txs.filter((x) => x.kind === "expense" && x.date.slice(0, 7) === key)),
    });
  }
  // give past months plausible values so the trend reads well in the demo
  const base = [6200, 7400, 5100, 8300, 6900];
  return out.map((m, i) => ({ ...m, amount: m.amount || (i < 5 ? (base[i] ?? 0) : 0) }));
}

export function sparkline(seedNum: number) {
  return Array.from({ length: 12 }, (_, i) => ({
    x: i,
    y: 50 + Math.sin(i / 1.7 + seedNum) * 18 + Math.cos(i / 3 + seedNum) * 10,
  }));
}