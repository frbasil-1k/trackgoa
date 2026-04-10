import React, { useState } from 'react';
import { useStore } from '../store/useStore';
import { ArrowLeft, Plus, Heart, MapPin, Search, Navigation, Activity, Clock } from 'lucide-react';

const Saved: React.FC = () => {
  const { setScreen, routes, favorites, toggleFavoriteRoute, setSelectedRoute } = useStore();
  const [activeTab, setActiveTab] = useState<'Routes' | 'Places'>('Routes');

  const savedRoutes = routes.filter(r => favorites.routes.includes(r.id));

  const handleTrack = (id: string) => {
    setSelectedRoute(id);
    setScreen('Map');
  };

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '90px' }}>
      
      {/* Premium minimal header */}
      <div style={{ padding: '48px 24px 20px', background: 'var(--surface)', position: 'sticky', top: 0, zIndex: 10 }}>
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-4 cursor-pointer" onClick={() => setScreen('Home')}>
            <ArrowLeft size={24} className="text-primary" />
            <h1 className="text-2xl font-bold text-primary tracking-tight">Saved</h1>
          </div>
          <button style={{ background: 'var(--bg-color)', color: 'var(--primary)', border: '1px solid var(--border)', padding: '8px 16px', borderRadius: 'var(--radius-full)', fontSize: '13px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px', cursor: 'pointer', boxShadow: 'var(--shadow-sm)' }}>
            <Plus size={14} /> Add Place
          </button>
        </div>

        {/* Tabs */}
        <div style={{ background: 'var(--bg-color)', padding: '4px', borderRadius: 'var(--radius-full)', display: 'flex', border: '1px solid var(--border-subtle)' }}>
           <button onClick={() => setActiveTab('Routes')} className="transition" style={{ 
             background: activeTab === 'Routes' ? 'var(--surface)' : 'transparent', 
             color: activeTab === 'Routes' ? 'var(--primary)' : 'var(--text-muted)',
             border: 'none', padding: '10px 16px', borderRadius: 'var(--radius-full)', fontSize: '14px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '6px', flex: 1, justifyContent: 'center',
             boxShadow: activeTab === 'Routes' ? 'var(--shadow-sm)' : 'none', cursor: 'pointer'
           }}>
             <Heart size={16} /> Routes
           </button>
           <button onClick={() => setActiveTab('Places')} className="transition" style={{ 
             background: activeTab === 'Places' ? 'var(--surface)' : 'transparent', 
             color: activeTab === 'Places' ? 'var(--primary)' : 'var(--text-muted)',
             border: 'none', padding: '10px 16px', borderRadius: 'var(--radius-full)', fontSize: '14px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '6px', flex: 1, justifyContent: 'center',
             boxShadow: activeTab === 'Places' ? 'var(--shadow-sm)' : 'none', cursor: 'pointer'
           }}>
             <MapPin size={16} /> Places
           </button>
        </div>
      </div>
      
      {activeTab === 'Routes' && savedRoutes.length === 0 && (
        <div style={{ padding: '40px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', minHeight: '50vh' }}>
          <div style={{ background: 'var(--surface)', width: '88px', height: '88px', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '24px', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
            <Heart size={40} className="text-muted" strokeWidth={1.5} />
          </div>
          
          <h2 className="font-bold text-xl mb-2 text-primary">No saved routes yet</h2>
          <p className="text-sm text-muted mb-8" style={{ maxWidth: '80%', lineHeight: '1.5' }}>
            Tap the heart icon on any route to save it here for quick access.
          </p>
          
          <button onClick={() => setScreen('Routes')} className="active:scale-95 transition" style={{ background: 'var(--primary)', color: 'var(--surface)', border: 'none', padding: '14px 28px', borderRadius: 'var(--radius-full)', fontSize: '15px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', boxShadow: 'var(--shadow-md)' }}>
            <Search size={16} /> Browse Routes
          </button>
        </div>
      )}

      {activeTab === 'Routes' && savedRoutes.length > 0 && (
        <div style={{ padding: '24px 20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {savedRoutes.map(route => (
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
                  <Heart size={22} fill="var(--live-color)" color="var(--live-color)" className="transition" />
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
          ))}
        </div>
      )}

      {activeTab === 'Places' && (
         <div style={{ padding: '40px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', minHeight: '50vh' }}>
          <div style={{ background: 'var(--surface)', width: '88px', height: '88px', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '24px', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
            <MapPin size={40} className="text-muted" strokeWidth={1.5} />
          </div>
          <h2 className="font-bold text-xl mb-2 text-primary">No saved places yet</h2>
          <p className="text-sm text-muted">Add locations like Home or Work for quicker routing.</p>
        </div>
      )}
      
    </div>
  );
};

export default Saved;
