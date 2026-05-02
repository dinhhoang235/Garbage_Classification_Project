import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

/// Global singleton app state.
/// Use [AppState()] anywhere to access the shared instance.
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);
  final ValueNotifier<int> historyUpdateNotifier = ValueNotifier<int>(0);

  User? get currentUser => userNotifier.value;

  void setUser(User? user) {
    userNotifier.value = user;
  }

  void notifyHistoryUpdated() {
    historyUpdateNotifier.value++;
  }

  bool get isLoggedIn => userNotifier.value != null;
}
