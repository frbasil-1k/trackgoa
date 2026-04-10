import React from 'react';
import { useStore } from '../store/useStore';

import { Search, MapPin, ChevronRight, Home as HomeIcon, Briefcase, GraduationCap, Plus } from 'lucide-react';

const Home: React.FC = () => {
  const { setScreen, setTrackedBus, setSelectedRoute, preferredCity, setPreferredCity } = useStore();

  const openMap = () => setScreen('Map');
  const openTracking = (busId: string, routeId: string) => {
    setSelectedRoute(routeId);
    setTrackedBus(busId);
  };

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '90px' }}>
      
      {/* Dark Blue Header Section */}
      <div style={{ padding: '48px 24px 24px', background: 'var(--primary)', color: 'white', borderBottomLeftRadius: '24px', borderBottomRightRadius: '24px', boxShadow: 'var(--shadow-md)' }}>
        
        {/* App Title & Subtitle */}
        <div className="flex justify-between items-start mb-6">
          <div>
            <h1 className="text-3xl font-bold flex items-center" style={{ letterSpacing: '-0.5px' }}>
              Track<span className="text-accent">Goa</span>
            </h1>
            <div className="flex items-center gap-1 text-xs mt-1" style={{ color: '#94a3b8' }}>
              <MapPin size={12} className="text-accent" /> Near Panaji · Live tracking
            </div>
          </div>
          {/* Compact Live Indicator */}
          <div style={{ background: 'rgba(244, 63, 94, 0.15)', padding: '6px 10px', borderRadius: 'var(--radius-full)', display: 'flex', alignItems: 'center', gap: '6px', border: '1px solid rgba(244, 63, 94, 0.3)' }}>
            <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: 'var(--live-color)', display: 'inline-block' }}></span>
            <span className="text-[10px] font-bold" style={{ color: 'var(--live-color)', letterSpacing: '0.5px' }}>LIVE</span>
          </div>
        </div>

        {/* Search Bar Inside Header */}
        <div style={{ background: 'rgba(255, 255, 255, 0.1)', padding: '14px 16px', borderRadius: '16px', display: 'flex', alignItems: 'center', marginBottom: '24px', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.05)' }}>
          <Search size={18} color="#94a3b8" style={{ marginRight: '12px' }}/>
          <input type="text" placeholder="Where do you want to go?" style={{ border: 'none', background: 'transparent', outline: 'none', width: '100%', fontSize: '15px', color: 'white' }} />
        </div>

        {/* 3 Metric Cards Inside Header */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
          <div style={{ background: 'rgba(255,255,255,0.08)', borderRadius: '16px', padding: '12px', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.05)' }}>
             <div className="font-bold text-2xl mb-1 text-white text-center">6</div>
             <div className="text-[10px] font-semibold text-center uppercase tracking-wider" style={{ color: '#94a3b8' }}>Active Buses</div>
          </div>
          <div style={{ background: 'rgba(255,255,255,0.08)', borderRadius: '16px', padding: '12px', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.05)' }}>
             <div className="font-bold text-2xl mb-1 text-white text-center">2</div>
             <div className="text-[10px] font-semibold text-center uppercase tracking-wider" style={{ color: '#94a3b8' }}>Buses Nearby</div>
          </div>
          <div style={{ background: 'rgba(255,255,255,0.08)', borderRadius: '16px', padding: '12px', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.05)' }}>
             <div className="font-bold text-2xl mb-1 text-white text-center text-success">83%</div>
             <div className="text-[10px] font-semibold text-center uppercase tracking-wider" style={{ color: '#94a3b8' }}>On-Time</div>
          </div>
        </div>
      </div>

      <div style={{ padding: '24px 20px' }}>
        
        {/* Quick Shortcut Pills */}
        <div style={{ display: 'flex', gap: '12px', overflowX: 'auto', paddingBottom: '8px', scrollbarWidth: 'none', msOverflowStyle: 'none' }} className="mb-6">
          <div className="pill" style={{ background: 'var(--surface)', border: '1px solid var(--border-subtle)' }}><HomeIcon size={14} className="text-accent" /> Home</div>
          <div className="pill" style={{ background: 'var(--surface)', border: '1px solid var(--border-subtle)' }}><Briefcase size={14} style={{ color: '#a855f7' }} /> Work</div>
          <div className="pill" style={{ background: 'var(--surface)', border: '1px solid var(--border-subtle)' }}><GraduationCap size={14} className="text-warning" /> College</div>
          <div className="pill" style={{ background: 'var(--surface)', border: '1px dashed var(--border)', color: 'var(--text-muted)' }}><Plus size={14} /> Add place</div>
        </div>

        {/* City Filter Row */}
        <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px', scrollbarWidth: 'none', msOverflowStyle: 'none' }} className="mb-8">
          {['All', 'Panaji', 'Margao', 'Vasco'].map(city => (
            <div 
              key={city} 
              onClick={() => setPreferredCity(city === 'All' ? 'All Cities' : city)}
              className="pill transition" 
              style={{ 
                background: preferredCity.includes(city) || (city === 'All' && preferredCity === 'All Cities') ? 'var(--accent)' : 'var(--bg-color)', 
                color: preferredCity.includes(city) || (city === 'All' && preferredCity === 'All Cities') ? 'white' : 'var(--text-muted)',
                border: 'none',
                boxShadow: preferredCity.includes(city) || (city === 'All' && preferredCity === 'All Cities') ? 'var(--shadow)' : 'none',
              }}
            >
              {city}
            </div>
          ))}
        </div>

        {/* Nearby Buses Section */}
        <div className="flex justify-between items-end mb-4">
          <div>
            <h2 className="font-bold text-xl text-primary tracking-tight">Buses Near You</h2>
            <div className="text-xs text-muted mt-1">Live from your area</div>
          </div>
          <span className="text-xs font-semibold text-accent cursor-pointer" onClick={openMap}>View Map</span>
        </div>

        <div className="flex flex-col gap-4 mb-8">
          <div onClick={() => openTracking('b1', 'r1')} style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-sm)', cursor: 'pointer', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: 0, right: 0, background: 'rgba(37, 99, 235, 0.1)', color: 'var(--accent)', fontSize: '10px', padding: '4px 10px', borderBottomLeftRadius: '12px', fontWeight: 'bold' }}>
              ✨ Best Option
            </div>
            
            <div className="flex justify-between items-center mb-4 mt-2">
              <div className="flex items-center gap-3">
                <div style={{ background: 'var(--bg-color)', border: '1px solid var(--border)', color: 'var(--primary)', fontWeight: 'bold', fontSize: '16px', width: '48px', height: '48px', borderRadius: '16px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  01
                </div>
                <div>
                  <div className="font-bold text-base text-primary mb-1">Panaji ➔ Miramar</div>
                  <div className="flex items-center gap-2">
                    <span style={{ fontSize: '10px', background: 'var(--success-light)', color: 'var(--success)', padding: '2px 8px', borderRadius: 'var(--radius-full)', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <span style={{ width: '4px', height: '4px', borderRadius: '50%', background: 'currentColor' }}></span> Running
                    </span>
                    <span className="text-[10px] text-muted font-bold">1.2 km away</span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="font-bold text-xl text-primary">2 <span className="text-xs text-muted">min</span></div>
              </div>
            </div>
          </div>
          
          <div onClick={() => openTracking('b3', 'r2')} style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-sm)', cursor: 'pointer' }}>
             <div className="flex justify-between items-center">
              <div className="flex items-center gap-3">
                <div style={{ background: 'var(--bg-color)', border: '1px solid var(--border)', color: 'var(--primary)', fontWeight: 'bold', fontSize: '16px', width: '48px', height: '48px', borderRadius: '16px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  12
                </div>
                <div>
                  <div className="font-bold text-base text-primary mb-1">Panaji ➔ Vasco</div>
                  <div className="flex items-center gap-2">
                    <span style={{ fontSize: '10px', background: 'var(--warning-light)', color: 'var(--warning)', padding: '2px 8px', borderRadius: 'var(--radius-full)', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <span style={{ width: '4px', height: '4px', borderRadius: '50%', background: 'currentColor' }}></span> Delayed
                    </span>
                    <span className="text-[10px] text-muted font-bold">5.4 km away</span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="font-bold text-xl text-primary">15 <span className="text-xs text-muted">min</span></div>
              </div>
            </div>
          </div>
        </div>

        {/* Live Routes Section */}
        <div className="flex justify-between items-end mb-4">
          <div>
            <h2 className="font-bold text-xl text-primary tracking-tight">Live Routes</h2>
            <div className="text-xs text-muted mt-1">Explore all network lines</div>
          </div>
          <span className="text-xs font-semibold text-accent cursor-pointer" onClick={() => setScreen('Routes')}>View All</span>
        </div>
        
        <div className="flex flex-col gap-4">
          <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', padding: '20px', border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-sm)' }}>
             <div className="flex justify-between items-start mb-4">
               <div>
                  <div className="font-bold text-base text-primary mb-1">KTC-07</div>
                  <div className="text-xs text-muted font-semibold">Margao ➔ Fatorda</div>
               </div>
               <span style={{ fontSize: '10px', background: 'var(--success-light)', color: 'var(--success)', padding: '4px 8px', borderRadius: 'var(--radius-full)', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                 LIVE
               </span>
             </div>
             
             <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr) minmax(0, 1fr)', gap: '8px', marginBottom: '16px' }}>
                <div style={{ background: 'var(--bg-color)', padding: '10px 8px', borderRadius: '12px', textAlign: 'center', border: '1px solid var(--border)' }}>
                   <div className="text-[10px] text-muted mb-1 font-semibold uppercase tracking-wider">Duration</div>
                   <div className="font-bold text-sm text-primary">12 min</div>
                </div>
                <div style={{ background: 'var(--bg-color)', padding: '10px 8px', borderRadius: '12px', textAlign: 'center', border: '1px solid var(--border)' }}>
                   <div className="text-[10px] text-muted mb-1 font-semibold uppercase tracking-wider">Reliability</div>
                   <div className="font-bold text-sm" style={{ color: 'var(--success)' }}>79%</div>
                </div>
                <div style={{ background: 'var(--bg-color)', padding: '10px 8px', borderRadius: '12px', textAlign: 'center', border: '1px solid var(--border)' }}>
                   <div className="text-[10px] text-muted mb-1 font-semibold uppercase tracking-wider">Frequency</div>
                   <div className="font-bold text-sm text-primary">10 min</div>
                </div>
             </div>
             
             <button onClick={() => { setSelectedRoute('r3'); setScreen('Map'); }} className="w-full active:scale-95 transition" style={{ padding: '12px', background: 'var(--bg-color)', color: 'var(--primary)', borderRadius: '12px', fontWeight: 'bold', fontSize: '14px', border: '1px solid var(--border)', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                Track Route <ChevronRight size={14} />
             </button>
          </div>
        </div>

      </div>
    </div>
  );
};

export default Home;
