# SMART-GO

**Goa's intelligent bus transportation companion.**

SMART-GO is the first deployment of the **SMART** transportation platform — a multi-region, multi-modal transit system built with Flutter.

## Features

- 🗺️ Real-time bus tracking on interactive maps
- 🚏 Route discovery with search and city filtering
- ⏱️ Live ETA predictions per stop
- 🔔 Smart proximity alerts (2 stops away, 1 stop away, arrived)
- ⭐ Favorites and recently viewed routes
- 📊 Route analytics and reliability dashboards
- 🌙 Dark mode support
- 📶 Low bandwidth mode for poor connectivity

## Architecture

```
SmartDeployment → DataSource → Repository → Riverpod Provider → UI
```

The platform is **deployment-aware**: all region-specific values (cities, map bounds, operator info) flow from a `SmartDeployment` configuration. The same codebase can be configured for future deployments:

- **SMART-GO** — Goa
- **SMART-KA** — Karnataka (future)
- **SMART-MH** — Maharashtra (future)

## Tech Stack

- **Flutter** + **Dart** — Cross-platform UI
- **Riverpod** — State management
- **GoRouter** — Navigation
- **flutter_map** + **OpenStreetMap** — Mapping
- **Dio** — HTTP client
- **Geolocator** — Device location

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── core/           # Platform core (models, providers, theme, navigation, widgets)
├── data/           # Data layer (models, sources, repositories, mock data)
├── features/       # Feature modules (home, routes, tracking, favorites, analytics, settings)
└── deployments/    # Deployment configs (smart_go/)
```
