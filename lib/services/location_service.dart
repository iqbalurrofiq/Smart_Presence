import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // School coordinates (should be configurable in a real app)
  static const double schoolLatitude =
      -6.2088; // Jakarta coordinates as example
  static const double schoolLongitude = 106.8456;
  static const double allowedRadius = 100.0; // 100 meters

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Check if user is within school premises
  Future<bool> isWithinSchoolPremises() async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final distance = _calculateDistance(
      position.latitude,
      position.longitude,
      schoolLatitude,
      schoolLongitude,
    );

    return distance <= allowedRadius;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get distance from school in meters
  Future<double?> getDistanceFromSchool() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    return _calculateDistance(
      position.latitude,
      position.longitude,
      schoolLatitude,
      schoolLongitude,
    );
  }
}
