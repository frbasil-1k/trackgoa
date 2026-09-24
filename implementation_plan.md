# SMART-GO — Repository Takeover & Transformation Plan

---

## 1. My Understanding of SMART-GO

SMART-GO is a **production-quality passenger application for Goa's bus transportation network**. It is the first deployment of a broader **SMART transportation platform** that must be architecturally capable of supporting multiple regions (SMART-KA, SMART-MH, etc.), operators, and potentially other transportation modes — without hard-coding Goa-specific assumptions into the core platform.

**Core product goals:**
- Real-time bus tracking on a map with live positions
- Route discovery, search, and filtering
- ETA prediction per-stop, with smart proximity alerts
- Favorites and recently viewed routes
- Route analytics and reliability data
- Tourist-friendly, low-bandwidth capable
- Premium, modern mobile UX (Google Maps / Citymapper / Moovit quality)
- Architecture ready for real GPS backends (WebSocket, GTFS-RT, etc.)

---

## 2. Assessment of the Existing Codebase

### 2.1 What Actually Exists (Honest Functional Inventory)

| Area | State | Assessment |
|------|-------|------------|
| **Flutter project scaffold** | ✅ Working | Standard Flutter project, SDK ^3.13, all platform targets configured |
| **Navigation shell** | ✅ Working | GoRouter with StatefulShellRoute, 4 tabs: Home, Routes, Favorites, Settings |
| **Theme system** | ✅ Working | Light + dark themes, Material 3, curated teal/orange palette, spacing/typography tokens |
| **Data models** | ✅ Working | 11 immutable `@immutable` models with `copyWith`, equality, hashCode — well crafted |
| **Repository pattern** | ✅ Working | Clean DataSource → Repository → Provider → UI pipeline |
| **Mock route data** | ✅ Working | 3 real Goa routes (Panaji-Miramar, Margao-Fatorda, Vasco-Chicalim) with real OSRM polylines |
| **Home screen** | ✅ Working | Search bar, city chips, featured routes, nearby buses, favorites preview, bandwidth toggle |
| **Route list screen** | ✅ Working | Search + city filter, animated route cards with Hero transitions |
| **Tracking screen** | ✅ Working | Full-screen flutter_map, live bus markers, polyline overlay, route bottom sheet, ETA, stop progress |
| **Bus simulation engine** | ✅ Working | Polyline-following simulation, 2 buses per route, calibrated speed, periodic tick, looping |
| **ETA calculation** | ✅ Working | Distance-based ETA, stop progress states (passed/current/upcoming), route summary |
| **Live alerts** | ✅ Working | Threshold-based alerts (2 stops, 1 stop, arrived) with deduplication |
| **Polyline navigation** | ✅ Working | Haversine distance, bearing calc, polyline interpolation, length calculation |
| **Favorites** | ✅ Working | SharedPreferences-backed, toggle/recent/remove, synced across screens |
| **Settings** | ✅ Working | Theme mode, low bandwidth, alerts, preferred city, demo simulation toggle |
| **Analytics screen** | ✅ Working | ~39KB screen — fully built analytics dashboard with mock data |
| **Shared widgets** | ✅ Working | AppCard, CityChip, FavoriteIconButton, LiveBadge, PrimarySearchBar, RouteCard, SectionHeader, StatusPill |
| **Tests** | ⚠️ Partial | 6 test files covering data foundation, ETA, analytics, routes filter, OSRM tracking, and a widget test |
| **Polyline simplifier** | ✅ Working | Douglas-Peucker implementation for map rendering performance |
| **Map tile service** | ✅ Working | Centralized OSM tile URL configuration |

### 2.2 Code Quality Assessment

**Strengths:**
- **Clean architecture**: Genuine separation of concerns — DataSource/Repository/Provider/UI is consistently applied
- **Immutable models**: All 11 models are `@immutable` with proper equality — this is production-quality
- **Provider design**: Riverpod providers are well-structured with family providers, stream providers, and convenience selectors
- **Simulation engine**: Genuinely impressive — calibrated speed, polyline interpolation, broadcast streams, designed for WebSocket drop-in replacement
- **Theme system**: Proper design tokens (colors, spacing, typography), both light/dark themes, no ad-hoc values
- **Real geographic data**: OSRM-sourced polylines with real Goa road geometry, not random test data
- **Shared widget library**: Reusable, themeable widgets with consistent design language

