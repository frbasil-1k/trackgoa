import { useStore } from '../store/useStore';
import { lineString } from '../data/mockData';
import { along } from '@turf/turf';

let simulationInterval: number | null = null;
const SIMULATION_TICK_MS = 1000; 
const TIME_SCALE = 15; // Speed up reality

export const startSimulation = () => {
  if (simulationInterval) clearInterval(simulationInterval);

  simulationInterval = window.setInterval(() => {
    const state = useStore.getState();
    const { buses, routes, setBuses, activeAlerts, triggeredAlerts, triggerAlert } = state;

    const updatedBuses = buses.map(bus => {
      const route = routes.find(r => r.id === bus.routeId);
      if (!route) return bus;

      // Handle Paused state at stops
      if (bus.status === 'Stopped') {
        if (bus.pausedCounter && bus.pausedCounter > 0) {
          return { ...bus, pausedCounter: bus.pausedCounter - 1 };
        } else {
          return { ...bus, status: 'Running', pausedCounter: undefined };
        }
      }

      const distanceMoved = bus.speed * (SIMULATION_TICK_MS / 3600000) * TIME_SCALE;
      let newAlongDistance = bus.alongDistance + (distanceMoved * bus.direction);
      let newDirection = bus.direction;

      // Check if near any stop to trigger a pause
      // Only pause if we just crossed the stop threshold
      let shouldPause = false;
      for (const stop of route.stops) {
        // If the bus crossed the stop distance in this tick
        if (
           (bus.direction === 1 && bus.alongDistance < stop.distanceKm && newAlongDistance >= stop.distanceKm) ||
           (bus.direction === -1 && bus.alongDistance > stop.distanceKm && newAlongDistance <= stop.distanceKm)
        ) {
          shouldPause = true;
          newAlongDistance = stop.distanceKm; // Snap exactly to stop
          break;
        }
      }

      // Bounce at ends
      if (newAlongDistance > route.distanceKm) {
        newAlongDistance = route.distanceKm;
        newDirection = -1; 
        shouldPause = true;
      } else if (newAlongDistance < 0) {
        newAlongDistance = 0;
        newDirection = 1;
        shouldPause = true;
      }

      // Format location
      const geoJsonLine = lineString(route.path.map(p => [p[1], p[0]]));
      const newPosPoint = along(geoJsonLine, newAlongDistance, { units: 'kilometers' });
      const newLat = newPosPoint.geometry.coordinates[1];
      const newLng = newPosPoint.geometry.coordinates[0];

      const updatedBus = {
        ...bus,
        alongDistance: newAlongDistance,
        direction: newDirection,
        location: [newLat, newLng] as [number, number],
        status: shouldPause ? 'Stopped' : 'Running',
        pausedCounter: shouldPause ? 3 : undefined, // pause for 3 ticks
      } as any;

      // --- Alerts Simulation Trigger ---
      // Check active alerts for this bus
      activeAlerts.forEach(alert => {
        if (alert.busId === bus.id && !triggeredAlerts.includes(alert.id)) {
           // Basic alert trigger logic: if alert type is Time e.g., < 2 mins away from start point (demo assumption)
           const distToUser = newAlongDistance; // simplifying user at 0
           const etaMins = (distToUser / bus.speed) * 60;
           if (alert.type === 'Time' && etaMins <= alert.value) {
             triggerAlert(alert.id);
             // Fire a mock system toast (since we use DOM for rapid PWA toast)
             window.dispatchEvent(new CustomEvent('smart-alert', { detail: alert.message }));
           }
        }
      });

      return updatedBus;
    });

    setBuses(updatedBuses);
  }, SIMULATION_TICK_MS);
};

export const stopSimulation = () => {
  if (simulationInterval) {
    clearInterval(simulationInterval);
    simulationInterval = null;
  }
};
