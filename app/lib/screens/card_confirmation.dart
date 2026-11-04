import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'my_requests.dart';

class CardConfirmationScreen extends StatelessWidget {
  final CardRequest request;
  const CardConfirmationScreen({super.key, required this.request});

  void _home(BuildContext context) {
    context.read<AppState>().setTab(0);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.deepRed,
      appBar: redAppBar(context, 'CARD REQUEST', color: C.deepRed),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (_, t, child) => Transform.scale(scale: t.clamp(0.0, 1.3), child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2E7D32), width: 2)),
                child: const Icon(Icons.check_rounded, size: 52, color: C.deepRed),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Request submitted!', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Your card request is awaiting review.\nYour card is not yet approved or issued.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF0CECE), fontWeight: FontWeight.w700, height: 1.35)),
            const SizedBox(height: 20),
            WhiteCard(
              title: 'Request summary',
              child: Column(children: [
                _row('Card requested', Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFF7F0E6), borderRadius: BorderRadius.circular(8)),
                  child: Text(request.cardName, style: const TextStyle(color: Color(0xFF805522), fontWeight: FontWeight.w800)),
                )),
                const Divider(height: 22, color: Color(0xFFEEE5E5)),
                _row('Reference', Text('#${request.id}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink))),
                const Divider(height: 22, color: Color(0xFFEEE5E5)),
                _row('Current status', const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule_rounded, size: 18, color: C.deepRed),
                  SizedBox(width: 5),
                  Text('Awaiting review', style: TextStyle(color: C.deepRed, fontWeight: FontWeight.w800)),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
            WhiteCard(
              title: 'What happens next?',
              child: Column(children: const [
                _Step(Icons.assignment_turned_in_outlined, 'Your details will be reviewed', 'The information you submitted will be checked before your card request can proceed.'),
                SizedBox(height: 14),
                _Step(Icons.checklist_rounded, 'Keep track of your request', 'View your request status for updates and any next steps you may need to take.'),
              ]),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Track my request',
              color: Colors.white,
              foreground: C.deepRed,
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialTab: 2))),
            ),
            TextButton(
              onPressed: () => _home(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Back to home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, Widget value) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700))),
        value,
      ]);
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _Step(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: const Color(0xFFF7EAEA), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: C.deepRed, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink, fontSize: 14.5)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(color: C.muted, fontSize: 12.5, height: 1.35)),
          ]),
        ),
      ]);
}