**Weaknesses / Technical Debt:**
- **Goa hard-coded in UI**: "Explore Goa", "TrackGoa", "Move through Goa", city chips hard-coded as `['Panaji', 'Margao', 'Vasco', 'Miramar']`
- **No multi-tenancy/region concept**: No `Region`, `Network`, `Operator`, or `Deployment` model — everything assumes a single static dataset
- **No real data source**: All data comes from `mock_routes.dart` (23KB of hand-coded Dart constants). No JSON/API/GTFS parsing
- **Legacy Riverpod**: Uses `StateNotifier` (legacy) and `Provider`/`StateNotifierProvider` patterns instead of modern Riverpod 3 codegen (`@riverpod` annotation) or `Notifier`/`AsyncNotifier`
- **UI strings not localized**: All user-facing strings are hard-coded English
- **No GTFS support**: No support for General Transit Feed Specification, which is the industry standard for transit data
- **Mock analytics**: `MockAnalyticsRepository` returns hard-coded data — no real computation
- **Reliability percentages are fake**: `92 - (index * 3)` used throughout home and route screens
- **No trip planning**: No A→B journey planner
- **No schedule data**: No timetable/schedule model — only live tracking
- **Giant screen files**: `tracking_screen.dart` (849 lines), `settings_screen.dart` (25KB), `analytics_screen.dart` (39KB) — monolithic widgets that should be decomposed
- **`repository_providers.dart` is a god file**: 241 lines mixing providers, notifiers, and mock implementations — should be split
- **No error recovery**: Minimal error handling beyond basic `AsyncValue.error` display
- **No offline support**: No caching, no local database
- **No accessibility**: No semantic labels, no screen reader support
- **Tests are thin**: 6 test files, mostly unit tests for services — no widget tests for actual screens, no integration tests

### 2.3 What's Genuinely Reusable for SMART-GO

| Component | Reusability | Notes |
|-----------|-------------|-------|
| Data models (route, stop, bus, position, status, alert) | **High** — keep and extend | Need `regionId`/`networkId` fields added, otherwise structurally sound |
| Repository pattern | **High** — keep architecture | Pattern is correct; implementations need to be swapped for real data sources |
| Bus simulation engine | **High** — keep | Well-designed, already built for drop-in backend replacement |
| ETA calculation service | **High** — keep | Stateless, pure functions, works with any position data |
| Polyline navigation service | **High** — keep | Math is correct, transport-agnostic |
| Live alert service | **High** — keep | Clean event-driven alert system |
| Theme system | **Medium** — rebrand colors/tokens | Architecture is sound; needs SMART-GO branding |
| Shared widgets | **Medium** — keep and restyle | Widgets are well-composed but need rebrand |
| GoRouter shell | **Medium** — restructure tabs | Navigation pattern is good; tab structure may change |
| Tracking screen logic | **Medium** — extract from monolith | Map integration logic is good but trapped in an 849-line widget |
| Polyline simplifier | **High** — keep | Pure algorithm, no dependencies |
| Mock data | **Low** — replace with real data loading | Useful for development/demo only |
| Settings/Favorites repos | **Medium** — keep, will evolve | SharedPreferences repos are fine for now; will migrate to local DB |

### 2.4 Goa-Specific Assumptions That Must Be Abstracted

1. Hard-coded city list: `['Panaji', 'Margao', 'Vasco', 'Miramar']`
2. `preferredCity` defaults to `'Panaji'`
3. App title: `'TrackGoa'`
4. Tagline: `'Move through Goa with confidence.'`
5. Location label: `'Goa'`
6. 3 fixed routes in `mock_routes.dart`
7. No concept of a "network" or "region" — data is flat
8. `Section header: 'Explore Goa'`

---

## 3. Proposed Architecture

### 3.1 Multi-Tenancy Architecture: The `Deployment` Pattern

