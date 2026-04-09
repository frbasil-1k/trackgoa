import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import { useStore } from '../../store/useStore';
import { nearestPointOnLine, point, lineString } from '@turf/turf';

const createIcon = (color: string) => {
  return new L.DivIcon({
    className: 'custom-icon',
    html: `<div style="background-color: ${color}; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>`,
    iconSize: [22, 22],
    iconAnchor: [11, 11]
  });
};

const getBusIcon = (isTracked: boolean) => new L.DivIcon({
  className: isTracked ? 'bus-icon-tracked' : 'bus-icon',
  html: `<div style="background-color: ${isTracked ? 'var(--warning)' : 'var(--primary)'}; padding: 4px; border-radius: 50%; border: 2px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; width: 28px; height: 28px; transition: all 0.3s;">
           <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 6v6"></path><path d="M15 6v6"></path><path d="M2 12h19.6"></path><path d="M18 18h3s.5-1.7.8-2.8c.1-.4.2-.8.2-1.2 0-.4-.1-.8-.2-1.2l-1.4-5C20.1 6.8 19.1 6 18 6H4a2 2 0 0 0-2 2v10h3"></path><circle cx="7" cy="18" r="2"></circle><path d="M9 18h5"></path><circle cx="16" cy="18" r="2"></circle></svg>
         </div>`,
  iconSize: [36, 36],
  iconAnchor: [18, 18]
});

const userIcon = createIcon('var(--primary)');
const stopIcon = createIcon('#64748b');
const stopIconTourist = createIcon('var(--warning)');
const customStopIcon = createIcon('var(--danger)');

const MapController = () => {
  const { userLocation, trackedBusId, buses } = useStore();
  const map = useMap();

  useEffect(() => {
    if (trackedBusId) {
      const bus = buses.find(b => b.id === trackedBusId);
      if (bus && bus.location) map.setView(bus.location, 15);
    } else {
      map.setView(userLocation, 14);
    }
  }, [trackedBusId, userLocation, map, buses]);

  return null;
};

const MapEvents = () => {
  const { routes, selectedRouteId, setCustomStop } = useStore();
  useMapEvents({
    click(e) {
      if (!selectedRouteId) return;
      const actRoute = routes.find(r => r.id === selectedRouteId);
      if (!actRoute) return;

      const pt = point([e.latlng.lng, e.latlng.lat]);
      const line = lineString(actRoute.path.map(p => [p[1], p[0]]));
      const snapped = nearestPointOnLine(line, pt, { units: 'kilometers' });

      setCustomStop([snapped.geometry.coordinates[1], snapped.geometry.coordinates[0]]);
    }
  });
  return null;
};

const MapViewer: React.FC = () => {
  const { userLocation, routes, buses, selectedRouteId, customStopLocation, touristMode, trackedBusId } = useStore();

  return (
    <div style={{ height: '100%', width: '100%' }}>
      <MapContainer center={userLocation} zoom={14} zoomControl={false} style={{ height: '100%', width: '100%' }}>
        <TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" />
        
        <MapController />
        <MapEvents />

        <Marker position={userLocation} icon={userIcon}>
          <Popup>You are here</Popup>
        </Marker>

        {routes.map(route => {
          const isSelected = selectedRouteId === route.id || selectedRouteId === null;
          if (!isSelected) return null;
          
          return (
            <React.Fragment key={route.id}>
              <Polyline 
                positions={route.path} 
                color={selectedRouteId === route.id ? 'var(--primary)' : '#94a3b8'} 
                weight={selectedRouteId === route.id ? 6 : 4} 
                opacity={0.8} 
              />
              {route.stops.map(stop => (
                <Marker key={stop.id} position={stop.location} icon={touristMode ? stopIconTourist : stopIcon}>
                  <Popup>{touristMode ? stop.touristName : stop.name}</Popup>
                </Marker>
              ))}
            </React.Fragment>
          );
        })}

        {customStopLocation && (
          <Marker position={customStopLocation} icon={customStopIcon}>
            <Popup>Your Custom Drop Point</Popup>
          </Marker>
        )}

        {buses.map(bus => {
          if (selectedRouteId && bus.routeId !== selectedRouteId) return null;

          return (
            <Marker key={bus.id} position={bus.location} icon={getBusIcon(trackedBusId === bus.id)}>
              <Popup>
                <strong>Bus {bus.id.toUpperCase()}</strong><br />
                Speed: {Math.round(bus.speed)} km/h<br />
                Status: {bus.status}
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </div>
  );
};

export default MapViewer;
