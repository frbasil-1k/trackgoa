import React from 'react';
import { useStore } from '../store/useStore';
import { Search, ArrowLeft, Heart, Navigation, Clock, Activity, Settings2, MapPin } from 'lucide-react';

const RoutesList: React.FC = () => {
  const { setScreen, routes, setSelectedRoute, toggleFavoriteRoute, favorites } = useStore();

  const handleTrack = (id: string) => {
    setSelectedRoute(id);
    setScreen('Map');
  };

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '90px' }}>
      
      {/* Header Container */}
      <div style={{ padding: '48px 24px 20px', background: 'var(--surface)', borderBottom: '1px solid var(--border-subtle)', position: 'sticky', top: 0, zIndex: 10 }}>
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-4 cursor-pointer" onClick={() => setScreen('Home')}>
            <ArrowLeft size={24} className="text-primary" />
            <h1 className="text-2xl font-bold text-primary tracking-tight">Routes</h1>
          </div>
          <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--bg-color)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border)', cursor: 'pointer' }}>
            <Settings2 size={18} className="text-primary" />
          </div>
        </div>

        <div style={{ background: 'var(--bg-color)', padding: '14px 16px', borderRadius: '16px', display: 'flex', alignItems: 'center', border: '1px solid var(--border)' }}>
          <Search size={18} className="text-muted" style={{ marginRight: '12px' }}/>
          <input type="text" placeholder="Search routes, stops, cities..." style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '15px', color: 'var(--text-main)', fontWeight: 500 }} />
        </div>
      </div>
      
      <div style={{ padding: '24px 20px' }}>
        <h2 className="font-bold text-lg mb-4 text-primary">All Routes</h2>
        
        <div className="flex flex-col gap-4">
          {routes.map(route => {
            const isFav = favorites.routes.includes(route.id);
            return (
              <div key={route.id} style={{ background: 'var(--surface)', borderRadius: 'var(--radius-2xl)', padding: '20px', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-4">
                    <div style={{ background: 'var(--bg-color)', border: '1px solid var(--border)', color: 'var(--primary)', fontWeight: 'bold', fontSize: '18px', width: '56px', height: '56px', borderRadius: '16px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                      {route.id.replace('r', '')}
                    </div>
                    <div>
                      <div className="font-bold text-lg text-primary">{route.name}</div>
                      <div className="text-xs text-muted flex items-center gap-1 mt-1">
                         <Activity size={12} /> {route.reliability}% On-Time Rating
                      </div>
                    </div>
                  </div>
                  <div onClick={() => toggleFavoriteRoute(route.id)} className="cursor-pointer" style={{ padding: '8px' }}>
                    <Heart size={22} fill={isFav ? "var(--live-color)" : "transparent"} color={isFav ? "var(--live-color)" : "var(--text-muted)"} className="transition" />
                  </div>
                </div>
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '20px' }}>
                  <div style={{ background: 'var(--bg-color)', padding: '12px', borderRadius: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{ background: 'var(--surface)', padding: '6px', borderRadius: '8px', boxShadow: 'var(--shadow-sm)' }}><MapPin size={14} className="text-accent" /></div>
                     <div>
                       <div className="text-[10px] text-muted font-semibold uppercase tracking-wider">Distance</div>
                       <div className="font-bold text-sm text-primary">{route.distanceKm.toFixed(1)} km</div>
                     </div>
                  </div>
                  <div style={{ background: 'var(--bg-color)', padding: '12px', borderRadius: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                     <div style={{ background: 'var(--surface)', padding: '6px', borderRadius: '8px', boxShadow: 'var(--shadow-sm)' }}><Clock size={14} className="text-success" /></div>
                     <div>
                       <div className="text-[10px] text-muted font-semibold uppercase tracking-wider">Stops</div>
                       <div className="font-bold text-sm text-primary">{route.stops.length} stops</div>
                     </div>
                  </div>
                </div>
                
                <button onClick={() => handleTrack(route.id)} className="w-full active:scale-95 transition" style={{ padding: '14px', background: 'var(--primary)', color: 'var(--surface)', borderRadius: '14px', fontWeight: 'bold', fontSize: '15px', border: 'none', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px', boxShadow: 'var(--shadow-sm)', cursor: 'pointer' }}>
                  <Navigation size={16} /> Track Route Real-time
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default RoutesList;
