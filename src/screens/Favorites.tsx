import React from 'react';
import { useStore } from '../store/useStore';
import type { Route } from '../data/mockData';
import { Heart, MapPin, Navigation } from 'lucide-react';

const Favorites: React.FC = () => {
  const { routes, favorites, setSelectedRoute, setScreen } = useStore();

  const handleRouteClick = (routeId: string) => {
    setSelectedRoute(routeId);
    setScreen('Map');
  };

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '80px' }}>
      
      <div style={{ padding: '24px 20px', background: 'var(--primary)', color: 'white' }}>
        <h1 className="text-lg font-bold">Your Favorites</h1>
        <p className="text-sm" style={{ opacity: 0.8 }}>Quick access to your regular paths</p>
      </div>

      <div style={{ padding: '20px' }}>
        <h2 className="font-semibold mb-4" style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Heart size={18} color="var(--danger)" fill="var(--danger)" /> Saved Routes
        </h2>
        
        <div className="flex flex-col gap-3">
          {favorites.routes.map((fid: string) => {
            const route = routes.find((r: Route) => r.id === fid);
            if (!route) return null;
            return (
              <div key={fid} className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', border: '1px solid var(--border)' }}>
                <div className="flex justify-between items-center mb-2">
                  <div className="font-bold">{route.name}</div>
                  <span className="text-xs" style={{ background: 'var(--success)', color: 'white', padding: '2px 8px', borderRadius: '12px' }}>{route.reliability}% Reliable</span>
                </div>
                <div className="text-sm text-muted mb-3">{route.stops.length} stops • {route.distanceKm.toFixed(1)} km</div>
                <button onClick={() => handleRouteClick(route.id)} style={{
                  width: '100%', padding: '10px', borderRadius: 'var(--radius)',
                  background: 'var(--primary)', border: 'none', color: 'white',
                  fontWeight: 600, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px'
                }}>
                  <Navigation size={16} /> Track Now
                </button>
              </div>
            );
          })}
          {favorites.routes.length === 0 && <p className="text-sm text-muted">No favorite routes saved.</p>}
        </div>

        <h2 className="font-semibold mb-4" style={{ marginTop: '32px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <MapPin size={18} color="var(--primary)" /> Saved Locations
        </h2>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
           <div className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', textAlign: 'center' }}>
              <div style={{ background: 'rgba(37,99,235,0.1)', width: '40px', height: '40px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px', color: 'var(--primary)' }}>
                <HomeIcon size={20} />
              </div>
              <div className="font-bold text-sm">Home</div>
              <div className="text-xs text-muted">Panaji Area</div>
           </div>
           <div className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', textAlign: 'center' }}>
              <div style={{ background: 'rgba(245,158,11,0.1)', width: '40px', height: '40px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px', color: 'var(--warning)' }}>
                <GraduationCap size={20} />
              </div>
              <div className="font-bold text-sm">College</div>
              <div className="text-xs text-muted">St. Inez</div>
           </div>
        </div>

      </div>
    </div>
  );
};

// SVG Icons since I didn't import them above
const HomeIcon = ({ size }: any) => <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>;
const GraduationCap = ({ size }: any) => <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>;

export default Favorites;
