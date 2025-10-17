// nearest_finder.dart
import 'package:geolocator/geolocator.dart';
import '../../../models/bank_site.dart';

Future<BankSite?> findNearest(List<BankSite> sites) async {
  // izin lokasi
  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return null;
  }
  if (perm == LocationPermission.deniedForever) return null;

  final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  final meLat = pos.latitude;
  final meLng = pos.longitude;

  BankSite? best;
  double bestDist = double.infinity;

  for (final s in sites) {
    final d = Geolocator.distanceBetween(meLat, meLng, s.lat, s.lng); // meter
    if (d < bestDist) {
      bestDist = d;
      best = s;
    }
  }
  return best;
}
