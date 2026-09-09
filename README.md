# Globe Tester 🌍✨

An interactive playground, testbed, and showcase application built with Flutter to prototype, benchmark, and evaluate advanced features of the [flutter_earth_globe](https://github.com/Pana-g/flutter_earth_globe) 3D interactive globe library.

Originally built to prototype interactive globe experiences for **TripPal**, this repository serves as a standalone reference implementation demonstrating region boundaries, ray-casted hit-testing (tap & hover), dynamic styling, day/night cycles, orbital satellites, and flight camera transitions.

---

## ✨ Key Features

### 1. 🗺️ Interactive Region Boundaries & Fill Colors
- **Country Outlines**: Renders global national borders from GeoJSON (`countries.geojson`) with custom line widths and boundary colors.
- **State & Province Support**: Sub-national boundaries for India, the United States, Russia, and Brazil.
- **Accurate Border Resolution**: Resolves overlapping sovereign territorial boundaries (e.g., India's official boundaries via `countries_10m_india.geojson` using boundary clipping).
- **Custom Fill & Highlight Colors**: Renders translucent filled polygons and highlights selected regions in real time.

### 2. 🎯 Precision Ray-Casting & Hit-Testing
- **Tap Response (`onRegionTap`)**: Tap on any country or state across the sphere to inspect its name and ISO code, automatically toggling highlights.
- **Hover Detection (`onRegionHover`)**: Real-time pointer tracking on desktop and web, displaying hovered territories in the top HUD chip.
- **Ray-Sphere Geometry**: Screen coordinates are projected onto the spherical surface and evaluated against geographic polygon contours.

### 3. 🎨 Dynamic Style Updates & Cache Invalidation
- **Live Style Mutation**: Test the `updateRegionStyle()` API on stationary globes to verify that the GPU shader/path cache immediately invalidates and repaints via the controller's revision counter.
- **Visibility Toggling**: One-click show/hide for all region outlines via `showRegions()` and `hideRegions()`.

### 4. ☀️ Day/Night Cycle & 2K NASA Textures
- **Realistic Surfaces**: Bundled with 2K NASA day, night, and starfield textures (`2k_earth-day.jpg`, `2k_earth-night.jpg`, `2k_stars.jpg`).
- **Shader Blending**: Toggle between simulated darkness and texture-swap night modes, with real-time shadow blend factor controls.

### 5. 🚀 Orbital Satellites & Point Connections
- **Orbiting Satellites**: Dynamically spawn and clear orbital tracking bodies with custom coordinates, altitudes, and cyan trails.
- **Great-Circle Connections**: Smooth, animated dashed arcs (`PointConnection`) linking major global cities (Tokyo, New York, London, Paris, Sydney, Rio, Cairo, Dubai, Singapore) to home base (Delhi).

### 6. ✈️ Camera Flight Navigation
- Smooth cubic-eased flight transitions (`focusOnCoordinates()`) across the globe with shortest-path angular interpolation.
- Quick navigation buttons to jump to key global coordinates.

### 7. 🎛️ Glassmorphic Control Deck
- Floating, collapsible bottom control panel tailored for touch screens, mobile devices, and desktop viewports.

---

## 📂 Project Structure

```
globe_tester/
├── assets/
│   ├── 2k_earth-day.jpg          # 2K NASA surface texture
│   ├── 2k_earth-night.jpg        # 2K Earth lights night texture
│   ├── 2k_stars.jpg              # Milky way background stars
│   └── geo/
│       ├── countries.geojson     # Optimized 689 KB global countries dataset
│       ├── countries_10m.geojson # 10m high-res country dataset
│       ├── countries_10m_india.geojson # Accurate India territorial boundaries
│       ├── india_states_10m.geojson    # India state borders
│       └── world_states.geojson        # World administrative level-1 states
├── lib/
│   └── main.dart                 # Application entry point, control deck & GeoJSON loaders
├── test/
│   └── widget_test.dart          # Controller, region styling & hit-testing unit tests
└── pubspec.yaml                  # Asset declarations & package dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.0` or higher)
- Chrome / Edge (for Web), Windows Desktop C++ toolchain (for Windows), or Android/iOS emulator

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ashwinchahar/globe_tester.git
   cd globe_tester
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Launch the application**:
   - **On Web**:
     ```bash
     flutter run -d chrome
     ```
   - **On Windows Desktop**:
     ```bash
     flutter run -d windows
     ```
   - **On Mobile**:
     ```bash
     flutter run
     ```

---

## 🧪 Running Automated Tests

Run the test suite to verify region loading, styling operations, and hit-testing callbacks:

```bash
flutter test
```

To run code static analysis:

```bash
flutter analyze
```

---

## 🛠️ Built With
- **[Flutter](https://flutter.dev/)** - Cross-platform UI toolkit
- **[flutter_earth_globe](https://github.com/Pana-g/flutter_earth_globe)** - 3D Earth Globe widget and GPU shader engine
- **[Natural Earth](https://www.naturalearthdata.com/)** - Public domain map dataset for country and state boundaries
- **[NASA Visible Earth](https://visibleearth.nasa.gov/)** - Earth imagery and planetary textures

---

## 📄 License
This project is licensed under the MIT License.
