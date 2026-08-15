import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import {
  SEED_BUDGETS,
  SEED_GOALS,
  SEED_TRANSACTIONS,
  type Budget,
  type Goal,
  type Transaction,
} from "./pockify";

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
  addGoal: (g: Omit<Goal, "id">) => void;
  contributeGoal: (id: string, amount: number) => void;
};

const Ctx = createContext<Store | null>(null);

const uid = () => Math.random().toString(36).slice(2, 10);

export function PockifyProvider({ children }: { children: ReactNode }) {
  const [transactions, setTransactions] = useState<Transaction[]>(SEED_TRANSACTIONS);
  const [budgets, setBudgets] = useState<Budget[]>(SEED_BUDGETS);
  const [goals, setGoals] = useState<Goal[]>(SEED_GOALS);

  const value = useMemo<Store>(
    () => ({
      user: { name: "Mark", email: "mark@pockify.app" },
      transactions,
      budgets,
      goals,
      addTransaction: (tx) => setTransactions((p) => [{ ...tx, id: uid() }, ...p]),
      updateTransaction: (id, patch) =>
        setTransactions((p) => p.map((t) => (t.id === id ? { ...t, ...patch } : t))),
      removeTransaction: (id) => setTransactions((p) => p.filter((t) => t.id !== id)),
      toggleFavorite: (id) =>
        setTransactions((p) => p.map((t) => (t.id === id ? { ...t, favorite: !t.favorite } : t))),
      addBudget: (b) => setBudgets((p) => [...p, { ...b, id: uid() }]),
      updateBudget: (id, limit) =>
        setBudgets((p) => p.map((b) => (b.id === id ? { ...b, limit } : b))),
      removeBudget: (id) => setBudgets((p) => p.filter((b) => b.id !== id)),
      addGoal: (g) => setGoals((p) => [...p, { ...g, id: uid() }]),
      contributeGoal: (id, amount) =>
        setGoals((p) =>
          p.map((g) =>
            g.id === id ? { ...g, current: Math.min(g.target, g.current + amount) } : g,
          ),
        ),
    }),
    [transactions, budgets, goals],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function usePockify() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("usePockify must be used inside PockifyProvider");
  return ctx;
}