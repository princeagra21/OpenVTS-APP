part of 'open_vts_map_screen.dart';

class _AnimatedVehicleMarker {
  _AnimatedVehicleMarker({required this.position, required this.bearing});

  LatLng position;
  double? bearing;
  int token = 0;
  AnimationController? controller;
  Animation<LatLng>? animation;

  LatLng get currentPosition => animation?.value ?? position;

  int bumpToken() => ++token;

  void stopAndDisposeController() {
    controller?.stop();
    controller?.dispose();
    controller = null;
    animation = null;
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    final start = begin ?? end!;
    final finish = end ?? begin!;
    return LatLng(
      start.latitude + (finish.latitude - start.latitude) * t,
      start.longitude + (finish.longitude - start.longitude) * t,
    );
  }
}
