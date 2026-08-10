import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';

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
  late FlutterEarthGlobeController _controller;

  // 2 major states each of the 5 top countries:
  // India (IN), US (US), Russia (RU), China (CN), Brazil (BR)
  final List<String> _statesToHighlight = [
    'IN-MH', 'IN-UP',   // India (Maharashtra, Uttar Pradesh)
    'US-CA', 'US-TX',   // US (California, Texas)
    'RU-MOW', 'RU-MOS',  // Russia (Moscow Oblast, Moscow City)
    'CN-GS', 'CN-QH',   // China (Gansu, Qinghai)
    'BR-SP', 'BR-RJ',   // Brazil (Sao Paulo, Rio de Janeiro)
  ];

  @override
  void initState() {
    super.initState();

    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      isRotating: true,
      zoom: 0.6,
      showAtmosphere: false, // Disabled for performance
      background: const AssetImage('assets/2k_stars.jpg'), // Optimized stars background
      surface: const AssetImage('assets/2k_earth-day.jpg'),   // Optimized 2K earth texture
      nightSurface: const AssetImage('assets/2k_earth-night.jpg'),
      isDayNightCycleEnabled: false,
    );

    _loadBoundariesAndStyle();
  }

  Future<void> _loadBoundariesAndStyle() async {
    try {
      final assetBundle = DefaultAssetBundle.of(context);

      // 1. Load countries dataset (with thin opaque white outlines)
      final countriesJsonString = await assetBundle
          .loadString('assets/geo/countries_10m.geojson');
      final countriesGeojson = jsonDecode(countriesJsonString) as Map<String, dynamic>;

      _controller.loadRegionDataset(
        countriesGeojson,
        defaultBorderColor: Colors.white, // White, fully opaque outlines
        defaultBorderWidth: 0.5,          // Thin outlines
        defaultFillColor: Colors.transparent,
        defaultIsVisible: true,
        clipAgainstBuilder: (id) {
          // Pakistan and China clip against India to prevent overlap issues
          if (id.startsWith('PAK') || id.startsWith('CHN')) {
            return ['IND'];
          }
          return [];
        },
      );

      // 2. Load world states dataset (initially hidden using defaultIsVisible: false)
      final statesJsonString = await assetBundle
          .loadString('assets/geo/world_states.geojson');
      final statesGeojson = jsonDecode(statesJsonString) as Map<String, dynamic>;

      _controller.loadRegionDataset(
        statesGeojson,
        defaultBorderColor: Colors.orangeAccent,
        defaultBorderWidth: 1.2,
        defaultFillColor: Colors.deepOrange.withOpacity(0.4),
        defaultIsVisible: false, // Do not show any state outlines unless explicitly enabled
      );

      // Make only the 10 selected states visible on the globe
      _controller.showRegions(_statesToHighlight);

    } catch (e) {
      debugPrint('Error loading boundaries: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double radius = screenWidth < 500 ? ((screenWidth / 3.5) - 20) : 150;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FlutterEarthGlobe(
            controller: _controller,
            radius: radius,
          ),
        ),
      ),
    );
  }
}
