import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_widgets/chat_input_bar.dart';
import 'chat_widgets/message_bubble.dart';
import 'chat_widgets/suggestion_card.dart';
import 'chat_widgets/typing_indicator.dart';

const _allowedEmails = <String>[
  'abdellahmazouz75@gmail.com',
  'tahamohamedadib@gmail.com',
  'tahamohammedadib@gmail.com',
];
const _openToAll = false;

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

  _Convo({
    required this.id,
    required this.title,
    required this.messages,
    required this.history,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'history': history,
    'createdAt': createdAt.toIso8601String(),
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

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();

  List<_Convo> _convos = [];
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

  Future<void> _loadConvos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        final loaded = list
            .map((j) => _Convo.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (loaded.isNotEmpty && mounted) {
          setState(() { _convos = loaded; _current = loaded.first; _ready = true; });
          return;
        }
      } catch (_) {}
    }
    final fresh = _newConvo();
    if (mounted) setState(() { _convos = [fresh]; _current = fresh; _ready = true; });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_convos.map((c) => c.toJson()).toList()));
  }

  _Convo _newConvo() => _Convo(
    id: const Uuid().v4(),
    title: 'New conversation',
    messages: [],
    history: [],
    createdAt: DateTime.now(),
  );

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
      final reply = await ChatService.sendMessage(
        history: _current.history.map((h) => ChatMessage(role: h['role']!, content: h['content']!)).toList(),
        financialContext: _buildContext(provider),
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
      if (!mounted) return;
      setState(() {
        _current.messages.add(_ChatMsg(
          text: 'Something went wrong. ${e.toString().replaceAll('Exception: ', '')}',
          isUser: false, isError: true,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
    _save();
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
    final drawerBg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);

    // Group conversations: Today, Yesterday, Previous 7 Days, Older
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final groups = <String, List<_Convo>>{};
    for (final c in _convos) {
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
                    icon: Icon(Icons.search_rounded, size: 22,
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
                        Icon(Icons.edit_outlined, size: 18,
                            color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 12),
                        Text(
                          'New chat',
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

            // ── Conversations list ────────────────────────────
            Expanded(
              child: _convos.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet',
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
          onLongPress: isActive ? null : () => _confirmDeleteConvo(conv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    conv.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isActive)
                  GestureDetector(
                    onTap: () => _confirmDeleteConvo(conv),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.more_horiz_rounded, size: 16,
                          color: isDark ? Colors.white24 : Colors.black26),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteConvo(_Convo conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete conversation?', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'This will permanently delete "${conv.title}".',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConvo(conv.id);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      child: Row(
        children: [
          // Menu / history button — horizontal lines like ChatGPT
          IconButton(
            icon: Icon(
              Icons.density_medium_rounded,
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
                  'SafeSpend AI',
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
            tooltip: 'New chat',
            onPressed: _startNewConvo,
            splashRadius: 20,
          ),
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {},
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Welcome state — ChatGPT style: typewriter + bottom suggestions ──
  Widget _buildWelcome(BuildContext context, bool isDark, AppProvider provider, bool hasAccess) {
    final suggestions = [
      {'title': 'Monthly overview', 'sub': 'how am I doing this month?'},
      {'title': 'Spending analysis', 'sub': 'where does my money go?'},
      {'title': 'Analyze receipt', 'sub': 'attach a photo or PDF'},
      {'title': 'Savings tips', 'sub': 'help me save more money'},
      {'title': 'Goal progress', 'sub': 'how close am I to my goals?'},
      {'title': 'Budget plan', 'sub': 'create a plan for me'},
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
              color: const Color(0xFF10A37F).withOpacity(0.12),
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
                  'Beta Access Only',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Full AI coach access coming soon.',
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
            'Attach',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _option(context, isDark, Icons.photo_library_rounded, 'Photo', const Color(0xFF10A37F), onPhoto),
              const SizedBox(width: 12),
              _option(context, isDark, Icons.camera_alt_rounded, 'Camera', const Color(0xFF6C6EF7), onCamera),
              const SizedBox(width: 12),
              _option(context, isDark, Icons.picture_as_pdf_rounded, 'Document', Colors.red, onDocument),
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
