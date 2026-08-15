import { useState } from "react";
import { toast } from "sonner";
import { CATEGORIES, INCOME_SOURCES, peso, type TxKind } from "@/lib/pockify";
import { usePockify } from "@/lib/pockify-store";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";

export function QuickAdd({ open, onOpenChange }: { open: boolean; onOpenChange: (v: boolean) => void }) {
  const { addTransaction, transactions } = usePockify();
  const [kind, setKind] = useState<TxKind>("expense");
  const [amount, setAmount] = useState("");
  const [category, setCategory] = useState("Food");
  const [source, setSource] = useState("Salary");
  const [note, setNote] = useState("");
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));

  const favorites = transactions.filter((t) => t.favorite).slice(0, 4);

  const submit = () => {
    const value = Number(amount);
    if (!value || value <= 0) {
      toast.error("Enter an amount first");
      return;
    }
    addTransaction({
      kind,
      amount: value,
      category: kind === "expense" ? category : source,
      note: note || undefined,
      date,
      method: kind === "expense" ? "Cash" : "Bank",
    });
    toast.success(`${kind === "expense" ? "Expense" : "Income"} of ${peso(value)} recorded`);
    setAmount("");
    setNote("");
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="card-raised max-w-sm gap-4 border-0 p-6">
        <DialogHeader className="space-y-1 text-left">
          <DialogTitle className="text-xl">Quick add</DialogTitle>
          <DialogDescription>Log it in a few taps — no backend needed yet.</DialogDescription>
        </DialogHeader>

        <div className="bg-surface-sunken flex rounded-full p-1">
          {(["expense", "income"] as TxKind[]).map((k) => (
            <button
              key={k}
              onClick={() => setKind(k)}
              className={`flex-1 rounded-full py-2 text-sm font-semibold capitalize transition ${
                kind === k
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-muted-foreground"
              }`}
            >
              {k}
            </button>
          ))}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="qa-amount">Amount</Label>
          <Input
            id="qa-amount"
            inputMode="decimal"
            placeholder="0.00"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="num h-14 rounded-2xl border-0 bg-surface-sunken text-2xl font-bold"
          />
        </div>

        {favorites.length > 0 && kind === "expense" && (
          <div className="flex flex-wrap gap-2">
            {favorites.map((f) => (
              <button
                key={f.id}
                onClick={() => {
                  setAmount(String(f.amount));
                  setCategory(f.category);
                  setNote(f.note ?? "");
                }}
                className="bg-surface-sunken text-muted-foreground rounded-full px-3 py-1.5 text-xs font-medium"
              >
                ⭐ {f.note ?? f.category} · {peso(f.amount)}
              </button>
            ))}
          </div>
        )}

        <div className="space-y-1.5">
          <Label>{kind === "expense" ? "Category" : "Source"}</Label>
          <div className="flex flex-wrap gap-2">
            {(kind === "expense" ? CATEGORIES.map((c) => c.name) : INCOME_SOURCES).map((name) => {
              const active = kind === "expense" ? category === name : source === name;
              return (
                <button
                  key={name}
                  onClick={() => (kind === "expense" ? setCategory(name) : setSource(name))}
                  className={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
                    active
                      ? "bg-accent text-accent-foreground"
                      : "bg-surface-sunken text-muted-foreground"
                  }`}
                >
                  {name}
                </button>
              );
            })}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1.5">
            <Label htmlFor="qa-date">Date</Label>
            <Input
              id="qa-date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="bg-surface-sunken h-11 rounded-xl border-0"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="qa-note">Note</Label>
            <Input
              id="qa-note"
              placeholder="Optional"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="bg-surface-sunken h-11 rounded-xl border-0"
            />
          </div>
        </div>

        <Button onClick={submit} className="h-12 w-full rounded-full text-base font-semibold">
          Save {kind}
        </Button>
      </DialogContent>
    </Dialog>
  );
}