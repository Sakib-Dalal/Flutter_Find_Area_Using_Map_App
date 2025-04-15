import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'area_calculator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart' as lottie;

const double squareMetersToHectares = 0.0001;
const double hectaresToAcre = 2.47105381;
const double acreToGuntha = 40;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> polygonPoints = [];
  double areaInSquareMeters = 0.0;
  double areaInHectares = 0.0;
  double areaInAcre = 0.0;
  double areaInGunta = 0.0;
  final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');

  void _addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
      _updateArea();
    });
  }

  void _updateArea() {
    if (polygonPoints.length > 2) {
      final rawArea = calculatePolygonArea(polygonPoints);
      setState(() {
        areaInSquareMeters = rawArea;
        print(rawArea);
        areaInHectares = areaInSquareMeters * squareMetersToHectares;
        areaInAcre = areaInHectares * hectaresToAcre;
        areaInGunta = areaInAcre * acreToGuntha;
      });
    } else {
      setState(() {
        areaInSquareMeters = 0.0;
        areaInHectares = 0.0;
        areaInGunta = 0.0;
      });
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
      areaInSquareMeters = 0.0;
      areaInHectares = 0.0;
      areaInGunta = 0.0;
    });
  }

  void _updatePoint(int index, LatLng newPoint) {
    setState(() {
      polygonPoints = List.from(polygonPoints); // Create a new list
      polygonPoints[index] = newPoint;
      _updateArea();
    });
  }

  Map<String, dynamic>? cropPredictionValue;
  bool isLoading = false;

  Future<void> getCropYieldPrediction() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'https://3spgyg1t6c.execute-api.ap-south-1.amazonaws.com/predict_crop_yield');

    List<List<double>> polygonData = polygonPoints
        .map((point) => [point.longitude, point.latitude])
        .toList();

    print(polygonData);

    final body = {
      "polygon": polygonData,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cropPredictionValue = data;
        });
        print("✅ Crop Yield Prediction: $cropPredictionValue");
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildAreaCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Land Area',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800])),
            Divider(),
            _buildMeasurementRow('Hectares:', areaInHectares),
            _buildMeasurementRow('Acre:', areaInAcre),
            _buildMeasurementRow('Gunta:', areaInGunta),
            isLoading
                ? Center(
                    child: LoadingAnimationWidget.newtonCradle(
                      color: Colors.green,
                      size: 80,
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      await getCropYieldPrediction();
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0.0,
                                    20.0,
                                    0.0,
                                    0.0,
                                  ),
                                  child: Text(
                                    'Crop Yield Prediction in Tons',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                lottie.LottieBuilder.network(
                                    'https://lottie.host/5264e424-5d8a-4366-b970-8cce31deead9/ak0kjHWIsW.json'),
                                SizedBox(
                                  height: 40,
                                ),
                                Text(
                                  // 'Mean NDVI: ${cropPredictionValue?['mean_ndvi']?.toStringAsFixed(2) ?? 'N/A'}\n'
                                  'Yield (tons/ha): ${cropPredictionValue?['predicted_yield_tons_per_ha']?.toStringAsFixed(2) ?? 'N/A'}\n'
                                  'Yield (tons/acre): ${cropPredictionValue?['predicted_yield_tons_per_acre']?.toStringAsFixed(2) ?? 'N/A'}\n'
                                  'Yield (tons/guntha): ${cropPredictionValue?['predicted_yield_tons_per_gu']?.toStringAsFixed(4) ?? 'N/A'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 15),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Predict Crop Yield in Tons',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double value) {
    final formattedValue = _formatter.format(value);
    print(formattedValue);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ),
          Text(formattedValue,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.0)),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 40.0,
        title: Text(
          'farmo',
          style: GoogleFonts.robotoFlex(
            color: Color(0xff2EA667),
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // To ensure text visibility
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(15.5937, 75.9629),
              initialZoom: 5.5,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}",
                subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: 'com.farmo.app',
                maxZoom: 25,
              ),
              if (polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: Colors.green.withOpacity(0.3),
                      borderStrokeWidth: 2,
                      borderColor: Colors.green,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: List.generate(
                  polygonPoints.length,
                  (index) {
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
                        child: Icon(Icons.location_on,
                            color: Colors.green, size: 30),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 12,
            right: 12,
            child: Column(
              children: [
                if (areaInSquareMeters > 0) _buildAreaCard(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _undoLastPoint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.undo,
                            color: Colors.white,
                          ),
                          Text(
                            'Undo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _resetPolygon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                          Text(
                            'Reset',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
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
