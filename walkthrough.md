# SMART-GO — Real Transit Data Reset & Evidence-Backed Network Rebuild

## Executive Summary
This document summarizes the complete data integrity reset and network rebuild executed on SMART-GO. Prior to this reset, the route dataset mixed authentic GTFS information with curated/renamed route concepts, generated data, cherry-picked stop subsets, and synthetic vehicle registrations.

Under the new evidence standard (`EVIDENCE > EXISTING CODE > NUMBER OF ROUTES > VISUAL REALISM`):
- All manually constructed route names, arbitrary stop subsets, and synthetic vehicle registrations were **DELETED**.
- The presentation network was **REBUILT** strictly from authoritative Government of Goa GTFS records, verified KTCL electric bus fleet registrations (Olectra K9 / Margao RTO), and OpenStreetMap road geometry generated directly across complete verified stop sequences.
- A comprehensive **Provenance Model** was created with evidence confidence levels (A through E).
- All 47 automated tests pass cleanly and `flutter analyze` reports zero warnings.

---

## Data Pipeline & Architecture

```
Government of Goa GTFS (routes.txt, trips.txt, stop_times.txt, stops.txt)
                             ↓
          scripts/preprocess_goa_gtfs.py (Offline Ingestion)
                             ↓
              OSRM Project Road Routing (OSM Roads)
                             ↓
          assets/data/goa_transit_data.json (Auditable Record)
                             ↓
     lib/data/gtfs/generated_goa_transit_data.dart (Strongly Typed Dart)
                             ↓
                 GoaGtfsRouteDataSource
                             ↓
                      RouteRepository
                             ↓
               BusSimulationEngine (Road-constrained)
                             ↓
                    Home UI & Tracking UI
```

---

## Flagship Verified Transit Network

| Route ID | Official Route Name | Direction / Headsign | Real Stops | Geometry Points | Fleet Asset |
|---|---|---|---|---|---|
| **R1** | Panaji Bus Stand To Panaji Bus Stand via TALEIGAO, DONA PAULA, CARANZALEM | PANAJI-Taleigao Church-Dona Paula Circle-PANAJI | 44 | 591 | GA-08-V-4965, GA-08-V-4980 (Olectra K9) |
| **B1** | Central Panaji City Route via Central Panaji City Route | PANAJI-18th June Road-Fontainhas-PANAJI | 33 | 489 | GA-08-V-5002 (Olectra K9) |
| **V1** | Panaji To Panaji via Patto Plaza, Portais, Kala Academy | PANAJI-Bhatlem Masjid-St. Inez Junction N-PANAJI | 23 | 329 | GA-08-V-5024 (Olectra K9) |
| **PNJ7** | PANAJI - MAPUSA | PANAJI-MAPUSA | 15 | 585 | GA-08-V-5055 (Olectra K9) |
| **MRG1** | MARGAO - PANAJI via CORTALIM | MARGAO-CORTALIM-PANAJI | 47 | 1416 | GA-08-V-5072 (Olectra K9) |
| **MRG11** | PANAJI - VASCO via CORTALIM | VASCO-CORTALIM-PANAJI | 37 | 1480 | GA-08-V-4980 (Olectra K9) |

---

## Evidence & Provenance Classification

Every transit entity and field is classified according to the SMART-GO standard:
- **Confidence A (Authoritative Direct Record)**:
  - Official GTFS Routes, Trips, Stop Sequences, Schedules (`https://goatransport.gov.in/GTFS`, CC BY 4.0)
  - KTCL Fleet Records & RTO Margao Commercial Registrations (Olectra K9 e-buses operated by Kadamba Transport Corporation / Evey Trans)
- **Confidence B (Strong Independent Evidence)**:
  - OpenStreetMap road-following geometry computed via Project OSRM connecting verified GTFS stop coordinates.
- **Confidence E (Inferred / Simulated Telemetry)**:
  - Live bus GPS positions, vehicle speed, and real-time crowding estimates are explicitly designated as simulated for demo presentation since no public GTFS-RT feed is published.

---

## Verification & Validation

1. **Static Analysis**: `flutter analyze` — 0 issues found.
2. **Automated Test Suite**: `flutter test` — 47/47 tests passed (covering provenance, route fidelity, trip-stop relationships, stop coordinate bounds, search, city filtering, vehicle intelligence, and simulated telemetry disclosures).
3. **Manual Route Inspections**:
   - `R1`: Complete 44-stop circular loop from Panaji Bus Stand through Miramar, Dona Paula Circle, Taleigao, and back.
   - `PNJ7`: Arterial express corridor connecting Panaji KTC Bus Stand to Mapusa KTC Bus Stand along NH 66.
   - `MRG1`: 47-stop regional backbone connecting Margao KTC Bus Stand to Panaji KTC Bus Stand across Zuari Bridge / Cortalim.
