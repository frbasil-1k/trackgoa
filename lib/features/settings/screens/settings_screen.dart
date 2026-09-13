import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// Phase 6.6 — Settings & Preferences screen.
///
/// Displays all app settings with premium animations and Cupertino-style toggles.
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
                      begin: const Offset(0, 0.05),
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
                          subtitle: 'Reduces map quality and animations',
                          icon: Icons.network_cell_outlined,
                          value: settings.lowBandwidthMode,
                          colorScheme: colorScheme,
                          onChanged: (value) => ref
                              .read(settingsNotifierProvider.notifier)
                              .setLowBandwidth(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(
                      title: 'Notifications',
                      icon: Icons.notifications_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SettingsCard(
                      colorScheme: colorScheme,
                      children: [
                        _SettingsToggle(
                          title: 'Bus Arrival Alerts',
                          subtitle: 'Get notified when your bus is arriving',
                          icon: Icons.directions_bus_outlined,
                          value: settings.busArrivalAlerts,
                          colorScheme: colorScheme,
                          onChanged: (value) => ref
                              .read(settingsNotifierProvider.notifier)
                              .setBusArrivalAlerts(value),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsToggle(
                          title: 'Delay Alerts',
                          subtitle: 'Get notified about significant delays',
                          icon: Icons.warning_amber_outlined,
                          value: settings.delayAlerts,
                          colorScheme: colorScheme,
                          onChanged: (value) => ref
                              .read(settingsNotifierProvider.notifier)
                              .setDelayAlerts(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                          title: 'Preferred City',
                          subtitle: settings.preferredCity,
                          icon: Icons.location_city_outlined,
                          colorScheme: colorScheme,
                          onTap: () => _showCityPicker(context),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsSelector(
                          title: 'Theme',
                          subtitle: settings.themeMode.displayName,
                          icon: Icons.palette_outlined,
                          colorScheme: colorScheme,
                          onTap: () => _showThemePicker(context),
                        ),
                        _SettingsDivider(colorScheme: colorScheme),
                        _SettingsToggle(
                          title: 'Demo Simulation',
                          subtitle: 'Enable simulated bus data for demo',
                          icon: Icons.science_outlined,
                          value: settings.demoSimulationEnabled,
                          colorScheme: colorScheme,
                          onChanged: (value) => ref
                              .read(settingsNotifierProvider.notifier)
                              .setDemoSimulation(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                          title: 'TrackGoa',
                          subtitle: 'Real-time bus tracking for Goa',
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
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showResetConfirmation(context),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Reset to Defaults'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
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
    final cities = ['Panaji', 'Margao', 'Vasco', 'Miramar'];
    final currentCity = ref.read(settingsNotifierProvider).preferredCity;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PickerBottomSheet(
        title: 'Select Preferred City',
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

    showModalBottomSheet(
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

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
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
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
        ),
      ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
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
                            fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
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
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
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
              icon: icons != null ? icons![index] : null,
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
