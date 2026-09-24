import type { Budget, Goal, GoalContribution } from "./pockify";

type FinancePayload = {
  budgets: Array<{ id: number; category: string; limit: string | number; budget_date: string }>;
  goals: Array<{
    id: number;
    title: string;
    target: string | number;
    current: string | number;
    contributions: Array<{
      id: number;
      amount: string | number;
      contributed_at: string;
    }>;
  }>;
};

const apiBase = () =>
  (import.meta.env["VITE_API_URL"] as string | undefined)?.replace(/\/$/, "") ??
  "http://localhost:8000/api";

const token = () =>
  typeof window === "undefined" ? null : localStorage.getItem("pockify_api_token");

async function request<T>(path: string, init?: RequestInit): Promise<T | null> {
  const accessToken = token();
  if (!accessToken) return null;

  const response = await fetch(`${apiBase()}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      ...init?.headers,
    },
  });

  if (!response.ok) throw new Error(`Finance request failed (${response.status})`);
  return response.status === 204 ? null : ((await response.json()) as T);
}

export const hasFinanceApiSession = () => Boolean(token());

export async function fetchFinance(): Promise<{ budgets: Budget[]; goals: Goal[] } | null> {
  const payload = await request<FinancePayload>("/finance");
  if (!payload) return null;

  return {
    budgets: payload.budgets.map((budget) => ({
      id: String(budget.id),
      category: budget.category,
      limit: Number(budget.limit),
      date: budget.budget_date,
    })),
    goals: payload.goals.map((goal) => ({
      id: String(goal.id),
      title: goal.title,
      target: Number(goal.target),
      current: Number(goal.current),
      contributions: goal.contributions.map((contribution) => ({
        id: String(contribution.id),
        amount: Number(contribution.amount),
        date: contribution.contributed_at,
      })),
    })),
  };
}

export async function createBudget(input: Omit<Budget, "id">) {
  const payload = await request<{
    budget: { id: number; category: string; limit: string; budget_date: string };
  }>("/budgets", { method: "POST", body: JSON.stringify({ ...input, date: input.date }) });
  if (!payload) return null;
  return {
    id: String(payload.budget.id),
    category: payload.budget.category,
    limit: Number(payload.budget.limit),
    date: payload.budget.budget_date,
  } satisfies Budget;
}

export async function deleteBudget(id: string) {
  await request(`/budgets/${id}`, { method: "DELETE" });
}

export async function createGoal(input: Omit<Goal, "id" | "current" | "contributions">) {
  const payload = await request<{ goal: { id: number; title: string; target: string } }>(
    "/savings-goals",
    { method: "POST", body: JSON.stringify(input) },
  );
  if (!payload) return null;
  return {
    id: String(payload.goal.id),
    title: payload.goal.title,
    target: Number(payload.goal.target),
    current: 0,
    contributions: [],
  } satisfies Goal;
}

export async function addGoalContribution(id: string, amount: number, date: string) {
  const payload = await request<{ goal: FinancePayload["goals"][number] }>(
    `/savings-goals/${id}/contributions`,
    { method: "POST", body: JSON.stringify({ amount, date }) },
  );
  if (!payload) return null;
  return {
    id: String(payload.goal.id),
    title: payload.goal.title,
    target: Number(payload.goal.target),
    current: Number(payload.goal.current),
    contributions: payload.goal.contributions.map((contribution) => ({
      id: String(contribution.id),
      amount: Number(contribution.amount),
      date: contribution.contributed_at,
    })),
  } satisfies Goal;
}

export type { GoalContribution };
