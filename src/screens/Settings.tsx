import React from 'react';
import { useStore } from '../store/useStore';
import { ArrowLeft, Wifi, Radio, Bell, Moon } from 'lucide-react';

const Settings: React.FC = () => {
  const { setScreen, lowBandwidthMode, setLowBandwidthMode, liveSimulation, setLiveSimulation, preferredCity, setPreferredCity } = useStore();

  return (
    <div style={{ height: '100%', width: '100%', background: 'var(--bg-color)', overflowY: 'auto', paddingBottom: '90px' }}>
      
      {/* Header */}
      <div style={{ padding: '48px 24px 16px', background: 'var(--surface)', position: 'sticky', top: 0, zIndex: 10 }}>
        <div className="flex items-center gap-4 mb-4" onClick={() => setScreen('Home')} style={{ cursor: 'pointer' }}>
          <ArrowLeft size={24} className="text-primary" />
          <h1 className="text-2xl font-bold text-primary tracking-tight">Settings</h1>
        </div>
      </div>
      
      <div style={{ padding: '24px 20px' }}>
        
        {/* GENERAL SECTION */}
        <h3 className="text-[11px] font-bold text-muted mb-3 ml-2 uppercase tracking-widest">Preferences</h3>
        
        <div className="flex flex-col mb-8" style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)', overflow: 'hidden' }}>
          <div className="flex justify-between items-center" style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-subtle)' }}>
             <div className="flex items-center gap-4">
               <div style={{ background: 'var(--bg-color)', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--accent)' }}>
                 <Wifi size={18} />
               </div>
               <div>
                 <div className="font-bold text-sm text-primary">Low Bandwidth Mode</div>
                 <div className="text-xs text-muted">Less animations, basic map</div>
               </div>
             </div>
             
             {/* Toggle */}
             <div onClick={() => setLowBandwidthMode(!lowBandwidthMode)} style={{ width: '48px', height: '28px', borderRadius: '14px', background: lowBandwidthMode ? 'var(--accent)' : 'var(--bg-color)', border: lowBandwidthMode ? '1px solid transparent' : '1px solid var(--border)', position: 'relative', cursor: 'pointer', transition: 'var(--transition)' }}>
               <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: 'var(--surface)', position: 'absolute', top: '2px', left: lowBandwidthMode ? '22px' : '2px', transition: 'var(--transition)', boxShadow: 'var(--shadow-sm)' }}></div>
             </div>
          </div>

          <div className="flex justify-between items-center" style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-subtle)' }}>
             <div className="flex items-center gap-4">
               <div style={{ background: 'var(--bg-color)', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--warning)' }}>
                 <Radio size={18} />
               </div>
               <div>
                 <div className="font-bold text-sm text-primary">Live Simulation</div>
                 <div className="text-xs text-muted">Buses move automatically</div>
               </div>
             </div>
             
             <div onClick={() => setLiveSimulation(!liveSimulation)} style={{ width: '48px', height: '28px', borderRadius: '14px', background: liveSimulation ? 'var(--success)' : 'var(--bg-color)', border: liveSimulation ? '1px solid transparent' : '1px solid var(--border)', position: 'relative', cursor: 'pointer', transition: 'var(--transition)' }}>
               <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: 'var(--surface)', position: 'absolute', top: '2px', left: liveSimulation ? '22px' : '2px', transition: 'var(--transition)', boxShadow: 'var(--shadow-sm)' }}></div>
             </div>
          </div>
          
          <div className="flex justify-between items-center" style={{ padding: '16px 20px' }}>
             <div className="flex items-center gap-4">
               <div style={{ background: 'var(--bg-color)', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>
                 <Moon size={18} />
               </div>
               <div>
                 <div className="font-bold text-sm text-primary">Night Mode</div>
                 <div className="text-xs text-muted">System default</div>
               </div>
             </div>
          </div>
        </div>

        {/* REGION SECTION */}
        <h3 className="text-[11px] font-bold text-muted mb-3 ml-2 uppercase tracking-widest">Region</h3>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '32px' }}>
           {['All Goa', 'Panaji', 'Margao', 'Vasco'].map(city => (
             <div key={city} onClick={() => setPreferredCity(city)} style={{
               padding: '16px', borderRadius: 'var(--radius-xl)', textAlign: 'center', cursor: 'pointer',
               border: preferredCity === city ? '2px solid var(--accent)' : '1px solid var(--border)',
               background: 'var(--surface)',
               color: 'var(--primary)',
               boxShadow: preferredCity === city ? 'var(--shadow-sm)' : 'none',
               fontWeight: 'bold', fontSize: '13px', transition: 'var(--transition)'
             }}>
               {city}
             </div>
           ))}
        </div>

        {/* ALERTS SECTION */}
        <h3 className="text-[11px] font-bold text-muted mb-3 ml-2 uppercase tracking-widest">Notifications</h3>
        
        <div className="flex flex-col mb-8" style={{ background: 'var(--surface)', borderRadius: 'var(--radius-xl)', border: '1px solid var(--border)', boxShadow: 'var(--shadow-sm)' }}>
          <div className="flex justify-between items-center" style={{ padding: '16px 20px' }}>
             <div className="flex items-center gap-4">
               <div style={{ background: 'var(--danger-light)', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--danger)' }}>
                 <Bell size={18} />
               </div>
               <div>
                 <div className="font-bold text-sm text-primary">Smart Alerts</div>
                 <div className="text-xs text-muted">Notify 2 stops before arrival</div>
               </div>
             </div>
             
             <div style={{ width: '48px', height: '28px', borderRadius: '14px', background: 'var(--accent)', border: '1px solid transparent', position: 'relative', cursor: 'pointer' }}>
               <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: 'var(--surface)', position: 'absolute', top: '2px', left: '22px', boxShadow: 'var(--shadow-sm)' }}></div>
             </div>
          </div>
        </div>
        
      </div>
    </div>
  );
};

export default Settings;
