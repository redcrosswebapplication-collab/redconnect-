import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/brand.dart';
import 'donor_verification.dart';
import 'my_requests.dart';
import 'notifications.dart';
import 'shell.dart' show UserAvatar;

class DashboardTab extends StatefulWidget {
  final VoidCallback onMenu;
  const DashboardTab({super.key, required this.onMenu});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // pick up unread count / donor status that changed while the app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = s.user!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: C.maroon,
        edgeOffset: 80,
        onRefresh: s.refreshUser,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ---------- header ----------
            Container(
              decoration: const BoxDecoration(
                  color: C.maroon,
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(60),
                      bottomLeft: Radius.circular(18))),
              padding: EdgeInsets.fromLTRB(
                  14, MediaQuery.of(context).padding.top + 8, 18, 22),
              child: Column(children: [
                Row(children: [
                  IconButton(
                      tooltip: 'Menu',
                      onPressed: widget.onMenu,
                      icon: const Icon(Icons.menu_rounded,
                          color: Colors.white, size: 28)),
                  const Spacer(),
                  Material(
                    color: C.opacity(Colors.white, .22),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen())),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Badge(
                          isLabelVisible: user.unreadCount > 0,
                          label: Text('${user.unreadCount}'),
                          child: const Icon(Icons.sms_rounded,
                              color: Colors.white,
                              size: 24,
                              semanticLabel: 'Notifications'),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  const SizedBox(width: 6),
                  GestureDetector(
                      onTap: widget.onMenu,
                      child: UserAvatar(user: user, size: 70)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800)),
                          const Text('WELCOME',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800)),
                          if (user.isDonor)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color: C.opacity(Colors.white, .2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          color: Colors.white, size: 15),
                                      SizedBox(width: 5),
                                      Text('Verified donor',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                              ),
                            ),
                        ]),
                  ),
                ]),
              ]),
            ),

            // ---------- appointment banner ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: Material(
                color: C.rose,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: Colors.black)),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  onTap: () => context.read<AppState>().setTab(3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    child: Row(children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Colors.white, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(children: [
                          Text('BOOK YOUR APPOINTMENT',
                              textAlign: TextAlign.center,
                              style: display(13.5)),
                          const SizedBox(height: 8),
                          const OutlinedText('NOW !', size: 38),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ---------- 2x2 actions ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.08,
                children: [
                  _Tile(
                      Icons.badge_rounded,
                      'Get My Card',
                      'Gain more Benefits',
                      () => context.read<AppState>().setTab(1)),
                  _Tile(
                      Icons.work_history_rounded,
                      'Appointment',
                      'Book your Appointment',
                      () => context.read<AppState>().setTab(3)),
                  _Tile(
                      Icons.emergency_rounded,
                      'Request Blood',
                      'Request Blood if Emergency',
                      () => context.read<AppState>().setTab(2)),
                  _Tile(
                      Icons.volunteer_activism_rounded,
                      'Be a Blood Donor',
                      'Your Blood may save lives',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DonorVerificationScreen()))),
                ],
              ),
            ),

            // ---------- status shortcut ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.maroon,
                  side: const BorderSide(color: C.maroon, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyRequestsScreen())),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Track my requests & appointments',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _Tile(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Colors.black)),
        child: InkWell(
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: C.crimson,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: C.maroon, size: 26),
              ]),
              const Spacer(),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2)),
            ]),
          ),
        ),
      );
}
