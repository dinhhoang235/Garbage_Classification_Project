import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'map_controller.dart';
import 'widgets/history_item_bottom_sheet.dart';
import 'widgets/map_controls.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/map_markers.dart';

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
  late MapScreenController _controller;
  String? _cachePath;

  @override
  void initState() {
    super.initState();
    _controller = MapScreenController(vsync: this);
    _initCache();
    _controller.loadAllHistoryMarkers();
    AppState().historyNotifier.addListener(_controller.onHistoryChanged);
    _controller.loadSearchHistory();

    if (widget.initialCenter != null) {
      _controller.currentPosition = widget.initialCenter;
      _controller.selectedPosition = widget.initialMarker;
      _controller.selectedLabel = widget.initialLabel;
      _controller.isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.animatedMapMove(widget.initialCenter!, 15.0);
      });
    } else {
      _controller.initLocation(_showError);
    }
  }

  Future<void> _initCache() async {
    final dir = await getTemporaryDirectory();
    setState(() => _cachePath = dir.path);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _controller.loadAllHistoryMarkers();
    }
    if (widget.initialCenter != oldWidget.initialCenter && widget.initialCenter != null) {
      _controller.selectedPosition = widget.initialMarker;
      _controller.selectedLabel = widget.initialLabel;
      _controller.showHistory = false;
      _controller.animatedMapMove(widget.initialCenter!, 18.0);
    }
  }

  @override
  void dispose() {
    AppState().historyNotifier.removeListener(_controller.onHistoryChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _controller.mapController,
                options: MapOptions(
                  initialCenter: _controller.currentPosition ?? const LatLng(10.762622, 106.660172),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dinhhoang235.ecosort',
                    tileProvider: _cachePath != null ? CachedTileProvider(store: FileCacheStore(_cachePath!)) : null,
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 15,
                      markers: _controller.allHistoryMarkers.map((item) => Marker(
                        point: LatLng(item.latitude!, item.longitude!),
                        width: 32,
                        height: 32,
                        child: CategoryMarker(
                          item: item,
                          onTap: () => HistoryItemBottomSheet.show(context, item),
                        ),
                      )).toList(),
                      builder: (context, markers) => _buildCluster(markers.length),
                    ),
                  ),
                  MarkerLayer(
                    markers: [
                      if (_controller.currentPosition != null)
                        Marker(point: _controller.currentPosition!, width: 60, height: 60, child: const CurrentLocationMarker()),
                      if (_controller.selectedPosition != null)
                        Marker(
                          point: _controller.selectedPosition!,
                          width: 200,
                          height: 150,
                          alignment: Alignment.center,
                          child: SelectedPositionMarker(
                            label: _controller.selectedLabel,
                            onClear: _controller.clearSelectedPosition,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (_controller.isLoading) _buildLoading(),
              MapSearchBar(
                controller: _controller.searchController,
                focusNode: _controller.searchFocus,
                isSearching: _controller.isSearching,
                showHistory: _controller.showHistory,
                searchResults: _controller.searchResults,
                searchHistory: _controller.searchHistory,
                onSearchChanged: _controller.onSearchChanged,
                onSelectPlace: _controller.selectPlace,
                onClearHistory: _controller.clearHistory,
                onRemoveHistoryItem: _controller.removeFromHistory,
                onMoveToPosition: _controller.animatedMapMove,
                selectedPosition: _controller.selectedPosition,
                onClearSearch: _controller.clearSelectedPosition,
              ),
              MapControls(
                mapController: _controller.mapController,
                onLocateMe: () => _controller.moveToCurrentLocation(() => _controller.initLocation(_showError)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCluster(int count) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.primary,
          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      );

  Widget _buildLoading() => const Center(
        child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
      );
}
