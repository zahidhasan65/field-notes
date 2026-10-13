import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/core.dart';
import 'permission_service.dart';

class GeoPoint {
  final double latitude;
  final double longitude;
  const GeoPoint(this.latitude, this.longitude);
}

class LocationService {
  LocationService(this._permissions);

  final PermissionService _permissions;

  /// Current GPS position, or null (a message was already shown).
  Future<GeoPoint?> getCurrent(BuildContext context) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (context.mounted) {
        snack(context, 'Turn on location services (GPS) and try again.');
      }
      return null;
    }

    if (!context.mounted) return null;
    if (!await _permissions.ensure(context, AppPermission.location)) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      if (context.mounted) snack(context, 'Could not get your location in time. Try again.');
    } catch (_) {
      if (context.mounted) snack(context, 'Could not read your location.');
    }
    return null;
  }
}
