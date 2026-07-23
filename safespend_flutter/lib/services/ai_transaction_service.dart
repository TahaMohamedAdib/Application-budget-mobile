import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../models/category.dart';
import '../models/account.dart';
import 'ai_proxy_service.dart';

class AiTransactionDraft {
  final String type;
  final double amount;
  final double fees;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String dateIso;
  final String? note;
  final String? description;
  final String? expenseSubType;
  final String? recipientName;
  final bool attachReceipt;

  const AiTransactionDraft({
    required this.type,
    required this.amount,
    required this.fees,
    required this.accountId,
    required this.dateIso,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.description,
    this.expenseSubType,
    this.recipientName,
    this.attachReceipt = false,
  });

  AiTransactionDraft copyWith({
    String? type,
    double? amount,
    double? fees,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? dateIso,
    String? note,
    String? description,
    String? expenseSubType,
    String? recipientName,
    bool? attachReceipt,
  }) {
    return AiTransactionDraft(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      dateIso: dateIso ?? this.dateIso,
      note: note ?? this.note,
      description: description ?? this.description,
      expenseSubType: expenseSubType ?? this.expenseSubType,
      recipientName: recipientName ?? this.recipientName,
      attachReceipt: attachReceipt ?? this.attachReceipt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'fees': fees,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'dateIso': dateIso,
      'note': note,
      'description': description,
      'expenseSubType': expenseSubType,
      'recipientName': recipientName,
      'attachReceipt': attachReceipt,
    };
  }

  factory AiTransactionDraft.fromJson(Map<String, dynamic> json) {
    return AiTransactionDraft(
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
      accountId: json['accountId'] as String? ?? '',
      toAccountId: json['toAccountId'] as String?,
      categoryId: json['categoryId'] as String?,
      dateIso: json['dateIso'] as String? ?? '',
      note: json['note'] as String?,
      description: json['description'] as String?,
      expenseSubType: json['expenseSubType'] as String?,
      recipientName: json['recipientName'] as String?,
      attachReceipt: json['attachReceipt'] as bool? ?? false,
    );
  }
}

class AiTransactionResult {
  final String kind; // not_transaction | question | draft
  final String message;
  final List<String> missingFields;
  final AiTransactionDraft? draft;

  const AiTransactionResult({
    required this.kind,
    required this.message,
    this.missingFields = const [],
    this.draft,
  });

  bool get isNotTransaction => kind == 'not_transaction';
  bool get needsQuestion => kind == 'question';
  bool get hasDraft => kind == 'draft' && draft != null;

  factory AiTransactionResult.fromJson(Map<String, dynamic> json) {
    final draftJson = json['draft'];
    return AiTransactionResult(
      kind: json['kind'] as String? ?? 'not_transaction',
      message: json['message'] as String? ?? '',
      missingFields: (json['missingFields'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      draft: draftJson is Map<String, dynamic>
          ? AiTransactionDraft.fromJson(draftJson)
          : null,
    );
  }
}

class AiTransactionService {
  static Future<AiTransactionResult> analyze({
    required String userText,
    required List<Map<String, String>> recentHistory,
    required List<Account> accounts,
    required List<Category> categories,
    required String currency,
    String? activeTransactionType,
    AiTransactionDraft? pendingDraft,
    String? attachmentBase64,
    String? attachmentMimeType,
  }) async {
    final now = DateTime.now();
    final prompt = _prompt(
      userText: userText,
      recentHistory: recentHistory,
      accounts: accounts,
      categories: categories,
      currency: currency,
      activeTransactionType: activeTransactionType,
      pendingDraft: pendingDraft,
      now: now,
      hasAttachment: attachmentBase64 != null && attachmentMimeType != null,
    );

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];
    if (attachmentBase64 != null && attachmentMimeType != null) {
      parts.add({
        'inlineData': {
          'mimeType': attachmentMimeType,
          'data': attachmentBase64,
        },
      });
    }

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1200,
        'responseMimeType': 'application/json',
      },
    };

