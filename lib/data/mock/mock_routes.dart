import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';
import '../models/stop_model.dart';

/// Static Phase 2 fixture data. Coordinates are approximate city locations.
final mockRoutes = <RouteModel>[
  RouteModel(
    id: 'r1',
    name: 'Panaji to Miramar',
    shortName: 'R1',
    origin: 'Panaji',
    destination: 'Miramar',
    estimatedTravelMinutes: 24,
    color: const Color(0xFF0B5D68),
    stops: const [
      StopModel(
        id: 'r1-panaji-market',
        name: 'Panaji Market',
        routeId: 'r1',
        order: 0,
        coordinates: LatLng(15.4989, 73.8278),
      ),
      StopModel(
        id: 'r1-azad-maidan',
        name: 'Azad Maidan',
        routeId: 'r1',
        order: 1,
        coordinates: LatLng(15.4972, 73.8264),
      ),
      StopModel(
        id: 'r1-st-inez',
        name: 'St. Inez',
        routeId: 'r1',
        order: 2,
        coordinates: LatLng(15.4918, 73.8177),
      ),
      StopModel(
        id: 'r1-campal',
        name: 'Campal',
        routeId: 'r1',
        order: 3,
        coordinates: LatLng(15.4902, 73.8129),
      ),
      StopModel(
        id: 'r1-miramar',
        name: 'Miramar Beach',
        routeId: 'r1',
        order: 4,
        coordinates: LatLng(15.4876, 73.8077),
      ),
    ],
    polylinePoints: const [
      LatLng(15.4989, 73.8278),
      LatLng(15.4972, 73.8264),
      LatLng(15.4918, 73.8177),
      LatLng(15.4902, 73.8129),
      LatLng(15.4876, 73.8077),
    ],
  ),
  RouteModel(
    id: 'r2',
    name: 'Margao to Fatorda',
    shortName: 'R2',
    origin: 'Margao',
    destination: 'Fatorda',
    estimatedTravelMinutes: 18,
    color: const Color(0xFFFF8A3D),
    stops: const [
      StopModel(
        id: 'r2-margao-bus-stand',
        name: 'Margao Bus Stand',
        routeId: 'r2',
        order: 0,
        coordinates: LatLng(15.2833, 73.9862),
      ),
      StopModel(
        id: 'r2-aquem',
        name: 'Aquem',
        routeId: 'r2',
        order: 1,
        coordinates: LatLng(15.2801, 73.9841),
      ),
      StopModel(
        id: 'r2-fatorda-church',
        name: 'Fatorda Church',
        routeId: 'r2',
        order: 2,
        coordinates: LatLng(15.2804, 73.9689),
      ),
      StopModel(
        id: 'r2-jawaharlal-nehru-stadium',
        name: 'Jawaharlal Nehru Stadium',
        routeId: 'r2',
        order: 3,
        coordinates: LatLng(15.2825, 73.9659),
      ),
    ],
    polylinePoints: const [
      LatLng(15.2833, 73.9862),
      LatLng(15.2801, 73.9841),
      LatLng(15.2804, 73.9689),
      LatLng(15.2825, 73.9659),
    ],
  ),
  RouteModel(
    id: 'r3',
    name: 'Vasco to Chicalim',
    shortName: 'R3',
    origin: 'Vasco',
    destination: 'Chicalim',
    estimatedTravelMinutes: 16,
    color: const Color(0xFF2E9E5B),
    stops: const [
      StopModel(
        id: 'r3-vasco-bus-stand',
        name: 'Vasco Bus Stand',
        routeId: 'r3',
        order: 0,
        coordinates: LatLng(15.3959, 73.8155),
      ),
      StopModel(
        id: 'r3-mangor-hill',
        name: 'Mangor Hill',
        routeId: 'r3',
        order: 1,
        coordinates: LatLng(15.3989, 73.8115),
      ),
      StopModel(
        id: 'r3-dabolim-junction',
        name: 'Dabolim Junction',
        routeId: 'r3',
        order: 2,
        coordinates: LatLng(15.3892, 73.8284),
      ),
      StopModel(
        id: 'r3-chicalim',
        name: 'Chicalim',
        routeId: 'r3',
        order: 3,
        coordinates: LatLng(15.3841, 73.8420),
      ),
    ],
    polylinePoints: const [
      LatLng(15.3959, 73.8155),
      LatLng(15.3989, 73.8115),
      LatLng(15.3892, 73.8284),
      LatLng(15.3841, 73.8420),
    ],
  ),
];
