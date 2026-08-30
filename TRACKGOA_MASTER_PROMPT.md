# TrackGoa Master Prompt (Project Brain)

You are working on **TrackGoa**, a flagship portfolio-quality Flutter application for real-time public bus tracking in Goa, India.

This is **not** a beginner project.
Every implementation should feel production-ready, smooth, and premium.

---

# Project Goal

Build a Google Maps/Uber-quality transit app using Flutter.

The app should eventually provide:

* Live bus tracking
* Route visualization
* ETA prediction
* Stop notifications
* Route analytics
* Tourist-friendly navigation
* Low-bandwidth mode
* Backend-ready architecture

Everything should be scalable for future WebSocket and GPS integration.

---

# Tech Stack

Frontend:

* Flutter
* Dart
* Riverpod
* GoRouter
* flutter_map
* OpenStreetMap
* Dio
* Geolocator

Backend (future):

* Node.js
* Express
* PostgreSQL
* PostGIS
* WebSockets

AI workflow:

* ChatGPT → Project Manager
* Claude → Architecture
* Claude Code + OmniRoute → Senior Engineer
* Cursor → IDE

---

# Architecture Rules

Use feature-first architecture.

Never flatten folders.

Current structure:

lib/

* core/
* data/
* features/

Keep these boundaries.

## Data flow

DataSource
→ Repository
→ Riverpod Provider
→ UI

Never bypass repositories.

---

# Completed Phases

## Phase 1 ✅

* App foundation
* Theme system
* Navigation shell
* GoRouter setup

## Phase 2 ✅

* Data models
* Repository layer
* Mock Goa routes
* Data sources

## Phase 3 ✅

* Premium Home Screen
* Reusable widgets
* City chips
* Route cards
* Nearby buses section

Do not regress these phases.

---

# Roadmap

Phase 4

* Functional Routes experience
* Working search
* Working city filters
* Route selection

Phase 5

* Flutter Map integration
* Route polylines
* Stop markers

Phase 6

* Bus simulation
* Animated movement

Phase 7

* ETA engine

Phase 8

* Alerts
* Analytics
* Favorites
* Settings improvements

Phase 9

* Backend API

Phase 10

* Real-time WebSocket tracking

Never skip phases unless explicitly instructed.

---

# Design Rules

Style inspiration:

* Google Maps
* Uber
* Citymapper

Design principles:

* Mobile-first
* Glassmorphism
* Rounded corners
* Soft shadows
* Consistent spacing
* Smooth animations

Colors

Primary:

* Deep teal

Accent:

* Warm orange

Status colors:

* Green
* Amber
* Red

Do not randomly introduce new colors.

---

# Performance Rules

Very important.

Map architecture:

* Bus markers update independently.
* Polylines should not rebuild unnecessarily.
* Use Riverpod's `select()` when appropriate.
* Keep widgets small.

Avoid rebuilding entire screens for changing bus positions.

---

# Git Rules

Never commit.

Never push.

Never delete project structure.

Never rename architecture folders without explicit instruction.

Leave Git operations to the developer.

---

# Code Rules

Always:

* Follow existing naming conventions.
* Reuse shared widgets.
* Prefer composition over duplication.
* Keep files readable.
* Use const constructors where appropriate.
* Run `flutter analyze`.
* Run `flutter test`.

Do not leave analyzer warnings.

---

# Before Every Task

1. Read this file.
2. Preserve architecture.
3. Implement only the requested phase.
4. Do not redesign unrelated parts.
5. Finish with verification commands.

TrackGoa should always prioritize production-quality decisions over quick shortcuts.