Rather than building a complex multi-tenant backend from day one, I propose a **deployment-aware architecture**:

```
┌──────────────────────────────────────────┐
│           SMART Platform Core            │
│  (Models, Services, Widgets, Providers)  │
│  ── region-agnostic, operator-agnostic ──│
└─────────────────┬────────────────────────┘
                  │
    ┌─────────────┼─────────────────┐
    │             │                 │
┌───▼───┐   ┌────▼────┐    ┌───────▼───────┐
│SMART-GO│   │SMART-KA │    │  SMART-MH     │
│(Goa)   │   │(Karnataka│    │  (Maharashtra)│
│Config  │   │ Config)  │    │  Config)      │
└────────┘   └─────────┘    └───────────────┘
```

**Key concepts:**

```dart
/// A deployment configuration — one per app variant
@immutable
class SmartDeployment {
  final String id;              // 'smart-go'
  final String displayName;     // 'SMART-GO'
  final String region;          // 'Goa'
  final String tagline;         // 'Move through Goa with confidence.'
  final LatLngBounds defaultBounds;
  final String defaultLocale;
  final SmartBranding branding; // colors, logo, theme seed
  final List<TransitNetwork> networks;
}

/// A transit network within a deployment
@immutable
class TransitNetwork {
  final String id;              // 'kadamba-transport'
  final String name;            // 'Kadamba Transport Corporation'
  final String operatorName;
  final TransitMode primaryMode; // TransitMode.bus
  final List<String> supportedModes;
}
```

**Why this approach:**
- **No unnecessary multi-tenant complexity today** — SMART-GO is the only deployment
- **No hard-coded Goa assumptions** — all region-specific values flow from configuration
- **Future deployments** just need a new `SmartDeployment` config + data source
- **Compile-time safety** — the deployment config is injected at app startup, not discovered at runtime

### 3.2 Proposed Folder Structure

```
lib/
├── main.dart                          # Entry point, injects SmartGoDeployment
├── app.dart                           # MaterialApp.router, deployment-aware
│
├── smart/                             # ═══ Platform core (region-agnostic) ═══
│   ├── models/                        # Domain models
│   │   ├── deployment.dart            # SmartDeployment, TransitNetwork
│   │   ├── route.dart                 # TransitRoute (renamed from RouteModel)
│   │   ├── stop.dart                  # TransitStop
│   │   ├── vehicle.dart               # Vehicle (renamed from BusModel)
│   │   ├── vehicle_position.dart      # VehiclePosition (renamed from BusPosition)
│   │   ├── vehicle_status.dart        # VehicleStatus (renamed from BusStatus)
│   │   ├── alert.dart                 # TransitAlert
│   │   ├── analytics.dart             # RouteAnalytics, TrendPoint, etc.
│   │   ├── favorites.dart             # FavoritesState
│   │   └── settings.dart              # AppSettingsState
│   │
│   ├── data/                          # Data layer
│   │   ├── sources/                   # Data source interfaces
│   │   │   ├── route_data_source.dart
│   │   │   ├── vehicle_data_source.dart
│   │   │   └── analytics_data_source.dart
│   │   ├── repositories/             # Repository implementations
│   │   │   ├── route_repository.dart
│   │   │   ├── vehicle_repository.dart
│   │   │   ├── analytics_repository.dart
│   │   │   ├── favorites_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── providers/                # Riverpod providers (split from god file)
│   │       ├── deployment_providers.dart
│   │       ├── route_providers.dart
│   │       ├── vehicle_providers.dart
│   │       ├── analytics_providers.dart
│   │       ├── favorites_providers.dart
│   │       └── settings_providers.dart
│   │
│   ├── services/                     # Business logic services
│   │   ├── simulation_engine.dart    # VehicleSimulationEngine
│   │   ├── eta_service.dart
│   │   ├── alert_service.dart
│   │   ├── polyline_service.dart
│   │   └── map_tile_service.dart
│   │
│   ├── theme/                        # Design system
│   │   ├── smart_theme.dart
│   │   ├── smart_colors.dart
│   │   ├── smart_spacing.dart
│   │   └── smart_typography.dart
│   │
│   ├── widgets/                      # Shared/reusable widgets
│   │   ├── transit_card.dart
│   │   ├── vehicle_marker.dart
│   │   ├── stop_marker.dart
│   │   ├── search_bar.dart
│   │   ├── status_pill.dart
│   │   ├── favorite_button.dart
│   │   └── ...
│   │
│   └── navigation/                   # Router
│       ├── app_router.dart
│       └── route_paths.dart
│
├── features/                         # ═══ Feature modules ═══
│   ├── home/
│   ├── routes/
│   ├── tracking/
│   ├── favorites/
│   ├── analytics/
│   └── settings/
│
└── deployments/                      # ═══ Deployment configs ═══
    └── smart_go/
        ├── smart_go_deployment.dart   # Goa-specific config
        ├── smart_go_branding.dart     # Goa colors/logo
        └── data/                     # Goa-specific data sources
            ├── goa_mock_data_source.dart
            └── goa_routes.json       # Move mock data to JSON
```

