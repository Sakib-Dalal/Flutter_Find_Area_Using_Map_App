import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'area_calculator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> polygonPoints = [];
  double calculatedArea = 0.0;

  void _addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
      _updateArea();
    });
  }

  void _updateArea() {
    if (polygonPoints.length > 2) {
      calculatedArea = calculatePolygonArea(polygonPoints);
    } else {
      calculatedArea = 0.0;
    }
  }

  void _undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
        _updateArea();
      });
    }
  }

  void _resetPolygon() {
    setState(() {
      polygonPoints.clear();
      calculatedArea = 0.0;
    });
  }

  void _updatePoint(int index, LatLng newPoint) {
    setState(() {
      polygonPoints[index] = newPoint;
      _updateArea();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Farm Area Calculator')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(20.5937, 78.9629),
              initialZoom: 6.0,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: Colors.green.withOpacity(0.5),
                      borderStrokeWidth: 2,
                      borderColor: Colors.green,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: List.generate(polygonPoints.length, (index) {
                  return Marker(
                    point: polygonPoints[index],
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        LatLng newPoint = LatLng(
                          polygonPoints[index].latitude +
                              details.delta.dy * 0.0001,
                          polygonPoints[index].longitude +
                              details.delta.dx * 0.0001,
                        );
                        _updatePoint(index, newPoint);
                      },
                      child:
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  );
                }),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                if (calculatedArea > 0)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Text(
                      'Area: ${calculatedArea.toStringAsFixed(2)} m² (${(calculatedArea / 10000).toStringAsFixed(2)} hectares)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _undoLastPoint,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: Text('Undo'),
                    ),
                    ElevatedButton(
                      onPressed: _resetPolygon,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
