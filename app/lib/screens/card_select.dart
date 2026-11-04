import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'card_form.dart';
import 'my_requests.dart';

class _CardData {
  final List<CardType> types;
  final CardRequest? pending;
  _CardData(this.types, this.pending);
}

class CardTab extends StatefulWidget {
  final VoidCallback onMenu;
  const CardTab({super.key, required this.onMenu});
  @override
  State<CardTab> createState() => _CardTabState();
}

class _CardTabState extends State<CardTab> {
  late Future<_CardData> _data;
  final _page = PageController(viewportFraction: .88);
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _data = _fetch();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<_CardData> _fetch() async {
    final api = context.read<AppState>().api;
    final types = await api.cardTypes();
    final reqs = await api.cardRequests();
    CardRequest? pending;
    for (final r in reqs) {
      if (r.status == 'awaiting_review') {
        pending = r;
        break;
      }
    }
    return _CardData(types, pending);
  }

  void _reload() {
    final f = _fetch();
    setState(() {
      _data = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          redAppBar(context, 'GET MY CARD', back: false, onMenu: widget.onMenu),
      body: FutureBuilder<_CardData>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            final msg = snap.error is ApiException
                ? (snap.error as ApiException).message
                : 'Could not load cards.';
            return ErrorRetry(message: msg, onRetry: _reload);
          }
          final d = snap.data!;
          final pending = d.pending;
          return Column(children: [
            const SizedBox(height: 14),
            const Text('Choose Your RedCross Card',
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 4, 28, 10),
              child: Text(
                  'Select a membership card and enjoy exclusive benefits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ),
            if (pending != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Material(
                  color: const Color(0xFFFBEFD5),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const MyRequestsScreen(initialTab: 2))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.schedule_rounded,
                            color: Color(0xFF8A5A00)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Your ${pending.cardName} card request is awaiting review.',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B4500),
                                    fontSize: 13))),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF8A5A00)),
                      ]),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: d.types.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => _CardPanel(type: d.types[i]),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < d.types.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  width: i == _i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: i == _i ? C.wine : Colors.black26,
                      borderRadius: BorderRadius.circular(8)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
              child: PrimaryButton(
                label: pending != null ? 'View my request' : 'Get My Card',
                trailing: Icons.arrow_forward_rounded,
                onPressed: () async {
                  if (pending != null) {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const MyRequestsScreen(initialTab: 2)));
                  } else {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardFormScreen(
                                card: d.types[_i], cards: d.types)));
                  }
                  if (mounted) _reload();
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _CardPanel extends StatelessWidget {
  final CardType type;
  const _CardPanel({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5C97A))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          CardArt(color: type.color),
          const SizedBox(height: 16),
          Text('${type.name.toUpperCase()} CARD',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          const SizedBox(height: 6),
          Text(peso(type.price),
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800, color: C.crimson)),
          const SizedBox(height: 14),
          for (final b in type.benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF1B7A1B), size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(b,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black))),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// The membership card artwork.
class CardArt extends StatelessWidget {
  final Color color;
  const CardArt({super.key, required this.color});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.65,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, .22)!]),
            boxShadow: [
              BoxShadow(
                  color: C.opacity(color, .4),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                AppLogo(size: 74),
                SizedBox(height: 10),
                OutlinedText('REDCROSS CARD', size: 20, stroke: 4),
              ]),
        ),
      );
}