### 3.3 Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Framework** | Flutter (keep) | Already in use, good mobile perf, cross-platform |
| **State management** | Riverpod 3 (upgrade) | Keep Riverpod but migrate from legacy `StateNotifier` to modern `Notifier`/`AsyncNotifier` |
| **Navigation** | GoRouter (keep) | Working well, StatefulShellRoute is the right pattern |
| **Map** | flutter_map + OSM (keep) | Free tile usage, no API key required, works well |
| **HTTP** | Dio (keep) | Already configured, good interceptor pattern for future API |
| **Location** | Geolocator (keep) | Already working for user location |
| **Local storage** | SharedPreferences → Drift (later) | SharedPreferences is fine for settings/favorites; upgrade to Drift for offline route caching when needed |
| **Data format** | JSON → GTFS (future) | Move mock data to JSON files immediately; design data sources to accept GTFS feeds later |
| **Model serialization** | Manual → freezed (future consideration) | Current manual immutable models are clean; freezed adds code generation overhead — evaluate later |
| **Naming convention** | `Vehicle` not `Bus` | Supports future multi-modal (ferry, rickshaw, metro). The *UI* can say "Bus" for SMART-GO; the *architecture* uses `Vehicle` |

### 3.4 Alternatives Considered

**Alternative: Full multi-tenant server with region switching**
- Rejected: Enormous complexity for a single-deployment MVP. The deployment config pattern achieves the same extensibility without runtime overhead.

**Alternative: Replace Riverpod with Bloc**
- Rejected: Existing codebase is thoroughly built on Riverpod. Migration would be all-cost, no-benefit. Riverpod 3 with codegen is modern and capable.

**Alternative: Replace flutter_map with Google Maps**
- Rejected: Google Maps requires API keys and billing. OSM tiles are free. flutter_map is well-integrated and performant. Can always switch later via the `MapTileService` abstraction.

**Alternative: Replace Flutter with React Native / native**
- Rejected: Existing codebase has significant working Flutter code. Flutter's rendering engine is ideal for map-heavy transit apps with smooth animations.

---

## 4. Proposed Product & UX Direction

### 4.1 Branding

