import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double officeLat = 9.0203;
  static const double officeLng = 7.4727;
  static const double allowedRadiusInMeters = 200.0;

  Future<String?> verifyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Enable GPS to clock in';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permissions are permanently denied, we cannot request permissions.';
    }

    final position = await Geolocator.getCurrentPosition();

    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      officeLat,
      officeLng,
    );

    if (distanceInMeters > allowedRadiusInMeters) {
      return 'You are not at the office';
    }

    return null;
  }
}
