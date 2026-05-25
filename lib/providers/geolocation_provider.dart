import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum GeoPermissionStatus { unknown, granted, denied, permanentlyDenied }

class GeoLocationState {
  final GeoPermissionStatus permissionStatus;
  final Position? position;
  final String? placeName;

  const GeoLocationState({
    this.permissionStatus = GeoPermissionStatus.unknown,
    this.position,
    this.placeName,
  });

  GeoLocationState copyWith({
    GeoPermissionStatus? permissionStatus,
    Position? position,
    String? placeName,
  }) {
    return GeoLocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      position: position ?? this.position,
      placeName: placeName ?? this.placeName,
    );
  }
}

class GeolocationNotifier extends StateNotifier<GeoLocationState> {
  GeolocationNotifier() : super(const GeoLocationState());

  /// Try to silently initialize location if permission was previously
  /// granted and location services are enabled. This won't prompt the user.
  Future<void> init() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        state = state.copyWith(
            permissionStatus: GeoPermissionStatus.granted, position: pos);
      }
    } catch (_) {
      // ignore silently; we'll fall back to explicit request flows
    }
  }

  Future<void> requestPermissionAndFetch() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(permissionStatus: GeoPermissionStatus.denied);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(permissionStatus: GeoPermissionStatus.denied);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
          permissionStatus: GeoPermissionStatus.permanentlyDenied);
      return;
    }

    // permission granted — use desiredAccuracy directly (geolocator 9.x API)
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    state = state.copyWith(
        permissionStatus: GeoPermissionStatus.granted, position: pos);
  }

  void clear() => state = const GeoLocationState();
}

final geolocationProvider =
    StateNotifierProvider<GeolocationNotifier, GeoLocationState>(
        (ref) => GeolocationNotifier());
