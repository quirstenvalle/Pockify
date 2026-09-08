<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\SavingsGoal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'budgets' => $user->budgets()->orderByDesc('budget_date')->orderByDesc('id')->get(),
            'goals' => $user->savingsGoals()->with('contributions')->orderBy('id')->get(),
        ]);
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
