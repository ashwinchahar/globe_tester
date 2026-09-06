import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:globe_tester/main.dart';

void main() {
  testWidgets('MyApp instantiates and builds MaterialApp with dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final widget = const MyApp().build(context) as MaterialApp;
          expect(widget.title, 'Globe Region Tester');
          expect(widget.debugShowCheckedModeBanner, isFalse);
          return const SizedBox();
        },
      ),
    );
  });

  test('GlobeTester region loading, styling, and hit-test callbacks', () {
    final controller = FlutterEarthGlobeController();
    final region = GlobeRegion(
      id: 'IND',
      name: 'India',
      polygons: [
        [
          [77.0, 28.0],
          [78.0, 28.0],
          [78.0, 29.0],
          [77.0, 29.0],
          [77.0, 28.0],
        ]
      ],
      borderColor: Colors.white,
      borderWidth: 1.0,
      fillColor: Colors.blue.withAlpha(20),
      highlightColor: Colors.amber.withAlpha(180),
    );

    controller.addRegions([region]);
    expect(controller.regions.length, 1);
    expect(controller.regions.first.id, 'IND');
    expect(controller.regions.first.fillColor, Colors.blue.withAlpha(20));
    expect(controller.regions.first.highlightColor, Colors.amber.withAlpha(180));

    // Test selection
    controller.selectRegions(['IND']);
    expect(controller.selectedRegionIds.contains('IND'), isTrue);

    // Test dynamic style update and revision increment
    final initialRev = controller.regionRevision;
    controller.updateRegionStyle(
      'IND',
      borderColor: Colors.greenAccent,
      borderWidth: 2.0,
      fillColor: Colors.green.withAlpha(100),
    );
    expect(controller.regionRevision, greaterThan(initialRev));
    expect(controller.regions.first.borderColor, Colors.greenAccent);

    // Test show/hide regions
    controller.hideRegions(['IND']);
    expect(controller.regions.first.isVisible, isFalse);
    controller.showRegions(['IND']);
    expect(controller.regions.first.isVisible, isTrue);

    // Test onRegionTap callback
    GlobeRegion? tappedRegion;
    controller.onRegionTap = (r) => tappedRegion = r;
    controller.onRegionTap?.call(region);
    expect(tappedRegion?.id, 'IND');

    // Test onRegionHover callback
    GlobeRegion? hoveredRegion;
    controller.onRegionHover = (r) => hoveredRegion = r;
    controller.onRegionHover?.call(region);
    expect(hoveredRegion?.id, 'IND');
  });
}
