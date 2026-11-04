import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'common.dart';

class _TileShell extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String status;
  final String? note;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _TileShell({required this.leading, required this.title, required this.subtitle, required this.status, this.note, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black87)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: C.muted, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 8),
            StatusChip(status),
          ]),
          if (note != null && note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Note: $note', style: const TextStyle(fontSize: 12.5, color: C.ink)),
            ),
          if (actionLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E), visualDensity: VisualDensity.compact),
                onPressed: onAction,
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
}

Widget _iconBox(IconData icon) => Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: C.crimson, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.white, size: 26),
    );

class AppointmentTile extends StatelessWidget {
  final Appointment a;
  final VoidCallback? onCancel;
  const AppointmentTile(this.a, {super.key, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final d = parseDay(a.date);
    return _TileShell(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: C.maroon, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(DateFormat('MMM').format(d).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
          Text('${d.day}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
        ]),
      ),
      title: fmtTime(a.time),
      subtitle: fmtDay(a.date),
      status: a.status,
      actionLabel: a.cancellable ? 'Cancel appointment' : null,
      onAction: onCancel,
    );
  }
}

class BloodRequestTile extends StatelessWidget {
  final BloodRequest r;
  final VoidCallback? onCancel;
  const BloodRequestTile(this.r, {super.key, this.onCancel});

  @override
  Widget build(BuildContext context) => _TileShell(
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: C.crimson, shape: BoxShape.circle),
          child: Text(r.bloodGroup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        title: r.patientName,
        subtitle: '${r.units} unit${r.units == 1 ? '' : 's'} · ${r.city} · ${timeAgo(r.createdAt)}',
        status: r.status,
        actionLabel: r.status == 'open' ? 'Cancel request' : null,
        onAction: onCancel,
      );
}

class CardRequestTile extends StatelessWidget {
  final CardRequest r;
  const CardRequestTile(this.r, {super.key});
  @override
  Widget build(BuildContext context) => _TileShell(
        leading: _iconBox(Icons.badge_rounded),
        title: '${r.cardName} card',
        subtitle: 'Requested ${timeAgo(r.createdAt)} · Ref #${r.id}',
        status: r.status,
        note: r.note,
      );
}

class VerificationTile extends StatelessWidget {
  final DonorVerification v;
  const VerificationTile(this.v, {super.key});
  @override
  Widget build(BuildContext context) => _TileShell(
        leading: _iconBox(Icons.volunteer_activism_rounded),
        title: 'Donor verification',
        subtitle: 'Submitted ${timeAgo(v.createdAt)}',
        status: v.status,
        note: v.note,
      );
}
