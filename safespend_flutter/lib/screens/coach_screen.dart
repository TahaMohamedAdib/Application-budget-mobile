import '../widgets/app_form_sheet.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/ai/ai_models.dart';
import '../services/ai/ai_service_factory.dart';
import '../services/env_config.dart';
import '../services/supabase_sync_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ai_confirmation_card.dart';
import '../widgets/feature_help_button.dart';
import 'chat_widgets/chat_input_bar.dart';
import 'chat_widgets/message_bubble.dart';
import 'chat_widgets/suggestion_card.dart';
import 'chat_widgets/typing_indicator.dart';

final _allowedEmails = EnvConfig.allowedEmails;
const _openToAll = EnvConfig.aiOpenToAll;

/// Closes the AI Coach for everyone and shows a "coming soon" screen in its
/// place, whatever the build-time access flags say.
///
/// The feature is finished but not ready to be seen, so this gates at the
/// screen rather than deleting anything: the services, tools, conversation
/// store and sync paths are all untouched and keep compiling. Flip this to
/// false to reopen it, and the allowlist in [_hasAccess] applies again.
const _coachComingSoon = true;

// ── Data models ────────────────────────────────────────────────
/// An AI-requested mutation held pending user approval.
class _PendingAction {
  final AIToolCall call;
  final String summary;
  bool resolved = false;
  String? resolvedLabel;

  _PendingAction({required this.call, required this.summary});
}

class _ChatMsg {
  final String text;
  final bool isUser;
  final bool isError;
  final String? imagePath;
  final String? filePath;
  final String? fileName;

  const _ChatMsg({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.imagePath,
    this.filePath,
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'isError': isError,
        'imagePath': imagePath,
        'filePath': filePath,
        'fileName': fileName,
      };

  factory _ChatMsg.fromJson(Map<String, dynamic> j) => _ChatMsg(
        text: j['text'] as String,
        isUser: j['isUser'] as bool,
        isError: j['isError'] as bool? ?? false,
        imagePath: j['imagePath'] as String?,
        filePath: j['filePath'] as String?,
        fileName: j['fileName'] as String?,
      );
}

class _Convo {
  final String id;
  String title;
  final List<_ChatMsg> messages;
  final List<Map<String, String>> history;
  final DateTime createdAt;
  bool isArchived;
  String? projectId;

  _Convo({
    required this.id,
    required this.title,
    required this.messages,
    required this.history,
    required this.createdAt,
    this.isArchived = false,
    this.projectId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'history': history,
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived,
        'projectId': projectId,
      };

  factory _Convo.fromJson(Map<String, dynamic> j) => _Convo(
        id: j['id'] as String,
        title: j['title'] as String,
        messages: (j['messages'] as List)
            .map((m) => _ChatMsg.fromJson(m as Map<String, dynamic>))
            .toList(),
        history: (j['history'] as List)
            .map((h) => Map<String, String>.from(h as Map))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        isArchived: j['isArchived'] as bool? ?? false,
        projectId: j['projectId'] as String?,
      );
}

class _Project {
  final String id;
  String name;
  final DateTime createdAt;

