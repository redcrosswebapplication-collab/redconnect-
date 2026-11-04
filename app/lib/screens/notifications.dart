import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final list = await state.api.notifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _error = null;
      });
      state.setUnread(list.where((n) => !n.read).length);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.read) return;
    final state = context.read<AppState>();
    setState(() => _items = [
          for (final x in _items!) x.id == n.id ? x.asRead() : x
        ]); // optimistic
    try {
      state.setUnread(await state.api.markRead(n.id));
    } on ApiException {
      _load(); // revert to the server's truth
    }
  }

  Future<void> _markAll() async {
    final state = context.read<AppState>();
    final ok =
        await guard(context, () => state.api.markAllRead().then((_) => true));
    if (ok == true && mounted) {
      setState(() => _items = [for (final x in _items!) x.asRead()]);
      state.setUnread(0);
    }
  }

  ({IconData icon, Color bg, Color fg}) _style(String type) {
    switch (type) {
      case 'emergency':
        return (
          icon: Icons.campaign_rounded,
          bg: const Color(0xFFEFB8B8),
          fg: const Color(0xFFB22525)
        );
      case 'donor':
        return (
          icon: Icons.notifications_active_rounded,
          bg: const Color(0xFFA08A50),
          fg: const Color(0xFFF2C21B)
        );
      case 'update':
        return (
          icon: Icons.fact_check_rounded,
          bg: const Color(0xFFD7EBD7),
          fg: const Color(0xFF2E7D32)
        );
      default:
        return (
          icon: Icons.priority_high_rounded,
          bg: const Color(0xFFB8F2F7),
          fg: const Color(0xFF1F2A7A)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items?.where((n) => !n.read).length ?? 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: redAppBar(context, 'SMS NOTIFICATIONS', actions: [
        if (unread > 0)
          TextButton(
              onPressed: _markAll,
              child: const Text('Read all',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800))),
      ]),
      body: Builder(builder: (context) {
        if (_error != null && _items == null) {
          return ErrorRetry(
              message: _error!,
              onRetry: () {
                setState(() => _error = null);
                _load();
              });
        }
        if (_items == null) return const LoadingView();
        return RefreshIndicator(
          color: C.maroon,
          onRefresh: _load,
          child: _items!.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyView(
                      icon: Icons.notifications_none_rounded,
                      title: 'All caught up',
                      message:
                          'New blood requests and updates will show up here.')
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = _items![i];
                    final st = _style(n.type);
                    return Material(
                      color: n.read ? Colors.white : const Color(0xFFFFF5F4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                              color: n.read ? Colors.black54 : C.crimson,
                              width: n.read ? 1 : 1.6)),
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        onTap: () => _open(n),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                        color: st.bg, shape: BoxShape.circle),
                                    child:
                                        Icon(st.icon, color: st.fg, size: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(n.title,
                                                  style: const TextStyle(
                                                      fontSize: 16.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black))),
                                          if (!n.read)
                                            Container(
                                                width: 9,
                                                height: 9,
                                                decoration: const BoxDecoration(
                                                    color: C.crimson,
                                                    shape: BoxShape.circle)),
                                        ]),
                                        const SizedBox(height: 2),
                                        Text(n.body,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF777070),
                                                height: 1.3)),
                                        const SizedBox(height: 4),
                                        Text(timeAgo(n.createdAt),
                                            style: const TextStyle(
                                                fontSize: 11.5,
                                                color: C.muted)),
                                      ]),
                                ),
                              ]),
                        ),
                      ),
                    );
                  },
                ),
        );
      }),
    );
  }
}
