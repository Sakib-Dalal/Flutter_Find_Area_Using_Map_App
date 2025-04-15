import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';

double calculatePolygonArea(List<LatLng> points) {
  if (points.length < 3) return 0.0;

  double area = 0.0;
  for (int i = 0; i < points.length; i++) {
    int j = (i + 1) % points.length;
    area += points[i].longitude * points[j].latitude;
    area -= points[j].longitude * points[i].latitude;
  }
  area = area.abs() / 2.0;
  return area * 111139 * 111139; // Approximate conversion to square meters
}
