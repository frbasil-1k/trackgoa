# SMART-GO — Project Operating Manual

You are working on **SMART-GO**, the first deployment of the **SMART** transportation platform.
SMART-GO is a production-quality Flutter application for real-time bus tracking in Goa, India.

The architecture is **deployment-aware**: all Goa-specific values flow from `SmartDeployment`
configuration rather than being hard-coded. This enables future deployments (SMART-KA, SMART-MH).

---

## Architecture

```
DataSource → Repository → Riverpod Provider → UI
```

Region-specific values come from `SmartDeployment` (see `lib/deployments/smart_go/`).

Key directories:
- `lib/core/` — Platform-core models, providers, theme, navigation, shared widgets
- `lib/data/` — Data layer (models, sources, repositories)
- `lib/features/` — Feature modules (home, routes, tracking, favorites, analytics, settings)
- `lib/deployments/` — Deployment-specific configuration (smart_go)

---

## Design Direction

Style: Mobile-first, premium, glassmorphism, soft shadows, rounded corners, smooth animations.
Inspiration: Google Maps, Uber, Citymapper, Moovit.
Colors: Deep teal primary, warm amber accent, green/amber/red status.

---

## Code Rules

- Use `Vehicle` in architecture, "Bus" in UI for SMART-GO
- All region-specific values must come from `deploymentProvider`
- Never hard-code city names, region names, or operator names in feature code
- Use const constructors where appropriate
- Run `flutter analyze` — zero warnings
- Run `flutter test` — all tests pass
