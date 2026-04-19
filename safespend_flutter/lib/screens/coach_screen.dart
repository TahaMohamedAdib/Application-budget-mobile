import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/env_config.dart';
import '../services/supabase_sync_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../l10n/app_localizations.dart';
import 'chat_widgets/chat_input_bar.dart';
import 'chat_widgets/message_bubble.dart';
import 'chat_widgets/suggestion_card.dart';
import 'chat_widgets/typing_indicator.dart';

final _allowedEmails = EnvConfig.allowedEmails;
const _openToAll = EnvConfig.aiOpenToAll;

// ── Data models ────────────────────────────────────────────────
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
    'text': text, 'isUser': isUser, 'isError': isError,
    'imagePath': imagePath, 'filePath': filePath, 'fileName': fileName,
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
    'id': id, 'title': title,
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
    'id': id, 'name': name,
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
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();

  List<_Convo> _convos = [];
  List<_Project> _projects = [];
  late _Convo _current;
  bool _isTyping     = false;
  bool _ready        = false;
  String? _pendingImage;
  String? _pendingFile;
  String? _pendingFileName;
  String? _pendingFileMime;

  // ── Persistence ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadConvos();
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
          _projects = cloudProjects.map((j) => _Project(
            id: j['id'] as String,
            name: j['name'] as String,
            createdAt: DateTime.parse(j['created_at'] as String),
          )).toList();
        }
        // Cache projects locally
        await ss.write(_projectsPrefsKey, jsonEncode(_projects.map((p) => p.toJson()).toList()));

        // Load conversations from cloud (may be empty for new users)
        List<_Convo> loaded = [];
        if (cloudConvos.isNotEmpty) {
          loaded = cloudConvos.map((row) => _Convo(
            id: row['id'] as String,
            title: row['title'] as String,
            messages: (row['messages'] as List? ?? [])
                .map((m) => _ChatMsg.fromJson(Map<String, dynamic>.from(m as Map)))
                .toList(),
            history: (row['history'] as List? ?? [])
                .map((h) => Map<String, String>.from(h as Map))
                .toList(),
            createdAt: DateTime.parse(row['created_at'] as String),
            isArchived: row['is_archived'] as bool? ?? false,
            projectId: row['project_id'] as String?,
          )).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        if (loaded.isEmpty) loaded = [_newConvo()];

        // Cache convos locally
        await ss.write(_prefsKey, jsonEncode(loaded.map((c) => c.toJson()).toList()));

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
        if (kDebugMode) debugPrint('[Coach] Cloud load failed, falling back to local: $e');
      }
    }

    // ── Fallback: load from local storage ──
    final projRaw = await ss.read(_projectsPrefsKey);
    if (projRaw != null) {
      try {
        final pList = jsonDecode(projRaw) as List;
        _projects = pList.map((j) => _Project.fromJson(j as Map<String, dynamic>)).toList();
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
    if (mounted) setState(() { _convos = [fresh]; _current = fresh; _ready = true; });
  }

  // ── Local save ──
  Future<void> _save() async {
    final ss = SecureStorageService.instance;
    await ss.write(_prefsKey, jsonEncode(_convos.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveProjects() async {
    final ss = SecureStorageService.instance;
    await ss.write(_projectsPrefsKey, jsonEncode(_projects.map((p) => p.toJson()).toList()));
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
        uid, _convos.map((c) => c.toJson()).toList(),
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
    final p = _Project(id: const Uuid().v4(), name: name, createdAt: DateTime.now());
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
    final s = S.forLocale(S.fallbackLocale);
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
    if (_openToAll) return true;
    if (email == null) return false;
    return _allowedEmails.any((e) => e.toLowerCase() == email.toLowerCase());
  }

  // ── Financial context ────────────────────────────────────────
  Map<String, dynamic> _buildContext(AppProvider p) {
    final now       = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTxns = p.transactions.where((t) => !DateTime.parse(t.date).isBefore(monthStart)).toList();
    final income    = monthTxns.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final expenses  = monthTxns.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final catMap    = <String, double>{};
    for (final t in monthTxns.where((t) => t.type == 'expense')) {
      final name = t.categoryId != null
          ? p.categories.where((c) => c.id == t.categoryId).firstOrNull?.name ?? 'Other'
          : 'Other';
      catMap[name] = (catMap[name] ?? 0) + t.amount;
    }
    final topCats = (catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(4).map((e) => {'name': e.key, 'amount': e.value}).toList();
    return {
      'currency':            p.settings.currency,
      'net_worth':           p.getNetWorth(),
      'bank_balance':        p.accounts.fold(0.0, (s, a) => s + a.balance),
      'cash_on_hand':        p.totalCash,
      'monthly_income':      p.settings.monthlyIncome,
      'this_month_income':   income,
      'this_month_expenses': expenses,
      'top_categories':      topCats,
      'goals': p.goals.where((g) => g.type == 'goal').map((g) => {
        'name': g.name,
        'progress': g.targetAmount > 0 ? ((g.currentAmount / g.targetAmount) * 100).round() : 0,
      }).toList(),
      'debts': p.goals.where((g) => g.type == 'debt').map((g) => {
        'name': g.name,
        'remaining': g.targetAmount - g.currentAmount,
      }).toList(),
    };
  }

  // ── Project context — gather summaries from sibling conversations ──
  String? _buildProjectContextSummary() {
    if (_current.projectId == null) return null;
    final project = _projects.where((p) => p.id == _current.projectId).firstOrNull;
    final siblings = _convos
        .where((c) => c.projectId == _current.projectId && c.id != _current.id && c.history.isNotEmpty)
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
        final snippet = content.length > 300 ? '${content.substring(0, 300)}...' : content;
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
    final text      = _msgCtrl.text.trim();
    final imgPath   = _pendingImage;
    final docPath   = _pendingFile;
    final docName   = _pendingFileName;
    final docMime   = _pendingFileMime;
    final hasAttach = imgPath != null || docPath != null;
    if ((text.isEmpty && !hasAttach) || _isTyping) return;

    String displayTxt = text;
    if (displayTxt.isEmpty) {
      displayTxt = imgPath != null ? '📷 Image' : '📄 $docName';
    }
    String historyContent = text.isNotEmpty ? text : '';
    if (imgPath != null) historyContent += (historyContent.isEmpty ? '' : '\n') + '[User attached an image]';
    if (docPath != null) historyContent += (historyContent.isEmpty ? '' : '\n') + '[User attached document: $docName]';

    final userMsg = _ChatMsg(text: displayTxt, isUser: true, imagePath: imgPath, filePath: docPath, fileName: docName);

    setState(() {
      _current.messages.add(userMsg);
      _current.history.add({'role': 'user', 'content': historyContent});
      _isTyping        = true;
      _pendingImage    = null;
      _pendingFile     = null;
      _pendingFileName = null;
      _pendingFileMime = null;
      if (_current.title == 'New conversation') {
        _current.title = displayTxt.length > 40 ? '${displayTxt.substring(0, 40)}...' : displayTxt;
      }
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      String? attachBase64, attachMime;
      if (imgPath != null) {
        final bytes  = await File(imgPath).readAsBytes();
        attachBase64 = base64Encode(bytes);
        attachMime   = imgPath.toLowerCase().endsWith('.png') ? 'image/png'
            : imgPath.toLowerCase().endsWith('.webp') ? 'image/webp'
            : 'image/jpeg';
      } else if (docPath != null && docMime != null) {
        final bytes  = await File(docPath).readAsBytes();
        attachBase64 = base64Encode(bytes);
        attachMime   = docMime;
      }

      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';

      // Build financial context, inject project context if applicable
      final ctx = _buildContext(provider);
      final projectCtx = _buildProjectContextSummary();
      if (projectCtx != null) {
        ctx['project_context'] = projectCtx;
      }

      final reply = await ChatService.sendMessage(
        history: _current.history.map((h) => ChatMessage(role: h['role']!, content: h['content']!)).toList(),
        financialContext: ctx,
        token: token,
        attachmentBase64: attachBase64,
        attachmentMimeType: attachMime,
      );
      if (!mounted) return;
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
          text: 'Something went wrong. Please check your connection and try again.',
          isUser: false, isError: true,
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
        onPhoto:    () { Navigator.pop(context); _pickImage(); },
        onCamera:   () { Navigator.pop(context); _pickCamera(); },
        onDocument: () { Navigator.pop(context); _pickDocument(); },
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) setState(() { _pendingImage = picked.path; _pendingFile = null; });
  }

  Future<void> _pickCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null && mounted) setState(() { _pendingImage = picked.path; _pendingFile = null; });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: false);
    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _pendingFile     = result.files.single.path;
        _pendingFileName = result.files.single.name;
        _pendingFileMime = 'application/pdf';
        _pendingImage    = null;
      });
    }
  }

  // ── Left drawer — ChatGPT-style conversation sidebar ────────
  Widget _buildDrawer(BuildContext context, bool isDark, AppProvider provider) {
    final s = S.of(context);
    final drawerBg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);

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
        label = 'Today';
      } else if (c.createdAt.isAfter(yesterdayStart)) {
        label = 'Yesterday';
      } else if (c.createdAt.isAfter(weekStart)) {
        label = 'Previous 7 Days';
      } else {
        label = 'Older';
      }
      groups.putIfAbsent(label, () => []).add(c);
    }
    final orderedLabels = ['Today', 'Yesterday', 'Previous 7 Days', 'Older'];

    return Drawer(
      backgroundColor: drawerBg,
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'SafeSpend AI',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Search placeholder
                  IconButton(
                    icon: Iconify(AppIcons.search, size: 18,
                        color: isDark ? Colors.white60 : Colors.black45),
                    onPressed: () {},
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
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    _startNewConvo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Iconify(AppIcons.edit, size: 18,
                            color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 12),
                        Text(
                          s.newChat,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
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
                      child: Iconify(AppIcons.add, size: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showNewProjectDialog(isDark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Iconify(AppIcons.folder, size: 18,
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
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                            for (final conv in groups[label]!) _buildConvoTile(conv, isDark),
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
            ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
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
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Iconify(AppIcons.folder, size: 11,
                                color: isDark ? Colors.white30 : Colors.black26),
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
    final convoCount = _convos.where((c) => c.projectId == proj.id && !c.isArchived).length;

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
                Iconify(AppIcons.folder, size: 18,
                    color: isDark ? Colors.white54 : Colors.black45),
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
    final s = S.forLocale(S.fallbackLocale);
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        child: Iconify(AppIcons.minus, size: 28,
                            color: isDark ? Colors.white60 : Colors.black45),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        icon: Iconify(AppIcons.more, size: 22, color: subtleColor),
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
                      Iconify(AppIcons.folder, size: 32,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          proj.name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                              Iconify(AppIcons.chat, size: 40,
                                  color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 12),
                              Text(
                                s.noConversationsYet,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.addConversationsFromMenu,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: projConvos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Iconify(AppIcons.add, size: 20, color: subtleColor),
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
    final s = S.forLocale(S.fallbackLocale);
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
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _actionTile(ctx, AppIcons.edit, s.renameProject,
                textColor, subtleColor, onTap: () {
              Navigator.pop(ctx);
              _showRenameProjectDialog(proj, isDark);
            }),
            _actionTile(ctx, AppIcons.delete, s.deleteProject,
                Colors.redAccent, Colors.redAccent, onTap: () {
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
    final s = S.forLocale(S.fallbackLocale);
    final ctrl = TextEditingController(text: proj.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.renameProject, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: s.projectName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
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
            child: Text(s.save, style: GoogleFonts.inter(
                color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Delete project confirmation ───────────────────────────
  void _confirmDeleteProject(_Project proj, bool isDark) {
    final s = S.forLocale(S.fallbackLocale);
    final convoCount = _convos.where((c) => c.projectId == proj.id).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteProject, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'This will delete "${proj.name}". $convoCount conversation${convoCount == 1 ? '' : 's'} will be unlinked but not deleted.',
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
            child: Text(s.delete, style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Conversation action sheet ────────────────────────────────
  void _showConvoActions(_Convo conv, bool isDark) {
    final s = S.forLocale(S.fallbackLocale);
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
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Add to project
            _actionTile(ctx, AppIcons.folder, s.addToProject,
                textColor, subtleColor, trailing: AppIcons.caretRight,
                onTap: () {
              Navigator.pop(ctx);
              _showProjectPicker(conv, isDark);
            }),
            // Rename
            _actionTile(ctx, AppIcons.edit, s.rename,
                textColor, subtleColor, onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(conv, isDark);
            }),
            // Archive
            _actionTile(ctx, AppIcons.archive, s.archive,
                textColor, subtleColor, onTap: () {
              Navigator.pop(ctx);
              _archiveConvo(conv);
            }),
            // Delete
            _actionTile(ctx, AppIcons.delete, s.delete,
                Colors.redAccent, Colors.redAccent, onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteConvo(conv, isDark);
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext ctx, String icon, String label,
      Color textColor, Color iconColor, {VoidCallback? onTap, String? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Iconify(icon, size: 20, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
              ),
              if (trailing != null)
                Iconify(trailing, size: 20, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rename dialog ──────────────────────────────────────────
  void _showRenameDialog(_Convo conv, bool isDark) {
    final s = S.forLocale(S.fallbackLocale);
    final ctrl = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.rename, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: s.conversationName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newTitle = ctrl.text.trim();
              if (newTitle.isNotEmpty) {
                _renameConvo(conv, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.save, style: GoogleFonts.inter(
                color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation ─────────────────────────────────────
  void _confirmDeleteConvo(_Convo conv, bool isDark) {
    final s = S.forLocale(S.fallbackLocale);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteConversation, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'This will permanently delete "${conv.title}".',
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
            child: Text(s.delete, style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Project picker — "Add to project" submenu ───────────────
  void _showProjectPicker(_Convo conv, bool isDark) {
    final s = S.forLocale(S.fallbackLocale);
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
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
                      Text(s.addToProject, style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      const Spacer(),
                      if (conv.projectId != null)
                        GestureDetector(
                          onTap: () {
                            _removeConvoFromProject(conv);
                            Navigator.pop(ctx);
                          },
                          child: Text(s.remove, style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.redAccent)),
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
                  Divider(height: 1, indent: 20, endIndent: 20,
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
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
                      final convoCount = _convos.where((c) => c.projectId == p.id).length;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _assignConvoToProject(conv, p.id);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Iconify(AppIcons.folder, size: 20, color: subtleColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: GoogleFonts.inter(
                                          fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                                      Text('$convoCount conversation${convoCount == 1 ? '' : 's'}',
                                          style: GoogleFonts.inter(fontSize: 12, color: subtleColor)),
                                    ],
                                  ),
                                ),
                                if (isAssigned)
                                  const Iconify(AppIcons.check, size: 20, color: Color(0xFF10A37F)),
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
  void _showNewProjectDialog(bool isDark, {void Function(String projectId)? onCreated}) {
    final s = S.forLocale(S.fallbackLocale);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.newProject, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: s.projectName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final p = _Project(id: const Uuid().v4(), name: name, createdAt: DateTime.now());
                setState(() => _projects.add(p));
                _saveProjects();
                _syncProjectToCloud(p);
                Navigator.pop(ctx);
                onCreated?.call(p.id);
              }
            },
            child: Text(s.create, style: GoogleFonts.inter(
                color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours   < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1) return '${diff.inHours}h ago';
    if (diff.inDays    < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AuthService>(
      builder: (context, provider, auth, _) {
        final isDark    = Theme.of(context).brightness == Brightness.dark;
        final hasAccess = _hasAccess(auth.user?.email);
        final bgColor   = isDark ? const Color(0xFF0D0D0D) : Colors.white;

        if (!_ready) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: SizedBox(
                width: 24, height: 24,
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
          drawer: _buildDrawer(context, isDark, provider),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
                Expanded(
                  child: _current.messages.isEmpty
                      ? _buildWelcome(context, isDark, provider, hasAccess)
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      child: Row(
        children: [
          // Menu / history button — horizontal lines like ChatGPT
          IconButton(
            icon: Iconify(
              AppIcons.list,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            splashRadius: 20,
          ),
          const Spacer(),
          // Title — minimal like ChatGPT
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.financialCoach,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
          const Spacer(),
          // New chat button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: s.newChat,
            onPressed: _startNewConvo,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Welcome state — ChatGPT style: typewriter + bottom suggestions ──
  Widget _buildWelcome(BuildContext context, bool isDark, AppProvider provider, bool hasAccess) {
    final s = S.of(context);
    final suggestions = [
      {'title': s.monthlyOverview, 'sub': 'how am I doing this month?'},
      {'title': s.spendingAnalysis, 'sub': 'where does my money go?'},
      {'title': s.analyzeReceipt, 'sub': 'attach a photo or PDF'},
      {'title': s.savingsTips, 'sub': 'help me save more money'},
      {'title': s.goalProgress, 'sub': 'how close am I to my goals?'},
      {'title': s.budgetPlan, 'sub': 'create a plan for me'},
    ];
    return Column(
      children: [
        const Spacer(),
        // Typewriter animation in center
        _TypewriterWelcome(isDark: isDark),
        const Spacer(),
        // Suggestion cards — horizontal scroll at the bottom
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SuggestionCard(
              text: suggestions[i]['title']!,
              subtitle: suggestions[i]['sub'],
              isDark: isDark,
              onTap: () {
                _msgCtrl.text = suggestions[i]['sub']!;
                _send(provider);
              },
            ),
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 350.ms)
            .slideY(begin: 0.1, end: 0, duration: 350.ms),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Message list ─────────────────────────────────────────────
  Widget _buildMessageList(BuildContext context, bool isDark) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      itemCount: _current.messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _current.messages.length) {
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
    );
  }

  // ── Input area ─────────────────────────────────────────────
  Widget _buildInputArea(BuildContext context, bool isDark, AppProvider provider) {
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

  // ── Locked banner ────────────────────────────────────────────
  Widget _buildLockedBanner(BuildContext context, bool isDark) {
    final s = S.of(context);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF10A37F), size: 20),
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
              width: 36, height: 4,
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
              _option(context, isDark, Icons.photo_library_rounded, s.photo, AppTheme.goldPrimary, onPhoto),
              const SizedBox(width: 12),
              _option(context, isDark, Icons.camera_alt_rounded, s.camera, const Color(0xFF6C6EF7), onCamera),
              const SizedBox(width: 12),
              _option(context, isDark, Icons.picture_as_pdf_rounded, s.document, Colors.red, onDocument),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, bool isDark, IconData icon, String label, Color color, VoidCallback onTap) {
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
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

// ── Typewriter welcome animation ──────────────────────────────
class _TypewriterWelcome extends StatefulWidget {
  final bool isDark;
  const _TypewriterWelcome({required this.isDark});
  @override
  State<_TypewriterWelcome> createState() => _TypewriterWelcomeState();
}

class _TypewriterWelcomeState extends State<_TypewriterWelcome> {
  static const _phrase1 = 'Welcome to SafeSpend AI';
  static const _phrase2 = 'How can we help you today?';
  static const _typeSpeed    = Duration(milliseconds: 55);
  static const _deleteSpeed  = Duration(milliseconds: 30);
  static const _pauseAfterType   = Duration(milliseconds: 1200);
  static const _pauseAfterDelete = Duration(milliseconds: 400);

  String _display = '';
  bool _showCursor = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _runSequence();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _wait(Duration d) => Future.delayed(d);

  void _startCursorBlink() async {
    while (!_disposed) {
      await _wait(const Duration(milliseconds: 530));
      if (_disposed) return;
      if (mounted) setState(() => _showCursor = !_showCursor);
    }
  }

  Future<void> _runSequence() async {
    await _wait(const Duration(milliseconds: 600));

    // Type phrase 1
    for (int i = 0; i <= _phrase1.length; i++) {
      if (_disposed) return;
      setState(() => _display = _phrase1.substring(0, i));
      await _wait(_typeSpeed);
    }
    await _wait(_pauseAfterType);

    // Delete phrase 1
    for (int i = _phrase1.length; i >= 0; i--) {
      if (_disposed) return;
      setState(() => _display = _phrase1.substring(0, i));
      await _wait(_deleteSpeed);
    }
    await _wait(_pauseAfterDelete);

    // Type phrase 2
    for (int i = 0; i <= _phrase2.length; i++) {
      if (_disposed) return;
      setState(() => _display = _phrase2.substring(0, i));
      await _wait(_typeSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _display,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
            TextSpan(
              text: _showCursor ? '|' : ' ',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: widget.isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
