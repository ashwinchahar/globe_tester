import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_earth_globe/misc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Globe Region Tester',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const GlobeTesterScreen(),
    );
  }
}

class GlobeTesterScreen extends StatefulWidget {
  const GlobeTesterScreen({super.key});

  @override
  State<GlobeTesterScreen> createState() => _GlobeTesterScreenState();
}

class _GlobeTesterScreenState extends State<GlobeTesterScreen> {
  late FlutterEarthGlobeController controller;
  bool isRotating = true;
  double rotationSpeed = 0.05;
  bool isDayNightEnabled = false;
  double dayNightBlend = 0.15;
  bool highlightsActive = false;
  int satelliteCount = 0;
  bool isCollapsed = false;

  String? _lastTappedRegion;
  String? _hoveredRegion;
  final Set<String> _selectedRegionIds = {};
  bool _styleTestActive = false;
  bool _regionsVisible = true;

  @override
  void initState() {
    super.initState();

    controller = FlutterEarthGlobeController(
      rotationSpeed: rotationSpeed,
      isRotating: isRotating,
      background: const AssetImage('assets/2k_stars.jpg'),
      surface: const AssetImage('assets/2k_earth-day.jpg'),
      nightSurface: const AssetImage('assets/2k_earth-night.jpg'),
      dayNightMode: DayNightMode.simulated,
    );

    // Wire up Region Tap hit-testing callback
    controller.onRegionTap = (region) {
      setState(() {
        _lastTappedRegion = '${region.name} (${region.id})';
        if (_selectedRegionIds.contains(region.id)) {
          _selectedRegionIds.remove(region.id);
        } else {
          _selectedRegionIds.add(region.id);
        }
        controller.selectRegions(_selectedRegionIds.toList());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tapped: ${region.name} (${region.id}) [${_selectedRegionIds.contains(region.id) ? "Selected" : "Deselected"}]',
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };

    // Wire up Region Hover hit-testing callback
    controller.onRegionHover = (region) {
      final name = '${region.name} (${region.id})';
      if (_hoveredRegion != name) {
        setState(() {
          _hoveredRegion = name;
        });
      }
    };

    // Define Delhi as Home
    final homeCoords = GlobeCoordinates(28.6139, 77.2090);
    controller.addPoint(
      Point(
        id: 'delhi',
        coordinates: homeCoords,
        label: 'Delhi (Home)',
        isLabelVisible: true,
        style: const PointStyle(
          color: Color(0xFFFFD700),
          size: 3.0,
        ),
      ),
    );

    // Top 10 cities of the world
    final top10Cities = [
      {'id': 'tokyo', 'name': 'Tokyo', 'coords': GlobeCoordinates(35.6762, 139.6503)},
      {'id': 'new_york', 'name': 'New York', 'coords': GlobeCoordinates(40.7128, -74.0060)},
      {'id': 'london', 'name': 'London', 'coords': GlobeCoordinates(51.5074, -0.1278)},
      {'id': 'paris', 'name': 'Paris', 'coords': GlobeCoordinates(48.8566, 2.3522)},
      {'id': 'sydney', 'name': 'Sydney', 'coords': GlobeCoordinates(-33.8688, 151.2093)},
      {'id': 'cairo', 'name': 'Cairo', 'coords': GlobeCoordinates(30.0444, 31.2357)},
      {'id': 'rio', 'name': 'Rio de Janeiro', 'coords': GlobeCoordinates(-22.9068, -43.1729)},
      {'id': 'dubai', 'name': 'Dubai', 'coords': GlobeCoordinates(25.2048, 55.2708)},
      {'id': 'cape_town', 'name': 'Cape Town', 'coords': GlobeCoordinates(-33.9249, 18.4241)},
      {'id': 'singapore', 'name': 'Singapore', 'coords': GlobeCoordinates(1.3521, 103.8198)},
    ];

    for (final city in top10Cities) {
      final cityId = city['id'] as String;
      final cityName = city['name'] as String;
      final cityCoords = city['coords'] as GlobeCoordinates;

      controller.addPoint(
        Point(
          id: cityId,
          coordinates: cityCoords,
          label: cityName,
          isLabelVisible: true,
          style: const PointStyle(
            color: Color(0xFFFFD700),
            size: 2.0,
          ),
        ),
      );

      controller.addPointConnection(
        PointConnection(
          id: 'delhi-$cityId',
          start: homeCoords,
          end: cityCoords,
          curveScale: 0.2,
          style: const PointConnectionStyle(
            type: PointConnectionType.dashed,
            color: Color(0xFFFFD700),
            lineWidth: 0.8,
            dashSize: 4.0,
            spacing: 5.0,
            animateOnAdd: true,
            growthAnimationDuration: 1500,
          ),
        ),
      );
    }

    _loadWorld();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          controller.focusOnCoordinates(
            GlobeCoordinates(28.6139, 77.2090),
            animate: true,
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  Future<void> _loadWorld() async {
    final countries = await GeoJsonRegionLoader.loadCountries();
    final states = await GeoJsonRegionLoader.loadStates();
    final worldStates = await GeoJsonRegionLoader.loadWorldStates();

    final List<GlobeRegion> finalRegions = [];

    // Load countries normally with country outlines
    for (final country in countries) {
      finalRegions.add(
        GlobeRegion(
          id: country.id,
          name: country.name,
          polygons: country.polygons,
          borderColor: country.borderColor,
          borderWidth: country.borderWidth,
          fillColor: country.fillColor ?? Colors.blue.withAlpha(20),
          highlightColor: country.highlightColor ?? Colors.amber.withAlpha(180),
          clipAgainst: country.clipAgainst,
        ),
      );
    }

    // Selected states of USA, Russia, and Brazil to highlight
    final highlightedUraStates = {
      'US-TX', 'US-CA', 'US-NY',
      'RU-MOW', 'RU-SPE', 'RU-MOS',
      'BR-SP', 'BR-RJ', 'BR-MG',
    };

    for (final state in worldStates) {
      final isHighlighted = highlightedUraStates.contains(state.id);
      if (isHighlighted) {
        finalRegions.add(
          GlobeRegion(
            id: state.id,
            name: state.name,
            polygons: state.polygons,
            borderColor: Colors.white,
            borderWidth: 1.2,
            fillColor: Colors.orange.withAlpha(100),
            highlightColor: Colors.orange.withAlpha(200),
          ),
        );
      } else {
        finalRegions.add(
          GlobeRegion(
            id: state.id,
            name: state.name,
            polygons: state.polygons,
            borderColor: Colors.transparent,
            borderWidth: 0.0,
            fillColor: null,
            highlightColor: null,
          ),
        );
      }
    }

    // India states to highlight
    final highlightedIndiaStates = {
      'IN-DL', 'IN-GA', 'IN-GJ', 'IN-KA', 'IN-MH',
    };

    for (final state in states) {
      final isHighlighted = highlightedIndiaStates.contains(state.id);
      if (isHighlighted) {
        finalRegions.add(
          GlobeRegion(
            id: state.id,
            name: state.name,
            polygons: state.polygons,
            borderColor: Colors.white,
            borderWidth: 1.5,
            fillColor: Colors.orange.withAlpha(100),
            highlightColor: Colors.orange.withAlpha(200),
          ),
        );
      } else {
        finalRegions.add(
          GlobeRegion(
            id: state.id,
            name: state.name,
            polygons: state.polygons,
            borderColor: Colors.transparent,
            borderWidth: 0.0,
            fillColor: null,
            highlightColor: null,
          ),
        );
      }
    }

    _selectedRegionIds.addAll([
      ...highlightedUraStates,
      ...highlightedIndiaStates,
    ]);
    controller.addRegions(finalRegions);
    controller.selectRegions(_selectedRegionIds.toList());
  }

  void _toggleRotation() {
    setState(() {
      isRotating = !isRotating;
      if (isRotating) {
        controller.startRotation(rotationSpeed: rotationSpeed);
      } else {
        controller.stopRotation();
      }
    });
  }

  void _updateRotationSpeed(double speed) {
    setState(() {
      rotationSpeed = speed;
      controller.rotationSpeed = speed;
      if (isRotating) {
        controller.startRotation(rotationSpeed: speed);
      }
    });
  }

  void _toggleDayNight() {
    setState(() {
      isDayNightEnabled = !isDayNightEnabled;
      controller.setDayNightCycleEnabled(isDayNightEnabled);
      if (isDayNightEnabled) {
        controller.startDayNightCycle(
          direction: DayNightCycleDirection.leftToRight,
        );
      } else {
        controller.stopDayNightCycle();
      }
    });
  }

  void _updateDayNightBlend(double blend) {
    setState(() {
      dayNightBlend = blend;
      controller.setDayNightBlendFactor(blend);
    });
  }

  void _toggleHighlights() {
    setState(() {
      highlightsActive = !highlightsActive;
      if (highlightsActive) {
        _selectedRegionIds.addAll([
          'US-TX', 'US-CA', 'US-NY',
          'RU-MOW', 'RU-SPE', 'RU-MOS',
          'BR-SP', 'BR-RJ', 'BR-MG',
          'IN-DL', 'IN-GA', 'IN-GJ', 'IN-KA', 'IN-MH',
        ]);
        controller.selectRegions(_selectedRegionIds.toList());
      } else {
        _selectedRegionIds.clear();
        controller.selectRegions([]);
      }
    });
  }

  void _testStyleUpdate() {
    setState(() {
      _styleTestActive = !_styleTestActive;
      // Dynamically modify India's style on the fly to test stationary repainting!
      controller.updateRegionStyle(
        'IND',
        borderColor: _styleTestActive ? Colors.greenAccent : Colors.white,
        borderWidth: _styleTestActive ? 2.5 : 0.8,
        fillColor: _styleTestActive ? Colors.green.withAlpha(140) : Colors.blue.withAlpha(20),
        highlightColor: Colors.amber.withAlpha(180),
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _styleTestActive
                ? 'Stationary Repaint Test: Updated IND to Green Accent'
                : 'Stationary Repaint Test: Reset IND style to Normal',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleRegionsVisibility() {
    setState(() {
      _regionsVisible = !_regionsVisible;
      final allIds = controller.regions.map((r) => r.id).toList();
      if (_regionsVisible) {
        controller.showRegions(allIds);
      } else {
        controller.hideRegions(allIds);
      }
    });
  }

  void _addSampleSatellite() {
    setState(() {
      satelliteCount++;
      controller.addSatellite(
        Satellite(
          id: 'sat_$satelliteCount',
          label: 'Satellite $satelliteCount',
          coordinates: GlobeCoordinates(
            (math.Random().nextDouble() * 120) - 60,
            (math.Random().nextDouble() * 360) - 180,
          ),
          style: const SatelliteStyle(
            color: Colors.cyanAccent,
            size: 6.0,
          ),
        ),
      );
    });
  }

  void _clearSatellites() {
    setState(() {
      for (int i = 1; i <= satelliteCount; i++) {
        controller.removeSatellite('sat_$i');
      }
      satelliteCount = 0;
    });
  }

  void _flyToCity(String name, double lat, double lon) {
    controller.focusOnCoordinates(
      GlobeCoordinates(lat, lon),
      animate: true,
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double radius = size.shortestSide * 0.35;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: FlutterEarthGlobe(
                controller: controller,
                radius: radius,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app, size: 14, color: Color(0xFFFFD700)),
                    const SizedBox(width: 6),
                    Text(
                      _lastTappedRegion != null
                          ? 'Tapped: $_lastTappedRegion'
                          : (_hoveredRegion != null ? 'Hover: $_hoveredRegion' : 'Tap any country/state to highlight'),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (_selectedRegionIds.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedRegionIds.length} selected',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12, width: 1.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Globe Prototype Control Deck',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            isCollapsed = !isCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!isCollapsed) ...[
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _toggleRotation,
                          icon: Icon(isRotating ? Icons.pause : Icons.play_arrow, size: 16),
                          label: Text(isRotating ? 'Pause' : 'Rotate', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 16),
                        const Text('Speed:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: rotationSpeed,
                            min: 0.0,
                            max: 0.2,
                            activeColor: const Color(0xFFFFD700),
                            inactiveColor: Colors.white10,
                            onChanged: _updateRotationSpeed,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Day/Night Cycle', style: TextStyle(color: Colors.white, fontSize: 12)),
                              value: isDayNightEnabled,
                              activeThumbColor: const Color(0xFFFFD700),
                              onChanged: (_) => _toggleDayNight(),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: highlightsActive ? const Color(0xFFFFD700).withAlpha(120) : Colors.white10,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: highlightsActive ? const Color(0xFFFFD700) : Colors.transparent,
                              ),
                            ),
                          ),
                          onPressed: _toggleHighlights,
                          child: const Text('Toggle Highlights', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _styleTestActive ? Colors.green.withAlpha(50) : Colors.white10,
                              foregroundColor: _styleTestActive ? Colors.greenAccent : Colors.white,
                              side: BorderSide(color: _styleTestActive ? Colors.greenAccent : Colors.transparent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onPressed: _testStyleUpdate,
                            icon: const Icon(Icons.palette, size: 14),
                            label: Text(
                              _styleTestActive ? 'Reset IND Style' : 'Test Style Repaint',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _regionsVisible ? Colors.white10 : Colors.red.withAlpha(40),
                              foregroundColor: _regionsVisible ? Colors.white : Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onPressed: _toggleRegionsVisibility,
                            icon: Icon(_regionsVisible ? Icons.visibility : Icons.visibility_off, size: 14),
                            label: Text(
                              _regionsVisible ? 'Hide Outlines' : 'Show Outlines',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isDayNightEnabled) ...[
                      Row(
                        children: [
                          const Text('Shadow Blend:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: dayNightBlend,
                              min: 0.01,
                              max: 1.0,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.white10,
                              onChanged: _updateDayNightBlend,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withAlpha(40),
                            foregroundColor: Colors.cyanAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _addSampleSatellite,
                          icon: const Icon(Icons.rocket_launch, size: 14),
                          label: Text('Add Orbiting Satellite ($satelliteCount)', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        if (satelliteCount > 0)
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.red.withAlpha(30)),
                            color: Colors.redAccent,
                            onPressed: _clearSatellites,
                            icon: const Icon(Icons.delete_sweep, size: 16),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Fly to:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 8),
                          _buildFlyButton('Delhi (Home)', 28.6139, 77.2090),
                          _buildFlyButton('New York', 40.7128, -74.0060),
                          _buildFlyButton('London', 51.5074, -0.1278),
                          _buildFlyButton('Tokyo', 35.6762, 139.6503),
                          _buildFlyButton('Sydney', -33.8688, 151.2093),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyButton(String label, double lat, double lon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: Colors.white10,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.all(4),
        label: Text(label),
        onPressed: () => _flyToCity(label, lat, lon),
      ),
    );
  }
}

class GeoJsonRegionLoader {
  static List<List<List<double>>> _parseFeaturePolygons(Map<String, dynamic> geometry) {
    final geometryType = geometry['type'] as String;
    final coordinates = geometry['coordinates'];
    final polygons = <List<List<double>>>[];

    if (geometryType == 'Polygon') {
      for (final ring in coordinates) {
        polygons.add(
          (ring as List)
              .map<List<double>>(
                (point) => [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
              )
              .toList(),
        );
      }
    } else if (geometryType == 'MultiPolygon') {
      for (final polygon in coordinates) {
        for (final ring in polygon) {
          polygons.add(
            (ring as List)
                .map<List<double>>(
                  (point) => [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
                )
                .toList(),
          );
        }
      }
    }
    return polygons;
  }

  static Future<List<GlobeRegion>> loadCountries({bool highRes = false}) async {
    final indiaRegion = await IndiaBorderResolver.resolveCorrectedIndia(_parseFeaturePolygons);
    String jsonString;
    try {
      jsonString = await rootBundle.loadString(
        highRes ? 'assets/geo/countries_10m.geojson' : 'assets/geo/countries.geojson',
      );
    } catch (_) {
      jsonString = await rootBundle.loadString('assets/geo/countries.geojson');
    }
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final features = data['features'] as List<dynamic>;
    final regions = <GlobeRegion>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;

      final name = properties['name'] as String?;
      final id = (properties['id'] ?? properties['iso_a3'] ?? properties['adm0_a3']) as String?;

      if (name == null || id == null) continue;
      if (id == 'IND' || id == 'IN') continue;

      final polygons = _parseFeaturePolygons(geometry);
      if (polygons.isEmpty) continue;

      final List<String> clipAgainst = [];
      if (id.startsWith('PAK') || id.startsWith('CHN') || id.startsWith('PK') || id.startsWith('CN')) {
        clipAgainst.addAll(['IND', 'IN']);
      }

      regions.add(
        GlobeRegion(
          id: id,
          name: name,
          polygons: polygons,
          borderColor: Colors.white.withAlpha(160),
          borderWidth: 0.8,
          fillColor: Colors.blue.withAlpha(20),
          highlightColor: Colors.amber.withAlpha(180),
          clipAgainst: clipAgainst,
        ),
      );
    }

    if (indiaRegion != null) {
      regions.add(indiaRegion);
    }
    return regions;
  }

  static Future<List<GlobeRegion>> loadStates() async {
    final jsonString = await rootBundle.loadString('assets/geo/india_states_10m.geojson');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final features = data['features'] as List<dynamic>;
    final regions = <GlobeRegion>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;

      final name = properties['name'] as String?;
      final id = properties['id'] as String?;

      if (name == null || id == null) continue;

      final polygons = _parseFeaturePolygons(geometry);
      if (polygons.isEmpty) continue;

      regions.add(
        GlobeRegion(
          id: id,
          name: name,
          polygons: polygons,
          borderColor: Colors.transparent,
          borderWidth: 0.0,
          fillColor: null,
          highlightColor: null,
        ),
      );
    }
    return regions;
  }

  static Future<List<GlobeRegion>> loadWorldStates() async {
    final jsonString = await rootBundle.loadString('assets/geo/world_states.geojson');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final features = data['features'] as List<dynamic>;
    final regions = <GlobeRegion>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;

      final name = (properties['name'] ?? properties['name_en'] ?? '').toString();
      final id = (properties['iso_3166_2'] ?? properties['adm1_code'] ?? '').toString();
      final countryCode = (properties['adm0_a3'] ?? properties['sr_adm0_a3'] ?? '').toString().toUpperCase();

      if (id.isEmpty) continue;

      final polygons = _parseFeaturePolygons(geometry);
      if (polygons.isEmpty) continue;

      regions.add(
        GlobeRegion(
          id: id,
          name: name,
          polygons: polygons,
          borderColor: Colors.transparent,
          borderWidth: 0.0,
          fillColor: null,
          highlightColor: null,
          clipAgainst: [countryCode],
        ),
      );
    }
    return regions;
  }
}

class IndiaBorderResolver {
  static Future<GlobeRegion?> resolveCorrectedIndia(
    List<List<List<double>>> Function(Map<String, dynamic> geometry) parsePolygons,
  ) async {
    try {
      final indiaJsonString = await rootBundle.loadString('assets/geo/countries_10m_india.geojson');
      final Map<String, dynamic> indiaData = jsonDecode(indiaJsonString);
      final indiaFeatures = indiaData['features'] as List<dynamic>;
      if (indiaFeatures.isNotEmpty) {
        final feature = indiaFeatures.first;
        final properties = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final name = properties['name'] as String? ?? 'India';
        final id = (properties['id'] ?? properties['iso_a3'] ?? 'IND') as String;
        final polygons = parsePolygons(geometry);
        if (polygons.isNotEmpty) {
          return GlobeRegion(
            id: id,
            name: name,
            polygons: polygons,
            borderColor: Colors.white,
            borderWidth: 0.8,
            fillColor: Colors.blue.withAlpha(20),
            highlightColor: Colors.amber.withAlpha(180),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading corrected India: $e');
    }
    return null;
  }
}
