<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\SavingsGoal;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'transactions' => $user->transactions()->orderByDesc('date')->orderByDesc('id')->get(),
            'budgets' => $user->budgets()->orderByDesc('budget_date')->orderByDesc('id')->get(),
            'goals' => $user->savingsGoals()->with('contributions')->orderBy('id')->get(),
        ]);
    }

    public function storeTransaction(Request $request)
    {
        $data = $request->validate([
            'kind' => ['required', 'in:income,expense'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'category' => ['required', 'string', 'max:120'],
            'note' => ['nullable', 'string', 'max:500'],
            'date' => ['required', 'date_format:Y-m-d'],
            'method' => ['nullable', 'string', 'max:80'],
            'favorite' => ['sometimes', 'boolean'],
        ]);

        $transaction = $request->user()->transactions()->create($data);

        return response()->json(['transaction' => $transaction], 201);
    }

    public function updateTransaction(Request $request, Transaction $transaction)
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);

        $data = $request->validate([
            'kind' => ['sometimes', 'in:income,expense'],
            'amount' => ['sometimes', 'numeric', 'gt:0'],
            'category' => ['sometimes', 'string', 'max:120'],
            'note' => ['nullable', 'string', 'max:500'],
            'date' => ['sometimes', 'date_format:Y-m-d'],
            'method' => ['nullable', 'string', 'max:80'],
            'favorite' => ['sometimes', 'boolean'],
        ]);

        $transaction->update($data);

        return response()->json(['transaction' => $transaction->fresh()]);
    }

    public function destroyTransaction(Request $request, Transaction $transaction)
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);
        $transaction->delete();

        return response()->noContent();
    }

    public function storeBudget(Request $request)
    {
        $data = $request->validate([
            'category' => ['required', 'string', 'max:120'],
            'limit' => ['required', 'numeric', 'gt:0'],
            'date' => ['required', 'date_format:Y-m-d'],
        ]);

        $budget = $request->user()->budgets()->create([
            'category' => trim($data['category']),
            'limit' => $data['limit'],
            'budget_date' => $data['date'],
        ]);

        return response()->json(['budget' => $budget], 201);
    }

    public function destroyBudget(Request $request, Budget $budget)
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
        $budget->delete();
        return response()->noContent();
    }

    public function storeGoal(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:160'],
            'target' => ['required', 'numeric', 'gt:0'],
        ]);

        $goal = $request->user()->savingsGoals()->create([
            'title' => trim($data['title']),
            'target' => $data['target'],
            'current' => 0,
        ]);

        return response()->json(['goal' => $goal->load('contributions')], 201);
    }

    public function contribute(Request $request, SavingsGoal $goal)
    {
        abort_unless($goal->user_id === $request->user()->id, 404);

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'gt:0'],
            'date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $goal = DB::transaction(function () use ($goal, $data) {
            $goal->contributions()->create([
                'amount' => $data['amount'],
                'contributed_at' => $data['date'] ?? now()->toDateString(),
            ]);
            $goal->increment('current', $data['amount']);
            return $goal->fresh('contributions');
        });

        return response()->json(['goal' => $goal]);
    }
}
