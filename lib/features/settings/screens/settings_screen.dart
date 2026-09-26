import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// SMART-GO Settings & Preferences screen.
///
/// Fully audited, passenger-centric settings where every control:
/// 1. Performs a real action.
/// 2. Persists to SharedPreferences.
/// 3. Survives app restart.
/// 4. Directly drives active transit behavior across Home, Map, and Alerts.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _SettingsSliverAppBar(colorScheme: colorScheme),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // ── 1. PREFERENCES ─────────────────────────────────────────
                    _SectionHeader(
                      title: 'Preferences',
                      icon: Icons.tune_rounded,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsSelector(
                          title: 'Default City',
                          subtitle: settings.preferredCity,
                          icon: Icons.location_city_rounded,
                          colorScheme: colorScheme,
                          onTap: () => _showCityPicker(context),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsSelector(
                          title: 'Appearance',
                          subtitle: settings.themeMode.displayName,
                          icon: Icons.palette_outlined,
                          colorScheme: colorScheme,
                          onTap: () => _showThemePicker(context),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsSelector(
                          title: 'Distance Units',
                          subtitle: settings.distanceUnit.displayName,
                          icon: Icons.straighten_rounded,
                          colorScheme: colorScheme,
                          onTap: () => _showDistanceUnitPicker(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── 2. NOTIFICATIONS & ALERTS ──────────────────────────────
                    _SectionHeader(
                      title: 'Notifications',
                      icon: Icons.notifications_active_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsToggle(
                          title: 'Bus Arrival Alerts',
                          subtitle: 'Notifies when bus is 2 and 1 stop from your destination',
                          icon: Icons.directions_bus_outlined,
                          value: settings.busArrivalAlerts,
                          colorScheme: colorScheme,
                          onChanged: (value) {
                            if (settings.vibrationEnabled) HapticFeedback.selectionClick();
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setBusArrivalAlerts(value);
                          },
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsToggle(
                          title: 'Delay & Disruption Alerts',
                          subtitle: 'Notify when significant traffic or route slowdowns occur',
                          icon: Icons.warning_amber_rounded,
                          value: settings.delayAlerts,
                          colorScheme: colorScheme,
                          onChanged: (value) {
                            if (settings.vibrationEnabled) HapticFeedback.selectionClick();
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setDelayAlerts(value);
                          },
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsToggle(
                          title: 'Vibrate on Arrival',
                          subtitle: 'Haptic pulse when approaching your alight stop',
                          icon: Icons.vibration_rounded,
                          value: settings.vibrationEnabled,
                          colorScheme: colorScheme,
                          onChanged: (value) {
                            if (value) HapticFeedback.mediumImpact();
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setVibration(value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── 3. PERFORMANCE & SIMULATION ────────────────────────────
                    _SectionHeader(
                      title: 'Performance',
                      icon: Icons.speed_rounded,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsToggle(
                          title: 'Low Bandwidth Mode',
                          subtitle: 'Reduces map tile downloads and simplifies graphics',
                          icon: Icons.network_cell_outlined,
                          value: settings.lowBandwidthMode,
                          colorScheme: colorScheme,
                          onChanged: (value) {
                            if (settings.vibrationEnabled) HapticFeedback.selectionClick();
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setLowBandwidth(value);
                          },
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsToggle(
                          title: 'Live Telemetry Simulation',
                          subtitle: 'Simulate vehicle motion along verified route paths',
                          icon: Icons.sensors_rounded,
                          value: settings.demoSimulationEnabled,
                          colorScheme: colorScheme,
                          onChanged: (value) {
                            if (settings.vibrationEnabled) HapticFeedback.selectionClick();
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .setDemoSimulation(value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── 4. DATA & TRANSPARENCY ─────────────────────────────────
                    _SectionHeader(
                      title: 'Data & Transparency',
                      icon: Icons.verified_user_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsSelector(
                          title: 'Transit Data & Attribution',
                          subtitle: 'Govt of Goa GTFS • CC BY 4.0',
                          icon: Icons.menu_book_outlined,
                          colorScheme: colorScheme,
                          onTap: () => _showGtfsAttributionDialog(context),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsInfo(
                          title: 'Data Provenance',
                          subtitle: 'Verified Kadamba (KTCL) GTFS routes & stops',
                          icon: Icons.hub_outlined,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── 5. ABOUT ───────────────────────────────────────────────
                    _SectionHeader(
                      title: 'About',
                      icon: Icons.info_outline_rounded,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsInfo(
                          title: 'SMART-GO',
                          subtitle: 'Passenger Transit Intelligence for Goa',
                          icon: Icons.directions_bus_rounded,
                          colorScheme: colorScheme,
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsInfo(
                          title: 'Version',
                          subtitle: '1.0.0 (Build 1)',
                          icon: Icons.build_outlined,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── RESET BUTTON ───────────────────────────────────────────
                    Center(
                      child: TextButton.icon(
                        key: const ValueKey('reset-settings-button'),
                        onPressed: () => _showResetConfirmation(context),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Reset All Settings to Defaults'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    final cities = ['Panaji', 'Margao', 'Vasco', 'Miramar', 'Mapusa'];
    final currentCity = ref.read(settingsNotifierProvider).preferredCity;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerBottomSheet(
        title: 'Select Default City',
        options: cities,
        selectedOption: currentCity,
        colorScheme: colorScheme,
        onSelect: (city) {
          ref.read(settingsNotifierProvider.notifier).setPreferredCity(city);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final modes = AppThemeMode.values;
    final currentMode = ref.read(settingsNotifierProvider).themeMode;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerBottomSheet(
        title: 'Select Theme',
        options: modes.map((m) => m.displayName).toList(),
        selectedOption: currentMode.displayName,
        icons: const [
          Icons.brightness_auto_rounded,
          Icons.light_mode_rounded,
          Icons.dark_mode_rounded,
        ],
        colorScheme: colorScheme,
        onSelect: (name) {
          final mode = modes.firstWhere((m) => m.displayName == name);
          ref.read(settingsNotifierProvider.notifier).setThemeMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDistanceUnitPicker(BuildContext context) {
    final units = DistanceUnit.values;
    final currentUnit = ref.read(settingsNotifierProvider).distanceUnit;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerBottomSheet(
        title: 'Select Distance Unit',
        options: units.map((u) => u.displayName).toList(),
        selectedOption: currentUnit.displayName,
        icons: const [
          Icons.speed_rounded,
          Icons.navigation_outlined,
        ],
        colorScheme: colorScheme,
        onSelect: (name) {
          final unit = units.firstWhere((u) => u.displayName == name);
          ref.read(settingsNotifierProvider.notifier).setDistanceUnit(unit);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset your preferred city, appearance, alerts, and performance preferences to their defaults. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showGtfsAttributionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_bus_rounded, color: AppColors.primary),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Transit Data Attribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Official Transit Data Source',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Department of Transport, Government of Goa & Kadamba Transport Corporation Limited (KTCL).',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'License & Permissions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Published under Creative Commons Attribution 4.0 International (CC BY 4.0). Travel planning applications are explicitly invited to utilize this GTFS dataset for routes and schedules.',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'Provenance & Modifications',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                '• Official GTFS stops, sequences, and schedules provided by the Government of Goa.\n'
                '• Road-following geometry generated by SMART-GO via OpenStreetMap routing.\n'
                '• Real-time bus telemetry, speed, and occupancy are currently demonstrated via simulated telemetry and clearly marked.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─── Sliver App Bar ──────────────────────────────────────────────────────────

class _SettingsSliverAppBar extends StatelessWidget {
  const _SettingsSliverAppBar({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: AppSpacing.md, bottom: 16),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.colorScheme,
  });
  final String title;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Card ───────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.colorScheme, required this.children});
  final ColorScheme colorScheme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

// ─── Settings Toggle ──────────────────────────────────────────────────────────

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.colorScheme,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ColorScheme colorScheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Settings Selector ───────────────────────────────────────────────────────

class _SettingsSelector extends StatelessWidget {
  const _SettingsSelector({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings Info ───────────────────────────────────────────────────────────

class _SettingsInfo extends StatelessWidget {
  const _SettingsInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorScheme,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Divider ────────────────────────────────────────────────────────

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(
        height: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─── Picker Bottom Sheet ────────────────────────────────────────────────────

class _PickerBottomSheet extends StatelessWidget {
  const _PickerBottomSheet({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.colorScheme,
    required this.onSelect,
    this.icons,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final ColorScheme colorScheme;
  final ValueChanged<String> onSelect;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = option == selectedOption;
            return _PickerOption(
              title: option,
              isSelected: isSelected,
              icon: icons != null && index < icons!.length ? icons![index] : null,
              colorScheme: colorScheme,
              onTap: () => onSelect(option),
            );
          }),
          SizedBox(
              height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.title,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
    this.icon,
  });

  final String title;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
