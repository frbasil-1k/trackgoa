import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/city_chip.dart';
import '../../../core/shared/widgets/primary_search_bar.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/route_list_providers.dart';

/// Header with search bar and city filter chips for the RouteListScreen.
class RouteListHeader extends ConsumerStatefulWidget {
  const RouteListHeader({super.key});

  @override
  ConsumerState<RouteListHeader> createState() => _RouteListHeaderState();
}

class _RouteListHeaderState extends ConsumerState<RouteListHeader> {
  static const _cities = ['All', 'Panaji', 'Margao', 'Vasco', 'Miramar'];
  bool _searchActive = false;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() => _searchActive = true);
    _focusNode.requestFocus();
  }

  void _deactivateSearch() {
    if (_searchController.text.isEmpty) {
      setState(() => _searchActive = false);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(
      routeFilterProvider.select((state) => state.selectedCity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searchActive
              ? TextField(
                  key: const ValueKey('search-field'),
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search routes, stops...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(routeFilterProvider.notifier).clearSearch();
                        _deactivateSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                  onChanged: (value) =>
                      ref.read(routeFilterProvider.notifier).setSearchQuery(
                            value,
                          ),
                  onSubmitted: (_) => _deactivateSearch(),
                )
              : PrimarySearchBar(
                  key: const ValueKey('search-bar'),
                  hintText: 'Search routes, stops...',
                  onTap: _activateSearch,
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final city = _cities[index];
              return CityChip(
                label: city,
                isSelected: selectedCity == city,
                onTap: () =>
                    ref.read(routeFilterProvider.notifier).setSelectedCity(
                          city,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}
