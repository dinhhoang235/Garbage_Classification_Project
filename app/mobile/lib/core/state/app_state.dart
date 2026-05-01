import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

/// Global singleton app state.
/// Use [AppState()] anywhere to access the shared instance.
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);

  User? get currentUser => userNotifier.value;

  void setUser(User? user) {
    userNotifier.value = user;
  }

  bool get isLoggedIn => userNotifier.value != null;
}
