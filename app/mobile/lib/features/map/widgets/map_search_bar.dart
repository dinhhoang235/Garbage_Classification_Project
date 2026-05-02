import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final bool showHistory;
  final List<dynamic> searchResults;
  final List<Map<String, dynamic>> searchHistory;
  final Function(String) onSearchChanged;
  final Function(dynamic) onSelectPlace;
  final VoidCallback onClearHistory;
  final Function(int) onRemoveHistoryItem;
  final VoidCallback onClearSearch;
  final LatLng? selectedPosition;
  final Function(LatLng, double) onMoveToPosition;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.showHistory,
    required this.searchResults,
    required this.searchHistory,
    required this.onSearchChanged,
    required this.onSelectPlace,
    required this.onClearHistory,
    required this.onRemoveHistoryItem,
    required this.onClearSearch,
    this.selectedPosition,
    required this.onMoveToPosition,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                controller: controller,
                focusNode: focusNode,
                onChanged: onSearchChanged,
                onSubmitted: (_) {
                  if (selectedPosition != null) {
                    onMoveToPosition(selectedPosition!, 18.0);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: GestureDetector(
                    onTap: () {
                      if (selectedPosition != null) {
                        onMoveToPosition(selectedPosition!, 18.0);
                      }
                    },
                    child: isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.grey[400]),
                            ),
                          )
                        : Icon(Icons.search, color: Colors.grey[400]),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
                          ),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
              ),
            ),
            // Kết quả tìm kiếm
            if (!showHistory && searchResults.isNotEmpty)
              _buildResultsList(context),

            // Lịch sử tìm kiếm
            if (showHistory && searchHistory.isNotEmpty)
              _buildHistoryList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return ConstrainedBox(
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
            itemCount: searchResults.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final place = searchResults[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.place_outlined,
                      color: Colors.grey[600], size: 20),
                ),
                title: Text(
                  place['display_name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                onTap: () => onSelectPlace(place),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ConstrainedBox(
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
                    onPressed: onClearHistory,
                    child: Text('Xóa tất cả',
                        style: TextStyle(fontSize: 12, color: AppColors.red)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: searchHistory.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[50]),
                itemBuilder: (context, index) {
                  final item = searchHistory[index];
                  return ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.history, size: 20, color: Colors.grey),
                    title: Text(
                      item['display_name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () => onRemoveHistoryItem(index),
                    ),
                    onTap: () => onSelectPlace(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
