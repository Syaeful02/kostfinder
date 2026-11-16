import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_web/geolocator_web.dart';

enum LocationFailureType { serviceDisabled, denied, deniedForever }

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);
  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class DeviceLocationService {
  Future<Position> getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'GPS/lokasi perangkat tidak aktif. Nyalakan melalui Settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.denied,
        'Izin lokasi ditolak. Foto dan draft tetap dapat digunakan.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.deniedForever,
        'Izin lokasi ditolak permanen. Ubah di Settings aplikasi.',
      );
    }

    // Pengaturan berbeda untuk Web dan Mobile
    late LocationSettings locationSettings;
    if (kIsWeb) {
      locationSettings = WebSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }
}