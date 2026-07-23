import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class AiProxyResponse {
  final int statusCode;
  final dynamic data;

  const AiProxyResponse({
    required this.statusCode,
    required this.data,
  });

  String get body => data is String ? data as String : jsonEncode(data);

  Map<String, dynamic> decodeJsonObject() {
    final value = data is String ? jsonDecode(data as String) : data;
    return Map<String, dynamic>.from(value as Map);
  }
}

class AiProxyService {
  const AiProxyService._();

  static const String _functionName = 'chat';
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint = 'generateContent';
  static const Duration _timeout = Duration(seconds: 90);

  static Future<AiProxyResponse> generateContent(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'model': _model,
          'endpoint': _endpoint,
          'body': payload,
        },
      ).timeout(_timeout);
      return AiProxyResponse(
        statusCode: response.status,
        data: response.data,
      );
    } on FunctionException catch (error) {
      return AiProxyResponse(
        statusCode: error.status,
        data: error.details,
      );
    }
  }
}