  _Project({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _Project.fromJson(Map<String, dynamic> j) => _Project(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ── Screen ─────────────────────────────────────────────────────
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  static const _prefsKey = 'ai_coach_conversations_v2';
  static const _projectsPrefsKey = 'ai_coach_projects_v1';

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  List<_Convo> _convos = [];
  List<_Project> _projects = [];
  late _Convo _current;
  bool _isTyping = false;

  /// Mutations awaiting user approval. Rendered as confirmation cards below
  /// the transcript; nothing executes while an entry sits here.
  final List<_PendingAction> _pendingActions = [];
  bool _ready = false;
  String? _pendingImage;
  String? _pendingFile;
  String? _pendingFileName;
  String? _pendingFileMime;

  // ── Persistence ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Skipped while the coach is closed: _loadConvos hits secure storage and
    // Supabase to build a history the "coming soon" screen never shows.
    if (!_coachComingSoon) _loadConvos();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String? get _userId => SupabaseSyncService.currentUserId;

  Future<void> _loadConvos() async {
    final ss = SecureStorageService.instance;
    final uid = _userId;

    // ── Try loading from Supabase first (cloud → local merge) ──
    if (uid != null) {
      try {
        final cloudResults = await Future.wait([
          SupabaseSyncService.loadProjects(uid),
          SupabaseSyncService.loadConversations(uid),
        ]);
        final cloudProjects = cloudResults[0] as List<Map<String, dynamic>>;
        final cloudConvos = cloudResults[1] as List<Map<String, dynamic>>;

        // Always load projects from cloud
        if (cloudProjects.isNotEmpty) {
          _projects = cloudProjects
              .map((j) => _Project(
                    id: j['id'] as String,
                    name: j['name'] as String,
                    createdAt: DateTime.parse(j['created_at'] as String),
                  ))
              .toList();
        }
        // Cache projects locally
        await ss.write(_projectsPrefsKey,
            jsonEncode(_projects.map((p) => p.toJson()).toList()));

        // Load conversations from cloud (may be empty for new users)
        List<_Convo> loaded = [];
        if (cloudConvos.isNotEmpty) {
          loaded = cloudConvos
              .map((row) => _Convo(
                    id: row['id'] as String,
                    title: row['title'] as String,
                    messages: (row['messages'] as List? ?? [])
                        .map((m) => _ChatMsg.fromJson(
                            Map<String, dynamic>.from(m as Map)))
                        .toList(),
                    history: (row['history'] as List? ?? [])
                        .map((h) => Map<String, String>.from(h as Map))
                        .toList(),
                    createdAt: DateTime.parse(row['created_at'] as String),
                    isArchived: row['is_archived'] as bool? ?? false,
                    projectId: row['project_id'] as String?,
                  ))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        if (loaded.isEmpty) loaded = [_newConvo()];

        // Cache convos locally
        await ss.write(
            _prefsKey, jsonEncode(loaded.map((c) => c.toJson()).toList()));

        if (mounted) {
          final active = loaded.where((c) => !c.isArchived).toList();
          setState(() {
            _convos = loaded;
            _current = active.isNotEmpty ? active.first : loaded.first;
            _ready = true;
          });
          return;
        }
      } catch (e) {
        if (kDebugMode)
          debugPrint('[Coach] Cloud load failed, falling back to local: $e');
      }
    }

    // ── Fallback: load from local storage ──
    final projRaw = await ss.read(_projectsPrefsKey);
    if (projRaw != null) {
      try {
        final pList = jsonDecode(projRaw) as List;
        _projects = pList
            .map((j) => _Project.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final raw = await ss.read(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        final loaded = list
            .map((j) => _Convo.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (loaded.isNotEmpty && mounted) {
          final active = loaded.where((c) => !c.isArchived).toList();
          setState(() {
            _convos = loaded;
            _current = active.isNotEmpty ? active.first : loaded.first;
            _ready = true;
          });

          // Upload local data to cloud if user just logged in
          if (uid != null) _uploadAllToCloud(uid);
          return;
        }
      } catch (_) {}
    }
    final fresh = _newConvo();
    if (mounted)
      setState(() {
        _convos = [fresh];
        _current = fresh;
        _ready = true;
      });
  }

  // ── Local save ──
  Future<void> _save() async {
    final ss = SecureStorageService.instance;
    await ss.write(
        _prefsKey, jsonEncode(_convos.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveProjects() async {
    final ss = SecureStorageService.instance;
    await ss.write(_projectsPrefsKey,
        jsonEncode(_projects.map((p) => p.toJson()).toList()));
  }

  // ── Cloud sync helpers ──
  void _syncConvoToCloud(_Convo conv) {
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveConversation(uid, conv.toJson());
  }

  void _syncProjectToCloud(_Project proj) {
    final uid = _userId;
    if (uid != null) SupabaseSyncService.saveProject(uid, proj.toJson());
  }

  Future<void> _uploadAllToCloud(String uid) async {
    try {
      await SupabaseSyncService.saveAllConversations(
        uid,
        _convos.map((c) => c.toJson()).toList(),
      );
      for (final p in _projects) {
        await SupabaseSyncService.saveProject(uid, p.toJson());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Coach] Upload to cloud failed: $e');
    }
  }

  // ── Mutation methods (local + cloud) ──
  void _addProject(String name) {
    final p =
        _Project(id: const Uuid().v4(), name: name, createdAt: DateTime.now());
    setState(() => _projects.add(p));
    _saveProjects();
    _syncProjectToCloud(p);
  }

  void _deleteProject(String projectId) {
    setState(() {
      _projects.removeWhere((p) => p.id == projectId);
      for (final c in _convos) {
        if (c.projectId == projectId) c.projectId = null;
      }
    });
    _saveProjects();
    _save();
    final uid = _userId;
    if (uid != null) {
      SupabaseSyncService.deleteProject(uid, projectId);
      // Re-sync affected convos
      for (final c in _convos) {
        _syncConvoToCloud(c);
      }
    }
  }

  void _assignConvoToProject(_Convo conv, String projectId) {
    setState(() => conv.projectId = projectId);
    _save();
    _syncConvoToCloud(conv);
  }

  void _removeConvoFromProject(_Convo conv) {
    setState(() => conv.projectId = null);
    _save();
    _syncConvoToCloud(conv);
  }

  void _archiveConvo(_Convo conv) {
    setState(() {
      conv.isArchived = true;
      if (_current.id == conv.id) {
        final active = _convos.where((c) => !c.isArchived).toList();
        if (active.isNotEmpty) {
          _current = active.first;
        } else {
          final fresh = _newConvo();
          _convos.insert(0, fresh);
          _current = fresh;
        }
      }
    });
    _save();
    _syncConvoToCloud(conv);
  }

  void _renameConvo(_Convo conv, String newTitle) {
    setState(() => conv.title = newTitle);
    _save();
    _syncConvoToCloud(conv);
  }

  _Convo _newConvo() {
    final s = S.of(context);
    return _Convo(
      id: const Uuid().v4(),
      title: s.newConversation,
      messages: [],
      history: [],
      createdAt: DateTime.now(),
    );
  }

  void _startNewConvo() {
    final c = _newConvo();
    setState(() {
      _convos.insert(0, c);
      _current = c;
      _pendingImage = null;
      _pendingFile = null;
      _pendingFileName = null;
      _pendingFileMime = null;
    });
    _save();
    _syncConvoToCloud(c);
  }

  void _switchConvo(_Convo c) {
    setState(() => _current = c);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _deleteConvo(String id) {
    setState(() {
      _convos.removeWhere((c) => c.id == id);
      if (_current.id == id) {
        if (_convos.isNotEmpty) {
          _current = _convos.first;
        } else {
          final fresh = _newConvo();
          _convos = [fresh];
          _current = fresh;
        }
      }
    });
    _save();
    final uid = _userId;
    if (uid != null) SupabaseSyncService.deleteConversation(uid, id);
  }

  // ── Access ───────────────────────────────────────────────────
  bool _hasAccess(String? email) {
    if (_coachComingSoon) return false;
    if (_openToAll) return true;
    if (email == null) return false;
    return _allowedEmails.any((e) => e.toLowerCase() == email.toLowerCase());
  }

  // ── Financial context ────────────────────────────────────────
  // ── Tool calls ───────────────────────────────────────────────
  /// Routes model-requested tools through the executor.
  ///
  /// Reads run immediately; writes surface a confirmation card and change
  /// nothing until the user approves. Dormant while no backend returns tool
  /// calls.
  void _handleToolCalls(AIResponse response, AppProvider provider) {
    final executor = AIToolExecutor(provider);
    final pending = <_PendingAction>[];
    final notes = <String>[];

    for (final call in response.toolCalls) {
      final outcome = executor.submit(call);
      switch (outcome.decision) {
        case AIToolDecision.needsConfirmation:
          pending.add(_PendingAction(
            call: outcome.call,
            summary: outcome.confirmationSummary ?? call.name,
          ));
        case AIToolDecision.rejected:
          notes.add(S.of(context).tr('actionCouldNotBeCompleted'));
        case AIToolDecision.executed:
          break;
      }
    }

    setState(() {
      _isTyping = false;
      if (response.text.isNotEmpty) {
        _current.messages.add(_ChatMsg(text: response.text, isUser: false));
        _current.history.add({'role': 'assistant', 'content': response.text});
      }
      for (final note in notes) {
        _current.messages.add(_ChatMsg(text: note, isUser: false));
      }
      _pendingActions.addAll(pending);
    });
    _scrollToBottom();
  }

  /// Executes an approved mutation.
  void _confirmAction(_PendingAction action, AppProvider provider) {
    final s = S.of(context);
    final result = AIToolExecutor(provider).confirm(action.call);
    setState(() {
      action.resolved = true;
      action.resolvedLabel = result.ok ? s.done : s.tr('failed');
      if (!result.ok) {
        _current.messages.add(_ChatMsg(
          text: s.tr('actionCouldNotBeCompleted'),
          isUser: false,
        ));
      }
    });
  }

  void _cancelAction(_PendingAction action) {
    final s = S.of(context);
    setState(() {
      action.resolved = true;
      action.resolvedLabel = s.tr('cancelled');
    });
  }

  // ── Project context — gather summaries from sibling conversations ──
  String? _buildProjectContextSummary() {
    if (_current.projectId == null) return null;
    final project =
        _projects.where((p) => p.id == _current.projectId).firstOrNull;
    final siblings = _convos
        .where((c) =>
            c.projectId == _current.projectId &&
            c.id != _current.id &&
            c.history.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (siblings.isEmpty) return null;

    final buf = StringBuffer();
    if (project != null) buf.writeln('Project name: "${project.name}"');
    buf.writeln('Other conversations in this project (${siblings.length}):');
    buf.writeln();

    int totalChars = 0;
    const maxChars = 4000;

    for (final sib in siblings) {
      if (totalChars >= maxChars) break;
      buf.writeln('── "${sib.title}" ──');
      // Take last 10 messages (5 exchanges) for richer context
      final recent = sib.history.length > 10
          ? sib.history.sublist(sib.history.length - 10)
          : sib.history;
      for (final msg in recent) {
        final role = msg['role'] == 'user' ? 'User' : 'Assistant';
        final content = msg['content'] ?? '';
        final snippet =
            content.length > 300 ? '${content.substring(0, 300)}...' : content;
        buf.writeln('$role: $snippet');
        totalChars += snippet.length;
        if (totalChars >= maxChars) break;
      }
      buf.writeln();
    }
    return buf.toString();
  }

  // ── Send ─────────────────────────────────────────────────────
  Future<void> _send(AppProvider provider) async {
    final s = S.of(context);
    final text = _msgCtrl.text.trim();
    final imgPath = _pendingImage;
    final docPath = _pendingFile;
    final docName = _pendingFileName;
    final docMime = _pendingFileMime;
    final hasAttach = imgPath != null || docPath != null;
    if ((text.isEmpty && !hasAttach) || _isTyping) return;

    String displayTxt = text;
    if (displayTxt.isEmpty) {
      displayTxt = imgPath != null ? '📷 ${s.tr('image')}' : '📄 $docName';
    }
    String historyContent = text.isNotEmpty ? text : '';
    if (imgPath != null)
      historyContent +=
          (historyContent.isEmpty ? '' : '\n') + '[User attached an image]';
    if (docPath != null)
      historyContent += (historyContent.isEmpty ? '' : '\n') +
          '[User attached document: $docName]';

    final userMsg = _ChatMsg(
        text: displayTxt,
        isUser: true,
        imagePath: imgPath,
        filePath: docPath,
        fileName: docName);

    setState(() {
      _current.messages.add(userMsg);
      _current.history.add({'role': 'user', 'content': historyContent});
      _isTyping = true;
      _pendingImage = null;
      _pendingFile = null;
      _pendingFileName = null;
      _pendingFileMime = null;
      if (_current.title == s.newConversation ||
          _current.title == S.forLocale(S.fallbackLocale).newConversation) {
        _current.title = displayTxt.length > 40
            ? '${displayTxt.substring(0, 40)}...'
            : displayTxt;
      }
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      Uint8List? attachBytes;
      String? attachMime;
      String? attachName;
      bool attachIsImage = false;
      if (imgPath != null) {
        attachBytes = await File(imgPath).readAsBytes();
        attachIsImage = true;
        attachMime = imgPath.toLowerCase().endsWith('.png')
            ? 'image/png'
            : imgPath.toLowerCase().endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
      } else if (docPath != null && docMime != null) {
        attachBytes = await File(docPath).readAsBytes();
        attachMime = docMime;
        attachName = docName;
      }

      // Financial context is computed by SafeSpend, never by the model.
      var ctx = FinancialContextService.build(provider);
      final projectCtx = _buildProjectContextSummary();
      if (projectCtx != null) {
        ctx = ctx.withExtras({'project_context': projectCtx});
      }

      final attachments = <AIAttachment>[];
      if (attachBytes != null && attachMime != null) {
        final candidate = attachIsImage
            ? AIAttachment.image(bytes: attachBytes, mimeType: attachMime)
            : AIAttachment.document(
                bytes: attachBytes, mimeType: attachMime, fileName: attachName);
        // Oversized or unexpected types are dropped before they reach a
        // provider: the upstream would reject them anyway, and forwarding
        // them spends the user's quota to no purpose.
        if (!candidate.isAcceptable) {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _pendingImage = null;
              _pendingFile = null;
              _pendingFileName = null;
              _pendingFileMime = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.tr('attachmentRejected'))),
            );
          }
          return;
        }
        attachments.add(candidate);
      }

      final response = await AIServiceFactory.instance.sendMessage(
        history: _current.history
            .map((h) => AIMessage(
                  role:
                      h['role'] == 'assistant' ? AIRole.assistant : AIRole.user,
                  text: h['content'] ?? '',
                ))
            .toList(),
        context: ctx,
        attachments: attachments.isEmpty ? null : attachments,
        conversationId: _current.id,
      );
      if (!mounted) return;

      // Tool calls need approval before anything changes; until a backend
      // returns them this stays dormant.
      if (response.hasToolCalls) {
        _handleToolCalls(response, provider);
        return;
      }

      final reply = response.text.isEmpty
          ? (s.tr('actionCouldNotBeCompleted'))
          : response.text;
      setState(() {
        _current.messages.add(_ChatMsg(text: reply, isUser: false));
        _current.history.add({'role': 'assistant', 'content': reply});
        _isTyping = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Chat error: $e');
      if (!mounted) return;
      setState(() {
        _current.messages.add(_ChatMsg(
          text: s.tr('chatConnectionError'),
          isUser: false,
          isError: true,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
    _save();
    _syncConvoToCloud(_current);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Attach ───────────────────────────────────────────────────
  void _showAttachOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(
        onPhoto: () {
          Navigator.pop(context);
          _pickImage();
        },
        onCamera: () {
          Navigator.pop(context);
          _pickCamera();
        },
        onDocument: () {
          Navigator.pop(context);
          _pickDocument();
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted)
      setState(() {
        _pendingImage = picked.path;
        _pendingFile = null;
      });
  }

  Future<void> _pickCamera() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null && mounted)
      setState(() {
        _pendingImage = picked.path;
        _pendingFile = null;
      });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false);
    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _pendingFile = result.files.single.path;
        _pendingFileName = result.files.single.name;
        _pendingFileMime = 'application/pdf';
        _pendingImage = null;
      });
    }
  }

  // ── Left drawer — ChatGPT-style conversation sidebar ────────
  Widget _buildDrawer(BuildContext context, bool isDark, AppProvider provider) {
    final s = S.of(context);
    final drawerBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F8F8);
    final surfaceColor =
        isDark ? const Color(0xFF27292A) : const Color(0xFFEDEFF0);

    // Group conversations: Today, Yesterday, Previous 7 Days, Older
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final groups = <String, List<_Convo>>{};
    for (final c in _convos) {
      if (c.isArchived) continue;
      String label;
      if (c.createdAt.isAfter(todayStart)) {
        label = s.today;
      } else if (c.createdAt.isAfter(yesterdayStart)) {
        label = s.yesterday;
      } else if (c.createdAt.isAfter(weekStart)) {
        label = s.tr('previousSevenDays');
      } else {
        label = s.tr('older');
      }
      groups.putIfAbsent(label, () => []).add(c);
    }
    final orderedLabels = [
      s.today,
      s.yesterday,
      s.tr('previousSevenDays'),
      s.tr('older'),
    ];

    return Drawer(
      backgroundColor: drawerBg,
      width: MediaQuery.of(context).size.width * 0.88,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveIconSurface(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IOSIcons.auto_awesome_rounded,
                      size: 17,
                      color: AppTheme.adaptiveIcon(context),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    'SafeSpend AI',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: s.close,
                    icon: Icon(
                      IOSIcons.close_rounded,
                      size: 19,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // ── New chat button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewConvo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Icon(
                          IOSIcons.edit_rounded,
                          size: 19,
                          color: AppTheme.adaptiveIcon(context),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s.newChat,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Projects section ──────────────────────────────
            if (_projects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                child: Row(
                  children: [
                    Text(
                      s.projects,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showNewProjectDialog(isDark),
                      child: AppIcon(AppIcons.add,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (final proj in _projects)
                      _buildProjectTile(proj, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showNewProjectDialog(isDark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          AppIcon(AppIcons.folder,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 12),
                          Text(
                            s.newProject,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // ── Conversations list ────────────────────────────
            Expanded(
              child: _convos.isEmpty
                  ? Center(
                      child: Text(
                        s.noConversationsYet,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final label in orderedLabels)
                          if (groups.containsKey(label)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                            for (final conv in groups[label]!)
                              _buildConvoTile(conv, isDark),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvoTile(_Convo conv, bool isDark) {
    final isActive = conv.id == _current.id;
    final project = conv.projectId != null
        ? _projects.where((p) => p.id == conv.projectId).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive
            ? AppTheme.goldPrimary.withOpacity(isDark ? 0.20 : 0.11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _switchConvo(conv);
            Navigator.pop(context);
          },
          onLongPress: () => _showConvoActions(conv, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w500 : FontWeight.w400,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            AppIcon(AppIcons.folder,
                                size: 11,
                                color:
                                    isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(width: 4),
                            Text(
                              project.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Project tile in drawer ─────────────────────────────────
  Widget _buildProjectTile(_Project proj, bool isDark) {
    final convoCount =
        _convos.where((c) => c.projectId == proj.id && !c.isArchived).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            _showProjectDetailView(proj, isDark);
          },
          onLongPress: () => _showProjectActions(proj, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AppIcon(AppIcons.folder,
                    size: 18, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    proj.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$convoCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Project detail view (ChatGPT-style) ───────────────────
  void _showProjectDetailView(_Project proj, bool isDark) {
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;
    final surfaceColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final projConvos = _convos
              .where((c) => c.projectId == proj.id && !c.isArchived)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar + close ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: AppIcon(AppIcons.minus,
                            size: 28,
                            color: isDark ? Colors.white60 : Colors.black45),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            proj.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: AppIcon(AppIcons.more,
                            size: 22, color: subtleColor),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showProjectActions(proj, isDark);
                        },
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // ── Project header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.folder,
                          size: 32,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          proj.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── "Chats" tab label ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.chats,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Conversation list ──
                Expanded(
                  child: projConvos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(AppIcons.chat,
                                  size: 40,
                                  color:
                                      isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 12),
                              Text(
                                s.noConversationsYet,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.addConversationsFromMenu,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: projConvos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (_, i) {
                            final conv = projConvos[i];
                            final lastMsg = conv.messages.isNotEmpty
                                ? conv.messages.last.text
                                : '';
                            final preview = lastMsg.length > 60
                                ? '${lastMsg.substring(0, 60)}...'
                                : lastMsg;

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _switchConvo(conv);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conv.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (preview.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          preview,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: subtleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // ── Bottom bar with "Message project" ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Material(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.pop(ctx);
                        // Start a new convo assigned to this project
                        final c = _newConvo();
                        c.projectId = proj.id;
                        setState(() {
                          _convos.insert(0, c);
                          _current = c;
                        });
                        _save();
                        _syncConvoToCloud(c);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            AppIcon(AppIcons.add, size: 20, color: subtleColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${s.message} ${proj.name}...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: subtleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Project actions (long-press on project tile) ──────────
  void _showProjectActions(_Project proj, bool isDark) {
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _actionTile(
                ctx, AppIcons.edit, s.renameProject, textColor, subtleColor,
                onTap: () {
              Navigator.pop(ctx);
              _showRenameProjectDialog(proj, isDark);
            }),
            _actionTile(ctx, AppIcons.delete, s.deleteProject, Colors.redAccent,
                Colors.redAccent, onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteProject(proj, isDark);
            }),
          ],
        ),
      ),
    );
  }

  // ── Rename project dialog ─────────────────────────────────
  void _showRenameProjectDialog(_Project proj, bool isDark) {
    final s = S.of(context);
    final ctrl = TextEditingController(text: proj.name);
    showAppFormSheet(
      context: context,
      builder: (ctx) => AppFormSheet(
          header: Text(s.renameProject,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          body: TextField(
            controller: ctrl,
            autofocus: false,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: s.projectName,
            ),
          ),
          actions: Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final newName = ctrl.text.trim();
                if (newName.isNotEmpty) {
                  setState(() => proj.name = newName);
                  _saveProjects();
                  _syncProjectToCloud(proj);
                }
                Navigator.pop(ctx);
              },
              child: Text(s.save,
                  style: GoogleFonts.inter(
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ])),
    );
  }

  // ── Delete project confirmation ───────────────────────────
  void _confirmDeleteProject(_Project proj, bool isDark) {
    final s = S.of(context);
    final convoCount = _convos.where((c) => c.projectId == proj.id).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteProject,
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          s.tr('deleteProjectDescription', {
            'name': proj.name,
            'count': convoCount,
          }),
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProject(proj.id);
            },
            child: Text(s.delete,
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Conversation action sheet ────────────────────────────────
  void _showConvoActions(_Convo conv, bool isDark) {
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Add to project
            _actionTile(
                ctx, AppIcons.folder, s.addToProject, textColor, subtleColor,
                trailing: AppIcons.caretRight, onTap: () {
              Navigator.pop(ctx);
              _showProjectPicker(conv, isDark);
            }),
            // Rename
            _actionTile(ctx, AppIcons.edit, s.rename, textColor, subtleColor,
                onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(conv, isDark);
            }),
            // Archive
            _actionTile(
                ctx, AppIcons.archive, s.archive, textColor, subtleColor,
                onTap: () {
              Navigator.pop(ctx);
              _archiveConvo(conv);
            }),
            // Delete
            _actionTile(ctx, AppIcons.delete, s.delete, Colors.redAccent,
                Colors.redAccent, onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteConvo(conv, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext ctx, String icon, String label,
      Color textColor, Color iconColor,
      {VoidCallback? onTap, String? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              AppIcon(icon, size: 20, color: AppTheme.adaptiveIcon(ctx)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
              ),
              if (trailing != null)
                AppIcon(trailing, size: 20, color: AppTheme.adaptiveIcon(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rename dialog ──────────────────────────────────────────
  void _showRenameDialog(_Convo conv, bool isDark) {
    final s = S.of(context);
    final ctrl = TextEditingController(text: conv.title);
    showAppFormSheet(
      context: context,
      builder: (ctx) => AppFormSheet(
          header: Text(s.rename,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          body: TextField(
            controller: ctrl,
            autofocus: false,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: s.conversationName,
            ),
          ),
          actions: Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final newTitle = ctrl.text.trim();
                if (newTitle.isNotEmpty) {
                  _renameConvo(conv, newTitle);
                }
                Navigator.pop(ctx);
              },
              child: Text(s.save,
                  style: GoogleFonts.inter(
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ])),
    );
  }

  // ── Delete confirmation ─────────────────────────────────────
  void _confirmDeleteConvo(_Convo conv, bool isDark) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteConversation,
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          s.tr('deleteConversationDescription', {'name': conv.title}),
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConvo(conv.id);
            },
            child: Text(s.delete,
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Project picker — "Add to project" submenu ───────────────
  void _showProjectPicker(_Convo conv, bool isDark) {
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 32),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(s.addToProject,
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      const Spacer(),
                      if (conv.projectId != null)
                        GestureDetector(
                          onTap: () {
                            _removeConvoFromProject(conv);
                            Navigator.pop(ctx);
                          },
                          child: Text(s.remove,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // New project button
                _actionTile(ctx, AppIcons.add, s.newProject,
                    AppTheme.goldPrimary, AppTheme.goldPrimary, onTap: () {
                  _showNewProjectDialog(isDark, onCreated: (projectId) {
                    _assignConvoToProject(conv, projectId);
                    Navigator.pop(ctx);
                  });
                }),
                if (_projects.isNotEmpty) ...[
                  Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.06)),
                  const SizedBox(height: 4),
                ],
                // Existing projects
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _projects.length,
                    itemBuilder: (_, i) {
                      final p = _projects[i];
                      final isAssigned = conv.projectId == p.id;
                      final convoCount =
                          _convos.where((c) => c.projectId == p.id).length;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _assignConvoToProject(conv, p.id);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                AppIcon(AppIcons.folder,
                                    size: 20, color: subtleColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: textColor)),
                                      Text(
                                          s.tr('conversationsCount', {
                                            'count': convoCount,
                                          }),
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: subtleColor)),
                                    ],
                                  ),
                                ),
                                if (isAssigned)
                                  AppIcon(AppIcons.check,
                                      size: 20,
                                      color: AppTheme.adaptiveIcon(context)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── New project dialog ──────────────────────────────────────
  void _showNewProjectDialog(bool isDark,
      {void Function(String projectId)? onCreated}) {
    final s = S.of(context);
    final ctrl = TextEditingController();
    showAppFormSheet(
      context: context,
      builder: (ctx) => AppFormSheet(
          header: Text(s.newProject,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          body: TextField(
            controller: ctrl,
            autofocus: false,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: s.projectName,
            ),
          ),
          actions: Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  final p = _Project(
                      id: const Uuid().v4(),
                      name: name,
                      createdAt: DateTime.now());
                  setState(() => _projects.add(p));
                  _saveProjects();
                  _syncProjectToCloud(p);
                  Navigator.pop(ctx);
                  onCreated?.call(p.id);
                }
              },
              child: Text(s.create,
                  style: GoogleFonts.inter(
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ])),
    );
  }

  String _fmtDate(DateTime dt) {
    final s = S.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return s.tr('justNow');
    if (diff.inHours < 1) {
      return s.tr('minutesAgo', {'count': diff.inMinutes});
    }
    if (diff.inDays < 1) return s.tr('hoursAgo', {'count': diff.inHours});
    if (diff.inDays < 7) return s.tr('daysAgo', {'count': diff.inDays});
    return DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
        .format(dt);
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AuthService>(
      builder: (context, provider, auth, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasAccess = _hasAccess(auth.user?.email);
        final bgColor =
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

        // Decided before the loading guard: a closed coach has no
        // conversations to wait for, and blocking on that load would show a
        // spinner forever whenever the network or secure storage is slow.
        if (_coachComingSoon) {
          return Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(child: _buildComingSoon(context, isDark)),
          );
        }

        if (!_ready) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgColor,
          drawerEdgeDragWidth: 40,
          drawerScrimColor: Colors.black.withOpacity(isDark ? 0.52 : 0.24),
          drawer: _buildDrawer(context, isDark, provider),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: _current.messages.isEmpty
                      ? _buildWelcome(context, isDark, provider)
                      : _buildMessageList(context, isDark),
                ),
                if (hasAccess) _buildInputArea(context, isDark, provider),
                if (!hasAccess) _buildLockedBanner(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassIconButton(
            icon: IOSIcons.menu_rounded,
            tooltip: s.tr('conversations'),
            isDark: isDark,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: _GlassSurface(
              isDark: isDark,
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveIconSurface(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IOSIcons.auto_awesome_rounded,
                      size: 14,
                      color: AppTheme.adaptiveIcon(context),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'SafeSpend AI',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    IOSIcons.expand_more_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          _GlassIconButton(
            icon: IOSIcons.edit_outlined,
            tooltip: S.of(context).newChat,
            isDark: isDark,
            onPressed: _startNewConvo,
          ),
        ],
      ),
    );
  }

  // ── Welcome state ───────────────────────────────────────────
  Widget _buildWelcome(
      BuildContext context, bool isDark, AppProvider provider) {
    final s = S.of(context);
    final suggestions = [
      (
        s.monthlyOverview,
        s.tr('monthlyOverviewPrompt'),
        IOSIcons.calendar_today_rounded
      ),
      (
        s.spendingAnalysis,
        s.tr('spendingAnalysisPrompt'),
        IOSIcons.pie_chart_outline_rounded
      ),
      (s.savingsTips, s.tr('savingsTipsPrompt'), IOSIcons.savings_outlined),
      (
        s.budgetPlan,
        s.tr('budgetPlanPrompt'),
        IOSIcons.account_balance_wallet_outlined
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveIconSurface(context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.adaptiveIcon(context, alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  IOSIcons.auto_awesome_rounded,
                  size: 27,
                  color: AppTheme.adaptiveIcon(context),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                  ),
              const SizedBox(height: 22),
              Text(
                s.tr('coachWelcomeTitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.tr('coachWelcomeBody'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, promptConstraints) {
                    final cardWidth = (promptConstraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final prompt in suggestions)
                          SizedBox(
                            width: cardWidth,
                            child: SuggestionCard(
                              text: prompt.$1,
                              subtitle: prompt.$2,
                              icon: prompt.$3,
                              isDark: isDark,
                              onTap: () {
                                _msgCtrl.text = prompt.$2;
                                _send(provider);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 350.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────
  Widget _buildMessageList(BuildContext context, bool isDark) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          itemCount: _current.messages.length +
              _pendingActions.length +
              (_isTyping ? 1 : 0),
          itemBuilder: (ctx, i) {
            // Confirmation cards sit after the transcript, before the typing
            // indicator, so a pending approval is the last thing on screen.
            if (i >= _current.messages.length) {
              final j = i - _current.messages.length;
              if (j < _pendingActions.length) {
                final action = _pendingActions[j];
                return AIConfirmationCard(
                  summary: AIToolExecutor(context.read<AppProvider>())
                          .describe(action.call) ??
                      action.summary,
                  isResolved: action.resolved,
                  resolvedLabel: action.resolvedLabel,
                  onConfirm: () =>
                      _confirmAction(action, context.read<AppProvider>()),
                  onCancel: () => _cancelAction(action),
                ).animate().fadeIn(duration: 250.ms);
              }
              return TypingIndicator(isDark: isDark)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms);
            }
            final msg = _current.messages[i];
            return MessageBubble(
              text: msg.text,
              isUser: msg.isUser,
              isError: msg.isError,
              isDark: isDark,
              imagePath: msg.imagePath,
              filePath: msg.filePath,
              fileName: msg.fileName,
            ).animate().fadeIn(duration: 250.ms).slideY(
                  begin: msg.isUser ? 0.05 : 0.08,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ),
    );
  }

  // ── Input area ─────────────────────────────────────────────
  Widget _buildInputArea(
      BuildContext context, bool isDark, AppProvider provider) {
    return ChatInputBar(
      controller: _msgCtrl,
      isTyping: _isTyping,
      isDark: isDark,
      pendingImage: _pendingImage,
      pendingFile: _pendingFile,
      pendingFileName: _pendingFileName,
      onSend: () => _send(provider),
      onAttach: () => _showAttachOptions(context),
      onClearImage: () => setState(() => _pendingImage = null),
      onClearFile: () => setState(() {
        _pendingFile = null;
        _pendingFileName = null;
        _pendingFileMime = null;
      }),
      onChanged: (_) => setState(() {}),
    );
  }

  // ── Coming soon ──────────────────────────────────────────────
  /// The closed Coach keeps help in the top-right safe area, separate from
  /// the centered message. Conversation controls remain unavailable.
  Widget _buildComingSoon(BuildContext context, bool isDark) {
    final s = S.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FeatureHelpButton(
              title: s.tourCoachTitle,
              description: s.aiCoachComingSoon,
              icon: IOSIcons.auto_awesome_rounded,
            ),
          ),
        ),
        Expanded(
            child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.adaptiveIcon(context, alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    IOSIcons.auto_awesome_rounded,
                    size: 34,
                    color: AppTheme.adaptiveIcon(context),
                  ),
                ).animate().fadeIn(duration: 320.ms).scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 320.ms),
                const SizedBox(height: 26),
                Text(
                  s.aiCoachComingSoon,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ).animate().fadeIn(duration: 320.ms, delay: 80.ms),
                const SizedBox(height: 10),
                Text(
                  s.financialCoach,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ).animate().fadeIn(duration: 320.ms, delay: 140.ms),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // ── Locked banner ────────────────────────────────────────────
  Widget _buildLockedBanner(BuildContext context, bool isDark) {
    final s = S.of(context);
    return _GlassSurface(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(14),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.adaptiveIconSurface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(IOSIcons.lock_outline_rounded,
                color: AppTheme.adaptiveIcon(context), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.betaAccessOnly,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.aiCoachComingSoon,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  const _GlassSurface({
    required this.isDark,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF282A2B).withOpacity(0.82)
                  : const Color(0xFFF1F3F4).withOpacity(0.86),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.11)
                    : Colors.white.withOpacity(0.96),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      isDark: isDark,
      radius: 23,
      child: SizedBox(
        width: 46,
        height: 46,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 21,
            color: isDark
                ? Colors.white.withOpacity(0.88)
                : AppTheme.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Attach sheet ───────────────────────────────────────────────
class _AttachSheet extends StatelessWidget {
  final VoidCallback onPhoto;
  final VoidCallback onCamera;
  final VoidCallback onDocument;

  const _AttachSheet({
    required this.onPhoto,
    required this.onCamera,
    required this.onDocument,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.attach,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _option(context, isDark, IOSIcons.photo_library_rounded, s.photo,
                  onPhoto),
              const SizedBox(width: 12),
              _option(context, isDark, IOSIcons.camera_alt_rounded, s.camera,
                  onCamera),
              const SizedBox(width: 12),
              _option(context, isDark, IOSIcons.picture_as_pdf_rounded,
                  s.document, onDocument),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, bool isDark, IconData icon, String label,
      VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveIconSurface(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: AppTheme.adaptiveIcon(context), size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