- **App name**: SMART-GO
- **Tagline**: "Navigate Goa, effortlessly." (or similar — your call)
- **Color palette**: Evolve from the existing teal/orange scheme. I propose keeping the teal primary (it's excellent for a transit app) but refreshing the palette:
  - Primary: Deep teal `#0B5D68` (keep — it's distinctive and professional)
  - Accent: Warm amber `#F59E0B` (slightly modernized from `#FF8A3D`)
  - Background: Soft blue-gray tones
  - Status: Green/Amber/Red (standard transit semantics)

### 4.2 App Structure (5 Tabs)

| Tab | Purpose | Changes from TrackGoa |
|-----|---------|----------------------|
| **Explore** (was Home) | Map-first experience with nearby routes, search, and quick access | More map-centric, less list-centric. The map is the hero, not a detail view |
| **Routes** | Browse and search all routes in the network | Keep and enhance with schedule/timetable data |
| **Track** *(new)* | Active tracking dashboard — currently tracking/recently tracked | Dedicated space for active journeys instead of pushing into a separate screen |
| **Saved** (was Favorites) | Saved routes, stops, and recent history | Combine favorites + recents in one organized view |
| **More** (was Settings) | Settings, about, feedback, help | Streamlined settings with deployment info |

> [!IMPORTANT]
> **Open question**: Do you want to keep a 4-tab layout (Home, Routes, Favorites, Settings) or move to the 5-tab layout above? The 5-tab layout better supports the "map-first" transit app experience but changes the existing navigation.

### 4.3 Key UX Principles

1. **Map-first**: The map should be the primary surface, not a detail screen you navigate into
2. **Live data prominence**: Live vehicle positions, ETAs, and status should be immediately visible, not hidden behind taps
3. **Zero-learning-curve**: A tourist landing in Goa should be able to find and track a bus within 10 seconds
4. **Progressive disclosure**: Simple for casual users, detailed for power users (analytics, stop-level ETA, reliability)
5. **Offline-aware**: Graceful degradation when connectivity is poor (cached routes, cached map tiles)

---

## 5. Proposed Implementation Roadmap

### Phase 0: Foundation Reset (1-2 days)
- [ ] Rename project: `trackgoa` → `smart_go` (pubspec, imports, Android/iOS configs)
- [ ] Introduce `SmartDeployment` and `SmartGoDeployment` config
- [ ] Restructure `lib/` to the new folder layout (`smart/`, `features/`, `deployments/`)
- [ ] Rename models: `BusModel` → `Vehicle`, `BusPosition` → `VehiclePosition`, `RouteModel` → `TransitRoute`, `StopModel` → `TransitStop`
- [ ] Split `repository_providers.dart` god file into focused provider files
- [ ] Replace hard-coded Goa strings with deployment-derived values
- [ ] Update all imports (systematic find-and-replace)
- [ ] Move mock data from Dart constants to JSON asset files
- [ ] Replace "TrackGoa" branding with "SMART-GO" throughout UI
- [ ] Verify all tests pass, `flutter analyze` clean

### Phase 1: Core Platform Hardening (2-3 days)
- [ ] Migrate legacy `StateNotifier` patterns to modern Riverpod `Notifier`/`AsyncNotifier`
- [ ] Decompose monolithic screens: split `tracking_screen.dart` (849 lines), `settings_screen.dart`, `analytics_screen.dart` into composable widgets
- [ ] Introduce proper error handling with retry logic
- [ ] Add loading skeletons/shimmer effects for async data
- [ ] Improve search: fuzzy matching, search by stop name, search by route number
- [ ] Connect Home screen's city filter + low bandwidth toggle to the global settings system (currently local state)

### Phase 2: Real Data Pipeline (3-4 days)
- [ ] Design and implement a `TransitDataLoader` that reads route/stop/schedule data from JSON asset files
- [ ] Research and integrate actual Goa KTC (Kadamba Transport Corporation) route data
- [ ] Build a GTFS-compatible data source interface (future-proofing)
- [ ] Implement route schedule/timetable model (first bus, last bus, frequency)
- [ ] Replace fake reliability percentages with computed/placeholder logic

### Phase 3: Map-First Experience (2-3 days)
- [ ] Redesign Home screen to be map-centric (map background with overlay cards)
- [ ] Show all active buses on the home map
- [ ] Tap-to-track from the map
- [ ] User location with "nearest routes" logic
- [ ] Map clustering for dense areas

### Phase 4: Production Polish (2-3 days)
- [ ] Accessibility audit (semantic labels, contrast ratios, screen reader)
- [ ] Add app icon and splash screen for SMART-GO branding
- [ ] Localization infrastructure (English, Hindi, Konkani placeholders)
- [ ] Performance profiling and optimization (especially map rendering)
- [ ] Comprehensive widget tests for all screens
- [ ] Integration test for core user journey

### Phase 5: Real Backend Preparation (3-5 days)
- [ ] Define API contract for route/vehicle/schedule endpoints
- [ ] Implement REST data source alongside mock data source
- [ ] WebSocket data source for live vehicle positions
- [ ] Offline caching with Drift/SQLite
- [ ] Push notification integration for alerts

---

## 6. Major Decisions Requiring Your Approval

### Decision 1: Project Rename
> [!IMPORTANT]
> Renaming `trackgoa` → `smart_go` throughout the project (package name, Android app ID, iOS bundle ID, import paths). This is a one-way door — git history will show the rename. **Proceed?**

### Decision 2: Model Renaming (Bus → Vehicle)
> [!IMPORTANT]
> Renaming `BusModel` → `Vehicle`, `BusPosition` → `VehiclePosition` etc. to support multi-modal future. The UI will still say "Bus" for SMART-GO — only the code-level abstractions become transport-agnostic. This touches every file in the project. **Proceed?**

### Decision 3: Navigation Structure
> [!IMPORTANT]
> Keep 4-tab layout (Home, Routes, Favorites, Settings) or move to 5-tab layout (Explore, Routes, Track, Saved, More)? I recommend the 4-tab for now and evolving it later. **Your preference?**

### Decision 4: Folder Restructure
> [!IMPORTANT]
> Moving from `lib/core/`, `lib/data/`, `lib/features/` to `lib/smart/`, `lib/features/`, `lib/deployments/`. This is a significant structural change but cleanly separates platform-core from deployment-specific code. **Approve the new structure, or prefer to keep `core/data/features` with modifications?**

### Decision 5: Mock Data → JSON Assets
> [!IMPORTANT]
> Moving the 23KB of Dart mock data (`mock_routes.dart`) into JSON asset files loaded at runtime. This is essential for eventually loading real data but changes how the development workflow feels (no more compile-time route data). **Proceed?**

### Decision 6: Riverpod Migration
> [!IMPORTANT]
> Migrating from legacy `StateNotifier`/`StateNotifierProvider` to modern `Notifier`/`AsyncNotifier`. This is best practice for Riverpod 3 but touches every provider and consumer in the app. **Proceed now, or defer until after the rename/restructure is stable?**

---

## 7. Risks and Concerns

### High Risk
| Risk | Impact | Mitigation |
|------|--------|------------|
| **Large rename/restructure may introduce subtle import bugs** | App won't compile | Do Phase 0 as a single atomic commit, test after every rename step |
| **No real Goa transit data available** | App ships with mock data only | Research KTC data sources; worst case, manually compile route data from official KTC website |
| **flutter_map performance with many vehicles** | UI jank on lower-end devices | Already have polyline simplifier; add marker clustering, throttled position updates |

### Medium Risk
| Risk | Impact | Mitigation |
|------|--------|------------|
| **Riverpod legacy→modern migration** | Temporary instability during migration | Can be done provider-by-provider, not all-at-once |
| **Scope creep** | Never ships | Phase 0–1 produce a rebrandable, improved version of what exists. Ship early. |
| **GTFS complexity** | Over-engineering for MVP | Don't build a full GTFS parser now; design data sources to *accept* GTFS-shaped data later |

### Low Risk
| Risk | Impact | Mitigation |
|------|--------|------------|
| **OSM tile changes/outages** | Map stops rendering | `MapTileService` already centralizes tile URLs; can swap providers |
| **Flutter version drift** | Build breaks on update | SDK constraint is `^3.13`, modern and stable |

---

## Summary

The existing TrackGoa codebase is **surprisingly well-built**. The architecture is clean, the data models are production-quality, and the simulation engine is genuinely impressive engineering. The main problems are:

1. **Goa is hard-coded everywhere** — needs deployment abstraction
2. **"Bus" is hard-coded everywhere** — needs vehicle abstraction  
3. **Data is all mock** — needs real data pipeline
4. **UI needs rebranding** — TrackGoa → SMART-GO
5. **Some code quality debt** — monolithic screens, legacy Riverpod patterns, god provider file

The transformation is very achievable because the *architecture patterns are already correct*. We're not rebuilding from scratch — we're lifting good engineering into a more extensible structure and rebranding it.

**Recommended starting point**: Phase 0 (Foundation Reset) — get the rename, restructure, and deployment config in place. Everything else builds on that foundation.
