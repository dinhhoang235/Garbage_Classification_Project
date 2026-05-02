import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/history_model.dart';
import '../../models/waste_category_model.dart';
import '../../core/services/category_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/user_service.dart';
import '../../core/state/app_state.dart';
import '../../core/services/notification_service.dart';
import 'widgets/home_header.dart';
import 'widgets/home_score_card.dart';
import 'widgets/home_guest_prompt.dart';
import 'widgets/home_scan_banner.dart';
import 'widgets/home_section_header.dart';
import 'widgets/home_category_grid.dart';
import 'widgets/home_recent_activity.dart';

class HomeScreen extends StatefulWidget {
  final User? currentUser;
  final VoidCallback? onLoginRequested;
  final VoidCallback? onScanRequested;
  final VoidCallback? onHistoryRequested;
  final Function(String)? onCategoryRequested;
  final Future<void> Function()? onNotificationRequested;
  final VoidCallback? onAchievementsRequested;

  const HomeScreen({
    super.key,
    this.currentUser,
    this.onLoginRequested,
    this.onScanRequested,
    this.onHistoryRequested,
    this.onCategoryRequested,
    this.onNotificationRequested,
    this.onAchievementsRequested,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WasteCategory> _categories = [];
  HistoryItem? _latestHistoryItem;
  int _unreadCount = 0;
  bool _isLoadingCategories = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadLatestHistory(),
      _refreshProfile(),
      _loadUnreadCount(),
    ]);
  }

  Future<void> _refreshProfile() async {
    if (!isLoggedIn) return;
    try {
      final user = await UserService().getProfile();
      if (user != null && mounted) {
        AppState().setUser(user);
      }
    } catch (e) {
      debugPrint('HomeScreen._refreshProfile error: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    if (!isLoggedIn) return;
    try {
      final count = await NotificationService().getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('HomeScreen._loadUnreadCount error: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadLatestHistory() async {
    if (!isLoggedIn) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    if (mounted) setState(() => _isLoadingHistory = true);

    try {
      final historyItems = await HistoryService()
          .getHistory(limit: 1)
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _latestHistoryItem = historyItems.isNotEmpty ? historyItems.first : null;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen._loadLatestHistory error: $e');
      if (mounted) {
        setState(() {
          _latestHistoryItem = null;
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser) {
      _loadLatestHistory();
      _loadUnreadCount();
    }
  }

  bool get isLoggedIn => widget.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  isLoggedIn: isLoggedIn,
                  currentUser: widget.currentUser,
                  unreadCount: _unreadCount,
                  onNotificationRequested: widget.onNotificationRequested,
                  onNotificationClosed: _loadUnreadCount,
                ),
                const SizedBox(height: 24),
                if (isLoggedIn) ...[
                  GestureDetector(
                    onTap: widget.onAchievementsRequested,
                    child: HomeScoreCard(user: widget.currentUser!),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  HomeGuestPrompt(onLoginRequested: widget.onLoginRequested),
                  const SizedBox(height: 24),
                ],
                HomeScanBanner(onScanRequested: widget.onScanRequested),
                const SizedBox(height: 24),
                HomeSectionHeader(
                  title: 'Danh mục rác',
                  action: 'Xem tất cả',
                  onPressed: () => widget.onCategoryRequested?.call('all'),
                ),
                const SizedBox(height: 16),
                HomeCategoryGrid(
                  categories: _categories,
                  isLoading: _isLoadingCategories,
                  onCategoryRequested: widget.onCategoryRequested,
                ),
                const SizedBox(height: 24),
                HomeSectionHeader(
                  title: 'Hoạt động gần đây',
                  action: 'Xem tất cả',
                  onPressed: widget.onHistoryRequested,
                ),
                const SizedBox(height: 16),
                HomeRecentActivity(
                  isLoading: _isLoadingHistory,
                  isLoggedIn: isLoggedIn,
                  latestHistoryItem: _latestHistoryItem,
                  onHistoryRequested: widget.onHistoryRequested,
                  onLoginRequested: widget.onLoginRequested,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
