import React, { useMemo } from 'react';
import { motion } from 'framer-motion';
import { useStore } from '../../store/useStore';
import BusCard from '../Cards/BusCard';
import type { Bus, Route } from '../../data/mockData';
import { point, lineString, lineSlice, length } from '@turf/turf';

const BottomSheet: React.FC = () => {
  const { buses, routes, customStopLocation, selectedRouteId } = useStore();

  const busListWithETA = useMemo(() => {
    return buses.map((bus: Bus) => {
      const route = routes.find((r: Route) => r.id === bus.routeId);
      if (!route) return null;

      let targetDistanceKm = 0; 

      if (customStopLocation && route.id === selectedRouteId) {
         // Exact distance from start to custom stop via turf lineSlice
         const pt = point([customStopLocation[1], customStopLocation[0]]);
         const line = lineString(route.path.map(p => [p[1], p[0]]));
         const startPt = point(line.geometry.coordinates[0]);
         
         const slice = lineSlice(startPt, pt, line);
         targetDistanceKm = length(slice, { units: 'kilometers' });
      }

      let distanceToTarget = Math.abs(bus.alongDistance - targetDistanceKm);
      const etaMins = (distanceToTarget / bus.speed) * 60;

      return { bus, route, distanceKm: distanceToTarget, etaMins };
    }).filter(Boolean) as any[];
  }, [buses, routes, customStopLocation, selectedRouteId]);

  // Sort by ETA
  const sortedBuses = [...busListWithETA].sort((a, b) => a.etaMins - b.etaMins);

  return (
    <motion.div 
      className="bottom-sheet"
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      drag="y"
      dragConstraints={{ top: 0, bottom: window.innerHeight * 0.8 }}
      dragElastic={0.2}
      whileDrag={{ cursor: 'grabbing' }}
    >
      <div className="bottom-sheet-handle" />
      
      <div style={{ padding: '0 20px 80px', overflowY: 'auto' }}>
        <div className="flex justify-between items-center mb-4" style={{ marginBottom: '16px' }}>
          <h2 className="font-bold text-lg">Nearby Buses</h2>
        </div>

        {customStopLocation && (
          <div style={{ padding: '12px', background: 'rgba(37, 99, 235, 0.1)', borderRadius: 'var(--radius)', border: '1px solid var(--primary)', marginBottom: '16px' }}>
            <p className="text-sm font-semibold" style={{ color: 'var(--primary)' }}>📍 Custom Stop ETA Mode</p>
            <p className="text-xs text-muted mt-1">Bus estimations are perfectly zeroing in on your custom pin drop.</p>
          </div>
        )}

        <div className="flex flex-col gap-3">
          {sortedBuses.length === 0 && <p className="text-muted text-sm text-center py-4">No buses currently active.</p>}
          {sortedBuses.map(({ bus, route, etaMins, distanceKm }, index) => (
            <BusCard 
              key={bus.id} 
              bus={bus} 
              route={route} 
              etaMins={etaMins} 
              distanceKm={distanceKm} 
              isBestOption={index === 0 && etaMins < 15} // Highlight best option
            />
          ))}
        </div>
      </div>
    </motion.div>
  );
};

export default BottomSheet;
