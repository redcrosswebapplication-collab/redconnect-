import 'package:intl/intl.dart';

DateTime parseDay(String ymd) {
  final p = ymd.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String fmtDay(String s) => DateFormat('EEE, MMM d, y').format(parseDay(s));
String fmtDate(DateTime d) => DateFormat('dd / MM / yyyy').format(d);

String fmtTime(String hhmm) {
  final p = hhmm.split(':');
  return DateFormat.jm().format(DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1])));
}

String peso(int n) => '₱${NumberFormat.decimalPattern().format(n)}';

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('MMM d').format(t.toLocal());
}

String prettyStatus(String s) {
  final t = s.replaceAll('_', ' ');
  return t[0].toUpperCase() + t.substring(1);
}
