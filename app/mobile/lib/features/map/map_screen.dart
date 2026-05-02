import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../../core/state/app_state.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../core/services/map_service.dart';
import '../../core/services/history_service.dart';
import '../../models/history_model.dart';
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final LatLng? initialMarker;
  final String? initialLabel;
  final int? mapRequestId;
  final int? refreshKey;

  const MapScreen({
    super.key,
    this.initialCenter,
    this.initialMarker,
    this.initialLabel,
    this.mapRequestId,
    this.refreshKey,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapService _mapService = MapService();
  final HistoryService _historyService = HistoryService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String? _selectedLabel;
  bool _isLoading = true;
  List<dynamic> _searchResults = [];
  List<Map<String, dynamic>> _searchHistory = [];
  List<HistoryItem> _allHistoryMarkers = [];
  bool _isSearching = false;
  bool _showHistory = false;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  String? _cachePath;

  // Hiệu ứng "Fly-to" chuyên nghiệp (Zoom out -> Move -> Zoom in)
  void _flyTo(LatLng destLocation, double destZoom) async {
    if (!mounted) return;
    
    final currentZoom = _mapController.camera.zoom;
    final isFarAway = (_mapController.camera.center.latitude - destLocation.latitude).abs() > 0.01 || 
                     (_mapController.camera.center.longitude - destLocation.longitude).abs() > 0.01;

    if (isFarAway) {
      // Step 1: Zoom out nhẹ nếu ở xa
      final zoomOutTarget = (currentZoom - 1.5).clamp(5.0, 18.0);
      await _animatedMapMoveAction(destLocation, zoomOutTarget, 600);
      // Step 2: Zoom in lại vị trí đích
      await _animatedMapMoveAction(destLocation, destZoom, 800);
    } else {
      _animatedMapMoveAction(destLocation, destZoom, 1000);
    }
  }

  Future<void> _animatedMapMoveAction(LatLng destLocation, double destZoom, int durationMs) async {
    final completer = Completer<void>();
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: Duration(milliseconds: durationMs), vsync: this);
    
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        completer.complete();
      }
    });

    controller.forward();
    return completer.future;
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _flyTo(destLocation, destZoom);
  }

  @override
  void initState() {
    super.initState();
    _initCache();
    _loadAllHistoryMarkers();
    AppState().historyNotifier.addListener(_onHistoryChanged);
    _loadSearchHistory();
    _searchFocus.addListener(() {
      setState(() {
        _showHistory = _searchFocus.hasFocus && _searchController.text.isEmpty;
      });
    });
    if (widget.initialCenter != null) {
      _currentPosition = widget.initialCenter;
      _selectedPosition = widget.initialMarker;
      _selectedLabel = widget.initialLabel;
      _isLoading = false;
      // Di chuyển tới vị trí được chỉ định sau khi map controller sẵn sàng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMapMove(widget.initialCenter!, 15.0);
      });
    } else {
      _initLocation();
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('map_search_history');
    if (historyJson != null) {
      setState(() {
        _searchHistory = List<Map<String, dynamic>>.from(json.decode(historyJson));
      });
    }
  }

  Future<void> _addToHistory(dynamic place) async {
    final Map<String, dynamic> historyItem = {
      'display_name': place['display_name'],
      'lat': place['lat'],
      'lon': place['lon'],
    };

    // Xóa nếu đã tồn tại để đưa lên đầu
    _searchHistory.removeWhere((item) => item['display_name'] == historyItem['display_name']);
    _searchHistory.insert(0, historyItem);
    
    // Giới hạn 5 mục
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_search_history', json.encode(_searchHistory));
    setState(() {});
  }

  Future<void> _removeFromHistory(int index) async {
    setState(() {
      _searchHistory.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_search_history', json.encode(_searchHistory));
  }

  Future<void> _clearHistory() async {
    setState(() {
      _searchHistory = [];
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('map_search_history');
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Tự động tải lại ghim khi có yêu cầu làm mới
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadAllHistoryMarkers();
    }

    // Nếu có tọa độ khởi tạo mới từ MainScreen truyền vào
    if (widget.initialCenter != oldWidget.initialCenter && widget.initialCenter != null) {
      setState(() {
        _selectedPosition = widget.initialMarker;
        _selectedLabel = widget.initialLabel;
        _showHistory = false; // Đóng lịch sử tìm kiếm nếu đang mở
      });
      _animatedMapMove(widget.initialCenter!, 18.0);
    }
  }

  @override
  void dispose() {
    AppState().historyNotifier.removeListener(_onHistoryChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      setState(() {
        _allHistoryMarkers = AppState().history.where((item) => item.latitude != null && item.longitude != null).toList();
      });
    }
  }

  Future<void> _initCache() async {
    final dir = await getTemporaryDirectory();
    setState(() {
      _cachePath = dir.path;
    });
  }

  Future<void> _loadAllHistoryMarkers() async {
    // Hiển thị ngay những gì đang có trong AppState
    if (AppState().history.isNotEmpty) {
      _onHistoryChanged();
      // Nếu đã có đủ dữ liệu (ví dụ > 500 mục), có thể không cần tải thêm ngay
      if (AppState().history.length >= 500) return;
    }

    try {
      // Tải tối đa 1000 mục để hiện trên bản đồ
      final history = await _historyService.getHistory(limit: 1000);
      if (mounted) {
        AppState().setHistory(history); // Gộp vào kho chung
      }
    } catch (e) {
      debugPrint('MapScreen: Lỗi tải ghim lịch sử - $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await _mapService.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _animatedMapMove(_currentPosition!, 15.0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _showHistory = _searchFocus.hasFocus && query.isEmpty;
    });
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _mapService.searchPlaces(query, biasPosition: _currentPosition);
      if (!mounted) return;
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _selectPlace(dynamic place) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(place['lon'].toString()) ?? 0.0;
    final position = LatLng(lat, lon);
    
    _addToHistory(place); // Lưu vào lịch sử
    
    _flyTo(position, 18.0); // Sử dụng hiệu ứng bay
    setState(() {
      _selectedPosition = position;
      _selectedLabel = place['display_name']; 
      _searchResults = [];
      _searchController.text = place['display_name'];
      _showHistory = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _showHistoryItemDetails(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+15 XP',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Địa điểm quét',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.location ?? 'Không có địa chỉ',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMarker(HistoryItem item) {
    Color markerColor;
    IconData iconData;

    switch (item.categoryId.toLowerCase()) {
      case 'plastic':
      case 'nhựa':
        markerColor = Colors.orange;
        iconData = Icons.recycling;
        break;
      case 'paper':
      case 'giấy':
        markerColor = Colors.blue;
        iconData = Icons.description;
        break;
      case 'metal':
      case 'kim loại':
        markerColor = Colors.grey;
        iconData = Icons.build;
        break;
      case 'biological':
      case 'hữu cơ':
        markerColor = Colors.green;
        iconData = Icons.eco;
        break;
      default:
        markerColor = AppColors.primary;
        iconData = Icons.delete_outline;
    }

    return GestureDetector(
      onTap: () => _showHistoryItemDetails(item),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              iconData,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _animatedMapMove(_currentPosition!, _mapController.camera.zoom); // Sử dụng hiệu ứng di chuyển mượt mà
    } else {
      _initLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(10.762622, 106.660172), // Default to HCMC
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dinhhoang235.ecosort',
                tileProvider: _cachePath != null 
                    ? CachedTileProvider(
                        store: FileCacheStore(_cachePath!),
                      )
                    : null,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: _allHistoryMarkers.map((item) => Marker(
                    point: LatLng(item.latitude!, item.longitude!),
                    width: 32,
                    height: 32,
                    child: _buildCategoryMarker(item),
                  )).toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withAlpha(30),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedPosition != null)
                    Marker(
                      point: _selectedPosition!,
                      width: 200,
                      height: 150,
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Dùng Transform để đưa đầu nhọn của ghim về chính giữa tâm Marker
                          Transform.translate(
                            offset: const Offset(0, -20), // Dịch lên 20px (1/2 size icon) để đầu nhọn nằm đúng tâm
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Biểu tượng ghim
                                const Icon(Icons.location_on, color: AppColors.red, size: 40),
                                // Nút X gắn vào ghim
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPosition = null;
                                        _selectedLabel = null;
                                        _searchController.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(30),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.grey.withAlpha(40)),
                                      ),
                                      child: const Icon(Icons.close, size: 10, color: AppColors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Nhãn địa điểm - Nằm trên ghim
                          Positioned(
                            bottom: 125, // Tạo khoảng cách 10px so với đỉnh ghim (150-35+10)
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedLabel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(40),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      _selectedLabel!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              ),
            ),

          // Search Bar & Results
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) {
                        // Nếu đã có ghim được chọn, nhấn Enter sẽ đưa màn hình về ghim đó
                        if (_selectedPosition != null) {
                          _animatedMapMove(_selectedPosition!, 18.0);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm địa điểm...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                        prefixIcon: GestureDetector(
                          onTap: () {
                            if (_selectedPosition != null) {
                              _animatedMapMove(_selectedPosition!, 18.0);
                            }
                          },
                          child: _isSearching 
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 10, 
                                  height: 10, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400])
                                ),
                              )
                            : Icon(Icons.search, color: Colors.grey[400]),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.grey),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocus.requestFocus(); // Tự động focus lại vào ô search
                                setState(() {
                                  _searchResults = [];
                                  _selectedPosition = null;
                                  _selectedLabel = null;
                                  _showHistory = true; // Hiện lại lịch sử khi xóa sạch
                                });
                              },
                            )
                          : null,
                      ),
                    ),
                  ),
                  // Kết quả tìm kiếm (Chỉ hiện khi không hiện lịch sử và có kết quả)
                  if (!_showHistory && _searchResults.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.place_outlined, color: Colors.grey[600], size: 20),
                                ),
                                title: Text(
                                  place['display_name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                ),
                                onTap: () => _selectPlace(place),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // Lịch sử tìm kiếm
                  if (_showHistory && _searchHistory.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tìm kiếm gần đây',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _clearHistory,
                                    child: Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: AppColors.red)),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _searchHistory.length,
                                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[50]),
                                itemBuilder: (context, index) {
                                  final item = _searchHistory[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.history, size: 20, color: Colors.grey),
                                    title: Text(
                                      item['display_name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      onPressed: () => _removeFromHistory(index),
                                    ),
                                    onTap: () => _selectPlace(item),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Map Controls (Right side)
          Positioned(
            bottom: 30,
            right: 16,
            child: Column(
              children: [
                // Zoom group
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildControlButton(
                        icon: Icons.add,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      Divider(height: 1, color: Colors.grey[100], indent: 8, endIndent: 8),
                      _buildControlButton(
                        icon: Icons.remove,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Locate button
                GestureDetector(
                  onTap: _moveToCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.grey[700], size: 22),
        ),
      ),
    );
  }
}
