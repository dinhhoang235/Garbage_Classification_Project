import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../core/services/map_service.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final LatLng? initialMarker;
  final String? initialLabel;
  final int? mapRequestId;

  const MapScreen({
    super.key,
    this.initialCenter,
    this.initialMarker,
    this.initialLabel,
    this.mapRequestId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final MapService _mapService = MapService();
  
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String? _selectedLabel;
  bool _isLoading = true;
  List<dynamic> _searchResults = [];
  List<Map<String, dynamic>> _searchHistory = [];
  bool _isSearching = false;
  bool _showHistory = false;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  // Animation controller for map movement
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;
    
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    
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
      }
    });

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
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
    // Nếu có vị trí mới truyền vào từ bên ngoài HOẶC mã yêu cầu thay đổi (để bắt lại vị trí cũ sau khi xóa)
    bool isNewLocation = widget.initialCenter != null && widget.initialCenter != oldWidget.initialCenter;
    bool isNewRequest = widget.mapRequestId != null && widget.mapRequestId != oldWidget.mapRequestId;

    if (isNewLocation || isNewRequest) {
      if (widget.initialCenter != null) {
        setState(() {
          _selectedPosition = widget.initialMarker;
          _selectedLabel = widget.initialLabel;
        });
        _animatedMapMove(widget.initialCenter!, 15.0);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
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
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final position = LatLng(lat, lon);
    
    _addToHistory(place); // Lưu vào lịch sử
    
    _animatedMapMove(position, 15.0); // Sử dụng hiệu ứng di chuyển mượt mà
    setState(() {
      _selectedPosition = position;
      _selectedLabel = place['display_name']; // Lưu nhãn địa chỉ để hiện cạnh Marker
      _searchResults = [];
      _searchController.text = place['display_name'];
      _showHistory = false;
    });
    FocusScope.of(context).unfocus();
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
                urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dinhhoang235.ecosort',
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
                      width: 280,
                      height: 60,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cái Ghim đỏ + Nút X xóa
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.location_on, color: AppColors.red, size: 30),
                              ),
                              // Nút X
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPosition = null;
                                      _selectedLabel = null;
                                      _searchController.clear(); // Xóa luôn text trong ô tìm kiếm
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
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
                          if (_selectedLabel != null)
                            SizedBox(
                              width: 220,
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(210), // Độ trong suốt vừa phải để vẫn đọc được chữ
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _selectedLabel!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm địa điểm...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                        prefixIcon: _isSearching 
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: 10, 
                                height: 10, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400])
                              ),
                            )
                          : Icon(Icons.search, color: Colors.grey[400]),
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
                                setState(() {
                                  _searchResults = [];
                                  _selectedPosition = null;
                                  _selectedLabel = null;
                                  _showHistory = _searchFocus.hasFocus;
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
                                    child: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: AppColors.red)),
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
