import 'package:latlong2/latlong.dart';
import 'package:geodesy/geodesy.dart';

double calculatePolygonArea(List<LatLng> points) {
  if (points.length < 3) return 0.0;

  final geodesy = Geodesy();
  final closedPoints = List<LatLng>.from(points);

  // Close the polygon if not closed
  if (closedPoints.isNotEmpty && closedPoints.first != closedPoints.last) {
    closedPoints.add(closedPoints.first);
  }

  // Using correct method for version 0.10 - returns square meters
  double area = geodesy.calculatePolygonArea(closedPoints);
  return area.abs(); // Ensure positive value
}
