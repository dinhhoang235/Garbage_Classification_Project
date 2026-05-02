import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/map_service.dart';
import '../../core/services/history_service.dart';
import '../../models/history_model.dart';
import '../../core/state/app_state.dart';

class MapScreenController extends ChangeNotifier {
  final MapService _mapService = MapService();
  final HistoryService _historyService = HistoryService();
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  
  LatLng? currentPosition;
  LatLng? selectedPosition;
  String? selectedLabel;
  bool isLoading = true;
  List<dynamic> searchResults = [];
  List<Map<String, dynamic>> searchHistory = [];
  List<HistoryItem> allHistoryMarkers = [];
  bool isSearching = false;
  bool showHistory = false;
  
  Timer? _debounce;
  final TickerProvider vsync;

  MapScreenController({required this.vsync}) {
    searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    showHistory = searchFocus.hasFocus && searchController.text.isEmpty;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onHistoryChanged() {
    allHistoryMarkers = AppState().history
        .where((item) => item.latitude != null && item.longitude != null)
        .toList();
    notifyListeners();
  }

  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('map_search_history');
    if (historyJson != null) {
      searchHistory = List<Map<String, dynamic>>.from(json.decode(historyJson));
      notifyListeners();
    }
  }

  Future<void> addToHistory(dynamic place) async {
    final Map<String, dynamic> historyItem = {
      'display_name': place['display_name'],
      'lat': place['lat'],
      'lon': place['lon'],
    };

    searchHistory.removeWhere((item) => item['display_name'] == historyItem['display_name']);
    searchHistory.insert(0, historyItem);
    
    if (searchHistory.length > 5) {
      searchHistory = searchHistory.sublist(0, 5);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_search_history', json.encode(searchHistory));
    notifyListeners();
  }

  Future<void> removeFromHistory(int index) async {
    searchHistory.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_search_history', json.encode(searchHistory));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    searchHistory = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('map_search_history');
    notifyListeners();
  }

  Future<void> loadAllHistoryMarkers() async {
    if (AppState().history.isNotEmpty) {
      onHistoryChanged();
      if (AppState().history.length >= 500) return;
    }

    try {
      final history = await _historyService.getHistory(limit: 1000);
      AppState().setHistory(history);
      onHistoryChanged();
    } catch (e) {
      debugPrint('MapScreen: Lỗi tải ghim lịch sử - $e');
    }
  }

  Future<void> initLocation(Function(String) onError) async {
    try {
      final position = await _mapService.getCurrentPosition();
      currentPosition = LatLng(position.latitude, position.longitude);
      isLoading = false;
      notifyListeners();
      animatedMapMove(currentPosition!, 15.0);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void onSearchChanged(String query) {
    showHistory = searchFocus.hasFocus && query.isEmpty;
    notifyListeners();
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        searchResults = [];
        notifyListeners();
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    isSearching = true;
    notifyListeners();
    try {
      final results = await _mapService.searchPlaces(query, biasPosition: currentPosition);
      searchResults = results;
      isSearching = false;
      notifyListeners();
    } catch (e) {
      isSearching = false;
      notifyListeners();
    }
  }

  void selectPlace(dynamic place) {
    final lat = double.tryParse(place['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(place['lon'].toString()) ?? 0.0;
    final position = LatLng(lat, lon);
    
    addToHistory(place);
    flyTo(position, 18.0);
    
    selectedPosition = position;
    selectedLabel = place['display_name']; 
    searchResults = [];
    searchController.text = place['display_name'];
    showHistory = false;
    searchFocus.unfocus();
    notifyListeners();
  }

  void clearSelectedPosition() {
    selectedPosition = null;
    selectedLabel = null;
    searchController.clear();
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    searchFocus.requestFocus();
    searchResults = [];
    selectedPosition = null;
    selectedLabel = null;
    showHistory = true;
    notifyListeners();
  }

  void moveToCurrentLocation(Function() onInitLocation) {
    if (currentPosition != null) {
      animatedMapMove(currentPosition!, mapController.camera.zoom); 
    } else {
      onInitLocation();
    }
  }

  // Animation logic
  void flyTo(LatLng destLocation, double destZoom) async {
    final currentZoom = mapController.camera.zoom;
    final isFarAway = (mapController.camera.center.latitude - destLocation.latitude).abs() > 0.01 || 
                     (mapController.camera.center.longitude - destLocation.longitude).abs() > 0.01;

    if (isFarAway) {
      final zoomOutTarget = (currentZoom - 1.5).clamp(5.0, 18.0);
      await _animatedMapMoveAction(destLocation, zoomOutTarget, 600);
      await _animatedMapMoveAction(destLocation, destZoom, 800);
    } else {
      _animatedMapMoveAction(destLocation, destZoom, 1000);
    }
  }

  Future<void> _animatedMapMoveAction(LatLng destLocation, double destZoom, int durationMs) async {
    final completer = Completer<void>();
    final latTween = Tween<double>(
        begin: mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: Duration(milliseconds: durationMs), vsync: vsync);
    
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
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

  void animatedMapMove(LatLng destLocation, double destZoom) {
    flyTo(destLocation, destZoom);
  }
}
