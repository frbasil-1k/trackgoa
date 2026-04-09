import { lineString, length, nearestPointOnLine, point, lineSlice } from '@turf/turf';

export interface Stop {
  id: string;
  name: string;
  touristName: string; // The name shown in tourist mode
  location: [number, number]; // [lat, lng]
  distanceKm: number; // calculated precise distance from route start
}

export interface Route {
  id: string;
  name: string;
  stops: Stop[];
  path: [number, number][]; // Dense points representing the road
  distanceKm: number;
  reliability: number; // 0-100 on-time %
}

export interface Bus {
  id: string;
  routeId: string;
  location: [number, number]; // current lat, lng
  alongDistance: number; // how far along the route in km
  speed: number; // km/h
  direction: 1 | -1; // 1 for forward, -1 for backward
  crowdLevel: 'Low' | 'Medium' | 'High';
  delay: number; // min
  status: 'Running' | 'Stopped';
  pausedCounter?: number; // How many ticks left to pause
}

const generatePath = (waypoints: [number, number][]): [number, number][] => {
  const path: [number, number][] = [];
  for (let i = 0; i < waypoints.length - 1; i++) {
    const start = waypoints[i];
    const end = waypoints[i+1];
    for (let j = 0; j < 10; j++) {
      const lat = start[0] + (end[0] - start[0]) * (j / 10);
      const lng = start[1] + (end[1] - start[1]) * (j / 10);
      path.push([lat, lng]);
    }
  }
  path.push(waypoints[waypoints.length - 1]);
  return path;
};

// Raw stops
const RAW_STOPS_R1 = [
  { id: 's1', name: 'Panaji KTC Bus Stand', touristName: 'Panaji City Center', location: [15.498, 73.827] as [number, number] },
  { id: 's2', name: 'Patto Center', touristName: 'Patto Business Hub', location: [15.495, 73.832] as [number, number] },
  { id: 's3', name: 'Caculo Mall (St Inez)', touristName: 'Shopping District', location: [15.487, 73.815] as [number, number] },
  { id: 's4', name: 'Miramar Circle', touristName: 'Miramar Beach 🏖️', location: [15.485, 73.805] as [number, number] },
];

const RAW_STOPS_R2 = [
  { id: 's5', name: 'Margao KTC Bus Stand', touristName: 'Margao Heritage', location: [15.273, 73.963] as [number, number] },
  { id: 's6', name: 'Ana Fonte Garden', touristName: 'Ana Fonte Park', location: [15.279, 73.960] as [number, number] },
  { id: 's7', name: 'Fatorda Stadium', touristName: 'Fatorda Sports Complex', location: [15.285, 73.955] as [number, number] },
];

const ROUTE_1_PATH = generatePath(RAW_STOPS_R1.map(s => s.location));
const ROUTE_2_PATH = generatePath(RAW_STOPS_R2.map(s => s.location));

const getGeoJSONLine = (path: [number, number][]) => lineString(path.map(p => [p[1], p[0]]));
const route1Line = getGeoJSONLine(ROUTE_1_PATH);
const route2Line = getGeoJSONLine(ROUTE_2_PATH);

const route1Length = length(route1Line, { units: 'kilometers' });
const route2Length = length(route2Line, { units: 'kilometers' });

// Function to calculate exact distance of stop from route start
const mapStopsWithDistances = (stops: any[], line: any): Stop[] => {
  const startPt = point(line.geometry.coordinates[0]);
  return stops.map(s => {
    const stopPt = point([s.location[1], s.location[0]]); // [lng, lat]
    const snapped = nearestPointOnLine(line, stopPt);
    const slice = lineSlice(startPt, snapped, line);
    const dist = length(slice, { units: 'kilometers' });
    return { ...s, distanceKm: dist };
  });
};

export const STOPS_ROUTE_1 = mapStopsWithDistances(RAW_STOPS_R1, route1Line);
export const STOPS_ROUTE_2 = mapStopsWithDistances(RAW_STOPS_R2, route2Line);

export const MOCK_ROUTES: Route[] = [
  {
    id: 'r1',
    name: 'Panaji - Miramar',
    stops: STOPS_ROUTE_1,
    path: ROUTE_1_PATH,
    distanceKm: route1Length,
    reliability: 92
  },
  {
    id: 'r2',
    name: 'Margao - Fatorda',
    stops: STOPS_ROUTE_2,
    path: ROUTE_2_PATH,
    distanceKm: route2Length,
    reliability: 78
  }
];

export const INITIAL_BUSES: Bus[] = [
  { id: 'b1', routeId: 'r1', location: ROUTE_1_PATH[2], alongDistance: 0.5, speed: 30, direction: 1, crowdLevel: 'Medium', delay: 0, status: 'Running' },
  { id: 'b2', routeId: 'r1', location: ROUTE_1_PATH[18], alongDistance: route1Length - 1.0, speed: 25, direction: -1, crowdLevel: 'Low', delay: 2, status: 'Running' },
  { id: 'b3', routeId: 'r2', location: ROUTE_2_PATH[5], alongDistance: 1.0, speed: 40, direction: 1, crowdLevel: 'High', delay: 5, status: 'Running' }
];

// Re-export turf tools for ETA
export { lineString, length, nearestPointOnLine, point, lineSlice };
