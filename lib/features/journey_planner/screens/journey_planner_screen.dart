import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/journey_location.dart';
import '../models/journey_option.dart';
import '../providers/journey_planner_providers.dart';
import '../widgets/journey_map_widget.dart';
import '../widgets/journey_option_card.dart';

/// Full-screen passenger journey planning and transfer navigation experience.
class JourneyPlannerScreen extends ConsumerStatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  ConsumerState<JourneyPlannerScreen> createState() => _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends ConsumerState<JourneyPlannerScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isSearchingDestination = false;
  bool _isSearchingOrigin = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Default origin text from provider
    final origin = ref.read(journeyOriginProvider);
    _originController.text = origin.name;
    final dest = ref.read(journeyDestinationProvider);
    if (dest != null) {
      _destinationController.text = dest.name;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(journeySearchQueryProvider.notifier).state = query;
      }
    });
  }

  void _swapOriginAndDestination() {
    final origin = ref.read(journeyOriginProvider);
    final destination = ref.read(journeyDestinationProvider);
    if (destination == null) return;

    ref.read(journeyOriginProvider.notifier).state = destination;
    ref.read(journeyDestinationProvider.notifier).state = origin;
    setState(() {
      _originController.text = destination.name;
      _destinationController.text = origin.name;
    });
  }

  void _selectDestination(JourneyLocation loc) {
    ref.read(journeyDestinationProvider.notifier).state = loc;
    setState(() {
      _destinationController.text = loc.name;
      _isSearchingDestination = false;
    });
    ref.read(journeySearchQueryProvider.notifier).state = '';
  }

  void _selectOrigin(JourneyLocation loc) {
    ref.read(journeyOriginProvider.notifier).state = loc;
    setState(() {
      _originController.text = loc.name;
      _isSearchingOrigin = false;
    });
    ref.read(journeySearchQueryProvider.notifier).state = '';
  }

  void _startLiveJourney(JourneyOption option) {
    final firstTransit = option.firstTransitLeg;
    if (firstTransit == null || firstTransit.route == null) return;

    // Initialize the active journey session
    ref.read(activeJourneySessionProvider.notifier).startJourney(option);

    // Navigate directly into tracking screen for the first leg
    context.push(RoutePaths.trackingFor(firstTransit.route!.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final origin = ref.watch(journeyOriginProvider);
    final destination = ref.watch(journeyDestinationProvider);
    final options = ref.watch(journeyOptionsProvider);
    final selectedOption = ref.watch(selectedJourneyOptionProvider) ??
        (options.isNotEmpty ? options.first : null);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Plan Your Journey',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Input Fields Card ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Dot-Line-Pin Indicator
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00897B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 38,
                        color: const Color(0xFFB0BEC5),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFFD32F2F),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Inputs
                  Expanded(
                    child: Column(
                      children: [
                        // FROM Input
                        TextField(
                          key: const ValueKey('journey-origin-input'),
                          controller: _originController,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            hintText: 'Choose starting point...',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            suffixIcon: origin.isCurrentLocation
                                ? Tooltip(
                                    message: 'Using GPS Current Location',
                                    child: Icon(Icons.my_location_rounded, size: 16, color: colorScheme.tertiary),
                                  )
                                : null,
                          ),
                          onTap: () {
                            setState(() {
                              _isSearchingOrigin = true;
                              _isSearchingDestination = false;
                            });
                          },
                          onChanged: _onSearchQueryChanged,
                        ),
                        const Divider(height: 1),

                        // TO Input
                        TextField(
                          key: const ValueKey('journey-destination-input'),
                          controller: _destinationController,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            hintText: 'Where to? (e.g. Deltin Royale, Fatorda...)',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                          ),
                          onTap: () {
                            setState(() {
                              _isSearchingDestination = true;
                              _isSearchingOrigin = false;
                            });
                          },
                          onChanged: _onSearchQueryChanged,
                        ),
                      ],
                    ),
                  ),

                  // Swap Button
                  IconButton(
                    tooltip: 'Swap origin and destination',
                    icon: Icon(Icons.swap_vert_rounded, color: colorScheme.onSurfaceVariant),
                    onPressed: destination != null ? _swapOriginAndDestination : null,
                  ),
                ],
              ),
            ),

            // ── Suggestions View (when active) OR Results View ──────────────
            Expanded(
              child: (_isSearchingOrigin || _isSearchingDestination)
                  ? _buildSearchResultsList()
                  : _buildJourneyResultsView(selectedOption, options),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    final colorScheme = Theme.of(context).colorScheme;
    final searchAsync = ref.watch(journeySearchResultsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Text(
              _isSearchingOrigin ? 'Select Origin' : 'Select Destination',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSearchingOrigin = false;
                  _isSearchingDestination = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        searchAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Resolving locations & transit stops...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  "Couldn't find that place.",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please check your spelling, choose a nearby stop, or select a popular hub.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ref.read(journeySearchQueryProvider.notifier).state = '';
                  },
                  child: const Text('Show Popular Hubs'),
                ),
              ],
            ),
          ),
          data: (results) {
            if (results.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(Icons.location_off_rounded, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      "Couldn't find that place.",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'No matching transit stop, landmark, or geocoded place was found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(journeySearchQueryProvider.notifier).state = '';
                      },
                      child: const Text('Show All Stops & Hubs'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: results.map((loc) {
                final iconBg = loc.isCurrentLocation
                    ? colorScheme.tertiary.withValues(alpha: 0.15)
                    : (loc.isVerifiedStop
                        ? colorScheme.tertiary.withValues(alpha: 0.12)
                        : (loc.isTransitHub
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : colorScheme.secondary.withValues(alpha: 0.12)));
                final iconFg = loc.isCurrentLocation
                    ? colorScheme.tertiary
                    : (loc.isVerifiedStop
                        ? colorScheme.tertiary
                        : (loc.isTransitHub
                            ? colorScheme.primary
                            : colorScheme.secondary));
                final badgeBg = loc.isVerifiedStop
                    ? colorScheme.tertiary.withValues(alpha: 0.12)
                    : (loc.isTransitHub
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : (loc.isLandmark
                            ? colorScheme.secondary.withValues(alpha: 0.12)
                            : colorScheme.surfaceContainerHighest));
                final badgeFg = loc.isVerifiedStop
                    ? colorScheme.tertiary
                    : (loc.isTransitHub
                        ? colorScheme.primary
                        : (loc.isLandmark
                            ? colorScheme.secondary
                            : colorScheme.onSurfaceVariant));
                return ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        loc.isCurrentLocation
                            ? Icons.my_location_rounded
                            : (loc.isVerifiedStop
                                ? Icons.directions_bus_rounded
                                : (loc.isTransitHub
                                    ? Icons.business_rounded
                                    : (loc.isLandmark
                                        ? Icons.account_balance_rounded
                                        : Icons.place_rounded))),
                        size: 20,
                        color: iconFg,
                      ),
                    ),
                  ),
                  title: Text(
                    loc.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    loc.address ?? loc.subtitle ?? '',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      loc.provenanceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (_isSearchingOrigin) {
                      _selectOrigin(loc);
                    } else {
                      _selectDestination(loc);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildJourneyResultsView(
    JourneyOption? selectedOption,
    List<JourneyOption> options,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = ref.watch(journeyDestinationProvider);

    if (destination == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 40,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Where are you headed?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Enter any destination, landmark, or place across Goa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick destination chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _quickDestChip('Fatorda'),
                  _quickDestChip('Margao'),
                  _quickDestChip('Panaji'),
                  _quickDestChip('Vasco'),
                  _quickDestChip('Mapusa'),
                  _quickDestChip('Deltin Royale'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (options.isEmpty) {
      final nearestStop = ref.watch(nearestTransitStopProvider);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_off_rounded, color: Color(0xFFC2410C), size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No nearby transit stop found',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF9A3412)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Destination "${destination.name}" was successfully located, but there are no verified SMART-GO bus stops within normal walking distance (1.4 km).',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7C2D12)),
                    ),
                    if (nearestStop != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus_rounded, size: 22, color: Color(0xFFC2410C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nearest available transit stop:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    nearestStop.stop.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '~${(nearestStop.walkingDistanceMeters / 1000).toStringAsFixed(1)} km away • Route ${nearestStop.route.shortName}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _selectDestination(
                              JourneyLocation(
                                name: nearestStop.stop.name,
                                subtitle: 'Nearest stop to ${destination.name}',
                                coordinate: nearestStop.stop.coordinates,
                                type: JourneyLocationType.verifiedStop,
                                stopId: nearestStop.stop.id,
                                routeId: nearestStop.route.id,
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_bus_rounded, size: 16),
                          label: Text('Plan to ${nearestStop.stop.name}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC2410C),
                            side: const BorderSide(color: Color(0xFFC2410C)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isSearchingDestination = true;
                  });
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search Another Place'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Destination Resolution Context Header
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Destination: ${destination.name} (${destination.provenanceLabel})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.tertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Interactive Journey Map preview of the selected journey
        if (selectedOption != null) ...[
          JourneyMapWidget(journey: selectedOption, height: 210),
          const SizedBox(height: AppSpacing.md),
        ],

        // Header
        Row(
          key: const ValueKey('journey-options-count-header'),
          children: [
            Text(
              '${options.length} Journey ${options.length == 1 ? 'Option' : 'Options'} Found',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16292D),
              ),
            ),
            const Spacer(),
            const Text(
              'Ranked by time',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Journey Option Cards
        ...options.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          final isSelected = selectedOption?.id == option.id;
          return JourneyOptionCard(
            key: ValueKey('journey-option-card-$i'),
            option: option,
            isSelected: isSelected,
            onSelect: () {
              ref.read(selectedJourneyOptionProvider.notifier).state = option;
            },
            onStartJourney: () => _startLiveJourney(option),
          );
        }),
      ],
    );
  }

  Widget _quickDestChip(String placeName) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(Icons.place_rounded, size: 14, color: colorScheme.primary),
      label: Text(
        placeName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
      ),
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outline),
      onPressed: () {
        // Find matching place
        final matches = JourneyLocation.prominentPlaces.where(
          (p) => p.name.toLowerCase().contains(placeName.toLowerCase()),
        );
        if (matches.isNotEmpty) {
          _selectDestination(matches.first);
        }
      },
    );
  }
}
