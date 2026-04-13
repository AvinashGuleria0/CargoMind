import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/shipment_model.dart';
import '../simulator/simulator_panel.dart';
import 'providers.dart';
import '../map/map_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeShipmentsAsync = ref.watch(activeShipmentsProvider);
    
    // Determine dynamic colors driven purely by the theme instance
    final borderColor = theme.dividerColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textMuted = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar (25% width) - Polished SaaS Look
          Container(
            width: 320, 
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Logo Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.hub_rounded, color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CARGOMIND AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Modern Light/Dark Mode Toggle
                      IconButton(
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggle();
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                          color: textMuted,
                        ),
                        splashRadius: 20,
                        hoverColor: colorScheme.primary.withOpacity(0.05),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Menu
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _SidebarItem(title: 'Active Fleet', icon: Icons.local_shipping_outlined, isActive: true),
                      SizedBox(height: 4),
                      _SidebarItem(title: 'Triage Logs', icon: Icons.receipt_long_outlined, isActive: false),
                      SizedBox(height: 4),
                      _SidebarItem(title: 'Market Prices', icon: Icons.candlestick_chart_outlined, isActive: false),
                      SizedBox(height: 4),
                      _SidebarItem(title: 'Settings', icon: Icons.settings_outlined, isActive: false),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _ActiveShipmentsSection(
                      activeShipmentsAsync: activeShipmentsAsync,
                    ),
                  ),
                ),
                
                // Bottom Telemetry Stats Box (Theme Dynamic)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.slate900 : AppTheme.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.5), blurRadius: 6)],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SYSTEM ONLINE',
                              style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GLOBAL TELEMETRY',
                          style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LAT: 28.7040\nLNG: 77.1025',
                          style: TextStyle(
                            fontFamily: theme.extension<ThemeStatsExtension>()?.monoFontFamily ?? 'monospace',
                            fontSize: 11,
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area (75% width)
          Expanded(
            child: Container(
              color: colorScheme.background,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: MapView(),
                  ),

                  // Simulator Panel
                  const Positioned(
                    bottom: 40,
                    right: 24,
                    child: SimulatorPanel(),
                  ),

                  // Floating Top-Right Agent Box
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'AI AGENT WATCHER: ACTIVE',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShipmentsSection extends StatelessWidget {
  final AsyncValue<List<ShipmentModel>> activeShipmentsAsync;

  const _ActiveShipmentsSection({
    required this.activeShipmentsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'Active Shipments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                activeShipmentsAsync.when(
                  data: (items) => Text(
                    '${items.length}',
                    style: theme.textTheme.labelMedium,
                  ),
                  loading: () => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error_outline, size: 14),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: activeShipmentsAsync.when(
              data: (shipments) {
                if (shipments.isEmpty) {
                  return Center(
                    child: Text(
                      'No active shipments',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: shipments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _ShipmentTile(shipment: shipments[index]);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Failed to load shipments',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentTile extends StatelessWidget {
  final ShipmentModel shipment;

  const _ShipmentTile({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    final statusColor = switch (shipment.status) {
      ShipmentStatus.onTrack => AppTheme.routeGreen,
      ShipmentStatus.critical => AppTheme.routeRed,
      ShipmentStatus.diverted => Colors.amber,
      ShipmentStatus.unknown => textMuted,
    };

    final title = shipment.telemetry.vehicleId.isEmpty
        ? shipment.id
        : shipment.telemetry.vehicleId;
    final subtitle = shipment.cargo.description.isEmpty
        ? shipment.cargo.type
        : shipment.cargo.description;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900.withOpacity(0.35) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  shipment.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            shipment.routeData.targetDestinationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: textMuted),
          ),
        ],
      ),
    );
  }
}

// Polished Sidebar Item reacting dynamically to Theme
class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final textMuted = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: isActive 
            ? (isDark ? AppTheme.slate700.withOpacity(0.4) : colorScheme.primary.withOpacity(0.08)) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          hoverColor: isDark ? AppTheme.slate700.withOpacity(0.2) : colorScheme.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? colorScheme.primary : textMuted,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? (isDark ? Colors.white : colorScheme.primary) : textMuted,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
