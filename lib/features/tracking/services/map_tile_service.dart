import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Service providing configured tile layers and caching hooks for FlutterMap.
abstract final class MapTileService {
  static const String openStreetMapUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackage = 'com.trackgoa.app';

  /// Standard OpenStreetMap tile layer with performance headers and subtle contrast tuning.
  static TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: openStreetMapUrl,
      userAgentPackageName: userAgentPackage,
      maxZoom: 19,
      tileProvider: NetworkTileProvider(
        headers: {
          'User-Agent': userAgentPackage,
          'Accept': 'image/webp,image/png,image/*;q=0.8',
        },
      ),
      tileBuilder: (context, widget, tile) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.04),
            BlendMode.lighten,
          ),
          child: widget,
        );
      },
    );
  }
}
