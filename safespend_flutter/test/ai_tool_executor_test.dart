import 'package:flutter_test/flutter_test.dart';
import 'package:safespend_flutter/models/account.dart';
import 'package:safespend_flutter/models/category.dart';
import 'package:safespend_flutter/providers/app_provider.dart';
import 'package:safespend_flutter/services/ai/ai_tool_call.dart';
import 'package:safespend_flutter/services/ai/tools/ai_tool_executor.dart';
import 'package:safespend_flutter/services/ai/tools/ai_tool_registry.dart';

/// Provider seeded in memory. `addAccount`/`addCategory` also try to sync to
/// Supabase, which is uninitialised in tests — the sync path guards on a null
/// user id, so seeding through the public API stays offline.
AppProvider _seededProvider() {
  final p = AppProvider();
  p.addAccount(Account(
    id: 'acc-checking',
    name: 'Checking',
    type: 'bank',
    balance: 5000,
  ));
  p.addAccount(Account(
    id: 'acc-savings',
    name: 'Savings',
    type: 'savings',
    balance: 2000,
  ));
  p.addCategory(Category(
    id: 'cat-food',
    name: 'Food',
    group: 'variable',
    icon: 'cart',
    color: '#FF0000',
    budgetLimit: 1500,
  ));
  return p;
}

void main() {
  // AppProvider's constructor reaches for SharedPreferences; the binding must
  // exist or every construction logs a initialisation failure.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('read tools', () {
    test('execute immediately without confirmation', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(
        const AIToolCall(id: '1', name: 'get_accounts'),
      );

      expect(outcome.decision, AIToolDecision.executed);
      expect(outcome.result?.ok, isTrue);
      final accounts = outcome.result!.data!['accounts'] as List;
      // Cash on hand is synthesised alongside the two real accounts.
      expect(accounts.length, 3);
    });

    test('get_account_balance rejects an unknown account', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'get_account_balance',
        arguments: {'account_id': 'does-not-exist'},
      ));

      expect(outcome.result?.ok, isFalse);
      expect(outcome.result?.errorCode, 'invalidToolRequest');
    });
  });

  group('write tools', () {
    test('require confirmation and change nothing on submit', () {
      final provider = _seededProvider();
      final executor = AIToolExecutor(provider);
      final before = provider.transactions.length;

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {
          'type': 'expense',
          'amount': 250,
          'account_id': 'acc-checking',
          'note': 'Groceries',
        },
      ));

      expect(outcome.decision, AIToolDecision.needsConfirmation);
      expect(outcome.confirmationSummary, contains('250.00'));
      expect(provider.transactions.length, before,
          reason: 'submit must not mutate before approval');
    });

    test('confirm executes the mutation', () {
      final provider = _seededProvider();
      final executor = AIToolExecutor(provider);

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {
          'type': 'expense',
          'amount': 250,
          'account_id': 'acc-checking',
        },
      ));
      final result = executor.confirm(outcome.call);

      expect(result.ok, isTrue);
      expect(provider.transactions.length, 1);
      expect(provider.transactions.first.amount, 250);
    });

    test('transfer summary names both accounts', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transfer',
        arguments: {
          'from_account_id': 'acc-checking',
          'to_account_id': 'acc-savings',
          'amount': 1000,
        },
      ));

      expect(outcome.decision, AIToolDecision.needsConfirmation);
      expect(outcome.confirmationSummary, contains('Checking'));
      expect(outcome.confirmationSummary, contains('Savings'));
    });

    test('rejects a transfer to the same account', () {
      final executor = AIToolExecutor(_seededProvider());

      final call = const AIToolCall(
        id: '1',
        name: 'create_transfer',
        arguments: {
          'from_account_id': 'acc-checking',
          'to_account_id': 'acc-checking',
          'amount': 100,
        },
      );
      final result = executor.confirm(call);

      expect(result.ok, isFalse);
      expect(result.errorCode, 'invalidToolRequest');
    });

    test('rejects a non-positive amount', () {
      final executor = AIToolExecutor(_seededProvider());

      final result = executor.confirm(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {
          'type': 'expense',
          'amount': -50,
          'account_id': 'acc-checking',
        },
      ));

      expect(result.ok, isFalse);
      expect(result.errorMessage, contains('greater than zero'));
    });
  });

  group('validation', () {
    test('unknown tool names are rejected', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome =
          executor.submit(const AIToolCall(id: '1', name: 'drop_all_tables'));

      expect(outcome.decision, AIToolDecision.rejected);
      expect(outcome.result?.errorMessage, contains('Unknown tool'));
    });

    test('missing required arguments are reported by name', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {'type': 'expense'},
      ));

      expect(outcome.decision, AIToolDecision.rejected);
      expect(outcome.result?.errorMessage, contains('amount'));
      expect(outcome.result?.errorMessage, contains('account_id'));
    });

    test('model-supplied identity arguments are stripped', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {
          'type': 'expense',
          'amount': 10,
          'account_id': 'acc-checking',
          'user_id': 'someone-else',
          'token': 'forged',
        },
      ));

      expect(outcome.call.arguments.containsKey('user_id'), isFalse);
      expect(outcome.call.arguments.containsKey('token'), isFalse);
    });

    test('writes against a missing entity are rejected, not queued', () {
      final executor = AIToolExecutor(_seededProvider());

      final outcome = executor.submit(const AIToolCall(
        id: '1',
        name: 'create_transaction',
        arguments: {
          'type': 'expense',
          'amount': 10,
          'account_id': 'ghost-account',
        },
      ));

      expect(outcome.decision, AIToolDecision.rejected);
    });
  });

  group('registry', () {
    test('every declared tool is implemented', () {
      final executor = AIToolExecutor(_seededProvider());

      for (final tool in AIToolRegistry.all) {
        final result = executor.confirm(AIToolCall(id: 't', name: tool.name));
        expect(result.errorMessage, isNot(contains('not implemented')),
            reason: '${tool.name} is declared but has no implementation');
      }
    });

    test('read tools never require confirmation, writes always do', () {
      for (final tool in AIToolRegistry.readTools) {
        expect(tool.requiresConfirmation, isFalse, reason: tool.name);
      }
      for (final tool in AIToolRegistry.writeTools) {
        expect(tool.requiresConfirmation, isTrue, reason: tool.name);
      }
    });
  });
}
