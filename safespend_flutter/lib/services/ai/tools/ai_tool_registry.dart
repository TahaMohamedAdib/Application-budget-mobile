import 'ai_tool.dart';

/// The complete set of capabilities SafeSpend exposes to the AI backend.
///
/// This is the contract: the backend may request any tool named here and
/// nothing else. Adding a capability means adding it here *and* handling it in
/// `AIToolExecutor` — an unhandled name is rejected rather than ignored.
class AIToolRegistry {
  const AIToolRegistry._();

  // ── Read tools ────────────────────────────────────────────────────────────

  static const _accountId = AIToolParam(
    name: 'account_id',
    type: AIToolParamType.string,
    description: 'SafeSpend account id, or "cash_on_hand" for physical cash.',
  );

  static const List<AITool> readTools = [
    AITool(
      name: 'get_financial_summary',
      description:
          'Overall snapshot: net worth, assets, debt, monthly income and expenses.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_safe_to_spend',
      description:
          'How much the user can safely spend, for today or the rest of the month.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'period',
          type: AIToolParamType.string,
          description: 'Which window to compute.',
          allowed: ['today', 'month'],
        ),
      ],
    ),
    AITool(
      name: 'get_accounts',
      description: 'List every account with its type and balance.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_account_balance',
      description: 'Current balance of one account.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'account_id',
          type: AIToolParamType.string,
          description: 'Account id, or "cash_on_hand".',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'get_recent_transactions',
      description: 'Most recent transactions, newest first.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'limit',
          type: AIToolParamType.integer,
          description: 'How many to return (default 20, max 100).',
        ),
        _accountId,
      ],
    ),
    AITool(
      name: 'search_transactions',
      description:
          'Find transactions by text, category, type, amount range or date range.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'query',
          type: AIToolParamType.string,
          description: 'Text to match against note and description.',
        ),
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'Restrict to one category.',
        ),
        AIToolParam(
          name: 'type',
          type: AIToolParamType.string,
          description: 'Transaction type.',
          allowed: ['expense', 'income', 'transfer', 'withdrawal'],
        ),
        AIToolParam(
          name: 'min_amount',
          type: AIToolParamType.number,
          description: 'Lower bound, inclusive.',
        ),
        AIToolParam(
          name: 'max_amount',
          type: AIToolParamType.number,
          description: 'Upper bound, inclusive.',
        ),
        AIToolParam(
          name: 'start_date',
          type: AIToolParamType.date,
          description: 'ISO-8601 earliest date, inclusive.',
        ),
        AIToolParam(
          name: 'end_date',
          type: AIToolParamType.date,
          description: 'ISO-8601 latest date, inclusive.',
        ),
        AIToolParam(
          name: 'limit',
          type: AIToolParamType.integer,
          description: 'Max results (default 50, max 200).',
        ),
      ],
    ),
    AITool(
      name: 'get_spending_by_category',
      description: 'Total spent per category over a period.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'start_date',
          type: AIToolParamType.date,
          description: 'ISO-8601 start. Defaults to the current month.',
        ),
        AIToolParam(
          name: 'end_date',
          type: AIToolParamType.date,
          description: 'ISO-8601 end. Defaults to now.',
        ),
      ],
    ),
    AITool(
      name: 'get_budget_status',
      description: 'Every budget with its limit, spent amount and remainder.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_upcoming_bills',
      description: 'Recurring charges due soon.',
      access: AIToolAccess.read,
      params: [
        AIToolParam(
          name: 'days_ahead',
          type: AIToolParamType.integer,
          description: 'Look-ahead window in days (default 30).',
        ),
      ],
    ),
    AITool(
      name: 'get_subscriptions',
      description: 'Active recurring subscriptions and their cost.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_savings_goals',
      description: 'Savings goals with target, saved amount and progress.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_debts',
      description: 'Debts with original amount, paid amount and remainder.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_net_worth',
      description: 'Net worth, with the asset and liability breakdown.',
      access: AIToolAccess.read,
    ),
    AITool(
      name: 'get_investment_summary',
      description: 'Portfolio value, cost basis and unrealised gain or loss.',
      access: AIToolAccess.read,
    ),
  ];

  // ── Write tools ───────────────────────────────────────────────────────────

  static const List<AITool> writeTools = [
    AITool(
      name: 'create_transaction',
      description: 'Record an expense, income or withdrawal.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'type',
          type: AIToolParamType.string,
          description: 'Kind of transaction.',
          required: true,
          allowed: ['expense', 'income', 'withdrawal'],
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'Positive amount in the user currency.',
          required: true,
        ),
        AIToolParam(
          name: 'account_id',
          type: AIToolParamType.string,
          description: 'Account to debit or credit, or "cash_on_hand".',
          required: true,
        ),
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'Category, for expenses.',
        ),
        AIToolParam(
          name: 'date',
          type: AIToolParamType.date,
          description: 'ISO-8601 date. Defaults to now.',
        ),
        AIToolParam(
          name: 'note',
          type: AIToolParamType.string,
          description: 'Short title, e.g. the merchant.',
        ),
        AIToolParam(
          name: 'description',
          type: AIToolParamType.string,
          description: 'Longer detail.',
        ),
        AIToolParam(
          name: 'fees',
          type: AIToolParamType.number,
          description: 'Bank fees charged on top.',
        ),
      ],
    ),
    AITool(
      name: 'update_transaction',
      description: 'Change fields on an existing transaction.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'transaction_id',
          type: AIToolParamType.string,
          description: 'Transaction to update.',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'New amount.',
        ),
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'New category.',
        ),
        AIToolParam(
          name: 'note',
          type: AIToolParamType.string,
          description: 'New title.',
        ),
        AIToolParam(
          name: 'date',
          type: AIToolParamType.date,
          description: 'New ISO-8601 date.',
        ),
      ],
    ),
    AITool(
      name: 'delete_transaction',
      description: 'Remove a transaction and reverse its balance effect.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'transaction_id',
          type: AIToolParamType.string,
          description: 'Transaction to delete.',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'create_transfer',
      description: 'Move money between two accounts.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'from_account_id',
          type: AIToolParamType.string,
          description: 'Source account, or "cash_on_hand".',
          required: true,
        ),
        AIToolParam(
          name: 'to_account_id',
          type: AIToolParamType.string,
          description: 'Destination account, or "cash_on_hand".',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'Positive amount to move.',
          required: true,
        ),
        AIToolParam(
          name: 'fees',
          type: AIToolParamType.number,
          description: 'Transfer fees.',
        ),
        AIToolParam(
          name: 'note',
          type: AIToolParamType.string,
          description: 'Short label.',
        ),
      ],
    ),
    AITool(
      name: 'create_budget',
      description: 'Set a monthly spending limit on a category.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'Category to budget.',
          required: true,
        ),
        AIToolParam(
          name: 'limit',
          type: AIToolParamType.number,
          description: 'Monthly cap.',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'update_budget',
      description: 'Change a category budget limit.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'Category to change.',
          required: true,
        ),
        AIToolParam(
          name: 'limit',
          type: AIToolParamType.number,
          description: 'New monthly cap. Zero removes the budget.',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'create_goal',
      description: 'Create a savings goal.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'name',
          type: AIToolParamType.string,
          description: 'Goal name.',
          required: true,
        ),
        AIToolParam(
          name: 'target_amount',
          type: AIToolParamType.number,
          description: 'Amount to reach.',
          required: true,
        ),
        AIToolParam(
          name: 'target_date',
          type: AIToolParamType.date,
          description: 'Optional ISO-8601 deadline.',
        ),
      ],
    ),
    AITool(
      name: 'update_goal',
      description: 'Change a goal name, target or deadline.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'goal_id',
          type: AIToolParamType.string,
          description: 'Goal to update.',
          required: true,
        ),
        AIToolParam(
          name: 'name',
          type: AIToolParamType.string,
          description: 'New name.',
        ),
        AIToolParam(
          name: 'target_amount',
          type: AIToolParamType.number,
          description: 'New target.',
        ),
        AIToolParam(
          name: 'target_date',
          type: AIToolParamType.date,
          description: 'New ISO-8601 deadline.',
        ),
      ],
    ),
    AITool(
      name: 'contribute_to_goal',
      description: 'Move money from an account into a savings goal.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'goal_id',
          type: AIToolParamType.string,
          description: 'Goal to fund.',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'Positive amount to contribute.',
          required: true,
        ),
        AIToolParam(
          name: 'account_id',
          type: AIToolParamType.string,
          description: 'Account to draw from.',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'create_subscription',
      description: 'Add a recurring charge.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'name',
          type: AIToolParamType.string,
          description: 'Subscription name.',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'Charge per period.',
          required: true,
        ),
        AIToolParam(
          name: 'account_id',
          type: AIToolParamType.string,
          description: 'Account charged.',
          required: true,
        ),
        AIToolParam(
          name: 'frequency',
          type: AIToolParamType.string,
          description: 'How often it recurs.',
          required: true,
          allowed: ['daily', 'weekly', 'monthly', 'yearly'],
        ),
        AIToolParam(
          name: 'next_date',
          type: AIToolParamType.date,
          description: 'ISO-8601 date of the next charge.',
        ),
        AIToolParam(
          name: 'category_id',
          type: AIToolParamType.string,
          description: 'Category to file it under.',
        ),
      ],
    ),
    AITool(
      name: 'update_subscription',
      description: 'Change a subscription amount, frequency or next date.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'subscription_id',
          type: AIToolParamType.string,
          description: 'Subscription to update.',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'New amount.',
        ),
        AIToolParam(
          name: 'frequency',
          type: AIToolParamType.string,
          description: 'New cadence.',
          allowed: ['daily', 'weekly', 'monthly', 'yearly'],
        ),
        AIToolParam(
          name: 'next_date',
          type: AIToolParamType.date,
          description: 'New ISO-8601 next charge date.',
        ),
      ],
    ),
    AITool(
      name: 'cancel_subscription',
      description: 'Stop a recurring charge.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'subscription_id',
          type: AIToolParamType.string,
          description: 'Subscription to cancel.',
          required: true,
        ),
      ],
    ),
    AITool(
      name: 'record_debt_payment',
      description: 'Record a payment against a debt.',
      access: AIToolAccess.write,
      params: [
        AIToolParam(
          name: 'debt_id',
          type: AIToolParamType.string,
          description: 'Debt being paid.',
          required: true,
        ),
        AIToolParam(
          name: 'amount',
          type: AIToolParamType.number,
          description: 'Positive payment amount.',
          required: true,
        ),
        AIToolParam(
          name: 'account_id',
          type: AIToolParamType.string,
          description: 'Account the payment comes from.',
          required: true,
        ),
      ],
    ),
  ];

  static List<AITool> get all => [...readTools, ...writeTools];

  static AITool? byName(String name) {
    for (final t in all) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Schema list for the backend's function-calling payload.
  static List<Map<String, dynamic>> toSchema() =>
      all.map((t) => t.toSchema()).toList();
}
