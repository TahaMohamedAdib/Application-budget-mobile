import 'dart:convert';

/// Store app-generated labels as keys so changing language also changes history.
/// User-entered notes remain plain text. The existing note storage column is used.
String systemNote(String key, [String? name]) => jsonEncode({
      'safespend_note': 1,
      'key': key,
      if (name != null) 'name': name,
    });

String? renderSystemNote(String? note, String Function(String) translate) {
  if (note == null || !note.startsWith('{')) return note;
  try {
    final data = jsonDecode(note);
    if (data is! Map || data['safespend_note'] != 1 || data['key'] is! String) {
      return note;
    }
    final label = translate(data['key'] as String);
    final name = data['name'];
    return name is String && name.isNotEmpty ? '$label: $name' : label;
  } on FormatException {
    return note;
  }
}
