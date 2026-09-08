import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import {
  SEED_BUDGETS,
  SEED_GOALS,
  SEED_TRANSACTIONS,
  type Budget,
  type Goal,
  type Transaction,
} from "./pockify";
import {
  addGoalContribution as persistGoalContribution,
  createBudget as persistBudget,
  createGoal as persistGoal,
  deleteBudget as persistBudgetDeletion,
  fetchFinance,
  hasFinanceApiSession,
} from "./pockify-api";

type Store = {
  user: { name: string; email: string };
  transactions: Transaction[];
  budgets: Budget[];
  goals: Goal[];
  addTransaction: (tx: Omit<Transaction, "id">) => void;
  updateTransaction: (id: string, patch: Partial<Transaction>) => void;
  removeTransaction: (id: string) => void;
  toggleFavorite: (id: string) => void;
  addBudget: (b: Omit<Budget, "id">) => void;
  updateBudget: (id: string, limit: number) => void;
  removeBudget: (id: string) => void;
  addGoal: (g: Omit<Goal, "id" | "current" | "contributions">) => void;
  contributeGoal: (id: string, amount: number) => void;
  readAlertIds: string[];
  markAlertRead: (id: string) => void;
  markAllAlertsRead: (ids: string[]) => void;
};

const Ctx = createContext<Store | null>(null);

const uid = () => Math.random().toString(36).slice(2, 10);

export function PockifyProvider({ children }: { children: ReactNode }) {
  const [transactions, setTransactions] = useState<Transaction[]>(SEED_TRANSACTIONS);
  const [budgets, setBudgets] = useState<Budget[]>(SEED_BUDGETS);
  const [goals, setGoals] = useState<Goal[]>(SEED_GOALS);
  const [readAlertIds, setReadAlertIds] = useState<string[]>([]);
  const hydrated = useRef(false);

  useEffect(() => {
    const saved = localStorage.getItem("pockify_finance");
    if (saved) {
      try {
        const parsed = JSON.parse(saved) as { budgets?: Budget[]; goals?: Goal[] };
        if (parsed.budgets) setBudgets(parsed.budgets);
        if (parsed.goals) setGoals(parsed.goals);
      } catch {
        localStorage.removeItem("pockify_finance");
      }
    }

    fetchFinance()
      .then((finance) => {
        if (finance) {
          setBudgets(finance.budgets);
          setGoals(finance.goals);
        }
      })
      .catch(() => undefined)
      .finally(() => {
        hydrated.current = true;
      });
  }, []);

  useEffect(() => {
    if (hydrated.current && !hasFinanceApiSession()) {
      localStorage.setItem("pockify_finance", JSON.stringify({ budgets, goals }));
    }
  }, [budgets, goals]);

  const value = useMemo<Store>(
    () => ({
      user: { name: "Mark", email: "mark@pockify.app" },
      transactions,
      budgets,
      goals,
      readAlertIds,
      markAlertRead: (id) => setReadAlertIds((prev) => (prev.includes(id) ? prev : [...prev, id])),
      markAllAlertsRead: (ids) => setReadAlertIds((prev) => [...new Set([...prev, ...ids])]),
      addTransaction: (tx) => setTransactions((p) => [{ ...tx, id: uid() }, ...p]),
      updateTransaction: (id, patch) =>
        setTransactions((p) => p.map((t) => (t.id === id ? { ...t, ...patch } : t))),
      removeTransaction: (id) => setTransactions((p) => p.filter((t) => t.id !== id)),
      toggleFavorite: (id) =>
        setTransactions((p) => p.map((t) => (t.id === id ? { ...t, favorite: !t.favorite } : t))),
      addBudget: (b) => {
        const optimistic = { ...b, id: uid() };
        setBudgets((p) => [optimistic, ...p]);
        persistBudget(b)
          .then(
            (saved) =>
              saved &&
              setBudgets((p) => p.map((item) => (item.id === optimistic.id ? saved : item))),
          )
          .catch(() => undefined);
      },
      updateBudget: (id, limit) =>
        setBudgets((p) => p.map((b) => (b.id === id ? { ...b, limit } : b))),
      removeBudget: (id) => {
        setBudgets((p) => p.filter((b) => b.id !== id));
        persistBudgetDeletion(id).catch(() => undefined);
      },
      addGoal: (g) => {
        const optimistic: Goal = { ...g, id: uid(), current: 0, contributions: [] };
        setGoals((p) => [...p, optimistic]);
        persistGoal(g)
          .then(
            (saved) =>
              saved && setGoals((p) => p.map((item) => (item.id === optimistic.id ? saved : item))),
          )
          .catch(() => undefined);
      },
      contributeGoal: (id, amount) => {
        const date = new Date().toISOString().slice(0, 10);
        setGoals((p) =>
          p.map((g) =>
            g.id === id
              ? {
                  ...g,
                  current: g.current + amount,
                  contributions: [...g.contributions, { id: uid(), amount, date }],
                }
              : g,
          ),
        );
        persistGoalContribution(id, amount, date)
          .then(
            (saved) => saved && setGoals((p) => p.map((item) => (item.id === id ? saved : item))),
          )
          .catch(() => undefined);
      },
    }),
    [transactions, budgets, goals, readAlertIds],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function usePockify() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("usePockify must be used inside PockifyProvider");
  return ctx;
}
