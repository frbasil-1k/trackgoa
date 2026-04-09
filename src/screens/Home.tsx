import React from 'react';
import { useStore } from '../store/useStore';
import type { Route } from '../data/mockData';
import { Search, Map, ChevronRight, Bus as BusIcon } from 'lucide-react';

const Home: React.FC = () => {
  const { setScreen, routes, favorites } = useStore();

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '80px' }}>
      
      {/* Header Container */}
      <div style={{ padding: '32px 20px 48px', background: 'var(--primary)', color: 'white', borderBottomLeftRadius: '24px', borderBottomRightRadius: '24px' }}>
        <div className="flex justify-between items-center mb-6">
          <div>
            <div className="text-sm opacity-80">Good Afternoon,</div>
            <h1 className="text-2xl font-bold">Where to today?</h1>
          </div>
          <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span className="font-bold">JD</span>
          </div>
        </div>

        <div className="glass" style={{ background: 'white', color: 'var(--text-main)', padding: '12px 16px', borderRadius: 'var(--radius-lg)', display: 'flex', alignItems: 'center', boxShadow: 'var(--shadow-md)' }}>
          <Search size={20} color="var(--text-muted)" style={{ marginRight: '12px' }}/>
          <input type="text" placeholder="Search for routes or stops..." style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '15px' }} />
        </div>
      </div>

      <div style={{ padding: '20px', marginTop: '-24px' }}>
        
        {/* Quick Actions */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '24px' }}>
          <button onClick={() => setScreen('Map')} className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', border: 'none', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px', cursor: 'pointer', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ background: 'rgba(37,99,235,0.1)', padding: '12px', borderRadius: '50%', color: 'var(--primary)' }}><Map size={24} /></div>
            <span className="font-semibold text-sm">Live Map</span>
          </button>
          <button onClick={() => setScreen('Favorites')} className="glass" style={{ padding: '16px', borderRadius: 'var(--radius)', border: 'none', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px', cursor: 'pointer', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ background: 'rgba(16,185,129,0.1)', padding: '12px', borderRadius: '50%', color: 'var(--success)' }}><BusIcon size={24} /></div>
            <span className="font-semibold text-sm">Saved Routes</span>
          </button>
        </div>

        <h2 className="font-bold text-lg mb-3" style={{ marginBottom: '12px' }}>Your regular routes</h2>
        
        <div className="flex flex-col gap-3">
          {favorites.routes.map((fid: string) => {
            const route = routes.find((r: Route) => r.id === fid);
            if (!route) return null;
            return (
              <div key={fid} onClick={() => setScreen('Map')} className="glass flex justify-between items-center" style={{ padding: '16px', borderRadius: 'var(--radius)', border: '1px solid var(--border)', cursor: 'pointer' }}>
                <div className="flex items-center gap-3">
                  <div style={{ background: 'var(--bg-color)', width: '36px', height: '36px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>
                    <BusIcon size={16} />
                  </div>
                  <div>
                    <div className="font-bold text-sm">{route.name}</div>
                    <div className="text-xs text-muted">{route.stops.length} stops</div>
                  </div>
                </div>
                <ChevronRight size={20} color="var(--text-muted)" />
              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
};

export default Home;
