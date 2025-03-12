import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';

double calculatePolygonArea(List<LatLng> points) {
  if (points.length < 3) return 0.0; // At least 3 points needed for a polygon

  Geodesy geodesy = Geodesy();
  double totalArea = 0.0;

  for (int i = 0; i < points.length - 1; i++) {
    LatLng p1 = points[i];
    LatLng p2 = points[i + 1];

    double segmentArea =
        (p1.longitude * p2.latitude - p2.longitude * p1.latitude);
    totalArea += segmentArea;
  }

  // Close the polygon by adding the last edge
  LatLng first = points.first;
  LatLng last = points.last;
  totalArea +=
      (last.longitude * first.latitude - first.longitude * last.latitude);

  totalArea = totalArea.abs() / 2.0; // Shoelace formula
  totalArea *= 111319.9 * 111319.9; // Convert degrees² to meters²

  double areaInHectares = totalArea / 10000.0; // Convert to hectares
  return areaInHectares;
}
