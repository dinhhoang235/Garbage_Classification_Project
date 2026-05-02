import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/history_model.dart';

/// Global singleton app state.
/// Use [AppState()] anywhere to access the shared instance.
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);
  final ValueNotifier<List<HistoryItem>> historyNotifier = ValueNotifier<List<HistoryItem>>([]);

  User? get currentUser => userNotifier.value;
  List<HistoryItem> get history => historyNotifier.value;

  void setUser(User? user) {
    userNotifier.value = user;
  }

  void setHistory(List<HistoryItem> items) {
    // Gộp dữ liệu mới vào dữ liệu cũ, tránh trùng lặp dựa trên ID
    final currentItems = historyNotifier.value;
    final Map<int, HistoryItem> itemsMap = {for (var item in currentItems) item.id: item};
    
    for (var item in items) {
      itemsMap[item.id] = item;
    }
    
    final mergedList = itemsMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    historyNotifier.value = mergedList;
  }

  void addHistoryItem(HistoryItem item) {
    final currentItems = historyNotifier.value;
    // Kiểm tra xem item đã tồn tại chưa (đề phòng server trả về nhanh hơn logic local)
    if (currentItems.any((i) => i.id == item.id && i.id != 0)) return;
    
    final newList = List<HistoryItem>.from(currentItems);
    newList.insert(0, item);
    historyNotifier.value = newList;
  }

  void notifyHistoryUpdated() {
    // This can still be used if needed for other listeners
  }

  bool get isLoggedIn => userNotifier.value != null;
}
