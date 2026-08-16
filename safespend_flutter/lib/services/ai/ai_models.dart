/// Public surface of the AI layer.
///
/// Import this rather than the individual files, so call sites don't depend on
/// the internal file layout.
library;

export 'ai_attachment.dart';
export 'ai_config.dart';
export 'ai_error.dart';
export 'ai_message.dart';
export 'ai_response.dart';
export 'ai_service.dart';
export 'ai_tool_call.dart';
export 'financial_context_service.dart';
export 'tools/ai_tool.dart';
export 'tools/ai_tool_executor.dart';
export 'tools/ai_tool_registry.dart';
