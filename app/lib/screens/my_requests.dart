import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'donor_verification.dart';

/// One place to follow everything the user has submitted.
/// initialTab: 0 appointments, 1 blood requests, 2 cards, 3 donor verification.
class MyRequestsScreen extends StatelessWidget {
  final int initialTab;
  const MyRequestsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: redAppBar(
          context,
          'MY REQUESTS',
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'Appointments'),
              Tab(text: 'Blood'),
              Tab(text: 'Card'),
              Tab(text: 'Donor')
            ],
          ),
        ),
        body: TabBarView(children: [
          _ListTab<Appointment>(
            load: api.appointments,
            empty: const EmptyView(
                icon: Icons.event_busy_rounded,
                title: 'No appointments',
                message: 'Book one from the Appointment tab.'),
            tile: (a, reload) => AppointmentTile(a,
                onCancel: () => _cancel(context, 'Cancel appointment?',
                    () => api.cancelAppointment(a.id), reload)),
          ),
          _ListTab<BloodRequest>(
            load: api.bloodRequests,
            empty: const EmptyView(
                icon: Icons.bloodtype_rounded,
                title: 'No blood requests',
                message: 'Requests you submit will be tracked here.'),
            tile: (r, reload) => BloodRequestTile(r,
                onCancel: () => _cancel(context, 'Cancel this request?',
                    () => api.cancelBloodRequest(r.id), reload)),
          ),
          _ListTab<CardRequest>(
            load: api.cardRequests,
            empty: const EmptyView(
                icon: Icons.badge_outlined,
                title: 'No card requests',
                message: 'Pick a membership card from the Card tab.'),
            tile: (r, _) => CardRequestTile(r),
          ),
          _ListTab<DonorVerification>(
            load: () async {
              final v = await api.donorVerification();
              return v == null ? <DonorVerification>[] : [v];
            },
            empty: Builder(
              builder: (context) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const EmptyView(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Not a donor yet',
                        message:
                            'Verify your identity to join our donor community.'),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: C.deepRed),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DonorVerificationScreen())),
                      child: const Text('Be a Blood Donor'),
                    ),
                  ]),
                ),
              ),
            ),
            tile: (v, _) => VerificationTile(v),
          ),
        ]),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, String title,
      Future<void> Function() action, VoidCallback reload) async {
    final yes = await confirm(context,
        title: title,
        message: 'This cannot be undone.',
        yes: 'Yes, cancel',
        no: 'Keep');
    if (!yes || !context.mounted) return;
    final ok = await guard(context, () => action().then((_) => true));
    if (ok == true) {
      if (context.mounted) toast(context, 'Cancelled');
      reload();
    }
  }
}

class _ListTab<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final Widget empty;
  final Widget Function(T item, VoidCallback reload) tile;
  const _ListTab({required this.load, required this.empty, required this.tile});
  @override
  State<_ListTab<T>> createState() => _ListTabState<T>();
}

class _ListTabState<T> extends State<_ListTab<T>>
    with AutomaticKeepAliveClientMixin {
  late Future<List<T>> _f;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _f = widget.load();
  }

  void _reload() {
    final f = widget.load();
    setState(() {
      _f = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<T>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          final m = snap.error is ApiException
              ? (snap.error as ApiException).message
              : 'Could not load this list.';
          return ErrorRetry(message: m, onRetry: _reload);
        }
        final items = snap.data!;
        return RefreshIndicator(
          color: C.maroon,
          onRefresh: () async {
            _reload();
            try {
              await _f;
            } catch (_) {}
          },
          child: items.isEmpty
              ? ListView(children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height * .5,
                      child: widget.empty)
                ])
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [for (final i in items) widget.tile(i, _reload)],
                ),
        );
      },
    );
  }
}
