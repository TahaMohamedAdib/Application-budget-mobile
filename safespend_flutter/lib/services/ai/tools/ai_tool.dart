/// Whether a tool observes state or changes it.
///
/// This split is the hinge of the safety model: [AIToolAccess.write] tools are
/// never executed straight from a model response — they go through user
/// confirmation first.
enum AIToolAccess { read, write }

/// Accepted argument types, kept minimal so the schema can be emitted for any
/// provider's function-calling format.
enum AIToolParamType { string, number, integer, boolean, date, stringList }

class AIToolParam {
  final String name;
  final AIToolParamType type;
  final String description;
  final bool required;

  /// Allowed values, for enum-like arguments.
  final List<String>? allowed;

  const AIToolParam({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.allowed,
  });

  String get jsonType => switch (type) {
        AIToolParamType.string || AIToolParamType.date => 'string',
        AIToolParamType.number => 'number',
        AIToolParamType.integer => 'integer',
        AIToolParamType.boolean => 'boolean',
        AIToolParamType.stringList => 'array',
      };

  Map<String, dynamic> toSchema() => {
        'type': jsonType,
        'description': description,
        if (type == AIToolParamType.date) 'format': 'date-time',
        if (type == AIToolParamType.stringList)
          'items': {'type': 'string'},
        if (allowed != null) 'enum': allowed,
      };
}

/// Declaration of a capability the AI backend may invoke.
class AITool {
  final String name;
  final String description;
  final AIToolAccess access;
  final List<AIToolParam> params;

  /// Overrides the default that every write tool needs confirmation. Set false
  /// only for writes that are trivially reversible.
  final bool? confirmationOverride;

  const AITool({
    required this.name,
    required this.description,
    required this.access,
    this.params = const [],
    this.confirmationOverride,
  });

  bool get isWrite => access == AIToolAccess.write;

  /// Read tools never prompt; writes prompt unless explicitly exempted.
  bool get requiresConfirmation =>
      confirmationOverride ?? (access == AIToolAccess.write);

  /// JSON-Schema-ish description for the backend's function-calling payload.
  Map<String, dynamic> toSchema() => {
        'name': name,
        'description': description,
        'access': access.name,
        'requires_confirmation': requiresConfirmation,
        'parameters': {
          'type': 'object',
          'properties': {
            for (final p in params) p.name: p.toSchema(),
          },
          'required': [
            for (final p in params.where((p) => p.required)) p.name,
          ],
        },
      };
}
