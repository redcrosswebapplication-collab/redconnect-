import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'appointment.dart';
import 'blood_request.dart';
import 'card_select.dart';
import 'dashboard.dart';
import 'donor_verification.dart';
import 'my_requests.dart';
import 'notifications.dart';

/// Logged-in container: 4 tabs (Home / Card / Request / Appointment) + the slide-out menu.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final Set<int> _visited = {0};

  void _openMenu() => _scaffold.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    _visited.add(s.tab); // tabs are built lazily, then kept alive

    final tabs = <Widget>[
      DashboardTab(onMenu: _openMenu),
      CardTab(onMenu: _openMenu),
      BloodRequestTab(onMenu: _openMenu),
      AppointmentTab(onMenu: _openMenu),
    ];

    return PopScope(
      canPop: s.tab == 0, // system back from another tab returns Home first
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<AppState>().setTab(0);
      },
      child: Scaffold(
        key: _scaffold,
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: s.tab,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _visited.contains(i) ? tabs[i] : const SizedBox.shrink()
          ],
        ),
        bottomNavigationBar: AppBottomNav(index: s.tab, onTap: s.setTab),
      ),
    );
  }
}

// ============================================================================
class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.index, required this.onTap});

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.badge_rounded, 'Card'),
    (Icons.send_rounded, 'Request'),
    (Icons.work_history_rounded, 'Appointment'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: C.navGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: _items[i].$2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 4),
                          decoration: BoxDecoration(
                              color:
                                  i == index ? C.deepRed : Colors.transparent,
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(_items[i].$1,
                              size: 26,
                              color: i == index ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(_items[i].$2,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color:
                                    i == index ? Colors.white : Colors.black)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ============================================================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = s.user!;
    final width = MediaQuery.of(context).size.width;

    void close() => Navigator.pop(context);
    void tab(int i) {
      close();
      context.read<AppState>().setTab(i);
    }

    void push(Widget w) {
      close();
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    }

    return Drawer(
      width: width * .82 > 330 ? 330 : width * .82,
      backgroundColor: C.drawer,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(50))),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  tooltip: 'Close menu',
                  onPressed: close,
                  icon:
                      const Icon(Icons.close_rounded, color: Colors.white70))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              _Avatar(user: user, size: 68),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const Text('WELCOME',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(Icons.home_rounded, 'Dashboard',
                      selected: s.tab == 0, onTap: () => tab(0)),
                  _DrawerItem(Icons.sms_rounded, 'SMS Notification',
                      badge: user.unreadCount,
                      onTap: () => push(const NotificationsScreen())),
                  _DrawerItem(Icons.badge_rounded, 'Get My Card',
                      selected: s.tab == 1, onTap: () => tab(1)),
                  _DrawerItem(Icons.work_history_rounded, 'Appointment',
                      selected: s.tab == 3, onTap: () => tab(3)),
                  _DrawerItem(Icons.emergency_rounded, 'Emergency Request',
                      selected: s.tab == 2, onTap: () => tab(2)),
                  _DrawerItem(
                      Icons.volunteer_activism_rounded, 'Be a Blood Donor',
                      onTap: () => push(const DonorVerificationScreen())),
                  _DrawerItem(Icons.fact_check_rounded, 'My Requests',
                      onTap: () => push(const MyRequestsScreen())),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 8, 24, 28),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE0BCBC),
                foregroundColor: const Color(0xFFCC3030),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              onPressed: () async {
                final state = context.read<AppState>();
                final ok = await confirm(context,
                    title: 'Log out?',
                    message: 'You will need to log in again to use the app.',
                    yes: 'Log out');
                if (ok) await state.logout();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final int badge;
  const _DrawerItem(this.icon, this.label,
      {required this.onTap, this.selected = false, this.badge = 0});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? C.opacity(Colors.white, .14) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(children: [
                Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    child: Icon(icon, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800))),
              ]),
            ),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final AppUser user;
  final double size;
  const _Avatar({required this.user, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: C.avatar,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5)),
        child: Text(user.initials,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * .36,
                fontWeight: FontWeight.w800)),
      );
}

/// Exposed so the dashboard header can reuse the same avatar.
class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  const UserAvatar({super.key, required this.user, this.size = 64});
  @override
  Widget build(BuildContext context) => _Avatar(user: user, size: size);
}