    final response = await AiProxyService.generateContent(body);

    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint(
            'Gemini transaction API error [${response.statusCode}]: ${response.body}');
      }
      return const AiTransactionResult(
        kind: 'not_transaction',
        message: '',
      );
    }

    final decoded = response.decodeJsonObject();
    final candidates = decoded['candidates'] as List<dynamic>?;
    final firstCandidate =
        candidates == null || candidates.isEmpty ? null : candidates.first;
    final content = firstCandidate is Map<String, dynamic>
        ? firstCandidate['content'] as Map<String, dynamic>?
        : null;
    final partsOut = content?['parts'] as List?;
    String? text;
    for (final part in partsOut ?? const []) {
      if (part is Map && part['text'] is String) {
        text = part['text'] as String;
        break;
      }
    }
    if (text == null || text.trim().isEmpty) {
      return const AiTransactionResult(kind: 'not_transaction', message: '');
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return AiTransactionResult.fromJson(json);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to parse transaction JSON: $e');
      return const AiTransactionResult(kind: 'not_transaction', message: '');
    }
  }

  static String _prompt({
    required String userText,
    required List<Map<String, String>> recentHistory,
    required List<Account> accounts,
    required List<Category> categories,
    required String currency,
    required String? activeTransactionType,
    required AiTransactionDraft? pendingDraft,
    required DateTime now,
    required bool hasAttachment,
  }) {
    final accountRows = [
      {
        'id': 'cash_on_hand',
        'name': 'Cash on Hand',
        'type': 'cash',
      },
      ...accounts.map((a) => {
            'id': a.id,
            'name': a.name,
            'type': a.type,
            'bankName': a.bankName,
          }),
    ];
    final categoryRows = categories
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'group': c.group,
            })
        .toList();
    final history = recentHistory
        .take(8)
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');
    final pendingDraftJson =
        pendingDraft == null ? 'null' : jsonEncode(pendingDraft.toJson());

    return '''
You are SafeSpend's transaction intake engine.

Decide whether the user is trying to record a transaction in SafeSpend.
Supported transaction types:
- expense
- income
- withdrawal
- transfer

Current datetime: ${now.toIso8601String()}
Currency: $currency
Attachment included: $hasAttachment
Active transaction flow: ${activeTransactionType ?? 'none'}
Existing partial transaction draft:
$pendingDraftJson

Available accounts:
${jsonEncode(accountRows)}

Available expense categories:
${jsonEncode(categoryRows)}

Recent conversation:
$history

User's latest message:
$userText

Return ONLY valid JSON with this shape:
{
  "kind": "not_transaction" | "question" | "draft",
  "message": "short user-facing message",
  "missingFields": ["fieldName"],
  "draft": {
    "type": "expense" | "income" | "withdrawal" | "transfer",
    "amount": 0,
    "fees": 0,
    "accountId": "account id or cash_on_hand",
    "toAccountId": "destination account id or null",
    "categoryId": "category id for expense or null",
    "dateIso": "ISO-8601 date/time",
    "note": "short title",
    "description": "optional details",
    "expenseSubType": "subscription or null",
    "recipientName": "person name for transfer-to-person or null",
    "attachReceipt": true
  }
}

Rules:
- If active transaction flow is not "none", the user is answering follow-up questions for that transaction. Do not return "not_transaction"; either ask the next missing question or return a draft.
- If an existing partial transaction draft is provided, preserve its known values and only update fields the user corrected or supplied.
- If active transaction flow is "none" and the user is not trying to log a transaction, return kind "not_transaction".
- If required fields are missing, return kind "question", include any known partial draft values in "draft", and ask ONLY for the missing information.
- Required for expense: amount, accountId, categoryId, dateIso.
- Required for income: amount, accountId, dateIso.
- Required for withdrawal: amount, bank accountId, dateIso.
- Required for transfer: amount, accountId, and either toAccountId or recipientName, dateIso.
- Use only account/category IDs from the lists. If unsure which one, ask.
- If user says cash, use accountId "cash_on_hand".
- If the user says "main account", "my account", or "only account" and there is exactly one non-cash account, use that account.
- For withdrawal, do not use cash_on_hand as source.
- Match category by natural language and common aliases. Examples: gym/fitness -> a gym, fitness, sport, or health category; gas/gaz/BP/fuel -> transport, fuel, or car category.
- If a receipt/image/PDF is attached, extract merchant/date/total/category when possible and set attachReceipt true.
- If user wants a receipt saved but no attachment is included, ask them to attach it.
- Never invent missing amount/account/category. Ask a question instead.
- Keep "message" concise. For a draft, summarize what will be saved and ask the user to confirm.
''';
  }
}
