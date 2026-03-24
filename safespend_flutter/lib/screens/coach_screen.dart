import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

// ─────────────────────────────────────────────────────────────
// ADD EMAILS OF USERS WHO HAVE BETA ACCESS TO THE AI COACH
// (case-insensitive). Leave empty + set _openToAll = true to
// give everyone access.
// ─────────────────────────────────────────────────────────────
const _allowedEmails = <String>[
  'abdellahmazouz75@gmail.com',
  'tahamohamedadib@gmail.com',
  'tahamohammedadib@gmail.com',
];
const _openToAll = false;
// ─────────────────────────────────────────────────────────────

// ── Data models ───────────────────────────────────────────────
class _ChatMsg {
  final String text;
  final bool isUser;
  final bool isError;
  final String? imagePath;

  const _ChatMsg({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'isError': isError,
    'imagePath': imagePath,
  };

  factory _ChatMsg.fromJson(Map<String, dynamic> j) => _ChatMsg(
    text: j['text'] as String,
    isUser: j['isUser'] as bool,
    isError: j['isError'] as bool? ?? false,
    imagePath: j['imagePath'] as String?,
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
    'id': id,
    'title': title,
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
// ─────────────────────────────────────────────────────────────

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  static const _prefsKey = 'ai_coach_conversations_v2';

  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();

  List<_Convo> _convos = [];
  late _Convo _current;
  bool _isTyping = false;
  bool _ready    = false;
  String? _pendingImage;

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

  // ── Persistence ────────────────────────────────────────────
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
          setState(() {
            _convos = loaded;
            _current = loaded.first;
            _ready = true;
          });
          return;
        }
      } catch (_) {}
    }
    final fresh = _newConvo();
    if (mounted) {
      setState(() {
        _convos = [fresh];
        _current = fresh;
        _ready = true;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_convos.map((c) => c.toJson()).toList()),
    );
  }

  _Convo _newConvo() => _Convo(
    id: const Uuid().v4(),
    title: 'New conversation',
    messages: [
      const _ChatMsg(
        text: "Hi! I'm your AI Financial Coach.\n\n"
              "I already have a live snapshot of your finances — ask me anything: "
              "budgeting advice, savings strategies, debt payoff, or just \"how am I doing?\" 💬",
        isUser: false,
      ),
    ],
    history: [],
    createdAt: DateTime.now(),
  );

  void _startNewConvo() {
    final c = _newConvo();
    setState(() {
      _convos.insert(0, c);
      _current = c;
      _pendingImage = null;
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

  // ── Access check ───────────────────────────────────────────
  bool _hasAccess(String? email) {
    if (_openToAll) return true;
    if (email == null) return false;
    return _allowedEmails.any((e) => e.toLowerCase() == email.toLowerCase());
  }

  // ── Financial context ──────────────────────────────────────
  Map<String, dynamic> _buildContext(AppProvider p) {
    final now        = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTxns  = p.transactions.where((t) {
      return !DateTime.parse(t.date).isBefore(monthStart);
    }).toList();
    final monthIncome   = monthTxns.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final monthExpenses = monthTxns.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    final catMap = <String, double>{};
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
      'this_month_income':   monthIncome,
      'this_month_expenses': monthExpenses,
      'top_categories':      topCats,
      'goals': p.goals.where((g) => g.type == 'goal').map((g) => {
        'name': g.name,
        'progress': g.targetAmount > 0 ? ((g.currentAmount / g.targetAmount) * 100).round() : 0,
      }).toList(),
      'debts': p.goals.where((g) => g.type == 'debt').map((g) => {
        'name': g.name,
        'remaining': g.targetAmount - g.currentAmount,
      }).toList(),
      'personal_debts': p.goals.where((g) => g.type == 'personal_debt').map((g) => {
        'name': g.name,
        'remaining': g.targetAmount - g.currentAmount,
      }).toList(),
    };
  }

  // ── Send message ───────────────────────────────────────────
  Future<void> _send(AppProvider provider) async {
    final text = _msgCtrl.text.trim();
    if ((text.isEmpty && _pendingImage == null) || _isTyping) return;

    final imgPath    = _pendingImage;
    final displayTxt = (text.isEmpty && imgPath != null) ? '📷 Image' : text;

    final userMsg = _ChatMsg(text: displayTxt, isUser: true, imagePath: imgPath);

    setState(() {
      _current.messages.add(userMsg);
      _current.history.add({'role': 'user', 'content': text.isEmpty ? '[User shared an image]' : text});
      _isTyping    = true;
      _pendingImage = null;
      if (_current.title == 'New conversation') {
        _current.title = displayTxt.length > 40
            ? '${displayTxt.substring(0, 40)}...'
            : displayTxt;
      }
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final reply = await ChatService.sendMessage(
        history: _current.history
            .map((h) => ChatMessage(role: h['role']!, content: h['content']!))
            .toList(),
        financialContext: _buildContext(provider),
        token: token,
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
          text: 'Something went wrong. Please try again.\n${e.toString().replaceAll('Exception: ', '')}',
          isUser: false,
          isError: true,
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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _pendingImage = picked.path);
  }

  // ── Conversations bottom sheet ────────────────────────────
  void _showConvosSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Conversations', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('New', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _startNewConvo();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _convos.isEmpty
                      ? Center(child: Text('No conversations yet.', style: Theme.of(ctx).textTheme.bodySmall))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _convos.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(ctx).dividerColor.withOpacity(0.5)),
                          itemBuilder: (_, i) {
                            final conv = _convos[i];
                            final isActive = conv.id == _current.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.aiAccent.withOpacity(0.12)
                                      : Theme.of(ctx).dividerColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: isActive ? AppTheme.aiAccent : Theme.of(ctx).textTheme.bodySmall?.color,
                                ),
                              ),
                              title: Text(
                                conv.title,
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _fmtDate(conv.createdAt),
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11),
                              ),
                              trailing: isActive
                                  ? Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.aiAccent)
                                  : IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(ctx).textTheme.bodySmall?.color),
                                      onPressed: () {
                                        setSheetState(() => _deleteConvo(conv.id));
                                        if (_convos.isEmpty) Navigator.pop(ctx);
                                      },
                                    ),
                              onTap: () {
                                _switchConvo(conv);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours  < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays   < 1)   return '${diff.inHours}h ago';
    if (diff.inDays   < 7)   return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AuthService>(
      builder: (context, provider, auth, _) {
        final hasAccess = _hasAccess(auth.user?.email);
        if (!_ready) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, hasAccess),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _current.messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _current.messages.length) return _buildTypingIndicator(ctx);
                      return _buildBubble(ctx, _current.messages[i]);
                    },
                  ),
                ),
                hasAccess
                    ? _buildInputBar(context, provider)
                    : _buildLockedBanner(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool hasAccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 22),
            tooltip: 'Conversations',
            onPressed: () => _showConvosSheet(context),
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.aiAccent, AppTheme.aiAccentDeep]),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Financial Coach', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: hasAccess ? AppTheme.success : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasAccess ? 'Online' : 'Beta — access restricted',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasAccess ? AppTheme.success : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasAccess)
            IconButton(
              icon: const Icon(Icons.edit_square, size: 20),
              tooltip: 'New chat',
              onPressed: _startNewConvo,
            ),
        ],
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────────
  Widget _buildBubble(BuildContext context, _ChatMsg msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.aiAccent, AppTheme.aiAccentDeep]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: msg.isError
                    ? AppTheme.error.withOpacity(0.10)
                    : msg.isUser
                        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE))
                        : AppTheme.aiAccent.withOpacity(0.10),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: msg.isError
                      ? AppTheme.error.withOpacity(0.25)
                      : msg.isUser
                          ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD))
                          : AppTheme.aiAccent.withOpacity(0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(msg.imagePath!),
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 40),
                      ),
                    ),
                    if (msg.text.isNotEmpty && msg.text != '📷 Image')
                      const SizedBox(height: 8),
                  ],
                  if (msg.text.isNotEmpty && msg.text != '📷 Image')
                    Text(
                      msg.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: msg.isError ? AppTheme.error : null,
                        height: 1.45,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.aiAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.aiAccent, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────
  Widget _buildTypingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.aiAccent, AppTheme.aiAccentDeep]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.aiAccent.withOpacity(0.10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.aiAccent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────
  Widget _buildInputBar(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image preview strip
        if (_pendingImage != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_pendingImage!), height: 100, width: 100, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _pendingImage = null),
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15))),
          ),
          child: Row(
            children: [
              // Image attach
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: _pendingImage != null
                        ? AppTheme.aiAccent
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Text field
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  enabled: !_isTyping,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(provider),
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about your finances...',
                    hintStyle: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.4))),
                    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppTheme.aiAccent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send
              GestureDetector(
                onTap: _isTyping ? null : () => _send(provider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isTyping
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [AppTheme.aiAccent, AppTheme.aiAccentDeep],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _isTyping ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.white, size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Locked banner ─────────────────────────────────────────
  Widget _buildLockedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppTheme.aiAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI Coach is in beta — full access coming soon.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot animation ─────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.delay > 0) {
      _ctrl.stop();
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 7, height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppTheme.aiAccent.withOpacity(0.35 + _anim.value * 0.65),
        shape: BoxShape.circle,
      ),
    ),
  );
}
