import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api.dart';
import 'models.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// App-wide state: who is logged in, which bottom tab is active.
class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _waitingForOAuth = false;
  AppUser? user;
  bool booting = true;
  String? bootError; // set when a saved session could not be verified (offline)
  int tab = 0;

  AppState() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        user = null;
        notifyListeners();
      } else if (state.event == AuthChangeEvent.signedIn && _waitingForOAuth) {
        _waitingForOAuth = false;
        _completeOAuthSignIn();
      }
    });
  }

  Future<void> _completeOAuthSignIn() async {
    try {
      user = await api.me();
      bootError = null;
      tab = 0;
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      bootError = e.message;
    }
    notifyListeners();
  }

  Future<void> init() async {
    booting = true;
    bootError = null;
    notifyListeners();
    if (Supabase.instance.client.auth.currentSession != null) {
      try {
        user = await api.me();
      } on ApiException catch (e) {
        if (e.status == 401) {
          await api.logout();
        } else {
          bootError = e.message;
        }
      }
    }
    booting = false;
    notifyListeners();
  }

  Future<void> _start(AuthResult r) async {
    if (r.user == null) return;
    user = r.user;
    tab = 0;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async =>
      _start(await api.login(identifier, password));
  Future<void> loginWithGoogle() async {
    _waitingForOAuth = true;
    try {
      await api.loginWithGoogle();
    } on ApiException {
      _waitingForOAuth = false;
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async =>
      _start(await api.signup(name, email, password));

  Future<void> logout() async {
    await api.logout();
    user = null;
    tab = 0;
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      user = await api.me();
      notifyListeners();
    } on ApiException {
      // keep the cached user; screens show their own errors
    }
  }

  void setUnread(int n) {
    if (user == null) return;
    user = user!.withUnread(n);
    notifyListeners();
  }

  void setTab(int i) {
    if (tab == i) return;
    tab = i;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
